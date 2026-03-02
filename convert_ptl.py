"""
Convert YOLOv8 best.pt to PyTorch Lite (.ptl) for Flutter offline inference.
Since the app already uses pytorch_lite for maturity, we can use it for disease detection too!
"""
import os
from pathlib import Path

MODEL_PATH = "models/best.pt"
OUTPUT_DIR = "frontend/iTeaGrow---Research-Project/assets/models"
PTL_DEST = os.path.join(OUTPUT_DIR, "disease_model.ptl")

def convert():
    print("=" * 60)
    print(" Exporting YOLOv8 to PyTorch Lite (.ptl) for Flutter")
    print("=" * 60)
    
    if not Path(MODEL_PATH).exists():
        print(f"ERROR: Model not found at {MODEL_PATH}")
        return False
        
    try:
        from ultralytics import YOLO
        import torch
        from torch.utils.mobile_optimizer import optimize_for_mobile
        
        print("1. Loading YOLO model...")
        model = YOLO(MODEL_PATH)
        print(f"Classes: {model.names}")
        
        print("2. Exporting to TorchScript...")
        # Ultralytics can export to torchscript natively
        ts_path = model.export(format="torchscript", imgsz=320)
        print(f"TorchScript saved to: {ts_path}")
        
        # In Ultralytics 8.x, it usually saves as best.torchscript
        # We need to load it and optimize for mobile
        print("3. Optimizing for PyTorch Mobile (.ptl)...")
        ts_model = torch.jit.load(ts_path)
        
        # Optimize for mobile
        optimized_model = optimize_for_mobile(ts_model)
        
        # Save as .ptl to the Flutter assets directory
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        optimized_model._save_for_lite_interpreter(PTL_DEST)
        
        size = Path(PTL_DEST).stat().st_size / 1024 / 1024
        print(f"\n✅ SUCCESS! PyTorch Lite model saved to:\n   {PTL_DEST} ({size:.1f} MB)")
        return True
        
    except Exception as e:
        print(f"\nERROR during conversion: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = convert()
    if not success:
        print("\nConversion failed.")
        exit(1)
        
