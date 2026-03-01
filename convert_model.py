"""
Convert ONNX model to TFLite using TensorFlow's built-in ONNX support.
Uses python -m tf2onnx.convert in reverse OR tensorflow's onnx import.
"""
import os
import sys
import subprocess
from pathlib import Path

ONNX_PATH = "models/best.onnx"
OUTPUT_DIR = "frontend/iTeaGrow---Research-Project/assets/models"
TFLITE_DEST = os.path.join(OUTPUT_DIR, "disease_model.tflite")
SAVEDMODEL_DIR = "models/best_tf_saved_model"

def run():
    print("Converting ONNX -> TFLite using onnx-tf + TensorFlow...")
    
    if not Path(ONNX_PATH).exists():
        print(f"ERROR: ONNX file not found at {ONNX_PATH}")
        return False
    
    # Step 1: Install onnx-tf
    print("\nInstalling onnx-tf...")
    try:
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "onnx-tf"],
            capture_output=True, text=True, timeout=300
        )
        if "Successfully installed" in result.stdout or "already satisfied" in result.stdout:
            print("✅ onnx-tf ready")
        else:
            print(f"Output: {result.stdout[-500:]}")
            print(f"Errors: {result.stderr[-500:]}")
    except subprocess.TimeoutExpired:
        print("Timeout installing onnx-tf")
        return False
    
    # Step 2: Convert ONNX → SavedModel using onnx_tf
    print("\nConverting ONNX → TensorFlow SavedModel...")
    try:
        import onnx
        from onnx_tf.backend import prepare
        import tensorflow as tf

        print("Loading ONNX model...")
        onnx_model = onnx.load(ONNX_PATH)
        
        print("Preparing TF backend...")
        tf_rep = prepare(onnx_model)
        
        print(f"Exporting SavedModel to {SAVEDMODEL_DIR}...")
        os.makedirs(SAVEDMODEL_DIR, exist_ok=True)
        tf_rep.export_graph(SAVEDMODEL_DIR)
        
        print("Converting SavedModel → TFLite...")
        converter = tf.lite.TFLiteConverter.from_saved_model(SAVEDMODEL_DIR)
        converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Float16 quantization
        converter.target_spec.supported_types = [tf.float16]
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS,
        ]
        
        print("Running conversion (may take a minute)...")
        tflite_model = converter.convert()
        
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        with open(TFLITE_DEST, 'wb') as f:
            f.write(tflite_model)
        
        size = Path(TFLITE_DEST).stat().st_size / 1024 / 1024
        print(f"\n✅ SUCCESS! TFLite model saved: {TFLITE_DEST} ({size:.1f} MB)")
        return True
        
    except ImportError as e:
        print(f"onnx-tf import failed: {e}")
        print("Trying alternative method via command line...")
        
        # Alternative: Use onnx2tf via python -m tf2onnx convert
        try:
            result = subprocess.run([
                sys.executable, "-m", "tf2onnx.convert",
                "--onnx", ONNX_PATH,
                "--output", os.path.join("models", "best_tf2.onnx"),
                "--verbose"
            ], capture_output=True, text=True, timeout=120)
            print(result.stdout[-1000:])
            print(result.stderr[-500:])
        except Exception as e2:
            print(f"Alternative also failed: {e2}")
        
        return False
    
    except Exception as e:
        print(f"Conversion error: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run()
    if not success:
        print("\n❌ TFLite conversion failed.")
        print("The app will use the ONNX model with flutter_onnxruntime.")
        print(f"ONNX model is at: {OUTPUT_DIR}/disease_model.onnx")
    else:
        print("\n✅ Done! TFLite model is ready for Flutter.")
