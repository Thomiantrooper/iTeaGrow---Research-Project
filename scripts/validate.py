#!/usr/bin/env python3
"""
Model Validation Script for Tea Leaf Disease Detection.

Validates trained models on test datasets and generates performance reports.

Usage:
    python scripts/validate.py --weights models/yolov8n_tealeaf.pt --data datasets/tealeaf/data.yaml
"""

import argparse
import sys
import json
from pathlib import Path
from datetime import datetime


def setup_paths():
    """Add project root to Python path."""
    project_root = Path(__file__).parent.parent
    sys.path.insert(0, str(project_root))


setup_paths()


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate YOLOv8n model for tea leaf disease detection"
    )

    parser.add_argument(
        "--weights",
        type=str,
        required=True,
        help="Path to model weights"
    )
    parser.add_argument(
        "--data",
        type=str,
        required=True,
        help="Path to data.yaml"
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Image size (default: 640)"
    )
    parser.add_argument(
        "--batch",
        type=int,
        default=16,
        help="Batch size (default: 16)"
    )
    parser.add_argument(
        "--device",
        type=str,
        default="0",
        help="CUDA device or 'cpu' (default: 0)"
    )
    parser.add_argument(
        "--split",
        type=str,
        default="val",
        choices=["train", "val", "test"],
        help="Dataset split to validate (default: val)"
    )
    parser.add_argument(
        "--conf",
        type=float,
        default=0.25,
        help="Confidence threshold (default: 0.25)"
    )
    parser.add_argument(
        "--iou",
        type=float,
        default=0.45,
        help="IoU threshold for NMS (default: 0.45)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="runs/validate",
        help="Output directory for results"
    )
    parser.add_argument(
        "--save-json",
        action="store_true",
        help="Save results in COCO JSON format"
    )
    parser.add_argument(
        "--plots",
        action="store_true",
        default=True,
        help="Generate validation plots"
    )

    return parser.parse_args()


def validate_model(args):
    """
    Validate the model on specified dataset.

    Args:
        args: Command line arguments
    """
    from ultralytics import YOLO

    print("=" * 60)
    print("Tea Leaf Disease Detection - Model Validation")
    print("=" * 60)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    weights_path = Path(args.weights)
    if not weights_path.exists():
        raise FileNotFoundError(f"Weights not found: {weights_path}")

    print(f"Loading model: {weights_path}")
    model = YOLO(weights_path)

    print(f"Validating on {args.split} split...")
    print(f"Configuration: imgsz={args.imgsz}, batch={args.batch}, conf={args.conf}")
    print()

    results = model.val(
        data=args.data,
        imgsz=args.imgsz,
        batch=args.batch,
        device=args.device,
        split=args.split,
        conf=args.conf,
        iou=args.iou,
        plots=args.plots,
        save_json=args.save_json,
        project=args.output,
        name=f"validate_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
    )

    print("\n" + "=" * 60)
    print("Validation Results")
    print("=" * 60)

    class_names = model.names
    print("\nOverall Metrics:")
    print(f"  mAP50: {results.box.map50:.4f}")
    print(f"  mAP50-95: {results.box.map:.4f}")
    print(f"  Precision: {results.box.mp:.4f}")
    print(f"  Recall: {results.box.mr:.4f}")

    print("\nPer-Class Results:")
    print("-" * 50)
    print(f"{'Class':<20} {'P':>8} {'R':>8} {'mAP50':>8} {'mAP50-95':>8}")
    print("-" * 50)

    for i, class_name in enumerate(class_names.values()):
        p = results.box.p[i]
        r = results.box.r[i]
        ap50 = results.box.ap50[i]
        ap = results.box.ap[i]
        print(f"{class_name:<20} {p:>8.4f} {r:>8.4f} {ap50:>8.4f} {ap:>8.4f}")

    print("-" * 50)

    report = {
        "timestamp": datetime.now().isoformat(),
        "model": str(weights_path),
        "dataset": args.data,
        "split": args.split,
        "configuration": {
            "imgsz": args.imgsz,
            "batch": args.batch,
            "conf": args.conf,
            "iou": args.iou,
        },
        "overall": {
            "mAP50": float(results.box.map50),
            "mAP50-95": float(results.box.map),
            "precision": float(results.box.mp),
            "recall": float(results.box.mr),
        },
        "per_class": {},
    }

    for i, class_name in enumerate(class_names.values()):
        report["per_class"][class_name] = {
            "precision": float(results.box.p[i]),
            "recall": float(results.box.r[i]),
            "mAP50": float(results.box.ap50[i]),
            "mAP50-95": float(results.box.ap[i]),
        }

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    report_path = output_dir / f"validation_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"\nReport saved to: {report_path}")

    print("\nQuality Assessment:")
    map50 = results.box.map50
    if map50 >= 0.9:
        print("  Status: EXCELLENT - Model is production-ready")
    elif map50 >= 0.8:
        print("  Status: GOOD - Model can be deployed with monitoring")
    elif map50 >= 0.7:
        print("  Status: ACCEPTABLE - Consider additional training")
    else:
        print("  Status: NEEDS IMPROVEMENT - More training data or epochs needed")

    for i, class_name in enumerate(class_names.values()):
        if results.box.ap50[i] < 0.5:
            print(f"  Warning: Low performance on '{class_name}' class")

    print(f"\nEnd time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    return results


def main():
    """Main entry point."""
    args = parse_arguments()

    try:
        validate_model(args)
    except Exception as e:
        print(f"\nValidation failed: {e}")
        raise


if __name__ == "__main__":
    main()
