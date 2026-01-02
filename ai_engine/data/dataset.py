"""
Dataset Module for Tea Leaf Disease Detection
==============================================
Custom dataset class for loading and processing tea leaf images with annotations.
"""

import os
import cv2
import torch
import numpy as np
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Callable
from torch.utils.data import Dataset, DataLoader
import json
import yaml
import random
from .augmentation import TeaLeafAugmentationPipeline, MosaicAugmentation, MixUpAugmentation


class TeaLeafDataset(Dataset):
    """
    PyTorch Dataset for tea leaf disease detection.
    Supports YOLO format annotations with optional mosaic and mixup augmentation.
    """

    def __init__(
        self,
        data_dir: str,
        mode: str = "train",
        image_size: Tuple[int, int] = (640, 640),
        use_mosaic: bool = True,
        use_mixup: bool = True,
        mosaic_prob: float = 0.5,
        mixup_prob: float = 0.1
    ):
        """
        Initialize dataset.

        Args:
            data_dir: Root directory containing images/ and labels/ subdirectories
            mode: 'train', 'val', or 'test'
            image_size: Target image size (width, height)
            use_mosaic: Whether to use mosaic augmentation
            use_mixup: Whether to use mixup augmentation
            mosaic_prob: Probability of applying mosaic
            mixup_prob: Probability of applying mixup
        """
        self.data_dir = Path(data_dir)
        self.mode = mode
        self.image_size = image_size
        self.use_mosaic = use_mosaic and mode == "train"
        self.use_mixup = use_mixup and mode == "train"
        self.mosaic_prob = mosaic_prob
        self.mixup_prob = mixup_prob

        # Initialize augmentation pipeline
        self.transform = TeaLeafAugmentationPipeline(
            image_size=image_size,
            mode=mode
        )

        # Initialize mosaic and mixup
        self.mosaic_aug = MosaicAugmentation(image_size) if self.use_mosaic else None
        self.mixup_aug = MixUpAugmentation(alpha=0.5) if self.use_mixup else None

        # Load image and label paths
        self.image_paths = []
        self.label_paths = []
        self._load_data_paths()

        # Class names
        self.class_names = ["healthy", "red_rust", "blister_blight"]
        self.num_classes = len(self.class_names)

    def _load_data_paths(self):
        """Load all image and label file paths."""
        images_dir = self.data_dir / "images" / self.mode
        labels_dir = self.data_dir / "labels" / self.mode

        if not images_dir.exists():
            # Try alternate structure
            images_dir = self.data_dir / self.mode / "images"
            labels_dir = self.data_dir / self.mode / "labels"

        if not images_dir.exists():
            raise ValueError(f"Images directory not found: {images_dir}")

        # Supported image formats
        image_extensions = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}

        for img_path in sorted(images_dir.iterdir()):
            if img_path.suffix.lower() in image_extensions:
                self.image_paths.append(img_path)

                # Find corresponding label file
                label_path = labels_dir / (img_path.stem + ".txt")
                if label_path.exists():
                    self.label_paths.append(label_path)
                else:
                    # Empty label (no detections)
                    self.label_paths.append(None)

        print(f"Loaded {len(self.image_paths)} images for {self.mode} set")

    def _load_image(self, index: int) -> np.ndarray:
        """Load image at given index."""
        img_path = self.image_paths[index]
        image = cv2.imread(str(img_path))
        if image is None:
            raise ValueError(f"Failed to load image: {img_path}")
        return image

    def _load_labels(self, index: int) -> Tuple[List[List[float]], List[int]]:
        """Load labels (bounding boxes and class ids) at given index."""
        label_path = self.label_paths[index]

        bboxes = []
        class_ids = []

        if label_path is not None and label_path.exists():
            with open(label_path, 'r') as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) >= 5:
                        class_id = int(parts[0])
                        x_center = float(parts[1])
                        y_center = float(parts[2])
                        width = float(parts[3])
                        height = float(parts[4])

                        bboxes.append([x_center, y_center, width, height])
                        class_ids.append(class_id)

        return bboxes, class_ids

    def __len__(self) -> int:
        return len(self.image_paths)

    def __getitem__(self, index: int) -> Dict:
        """Get item with augmentation."""
        # Apply mosaic with probability
        if self.use_mosaic and random.random() < self.mosaic_prob:
            return self._get_mosaic_item(index)

        # Apply mixup with probability
        if self.use_mixup and random.random() < self.mixup_prob:
            return self._get_mixup_item(index)

        # Standard augmentation
        return self._get_standard_item(index)

    def _get_standard_item(self, index: int) -> Dict:
        """Get item with standard augmentation."""
        image = self._load_image(index)
        bboxes, class_ids = self._load_labels(index)

        # Apply transforms
        if bboxes:
            transformed = self.transform(
                image=image,
                bboxes=bboxes,
                class_labels=class_ids
            )
            image_tensor = transformed['image']
            bboxes = transformed['bboxes']
            class_ids = transformed['class_labels']
        else:
            transformed = self.transform(image=image)
            image_tensor = transformed['image']
            bboxes = []
            class_ids = []

        # Convert to target tensor format
        targets = self._format_targets(bboxes, class_ids)

        return {
            'image': image_tensor,
            'targets': targets,
            'image_path': str(self.image_paths[index]),
            'original_size': image.shape[:2]
        }

    def _get_mosaic_item(self, index: int) -> Dict:
        """Get item with mosaic augmentation."""
        # Get 4 random indices including current
        indices = [index] + random.choices(range(len(self)), k=3)

        images = []
        all_bboxes = []
        all_labels = []

        for idx in indices:
            img = self._load_image(idx)
            bboxes, labels = self._load_labels(idx)
            images.append(img)
            all_bboxes.append(bboxes)
            all_labels.append(labels)

        # Apply mosaic
        mosaic_img, combined_bboxes, combined_labels = self.mosaic_aug(
            images, all_bboxes, all_labels
        )

        # Apply standard transforms
        if combined_bboxes:
            transformed = self.transform(
                image=mosaic_img,
                bboxes=combined_bboxes,
                class_labels=combined_labels
            )
            image_tensor = transformed['image']
            bboxes = transformed['bboxes']
            class_ids = transformed['class_labels']
        else:
            transformed = self.transform(image=mosaic_img)
            image_tensor = transformed['image']
            bboxes = []
            class_ids = []

        targets = self._format_targets(bboxes, class_ids)

        return {
            'image': image_tensor,
            'targets': targets,
            'image_path': str(self.image_paths[index]),
            'original_size': mosaic_img.shape[:2]
        }

    def _get_mixup_item(self, index: int) -> Dict:
        """Get item with mixup augmentation."""
        # Get second random index
        index2 = random.randint(0, len(self) - 1)

        img1 = self._load_image(index)
        img2 = self._load_image(index2)
        bboxes1, labels1 = self._load_labels(index)
        bboxes2, labels2 = self._load_labels(index2)

        # Apply mixup
        mixed_img, combined_bboxes, combined_labels, lam = self.mixup_aug(
            img1, img2, bboxes1, bboxes2, labels1, labels2
        )

        # Apply standard transforms
        if combined_bboxes:
            transformed = self.transform(
                image=mixed_img,
                bboxes=combined_bboxes,
                class_labels=combined_labels
            )
            image_tensor = transformed['image']
            bboxes = transformed['bboxes']
            class_ids = transformed['class_labels']
        else:
            transformed = self.transform(image=mixed_img)
            image_tensor = transformed['image']
            bboxes = []
            class_ids = []

        targets = self._format_targets(bboxes, class_ids)

        return {
            'image': image_tensor,
            'targets': targets,
            'image_path': str(self.image_paths[index]),
            'original_size': mixed_img.shape[:2],
            'mixup_ratio': lam
        }

    def _format_targets(
        self,
        bboxes: List[List[float]],
        class_ids: List[int]
    ) -> torch.Tensor:
        """
        Format targets for YOLO training.

        Returns:
            Tensor of shape (N, 6) where each row is [batch_idx, class_id, x, y, w, h]
        """
        if not bboxes:
            return torch.zeros((0, 6))

        targets = []
        for bbox, class_id in zip(bboxes, class_ids):
            targets.append([0, class_id] + list(bbox))

        return torch.tensor(targets, dtype=torch.float32)


