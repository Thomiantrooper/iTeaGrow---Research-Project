#!/usr/bin/env python3
"""
Test Inference Script
======================
Tests the trained model on a single image or directory.
"""

import os
import sys
from pathlib import Path
import argparse
import time

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


def test_single_image(model_path: str, image_path: str, confidence: float = 0.5):
    """Test model on a single image."""
    try:
        from ultralytics import YOLO
        import cv2
    except ImportError:
        print("Installing required packages...")
        os.system("pip install ultralytics opencv-python")
        from ultralytics import YOLO
        import cv2

    print("=" * 60)
    print("TEA LEAF DISEASE DETECTION - INFERENCE TEST")
    print("=" * 60)

    # Load model
    print(f"\nLoading model: {model_path}")
    model = YOLO(model_path)

    # Load image
    print(f"Loading image: {image_path}")
    image = cv2.imread(image_path)
    if image is None:
        print(f"❌ Error: Could not load image {image_path}")
        return

    # Run inference
    print(f"\nRunning inference (confidence threshold: {confidence})...")
    start_time = time.time()
    results = model.predict(image, conf=confidence, verbose=False)
    inference_time = (time.time() - start_time) * 1000

    print(f"Inference time: {inference_time:.1f}ms")

    # Process results
    result = results[0]
    boxes = result.boxes

    class_names = ["healthy", "red_rust", "blister_blight"]

    print("\n" + "-" * 60)
    print("DETECTION RESULTS")
    print("-" * 60)

    if len(boxes) == 0:
        print("No leaves detected!")
    else:
        disease_counts = {"healthy": 0, "red_rust": 0, "blister_blight": 0}

        for i, box in enumerate(boxes):
            class_id = int(box.cls[0])
            conf = float(box.conf[0])
            x1, y1, x2, y2 = map(int, box.xyxy[0])

            class_name = class_names[class_id] if class_id < len(class_names) else f"class_{class_id}"
            disease_counts[class_name] = disease_counts.get(class_name, 0) + 1

            print(f"\n  Detection {i + 1}:")
            print(f"    Class:      {class_name}")
            print(f"    Confidence: {conf * 100:.1f}%")
            print(f"    Bounding box: ({x1}, {y1}) to ({x2}, {y2})")

        print("\n" + "-" * 60)
        print("SUMMARY")
        print("-" * 60)
        print(f"\n  Total leaves detected: {len(boxes)}")

        for class_name, count in disease_counts.items():
            if count > 0:
                print(f"    {class_name}: {count}")

        # Overall assessment
        infected = disease_counts.get("red_rust", 0) + disease_counts.get("blister_blight", 0)
        if infected == 0:
            print("\n  ✅ Status: HEALTHY - No disease detected")
        elif infected < len(boxes) / 2:
            print("\n  ⚠️  Status: MILD INFECTION - Some diseased leaves detected")
        else:
            print("\n  ❌ Status: SIGNIFICANT INFECTION - Immediate action recommended")

    # Save annotated image
    output_path = Path(image_path).stem + "_result.jpg"
    annotated = result.plot()
    cv2.imwrite(output_path, annotated)
    print(f"\n  Annotated image saved: {output_path}")

    print("\n" + "=" * 60)


def test_directory(model_path: str, dir_path: str, confidence: float = 0.5):
    """Test model on all images in a directory."""
    from ultralytics import YOLO
    import cv2

    print("=" * 60)
    print("BATCH INFERENCE TEST")
    print("=" * 60)

    # Load model
    print(f"\nLoading model: {model_path}")
    model = YOLO(model_path)

    # Get image files
    dir_path = Path(dir_path)
    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    images = [f for f in dir_path.iterdir() if f.suffix.lower() in image_extensions]

    if not images:
        print(f"❌ No images found in {dir_path}")
        return

    print(f"Found {len(images)} images")
    print("-" * 60)

    total_time = 0
    total_detections = 0
    disease_summary = {"healthy": 0, "red_rust": 0, "blister_blight": 0}

    for img_path in images:
        image = cv2.imread(str(img_path))
        if image is None:
            continue

        start_time = time.time()
        results = model.predict(image, conf=confidence, verbose=False)
        inference_time = (time.time() - start_time) * 1000
        total_time += inference_time

        result = results[0]
        boxes = result.boxes
        total_detections += len(boxes)

        for box in boxes:
            class_id = int(box.cls[0])
            if class_id == 0:
                disease_summary["healthy"] += 1
            elif class_id == 1:
                disease_summary["red_rust"] += 1
            elif class_id == 2:
                disease_summary["blister_blight"] += 1

        print(f"  {img_path.name}: {len(boxes)} detections ({inference_time:.1f}ms)")

    print("\n" + "-" * 60)
    print("BATCH SUMMARY")
    print("-" * 60)
    print(f"\n  Images processed: {len(images)}")
    print(f"  Total detections: {total_detections}")
    print(f"  Average time/image: {total_time / len(images):.1f}ms")
    print(f"\n  Disease distribution:")
    for disease, count in disease_summary.items():
        if count > 0:
            percentage = count / total_detections * 100 if total_detections > 0 else 0
            print(f"    {disease}: {count} ({percentage:.1f}%)")


def find_latest_model(runs_dir: str = "./runs"):
    """Find the latest trained model."""
    runs_path = Path(runs_dir)
    if not runs_path.exists():
        return None

    # Find most recent training run
    train_dirs = sorted(
        [d for d in runs_path.iterdir() if d.is_dir() and d.name.startswith("tea_disease")],
        key=lambda x: x.stat().st_mtime,
        reverse=True,
    )

    if train_dirs:
        best_model = train_dirs[0] / "weights" / "best.pt"
        if best_model.exists():
            return str(best_model)

    return None


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test disease detection model")
    parser.add_argument("--model", type=str, help="Path to model file (.pt, .onnx, .tflite)")
    parser.add_argument("--image", type=str, help="Path to test image")
    parser.add_argument("--dir", type=str, help="Path to directory of images")
    parser.add_argument("--confidence", type=float, default=0.5, help="Confidence threshold")

    args = parser.parse_args()

    # Find model if not specified
    model_path = args.model
    if not model_path:
        model_path = find_latest_model()
        if model_path:
            print(f"Using latest model: {model_path}")
        else:
            print("❌ No model found. Please train a model first or specify --model path")
            print("\nTo train a model:")
            print("  python scripts/train_model.py --data ./data --epochs 100")
            sys.exit(1)

    if not Path(model_path).exists():
        print(f"❌ Model not found: {model_path}")
        sys.exit(1)

    if args.dir:
        test_directory(model_path, args.dir, args.confidence)
    elif args.image:
        test_single_image(model_path, args.image, args.confidence)
    else:
        # Use a demo image if available
        demo_images = list(Path("./data/images/test").glob("*.jpg")) if Path("./data/images/test").exists() else []
        if demo_images:
            test_single_image(model_path, str(demo_images[0]), args.confidence)
        else:
            print("Please specify --image or --dir")
            print("\nExamples:")
            print("  python scripts/test_inference.py --image path/to/image.jpg")
            print("  python scripts/test_inference.py --dir path/to/images/")
