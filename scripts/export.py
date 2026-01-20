#!/usr/bin/env python3
"""
Model Export Script for Tea Leaf Disease Detection.

Exports trained YOLOv8n models to various formats including ONNX, TensorRT, and INT8.

Usage:
    python scripts/export.py --weights runs/train/tealeaf/weights/best.pt --format onnx
"""

import argparse
import sys
from pathlib import Path
from datetime import datetime
import hashlib


def setup_paths():
    """Add project root to Python path."""
    project_root = Path(__file__).parent.parent
    sys.path.insert(0, str(project_root))


setup_paths()


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Export YOLOv8n model to various formats"
    )

    parser.add_argument(
        "--weights",
        type=str,
        required=True,
        help="Path to trained model weights (.pt file)"
    )
    parser.add_argument(
        "--format",
        type=str,
        default="onnx",
        choices=["onnx", "torchscript", "engine", "coreml", "saved_model", "tflite"],
        help="Export format (default: onnx)"
    )
    parser.add_argument(
        "--imgsz",
        type=int,
        default=640,
        help="Image size for export (default: 640)"
    )
    parser.add_argument(
        "--batch",
        type=int,
        default=1,
        help="Batch size for export (default: 1)"
    )
    parser.add_argument(
        "--device",
        type=str,
        default="cpu",
        help="Device for export (default: cpu)"
    )
    parser.add_argument(
        "--half",
        action="store_true",
        help="Export as FP16 (half precision)"
    )
    parser.add_argument(
        "--int8",
        action="store_true",
        help="Export as INT8 quantized"
    )
    parser.add_argument(
        "--dynamic",
        action="store_true",
        help="Enable dynamic batch size (ONNX only)"
    )
    parser.add_argument(
        "--simplify",
        action="store_true",
        default=True,
        help="Simplify ONNX model (default: True)"
    )
    parser.add_argument(
        "--opset",
        type=int,
        default=12,
        help="ONNX opset version (default: 12)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output directory (default: same as weights)"
    )
    parser.add_argument(
        "--workspace",
        type=int,
        default=4,
        help="TensorRT workspace size in GB (default: 4)"
    )

    return parser.parse_args()


def calculate_checksum(file_path: Path) -> str:
    """Calculate MD5 checksum of a file."""
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


def get_model_info(model) -> dict:
    """Get model information."""
    info = {
        "task": model.task,
        "stride": int(model.stride),
        "names": model.names,
        "nc": len(model.names),
    }

    if hasattr(model.model, 'parameters'):
        params = sum(p.numel() for p in model.model.parameters())
        info["parameters"] = f"{params / 1e6:.2f}M"

    return info


def export_model(args):
    """
    Export the model to specified format.

    Args:
        args: Command line arguments
    """
    from ultralytics import YOLO

    print("=" * 60)
    print("Tea Leaf Disease Detection - Model Export")
    print("=" * 60)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    weights_path = Path(args.weights)
    if not weights_path.exists():
        raise FileNotFoundError(f"Weights file not found: {weights_path}")

    print(f"Loading model from: {weights_path}")
    model = YOLO(weights_path)

    model_info = get_model_info(model)
    print("\nModel Information:")
    for key, value in model_info.items():
        print(f"  {key}: {value}")

    export_args = {
        'format': args.format,
        'imgsz': args.imgsz,
        'batch': args.batch,
        'device': args.device,
        'half': args.half,
        'int8': args.int8,
    }

    if args.format == 'onnx':
        export_args.update({
            'simplify': args.simplify,
            'dynamic': args.dynamic,
            'opset': args.opset,
        })
    elif args.format == 'engine':
        export_args.update({
            'workspace': args.workspace,
        })

    print("\nExport configuration:")
    for key, value in export_args.items():
        print(f"  {key}: {value}")

    print(f"\nExporting to {args.format.upper()} format...")
    export_path = model.export(**export_args)

    export_path = Path(export_path)

    if args.output:
        output_dir = Path(args.output)
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / export_path.name

        import shutil
        shutil.copy(export_path, output_path)
        export_path = output_path

    file_size = export_path.stat().st_size / (1024 * 1024)
    checksum = calculate_checksum(export_path)

    print("\n" + "=" * 60)
    print("Export completed!")
    print("=" * 60)
    print(f"\nExported model: {export_path}")
    print(f"File size: {file_size:.2f} MB")
    print(f"MD5 checksum: {checksum}")

    if args.format == 'onnx':
        print("\nValidating ONNX model...")
        try:
            import onnx
            onnx_model = onnx.load(str(export_path))
            onnx.checker.check_model(onnx_model)
            print("ONNX model validation: PASSED")

            print(f"ONNX opset version: {onnx_model.opset_import[0].version}")
            print(f"Input shape: {[d.dim_value for d in onnx_model.graph.input[0].type.tensor_type.shape.dim]}")

        except ImportError:
            print("ONNX package not installed, skipping validation")
        except Exception as e:
            print(f"ONNX validation failed: {e}")

    print("\nBenchmarking inference speed...")
    try:
        import time
        import numpy as np

        warmup_runs = 5
        benchmark_runs = 20

        dummy_input = np.random.rand(1, 3, args.imgsz, args.imgsz).astype(np.float32)

        if args.format == 'onnx':
            import onnxruntime as ort
            session = ort.InferenceSession(str(export_path))
            input_name = session.get_inputs()[0].name

            for _ in range(warmup_runs):
                session.run(None, {input_name: dummy_input})

            times = []
            for _ in range(benchmark_runs):
                start = time.perf_counter()
                session.run(None, {input_name: dummy_input})
                times.append((time.perf_counter() - start) * 1000)

            avg_time = sum(times) / len(times)
            std_time = (sum((t - avg_time) ** 2 for t in times) / len(times)) ** 0.5

            print(f"Average inference time: {avg_time:.2f} ± {std_time:.2f} ms")
            print(f"Throughput: {1000 / avg_time:.1f} FPS")

    except Exception as e:
        print(f"Benchmarking failed: {e}")

    print(f"\nEnd time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    return export_path


def main():
    """Main entry point."""
    args = parse_arguments()

    try:
        export_model(args)
    except Exception as e:
        print(f"\nExport failed: {e}")
        raise


if __name__ == "__main__":
    main()
