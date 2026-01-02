"""
Data Augmentation Module for Tea Leaf Disease Detection
========================================================
Specialized augmentations for field conditions: variable lighting,
overlapping leaves, complex backgrounds, and camera quality variations.
"""

import cv2
import numpy as np
import albumentations as A
from albumentations.pytorch import ToTensorV2
from typing import Tuple, List, Dict, Optional, Callable
import random


class TeaLeafAugmentationPipeline:
    """
    Comprehensive augmentation pipeline optimized for tea plantation field conditions.
    """

    def __init__(
        self,
        image_size: Tuple[int, int] = (640, 640),
        mode: str = "train"
    ):
        """
        Initialize augmentation pipeline.

        Args:
            image_size: Target image size (width, height)
            mode: 'train', 'val', or 'test'
        """
        self.image_size = image_size
        self.mode = mode
        self.transform = self._build_transform()

    def _build_transform(self) -> A.Compose:
        """Build augmentation pipeline based on mode."""
        if self.mode == "train":
            return self._build_train_transform()
        elif self.mode == "val":
            return self._build_val_transform()
        else:
            return self._build_test_transform()

    def _build_train_transform(self) -> A.Compose:
        """Build training augmentation pipeline with field-realistic transforms."""
        return A.Compose([
            # Geometric transforms
            A.HorizontalFlip(p=0.5),
            A.VerticalFlip(p=0.1),
            A.Rotate(limit=15, border_mode=cv2.BORDER_REFLECT_101, p=0.5),
            A.Affine(
                scale=(0.8, 1.2),
                translate_percent=(-0.1, 0.1),
                rotate=(-10, 10),
                shear=(-5, 5),
                p=0.3
            ),

            # Simulate variable field lighting conditions
            A.OneOf([
                A.RandomBrightnessContrast(
                    brightness_limit=0.3,
                    contrast_limit=0.2,
                    p=1.0
                ),
                A.RandomGamma(gamma_limit=(70, 130), p=1.0),
                A.CLAHE(clip_limit=4.0, tile_grid_size=(8, 8), p=1.0),
            ], p=0.7),

            # Color variations (leaf color can vary)
            A.HueSaturationValue(
                hue_shift_limit=10,
                sat_shift_limit=20,
                val_shift_limit=20,
                p=0.5
            ),
            A.ColorJitter(
                brightness=0.2,
                contrast=0.2,
                saturation=0.2,
                hue=0.02,
                p=0.3
            ),

            # Simulate weather and atmospheric conditions
            A.OneOf([
                A.RandomFog(fog_coef_lower=0.1, fog_coef_upper=0.3, p=1.0),
                A.RandomSunFlare(
                    flare_roi=(0, 0, 1, 0.5),
                    angle_lower=0,
                    angle_upper=1,
                    num_flare_circles_lower=1,
                    num_flare_circles_upper=2,
                    src_radius=100,
                    p=1.0
                ),
                A.RandomShadow(
                    shadow_roi=(0, 0.5, 1, 1),
                    num_shadows_lower=1,
                    num_shadows_upper=3,
                    shadow_dimension=5,
                    p=1.0
                ),
            ], p=0.3),

            # Camera quality variations
            A.OneOf([
                A.GaussNoise(var_limit=(10, 50), p=1.0),
                A.ISONoise(color_shift=(0.01, 0.05), intensity=(0.1, 0.5), p=1.0),
                A.MultiplicativeNoise(multiplier=(0.9, 1.1), p=1.0),
            ], p=0.3),

            A.OneOf([
                A.MotionBlur(blur_limit=5, p=1.0),
                A.GaussianBlur(blur_limit=(3, 5), p=1.0),
                A.Defocus(radius=(1, 3), p=1.0),
            ], p=0.2),

            # Simulate overlapping leaves / partial occlusion
            A.CoarseDropout(
                max_holes=8,
                max_height=32,
                max_width=32,
                min_holes=1,
                min_height=16,
                min_width=16,
                fill_value=0,
                p=0.2
            ),

            # Resize to target size
            A.LongestMaxSize(max_size=max(self.image_size)),
            A.PadIfNeeded(
                min_height=self.image_size[1],
                min_width=self.image_size[0],
                border_mode=cv2.BORDER_CONSTANT,
                value=(114, 114, 114)
            ),

            # Normalize
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ], bbox_params=A.BboxParams(
            format='yolo',
            label_fields=['class_labels'],
            min_visibility=0.3
        ))

    def _build_val_transform(self) -> A.Compose:
        """Build validation transform (minimal augmentation)."""
        return A.Compose([
            A.LongestMaxSize(max_size=max(self.image_size)),
            A.PadIfNeeded(
                min_height=self.image_size[1],
                min_width=self.image_size[0],
                border_mode=cv2.BORDER_CONSTANT,
                value=(114, 114, 114)
            ),
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ], bbox_params=A.BboxParams(
            format='yolo',
            label_fields=['class_labels'],
            min_visibility=0.3
        ))

    def _build_test_transform(self) -> A.Compose:
        """Build test/inference transform."""
        return A.Compose([
            A.LongestMaxSize(max_size=max(self.image_size)),
            A.PadIfNeeded(
                min_height=self.image_size[1],
                min_width=self.image_size[0],
                border_mode=cv2.BORDER_CONSTANT,
                value=(114, 114, 114)
            ),
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ])

    def __call__(
        self,
        image: np.ndarray,
        bboxes: Optional[List[List[float]]] = None,
        class_labels: Optional[List[int]] = None
    ) -> Dict:
        """
        Apply augmentation to image and bounding boxes.

        Args:
            image: Input image (H, W, C) in BGR format
            bboxes: List of bounding boxes in YOLO format [x_center, y_center, w, h]
            class_labels: List of class labels for each bbox

        Returns:
            Dictionary with transformed image and bboxes
        """
        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        if bboxes is not None and class_labels is not None:
            transformed = self.transform(
                image=image_rgb,
                bboxes=bboxes,
                class_labels=class_labels
            )
        else:
            # For inference without bboxes
            transformed = self.transform(image=image_rgb)

        return transformed


