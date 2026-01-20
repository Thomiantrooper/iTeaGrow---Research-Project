#!/usr/bin/env python3
"""
Maximum Accuracy YOLOv8 Training Script for Tea Leaf Disease Detection.

Target: 95%+ mAP50 accuracy
Strategy: Use larger model (yolov8s), aggressive augmentation, longer training,
          and optimized hyperparameters for small datasets.
"""

import argparse
from pathlib import Path
from datetime import datetime
from ultralytics import YOLO


def main():
    parser = argparse.ArgumentParser(description="Maximum accuracy training for tea leaf disease detection")
    parser.add_argument("--epochs", type=int, default=50, help="Number of epochs (default: 50 - more data needs fewer epochs)")
    parser.add_argument("--model", type=str, default="yolov8s.pt", help="Base model (yolov8s.pt recommended)")
    parser.add_argument("--imgsz", type=int, default=640, help="Image size")
    parser.add_argument("--batch", type=int, default=8, help="Batch size")
    args = parser.parse_args()

    print("=" * 70)
    print("  TEA LEAF DISEASE DETECTION - MAXIMUM ACCURACY TRAINING")
    print("  Target: 95%+ mAP50")
    print("=" * 70)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    # Paths
    project_root = Path(__file__).parent.parent
    data_yaml = project_root / "raw_data" / "data.yaml"

    # Use YOLOv8s (small) - better accuracy than nano, still fast
    model = YOLO(args.model)
    print(f"Using model: {args.model}")
    print(f"Dataset: {data_yaml}")
    print()

    # MAXIMUM ACCURACY training configuration
    train_config = {
        'data': str(data_yaml),
        'epochs': args.epochs,
        'imgsz': args.imgsz,
        'batch': args.batch,
        'device': 'cpu',  # Use CPU (change to 0 if you have CUDA GPU)
        'workers': 4,
        'project': 'runs/detect/augmented',
        'name': 'tealeaf_aug',
        'exist_ok': True,
        'patience': 50,  # More patience for convergence
        'save': True,
        'save_period': 25,
        'cache': 'disk',  # Cache to disk (more stable for large datasets)
        'pretrained': True,
        'cos_lr': True,  # Cosine learning rate scheduler (better convergence)
        'amp': True,  # Mixed precision training

        # Optimized learning rates for transfer learning
        'optimizer': 'AdamW',
        'lr0': 0.001,
        'lrf': 0.001,  # Very low final LR for fine convergence
        'momentum': 0.937,
        'weight_decay': 0.0005,
        'warmup_epochs': 10,  # Longer warmup
        'warmup_momentum': 0.8,
        'warmup_bias_lr': 0.1,

        # Loss weights - balanced for detection
        'box': 7.5,
        'cls': 1.5,  # Higher classification weight
        'dfl': 1.5,

        # AGGRESSIVE AUGMENTATION for small datasets
        # Color augmentation (crucial for disease detection)
        'hsv_h': 0.015,
        'hsv_s': 0.7,  # Strong saturation changes
        'hsv_v': 0.4,

        # Geometric augmentation
        'degrees': 20.0,  # More rotation
        'translate': 0.2,
        'scale': 0.5,
        'shear': 5.0,
        'perspective': 0.0005,
        'flipud': 0.5,
        'fliplr': 0.5,

        # Advanced augmentation
        'mosaic': 1.0,  # Always use mosaic
        'mixup': 0.2,  # MixUp for regularization
        'copy_paste': 0.2,  # Copy-paste augmentation
        'erasing': 0.4,  # Random erasing for robustness

        # Close mosaic near end for cleaner final training
        'close_mosaic': 30,

        # Validation and output
        'plots': True,
        'val': True,
        'rect': False,  # Disable rect training for more augmentation variety

        # Label smoothing for better generalization
        'label_smoothing': 0.1,
    }

    print("Training Configuration (Optimized for 95%+ accuracy):")
    print("-" * 50)
    key_params = ['epochs', 'imgsz', 'batch', 'optimizer', 'lr0', 'cos_lr',
                  'mosaic', 'mixup', 'label_smoothing', 'close_mosaic']
    for key in key_params:
        print(f"  {key}: {train_config[key]}")
    print()

    print("Starting maximum accuracy training...")
    print("This will train for", args.epochs, "epochs with heavy augmentation.")
    print("NOTE: Running on CPU - this may take several hours.")
    print()

    results = model.train(**train_config)

    print()
    print("=" * 70)
    print("  TRAINING COMPLETE!")
    print("=" * 70)

    # Validate best model
    best_weights = Path('runs/detect/augmented/tealeaf_aug/weights/best.pt')
    if best_weights.exists():
        print(f"\nBest model saved to: {best_weights}")

        print("\nRunning final validation on best model...")
        best_model = YOLO(str(best_weights))
        val_results = best_model.val(data=str(data_yaml), imgsz=args.imgsz)

        print()
        print("=" * 50)
        print("  FINAL RESULTS")
        print("=" * 50)
        map50 = val_results.box.map50 * 100
        map50_95 = val_results.box.map * 100
        precision = val_results.box.mp * 100
        recall = val_results.box.mr * 100

        print(f"  mAP50:     {map50:.1f}%  {'✓ TARGET MET!' if map50 >= 95 else '(target: 95%)'}")
        print(f"  mAP50-95:  {map50_95:.1f}%")
        print(f"  Precision: {precision:.1f}%")
        print(f"  Recall:    {recall:.1f}%")

        # Class-wise results
        print("\n  Per-class mAP50:")
        class_names = ['blister_blight', 'healthy', 'red_rust']
        for i, name in enumerate(class_names):
            if i < len(val_results.box.ap50):
                ap = val_results.box.ap50[i] * 100
                print(f"    {name}: {ap:.1f}%")

        if map50 < 95:
            print("\n  Tips to reach 95%:")
            print("  - Add more training images (ideally 200+ per class)")
            print("  - Try yolov8m.pt (medium model) for even higher accuracy")
            print("  - Run for more epochs (--epochs 500)")
            print("  - Check annotation quality in your dataset")

    print()
    print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    main()