def create_dataloaders(
    data_dir: str,
    batch_size: int = 16,
    image_size: Tuple[int, int] = (640, 640),
    num_workers: int = 4
) -> Tuple[DataLoader, DataLoader, Optional[DataLoader]]:
    """
    Create train, validation, and test dataloaders.

    Args:
        data_dir: Root data directory
        batch_size: Batch size
        image_size: Target image size
        num_workers: Number of data loading workers

    Returns:
        Tuple of (train_loader, val_loader, test_loader)
    """
    train_dataset = TeaLeafDataset(
        data_dir=data_dir,
        mode="train",
        image_size=image_size,
        use_mosaic=True,
        use_mixup=True
    )

    val_dataset = TeaLeafDataset(
        data_dir=data_dir,
        mode="val",
        image_size=image_size,
        use_mosaic=False,
        use_mixup=False
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True,
        collate_fn=collate_fn
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True,
        collate_fn=collate_fn
    )

    # Try to create test loader
    test_loader = None
    try:
        test_dataset = TeaLeafDataset(
            data_dir=data_dir,
            mode="test",
            image_size=image_size,
            use_mosaic=False,
            use_mixup=False
        )
        test_loader = DataLoader(
            test_dataset,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
            pin_memory=True,
            collate_fn=collate_fn
        )
    except Exception:
        print("No test set found, using validation set for testing")

    return train_loader, val_loader, test_loader


def collate_fn(batch: List[Dict]) -> Dict:
    """Custom collate function for variable-sized targets."""
    images = torch.stack([item['image'] for item in batch])

    # Adjust batch index in targets
    targets = []
    for i, item in enumerate(batch):
        target = item['targets'].clone()
        if len(target) > 0:
            target[:, 0] = i  # Set batch index
        targets.append(target)

    targets = torch.cat(targets, dim=0) if targets else torch.zeros((0, 6))

    return {
        'images': images,
        'targets': targets,
        'image_paths': [item['image_path'] for item in batch],
        'original_sizes': [item['original_size'] for item in batch]
    }


def generate_dataset_yaml(
    data_dir: str,
    output_path: str,
    class_names: List[str] = None
) -> str:
    """
    Generate YOLO-format dataset configuration YAML file.

    Args:
        data_dir: Root data directory
        output_path: Where to save the YAML file
        class_names: List of class names

    Returns:
        Path to generated YAML file
    """
    if class_names is None:
        class_names = ["healthy", "red_rust", "blister_blight"]

    data_dir = Path(data_dir)

    config = {
        'path': str(data_dir.absolute()),
        'train': 'images/train',
        'val': 'images/val',
        'test': 'images/test',
        'nc': len(class_names),
        'names': class_names
    }

    with open(output_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

    return output_path
