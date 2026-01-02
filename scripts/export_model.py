#!/usr/bin/env python3
"""
Model Export Script
====================
Exports trained model to various formats for deployment.
"""

import argparse
import sys
from pathlib import Path


def export_model(model_path: str, formats: list, output_dir: str = None):
    """Export model to specified formats."""
    try:
        from ultralytics import YOLO
    except ImportError:
        print("Installing ultralytics...")
        import subprocess
        subprocess.run([sys.executable, "-m", "pip", "install", "ultralytics"])
        from ultralytics import YOLO

    model_path = Path(model_path)
    if not model_path.exists():
        print(f"❌ Model not found: {model_path}")
        sys.exit(1)

    output_dir = Path(output_dir) if output_dir else Path("exports")
    output_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("MODEL EXPORT")
    print("=" * 60)
    print(f"Source model: {model_path}")
    print(f"Output directory: {output_dir}")
    print(f"Formats: {', '.join(formats)}")
    print("-" * 60)

    # Load model
    model = YOLO(str(model_path))

    exported = {}

    for fmt in formats:
        print(f"\nExporting to {fmt.upper()}...")

        try:
            if fmt == "onnx":
                export_path = model.export(
                    format="onnx",
                    imgsz=640,
                    simplify=True,
                    opset=12,
                    dynamic=False,
                )

            elif fmt == "tflite":
                export_path = model.export(
                    format="tflite",
                    imgsz=640,
                    int8=False,  # FP32 for better accuracy
                )

            elif fmt == "coreml":
                export_path = model.export(
                    format="coreml",
                    imgsz=640,
                    nms=True,
                )

            elif fmt == "torchscript":
                export_path = model.export(
                    format="torchscript",
                    imgsz=640,
                )

            elif fmt == "engine":
                # TensorRT (requires NVIDIA GPU)
                export_path = model.export(
                    format="engine",
                    imgsz=640,
                    half=True,  # FP16 for faster inference
                )

            else:
                print(f"  ⚠ Unknown format: {fmt}")
                continue

            # Move to output directory
            export_path = Path(export_path)
            if export_path.exists():
                dest = output_dir / export_path.name
                export_path.rename(dest)
                exported[fmt] = str(dest)
                print(f"  ✓ Exported: {dest}")
                print(f"    Size: {dest.stat().st_size / 1024 / 1024:.2f} MB")

        except Exception as e:
            print(f"  ✗ Failed: {e}")

    print("\n" + "=" * 60)
    print("EXPORT SUMMARY")
    print("=" * 60)

    if exported:
        print("\nSuccessfully exported:")
        for fmt, path in exported.items():
            print(f"  {fmt}: {path}")

        print("\nUsage:")
        if "onnx" in exported:
            print(f"\n  ONNX (Python):")
            print(f"    import onnxruntime as ort")
            print(f"    session = ort.InferenceSession('{exported['onnx']}')")

        if "tflite" in exported:
            print(f"\n  TFLite (Mobile):")
            print(f"    Copy {exported['tflite']} to mobile_app/assets/models/")

    else:
        print("\n⚠ No models were exported successfully")

    return exported


def find_latest_model(runs_dir: str = "./runs"):
    """Find the latest trained model."""
    runs_path = Path(runs_dir)

    if not runs_path.exists():
        return None

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
    parser = argparse.ArgumentParser(description="Export trained model")
    parser.add_argument("--model", type=str, help="Path to model .pt file")
    parser.add_argument(
        "--formats",
        nargs="+",
        default=["onnx", "tflite"],
        choices=["onnx", "tflite", "coreml", "torchscript", "engine"],
        help="Export formats",
    )
    parser.add_argument("--output", type=str, default="./exports", help="Output directory")

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

    export_model(model_path, args.formats, args.output)
