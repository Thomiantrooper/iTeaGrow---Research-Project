#!/usr/bin/env python3
"""
Train Tea Leaf Disease Detection Model
========================================
Main training script for YOLOv8n model.

Usage:
    python scripts/train_model.py --data ./data --output ./runs --epochs 100
"""

import argparse
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from ai_engine.training.trainer import train_tea_disease_model, create_sample_dataset_structure


def main():
    parser = argparse.ArgumentParser(
        description="Train Tea Leaf Disease Detection Model"
    )
    parser.add_argument(
        "--data",
        type=str,
        required=True,
        help="Path to dataset directory"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="./runs",
        help="Output directory for trained models"
    )
    parser.add_argument(
        "--epochs",
        type=int,
        default=100,
        help="Number of training epochs"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=16,
        help="Batch size for training"
    )
    parser.add_argument(
        "--export",
        nargs="+",
        default=["onnx", "tflite"],
        help="Export formats (onnx, tflite, coreml)"
    )
    parser.add_argument(
        "--create-structure",
        action="store_true",
        help="Create sample dataset directory structure"
    )

    args = parser.parse_args()

    if args.create_structure:
        create_sample_dataset_structure(args.data)
        print(f"Created sample dataset structure at {args.data}")
        return

    print("=" * 60)
    print("TEA LEAF DISEASE DETECTION - MODEL TRAINING")
    print("=" * 60)
    print(f"Dataset: {args.data}")
    print(f"Output: {args.output}")
    print(f"Epochs: {args.epochs}")
    print(f"Batch Size: {args.batch_size}")
    print(f"Export Formats: {args.export}")
    print("=" * 60)

    results = train_tea_disease_model(
        data_dir=args.data,
        output_dir=args.output,
        epochs=args.epochs,
        batch_size=args.batch_size,
        export_formats=args.export
    )

    print("\n" + "=" * 60)
    print("TRAINING COMPLETE")
    print("=" * 60)
    print(f"Best Model: {results['training']['best_model_path']}")
    print(f"Validation mAP@0.5: {results['validation']['mAP50']:.4f}")
    print(f"Validation mAP@0.5:0.95: {results['validation']['mAP50_95']:.4f}")
    print("\nExported Models:")
    for fmt, path in results['exports'].items():
        print(f"  {fmt}: {path}")
    print("=" * 60)


if __name__ == "__main__":
    main()
