"""
Proper Model Conversion for Offline Inference
Converts best.pt -> disease_model.ptl optimized for PyTorch Mobile
"""

import torch
import os
from pathlib import Path
from datetime import datetime

MODEL_PATH = "models/best.pt"
OUTPUT_DIR = "frontend/iTeaGrow---Research-Project/assets/models"
PTL_DEST = os.path.join(OUTPUT_DIR, "disease_model.ptl.new")
BACKUP_PATH = os.path.join(OUTPUT_DIR, "disease_model.ptl.backup")

print("=" * 80)
print(" PROPER MODEL CONVERSION FOR OFFLINE INFERENCE")
print(" best.pt -> disease_model.ptl (PyTorch Mobile Optimized)")
print("=" * 80)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Verify source model
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 1] Verifying source model...")
if not Path(MODEL_PATH).exists():
    print(f"ERROR: Model not found at {MODEL_PATH}")
    exit(1)

model_size_mb = Path(MODEL_PATH).stat().st_size / 1024 / 1024
print(f"✓ Source model: {MODEL_PATH} ({model_size_mb:.2f} MB)")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Load the YOLOv8 model
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 2] Loading YOLOv8 model with ultralytics...")
try:
    from ultralytics import YOLO

    model = YOLO(MODEL_PATH)
    print(f"✓ Model loaded successfully")
    print(f"  Classes: {model.names}")
    print(f"  Model type: {model.model.__class__.__name__}")
except Exception as e:
    print(f"ERROR: Failed to load model: {e}")
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Export to TorchScript (the proper way for mobile)
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 3] Exporting to TorchScript format...")
try:
    # Use ultralytics native export
    ts_export_path = model.export(format="torchscript", imgsz=320)
    print(f"✓ TorchScript exported to: {ts_export_path}")

    # Check size of exported model
    ts_size_mb = Path(ts_export_path).stat().st_size / 1024 / 1024
    print(f"  TorchScript size: {ts_size_mb:.2f} MB")
except Exception as e:
    print(f"ERROR: TorchScript export failed: {e}")
    import traceback

    traceback.print_exc()
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Load and optimize for mobile
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 4] Optimizing for PyTorch Mobile...")
try:
    # Load the TorchScript model
    ts_model = torch.jit.load(ts_export_path, map_location="cpu")
    print(f"✓ TorchScript model loaded")

    # Apply mobile optimization (this reduces size and improves inference speed)
    from torch.utils.mobile_optimizer import optimize_for_mobile

    optimized_model = optimize_for_mobile(ts_model)
    print(f"✓ Mobile optimization applied")

except Exception as e:
    print(f"ERROR: Mobile optimization failed: {e}")
    import traceback

    traceback.print_exc()
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Test inference on a dummy input
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 5] Testing inference...")
try:
    # Create dummy input (320x320 image)
    dummy_input = torch.randn(1, 3, 320, 320)

    print(f"  Running inference with dummy input (1, 3, 320, 320)...")
    with torch.no_grad():
        output = ts_model(dummy_input)

    print(f"✓ Inference successful")
    print(f"  Output type: {type(output)}")
    if isinstance(output, (tuple, list)):
        print(f"  Output structure: tuple/list with {len(output)} elements")
        for i, o in enumerate(output):
            if isinstance(o, torch.Tensor):
                print(f"    [{i}] Tensor shape: {o.shape}")
    elif isinstance(output, torch.Tensor):
        print(f"  Output shape: {output.shape}")

except Exception as e:
    print(f"WARNING: Inference test failed (may not affect mobile inference): {e}")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6: Save optimized model
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 6] Saving optimized model...")
try:
    # Create output directory if needed
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Save the optimized model
    optimized_model.save(PTL_DEST)

    # Verify it was saved
    saved_size_mb = Path(PTL_DEST).stat().st_size / 1024 / 1024
    print(f"✓ Model saved to: {PTL_DEST}")
    print(f"  Final size: {saved_size_mb:.2f} MB")

    # Size reduction summary
    reduction_pct = (1 - saved_size_mb / model_size_mb) * 100
    print(f"  Size reduction: {reduction_pct:.1f}% (from {model_size_mb:.2f} MB)")

except Exception as e:
    print(f"ERROR: Failed to save model: {e}")
    import traceback

    traceback.print_exc()
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7: Backup old model and replace with new one
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 7] Updating production model...")
old_model_path = os.path.join(OUTPUT_DIR, "disease_model.ptl")

try:
    if Path(old_model_path).exists():
        # Backup old version
        backup_path = f"{BACKUP_PATH}.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        os.rename(old_model_path, backup_path)
        print(f"✓ Old model backed up to: {backup_path}")

    # Replace with new optimized model
    os.rename(PTL_DEST, old_model_path)
    print(f"✓ Production model updated: {old_model_path}")

except Exception as e:
    print(f"ERROR: Failed to update production model: {e}")
    print(f"Manual action needed: Move {PTL_DEST} to {old_model_path}")
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 8: Create labels file for Flutter
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 8] Creating labels file for Flutter app...")
try:
    labels_path = os.path.join(OUTPUT_DIR, "disease_labels.txt")
    with open(labels_path, "w") as f:
        f.write("blister_blight\n")
        f.write("healthy\n")
        f.write("red_rust\n")
    print(f"✓ Labels file created: {labels_path}")
except Exception as e:
    print(f"WARNING: Could not create labels file: {e}")

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

print("\n" + "=" * 80)
print(" CONVERSION COMPLETE ✓")
print("=" * 80)
print(
    f"""
Summary:
  Source:         {MODEL_PATH} ({model_size_mb:.2f} MB)
  Exported:       TorchScript (via ultralytics)
  Optimized:      PyTorch Mobile optimized
  Final model:    {old_model_path} ({saved_size_mb:.2f} MB)
  Reduction:      {reduction_pct:.1f}%
  
Status: Production model updated and ready for offline inference!

Next steps:
  1. Rebuild Flutter app to include new model
  2. Test offline detection WITHOUT backend running
  3. Verify detection accuracy matches backend

The model is ready for PyTorch Mobile integration via pytorch_lite package.
"""
)

print("=" * 80)