class MosaicAugmentation:
    """
    Mosaic augmentation combining 4 images for better context learning.
    Particularly useful for detecting multiple leaves in complex scenes.
    """

    def __init__(self, image_size: Tuple[int, int] = (640, 640)):
        self.image_size = image_size

    def __call__(
        self,
        images: List[np.ndarray],
        all_bboxes: List[List[List[float]]],
        all_labels: List[List[int]]
    ) -> Tuple[np.ndarray, List[List[float]], List[int]]:
        """
        Create mosaic from 4 images.

        Args:
            images: List of 4 images
            all_bboxes: List of bbox lists for each image
            all_labels: List of label lists for each image

        Returns:
            Mosaic image, combined bboxes, combined labels
        """
        assert len(images) == 4, "Mosaic requires exactly 4 images"

        h, w = self.image_size
        mosaic_image = np.full((h, w, 3), 114, dtype=np.uint8)

        # Random center point
        cx = random.randint(w // 4, 3 * w // 4)
        cy = random.randint(h // 4, 3 * h // 4)

        combined_bboxes = []
        combined_labels = []

        # Placement positions for 4 quadrants
        placements = [
            (0, 0, cx, cy),          # top-left
            (cx, 0, w, cy),          # top-right
            (0, cy, cx, h),          # bottom-left
            (cx, cy, w, h)           # bottom-right
        ]

        for i, (img, bboxes, labels) in enumerate(zip(images, all_bboxes, all_labels)):
            x1, y1, x2, y2 = placements[i]
            target_h, target_w = y2 - y1, x2 - x1

            # Resize image to fit quadrant
            img_h, img_w = img.shape[:2]
            scale = min(target_w / img_w, target_h / img_h)
            new_w, new_h = int(img_w * scale), int(img_h * scale)
            resized = cv2.resize(img, (new_w, new_h))

            # Calculate placement offset
            offset_x = x1 + (target_w - new_w) // 2
            offset_y = y1 + (target_h - new_h) // 2

            # Place in mosaic
            mosaic_image[offset_y:offset_y + new_h, offset_x:offset_x + new_w] = resized

            # Transform bounding boxes
            for bbox, label in zip(bboxes, labels):
                # Original bbox in normalized coords
                bx, by, bw, bh = bbox

                # Convert to absolute coords in original image
                abs_x = bx * img_w
                abs_y = by * img_h
                abs_w = bw * img_w
                abs_h = bh * img_h

                # Scale and offset to mosaic coords
                new_x = (abs_x * scale + offset_x) / w
                new_y = (abs_y * scale + offset_y) / h
                new_bw = (abs_w * scale) / w
                new_bh = (abs_h * scale) / h

                # Clip to valid range
                if 0 < new_x < 1 and 0 < new_y < 1:
                    combined_bboxes.append([new_x, new_y, new_bw, new_bh])
                    combined_labels.append(label)

        return mosaic_image, combined_bboxes, combined_labels


class MixUpAugmentation:
    """
    MixUp augmentation for regularization and handling ambiguous samples.
    """

    def __init__(self, alpha: float = 0.5):
        self.alpha = alpha

    def __call__(
        self,
        image1: np.ndarray,
        image2: np.ndarray,
        bboxes1: List[List[float]],
        bboxes2: List[List[float]],
        labels1: List[int],
        labels2: List[int]
    ) -> Tuple[np.ndarray, List[List[float]], List[int], float]:
        """
        Mix two images with random ratio.

        Returns:
            Mixed image, combined bboxes, combined labels, mixing ratio
        """
        # Sample mixing ratio from Beta distribution
        lam = np.random.beta(self.alpha, self.alpha)

        # Ensure images are same size
        h, w = image1.shape[:2]
        image2_resized = cv2.resize(image2, (w, h))

        # Mix images
        mixed_image = (lam * image1 + (1 - lam) * image2_resized).astype(np.uint8)

        # Combine bounding boxes and labels
        combined_bboxes = bboxes1 + bboxes2
        combined_labels = labels1 + labels2

        return mixed_image, combined_bboxes, combined_labels, lam


def create_augmentation_pipeline(
    image_size: Tuple[int, int] = (640, 640),
    mode: str = "train"
) -> TeaLeafAugmentationPipeline:
    """
    Factory function to create augmentation pipeline.

    Args:
        image_size: Target image size
        mode: 'train', 'val', or 'test'

    Returns:
        Configured augmentation pipeline
    """
    return TeaLeafAugmentationPipeline(image_size=image_size, mode=mode)
