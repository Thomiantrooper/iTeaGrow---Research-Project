#!/usr/bin/env python3
"""
YOLOv8n Training Script for Tea Leaf Disease Detection.

This script provides a complete training pipeline for the disease detection model,
including data validation, training, evaluation, and export.

Usage:
    python scripts/train.py --data datasets/tealeaf/data.yaml --epochs 100
"""

import argparse
import sys
from pathlib import Path
from datetime import datetime
import yaml
import shutil

def setup_paths():
    """Add project root to Python path."""
    project_root = Path(__file__).parent.parent
    sys.path.insert(0, str(project_root))

setup_paths()


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Train YOLOv8n model for tea leaf disease detection"
    )

    parser.add_argument(
        "--data",
        type=str,
        required=True,
        help="Path to data.yaml configuration file"
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=100,
        help="Number of training epochs (default: 100)"
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Image size for training (default: 640)"
    )
    parser.add_argument(
        "--batch",
        type=int,
        default=16,
        help="Batch size (default: 16)"
    )
    parser.add_argument(
        "--weights",
        type=str,
        default="yolov8n.pt",
        help="Initial weights path (default: yolov8n.pt)"
    )
    parser.add_argument(
        "--device",
        type=str,
        default="0",
        help="CUDA device (0, 1, 2, ...) or 'cpu' (default: 0)"
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=8,
        help="Number of dataloader workers (default: 8)"
    )
    parser.add_argument(
        "--project",
        type=str,
        default="runs/train",
        help="Project directory for saving results"
    )
    parser.add_argument(
        "--name",
        type=str,
        default="tealeaf",
        help="Experiment name"
    )
    parser.add_argument(
        "--resume",
        type=str,
        default=None,
        help="Resume training from checkpoint"
    )
    parser.add_argument(
        "--patience",
        type=int,
        default=50,
        help="Early stopping patience (default: 50)"
    )
    parser.add_argument(
        "--augment",
        action="store_true",
        help="Enable advanced augmentation"
    )
    parser.add_argument(
        "--export-onnx",
        action="store_true",
        help="Export to ONNX after training"
    )

    return parser.parse_args()


def validate_dataset(data_path: str) -> dict:
    """
    Validate the dataset configuration and paths.

    Args:
        data_path: Path to data.yaml

    Returns:
        Loaded data configuration
    """
    data_path = Path(data_path)

    if not data_path.exists():
        raise FileNotFoundError(f"Data configuration not found: {data_path}")

    with open(data_path, 'r') as f:
        data_config = yaml.safe_load(f)

    required_keys = ['train', 'val', 'nc', 'names']
    for key in required_keys:
        if key not in data_config:
            raise ValueError(f"Missing required key in data.yaml: {key}")

    expected_classes = ['healthy', 'red_rust', 'blister_blight']
    if data_config['names'] != expected_classes:
        print(f"Warning: Class names differ from expected. Got: {data_config['names']}")

    if data_config['nc'] != 3:
        print(f"Warning: Expected 3 classes, got {data_config['nc']}")

    base_path = data_path.parent
    for split in ['train', 'val']:
        images_path = base_path / data_config[split] / 'images'
        labels_path = base_path / data_config[split] / 'labels'

        if not images_path.exists():
            raise FileNotFoundError(f"{split} images not found: {images_path}")
        if not labels_path.exists():
            raise FileNotFoundError(f"{split} labels not found: {labels_path}")

        image_count = len(list(images_path.glob('*.jpg')) + list(images_path.glob('*.png')))
        label_count = len(list(labels_path.glob('*.txt')))

        print(f"{split}: {image_count} images, {label_count} labels")

        if image_count != label_count:
            print(f"Warning: Image/label count mismatch in {split} set")

    return data_config


def create_augmentation_config(enabled: bool) -> dict:
    """Create augmentation configuration for training."""
    if not enabled:
        return {}

    return {
        'hsv_h': 0.015,
        'hsv_s': 0.7,
        'hsv_v': 0.4,
        'degrees': 10.0,
        'translate': 0.1,
        'scale': 0.5,
        'shear': 5.0,
        'perspective': 0.0005,
        'flipud': 0.5,
        'fliplr': 0.5,
        'mosaic': 1.0,
        'mixup': 0.1,
        'copy_paste': 0.1,
    }


def train_model(args):
    """
    Train the YOLOv8n model.

    Args:
        args: Command line arguments
    """
    from ultralytics import YOLO

    print("=" * 60)
    print("Tea Leaf Disease Detection - Model Training")
    print("=" * 60)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    print("Validating dataset...")
    data_config = validate_dataset(args.data)
    print(f"Dataset validated: {data_config['nc']} classes")
    print()

    print(f"Loading base model: {args.weights}")
    if args.resume:
        model = YOLO(args.resume)
        print(f"Resuming from checkpoint: {args.resume}")
    else:
        model = YOLO(args.weights)

    augmentation = create_augmentation_config(args.augment)

    train_args = {
        'data': args.data,
        'epochs': args.epochs,
        'imgsz': args.imgsz,
        'batch': args.batch,
        'device': args.device,
        'workers': args.workers,
        'project': args.project,
        'name': args.name,
        'patience': args.patience,
        'save': True,
        'save_period': 10,
        'cache': True,
        'pretrained': True,
        'optimizer': 'AdamW',
        'lr0': 0.01,
        'lrf': 0.01,
        'momentum': 0.937,
        'weight_decay': 0.0005,
        'warmup_epochs': 3,
        'warmup_momentum': 0.8,
        'warmup_bias_lr': 0.1,
        'box': 7.5,
        'cls': 0.5,
        'dfl': 1.5,
        'plots': True,
        'val': True,
        **augmentation,
    }

    print("Training configuration:")
    for key, value in train_args.items():
        print(f"  {key}: {value}")
    print()

    print("Starting training...")
    results = model.train(**train_args)

    print()
    print("=" * 60)
    print("Training completed!")
    print("=" * 60)

    best_weights = Path(args.project) / args.name / 'weights' / 'best.pt'

    print(f"Best weights saved to: {best_weights}")

    print()
    print("Validating best model...")
    best_model = YOLO(best_weights)
    val_results = best_model.val(data=args.data, imgsz=args.imgsz)

    print()
    print("Validation Results:")
    print(f"  mAP50: {val_results.box.map50:.4f}")
    print(f"  mAP50-95: {val_results.box.map:.4f}")

    if args.export_onnx:
        print()
        print("Exporting to ONNX format...")
        export_path = best_model.export(
            format='onnx',
            imgsz=args.imgsz,
            simplify=True,
            opset=12,
        )
        print(f"ONNX model saved to: {export_path}")

        models_dir = Path('models')
        models_dir.mkdir(exist_ok=True)

        final_pt_path = models_dir / 'yolov8n_tealeaf.pt'
        final_onnx_path = models_dir / 'yolov8n_tealeaf.onnx'

        shutil.copy(best_weights, final_pt_path)
        shutil.copy(export_path, final_onnx_path)

        print()
        print("Models copied to production directory:")
        print(f"  PyTorch: {final_pt_path}")
        print(f"  ONNX: {final_onnx_path}")

    print()
    print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    return results


def main():
    """Main entry point."""
    args = parse_arguments()

    try:
        train_model(args)
    except KeyboardInterrupt:
        print("\nTraining interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nTraining failed: {e}")
        raise


if __name__ == "__main__":
    main()
