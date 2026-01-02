"""
YOLOv8n Training Pipeline for Tea Leaf Disease Detection
==========================================================
Training, validation, and model export pipeline optimized for mobile deployment.
"""

import os
import torch
import yaml
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List, Tuple
from ultralytics import YOLO
import json
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TeaLeafDiseaseTrainer:
    """
    Training pipeline for YOLOv8n tea leaf disease detection model.
    """

    def __init__(
        self,
        data_dir: str,
        output_dir: str,
        model_size: str = "n",  # nano for mobile
        pretrained: bool = True,
        device: str = None
    ):
        """
        Initialize trainer.

        Args:
            data_dir: Directory containing training data
            output_dir: Directory to save trained models
            model_size: YOLO model size ('n', 's', 'm', 'l', 'x')
            pretrained: Whether to use pretrained weights
            device: Training device ('cuda', 'cpu', or specific GPU)
        """
        self.data_dir = Path(data_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.model_size = model_size
        self.pretrained = pretrained

        # Auto-detect device
        if device is None:
            self.device = 'cuda' if torch.cuda.is_available() else 'cpu'
        else:
            self.device = device

        # Class configuration
        self.class_names = ["healthy", "red_rust", "blister_blight"]
        self.num_classes = len(self.class_names)

        # Initialize model
        self.model = None
        self._setup_model()

        # Training history
        self.history = {
            'train_loss': [],
            'val_loss': [],
            'mAP50': [],
            'mAP50_95': [],
            'precision': [],
            'recall': []
        }

    def _setup_model(self):
        """Initialize YOLOv8 model."""
        model_name = f"yolov8{self.model_size}.pt"

        if self.pretrained:
            # Load pretrained model
            self.model = YOLO(model_name)
            logger.info(f"Loaded pretrained YOLOv8{self.model_size} model")
        else:
            # Create new model from scratch
            self.model = YOLO(f"yolov8{self.model_size}.yaml")
            logger.info(f"Created new YOLOv8{self.model_size} model from scratch")

    def _create_data_yaml(self) -> str:
        """Create YOLO-format data configuration file."""
        yaml_path = self.output_dir / "data.yaml"

        data_config = {
            'path': str(self.data_dir.absolute()),
            'train': 'images/train',
            'val': 'images/val',
            'test': 'images/test',
            'nc': self.num_classes,
            'names': self.class_names
        }

        with open(yaml_path, 'w') as f:
            yaml.dump(data_config, f, default_flow_style=False)

        return str(yaml_path)

    def train(
        self,
        epochs: int = 100,
        batch_size: int = 16,
        image_size: int = 640,
        learning_rate: float = 0.01,
        patience: int = 20,
        augment: bool = True,
        resume: bool = False,
        **kwargs
    ) -> Dict:
        """
        Train the model.

        Args:
            epochs: Number of training epochs
            batch_size: Batch size
            image_size: Input image size
            learning_rate: Initial learning rate
            patience: Early stopping patience
            augment: Whether to use data augmentation
            resume: Whether to resume from last checkpoint
            **kwargs: Additional training arguments

        Returns:
            Training results dictionary
        """
        logger.info("Starting training...")

        # Create data configuration
        data_yaml = self._create_data_yaml()

        # Run name with timestamp
        run_name = f"tea_disease_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        # Training arguments optimized for tea leaf detection
        train_args = {
            'data': data_yaml,
            'epochs': epochs,
            'batch': batch_size,
            'imgsz': image_size,
            'device': self.device,
            'project': str(self.output_dir),
            'name': run_name,
            'patience': patience,
            'save': True,
            'save_period': 10,
            'cache': True,
            'pretrained': self.pretrained,
            'optimizer': 'AdamW',
            'lr0': learning_rate,
            'lrf': 0.01,  # Final learning rate factor
            'momentum': 0.937,
            'weight_decay': 0.0005,
            'warmup_epochs': 3,
            'warmup_momentum': 0.8,
            'warmup_bias_lr': 0.1,
            'box': 7.5,  # Box loss gain
            'cls': 0.5,  # Class loss gain
            'dfl': 1.5,  # DFL loss gain
            'hsv_h': 0.015,  # Image HSV-Hue augmentation
            'hsv_s': 0.7,   # Image HSV-Saturation augmentation
            'hsv_v': 0.4,   # Image HSV-Value augmentation
            'degrees': 10,  # Image rotation
            'translate': 0.1,  # Image translation
            'scale': 0.5,  # Image scale
            'shear': 5,    # Image shear
            'perspective': 0.0001,  # Image perspective
            'flipud': 0.1,  # Vertical flip
            'fliplr': 0.5,  # Horizontal flip
            'mosaic': 1.0 if augment else 0.0,
            'mixup': 0.1 if augment else 0.0,
            'copy_paste': 0.1 if augment else 0.0,
            'resume': resume,
            'amp': True,  # Automatic mixed precision
            'fraction': 1.0,
            'verbose': True,
            'seed': 42,
            **kwargs
        }

        # Train model
        results = self.model.train(**train_args)

        # Extract metrics
        self._extract_metrics(results)

        # Save training config
        self._save_training_config(train_args, run_name)

        logger.info(f"Training completed. Results saved to {self.output_dir / run_name}")

        return {
            'run_name': run_name,
            'best_model_path': str(self.output_dir / run_name / 'weights' / 'best.pt'),
            'metrics': self.history
        }

    def _extract_metrics(self, results):
        """Extract and store training metrics."""
        if hasattr(results, 'results_dict'):
            metrics = results.results_dict
            self.history['mAP50'].append(metrics.get('metrics/mAP50(B)', 0))
            self.history['mAP50_95'].append(metrics.get('metrics/mAP50-95(B)', 0))
            self.history['precision'].append(metrics.get('metrics/precision(B)', 0))
            self.history['recall'].append(metrics.get('metrics/recall(B)', 0))

    def _save_training_config(self, config: Dict, run_name: str):
        """Save training configuration for reproducibility."""
        config_path = self.output_dir / run_name / 'training_config.json'
        with open(config_path, 'w') as f:
            # Convert Path objects to strings
            serializable_config = {}
            for k, v in config.items():
                if isinstance(v, Path):
                    serializable_config[k] = str(v)
                else:
                    serializable_config[k] = v
            json.dump(serializable_config, f, indent=2)

    def validate(
        self,
        model_path: str = None,
        data_split: str = "val"
    ) -> Dict:
        """
        Validate model on specified data split.

        Args:
            model_path: Path to model weights (uses current model if None)
            data_split: Data split to validate on ('val' or 'test')

        Returns:
            Validation metrics dictionary
        """
        if model_path:
            model = YOLO(model_path)
        else:
            model = self.model

        data_yaml = self._create_data_yaml()

        results = model.val(
            data=data_yaml,
            split=data_split,
            device=self.device,
            batch=16,
            imgsz=640,
            verbose=True
        )

        metrics = {
            'mAP50': results.box.map50,
            'mAP50_95': results.box.map,
            'precision': results.box.mp,
            'recall': results.box.mr,
            'per_class_ap50': {
                self.class_names[i]: results.box.ap50[i]
                for i in range(len(self.class_names))
            }
        }

        logger.info(f"Validation Results:")
        logger.info(f"  mAP@0.5: {metrics['mAP50']:.4f}")
        logger.info(f"  mAP@0.5:0.95: {metrics['mAP50_95']:.4f}")
        logger.info(f"  Precision: {metrics['precision']:.4f}")
        logger.info(f"  Recall: {metrics['recall']:.4f}")

        return metrics

    def export_model(
        self,
        model_path: str,
        formats: List[str] = None,
        optimize_for_mobile: bool = True
    ) -> Dict[str, str]:
        """
        Export model to various formats for deployment.

        Args:
            model_path: Path to the trained model weights
            formats: List of export formats ('onnx', 'tflite', 'coreml', 'torchscript')
            optimize_for_mobile: Whether to optimize for mobile deployment

        Returns:
            Dictionary mapping format to exported file path
        """
        if formats is None:
            formats = ['onnx', 'tflite']

        model = YOLO(model_path)
        exported_paths = {}

        for fmt in formats:
            logger.info(f"Exporting model to {fmt} format...")

            export_args = {
                'format': fmt,
                'imgsz': 640,
                'half': False,  # FP32 for compatibility
                'dynamic': False,
                'simplify': True if fmt == 'onnx' else False,
            }

            if fmt == 'tflite':
                export_args.update({
                    'int8': False,  # Use FP32 for better accuracy
                    'nms': True,    # Include NMS in model
                })
            elif fmt == 'onnx':
                export_args.update({
                    'opset': 12,
                    'simplify': True,
                })
            elif fmt == 'coreml':
                export_args.update({
                    'nms': True,
                })

            try:
                export_path = model.export(**export_args)
                exported_paths[fmt] = str(export_path)
                logger.info(f"  Exported to: {export_path}")
            except Exception as e:
                logger.error(f"  Failed to export to {fmt}: {e}")

        return exported_paths


def create_sample_dataset_structure(base_dir: str):
    """
    Create sample dataset directory structure for reference.

    Args:
        base_dir: Base directory for dataset
    """
    base_path = Path(base_dir)

    # Create directories
    for split in ['train', 'val', 'test']:
        (base_path / 'images' / split).mkdir(parents=True, exist_ok=True)
        (base_path / 'labels' / split).mkdir(parents=True, exist_ok=True)

    # Create sample annotation format README
    readme_content = """
# Tea Leaf Disease Dataset Structure

## Directory Structure
```
dataset/
├── images/
│   ├── train/
│   │   ├── image001.jpg
│   │   └── ...
│   ├── val/
│   │   └── ...
│   └── test/
│       └── ...
└── labels/
    ├── train/
    │   ├── image001.txt
    │   └── ...
    ├── val/
    │   └── ...
    └── test/
        └── ...
```

## Label Format (YOLO format)
Each line in label file: `class_id x_center y_center width height`
- All coordinates are normalized (0-1)
- class_id: 0=healthy, 1=red_rust, 2=blister_blight

## Example Label File (image001.txt)
```
1 0.45 0.32 0.12 0.08
2 0.67 0.55 0.15 0.10
0 0.25 0.75 0.20 0.18
```

## Recommended Split Ratio
- Train: 70%
- Validation: 20%
- Test: 10%

## Image Requirements
- RGB format (JPEG or PNG)
- Minimum resolution: 640x640 recommended
- Captured under natural field conditions
- Include varied lighting, angles, and backgrounds
"""

    with open(base_path / 'README.md', 'w') as f:
        f.write(readme_content)

    logger.info(f"Created sample dataset structure at {base_path}")


def train_tea_disease_model(
    data_dir: str,
    output_dir: str,
    epochs: int = 100,
    batch_size: int = 16,
    export_formats: List[str] = None
) -> Dict:
    """
    Convenience function to train and export model.

    Args:
        data_dir: Path to dataset
        output_dir: Path for output
        epochs: Training epochs
        batch_size: Batch size
        export_formats: List of export formats

    Returns:
        Dictionary with training results and exported model paths
    """
    if export_formats is None:
        export_formats = ['onnx', 'tflite']

    # Initialize trainer
    trainer = TeaLeafDiseaseTrainer(
        data_dir=data_dir,
        output_dir=output_dir,
        model_size='n',  # Nano for mobile
        pretrained=True
    )

    # Train model
    train_results = trainer.train(
        epochs=epochs,
        batch_size=batch_size,
        image_size=640,
        augment=True
    )

    # Validate
    val_metrics = trainer.validate(
        model_path=train_results['best_model_path']
    )

    # Export
    exported_paths = trainer.export_model(
        model_path=train_results['best_model_path'],
        formats=export_formats,
        optimize_for_mobile=True
    )

    return {
        'training': train_results,
        'validation': val_metrics,
        'exports': exported_paths
    }


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Train Tea Leaf Disease Detection Model")
    parser.add_argument("--data", type=str, required=True, help="Path to dataset directory")
    parser.add_argument("--output", type=str, default="./runs", help="Output directory")
    parser.add_argument("--epochs", type=int, default=100, help="Number of epochs")
    parser.add_argument("--batch-size", type=int, default=16, help="Batch size")
    parser.add_argument("--export", nargs="+", default=["onnx", "tflite"], help="Export formats")

    args = parser.parse_args()

    results = train_tea_disease_model(
        data_dir=args.data,
        output_dir=args.output,
        epochs=args.epochs,
        batch_size=args.batch_size,
        export_formats=args.export
    )

    print("\n" + "=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"Best Model: {results['training']['best_model_path']}")
    print(f"Validation mAP@0.5: {results['validation']['mAP50']:.4f}")
    print(f"Exported Models: {results['exports']}")
