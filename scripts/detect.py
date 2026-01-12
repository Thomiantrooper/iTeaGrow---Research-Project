#!/usr/bin/env python3
"""
Tea Leaf Disease Detection - Inference Script

Usage:
    python detect.py --image path/to/image.jpg
    python detect.py --folder path/to/images/
    python detect.py --webcam
"""

import argparse
from pathlib import Path
from ultralytics import YOLO
import cv2


def main():
    parser = argparse.ArgumentParser(description="Detect tea leaf diseases")
    parser.add_argument("--image", type=str, help="Path to a single image")
    parser.add_argument("--folder", type=str, help="Path to folder of images")
    parser.add_argument("--webcam", action="store_true", help="Use webcam")
    parser.add_argument("--conf", type=float, default=0.25, help="Confidence threshold")
    parser.add_argument("--save", action="store_true", help="Save results")
    args = parser.parse_args()

    # Find best model
    project_root = Path(__file__).parent.parent
    model_paths = [
        project_root / "runs/detect/runs/detect/max_accuracy/tealeaf_95/weights/best.pt",
        project_root / "runs/detect/runs/train/tealeaf2/weights/best.pt",
        project_root / "runs/detect/augmented/tealeaf_aug/weights/best.pt",
    ]

    model_path = None
    for path in model_paths:
        if path.exists():
            model_path = path
            break

    if model_path is None:
        print("ERROR: No trained model found!")
        print("Please train a model first using train_improved.py")
        return

    print(f"Loading model: {model_path}")
    model = YOLO(str(model_path))

    # Class names and colors
    class_colors = {
        'blister_blight': (0, 0, 255),    # Red
        'healthy': (0, 255, 0),            # Green
        'red_rust': (0, 165, 255)          # Orange
    }

    if args.image:
        # Single image detection
        results = model.predict(
            source=args.image,
            conf=args.conf,
            save=args.save,
            show=True
        )
        print_results(results[0])

    elif args.folder:
        # Folder of images
        results = model.predict(
            source=args.folder,
            conf=args.conf,
            save=args.save
        )
        for r in results:
            print_results(r)

    elif args.webcam:
        # Webcam detection
        print("Starting webcam detection... Press 'q' to quit")
        results = model.predict(
            source=0,
            conf=args.conf,
            show=True,
            stream=True
        )
        for r in results:
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    else:
        print("Please specify --image, --folder, or --webcam")
        print("Example: python detect.py --image leaf.jpg")


def print_results(result):
    """Print detection results."""
    print("\n" + "=" * 50)
    print(f"Image: {Path(result.path).name}")
    print("=" * 50)

    if len(result.boxes) == 0:
        print("  No detections found")
        return

    class_names = ['blister_blight', 'healthy', 'red_rust']

    for box in result.boxes:
        cls_id = int(box.cls[0])
        conf = float(box.conf[0])
        cls_name = class_names[cls_id] if cls_id < len(class_names) else f"class_{cls_id}"

        status = "DISEASED" if cls_name != "healthy" else "HEALTHY"
        print(f"  [{status}] {cls_name}: {conf*100:.1f}% confidence")

    print()


if __name__ == "__main__":
    main()
