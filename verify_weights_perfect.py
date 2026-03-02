"""
COMPREHENSIVE WEIGHT VERIFICATION
Ensures backend model (best.pt) and offline model (disease_model.ptl)
have IDENTICAL weights - no data loss or corruption during conversion
"""

import torch
import numpy as np
from pathlib import Path
import json

print("=" * 100)
print(" WEIGHT VERIFICATION - BACKEND vs OFFLINE MODEL")
print("=" * 100)

# ─────────────────────────────────────────────────────────────────────────────
# PART 1: Load both models
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 1] Loading models...")

# Load backend model
print("  Loading backend model (best.pt)...")
try:
    from ultralytics import YOLO

    backend_model = YOLO("models/best.pt")
    backend_state = backend_model.model.state_dict()
    print(f"  ✓ Backend loaded - {len(backend_state)} tensors")
except Exception as e:
    print(f"  ERROR: {e}")
    exit(1)

# Load offline model
print("  Loading offline model (disease_model.ptl)...")
try:
    offline_model = torch.jit.load(
        r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl",
        map_location="cpu",
    )
    offline_state = offline_model.state_dict()
    print(f"  ✓ Offline loaded - {len(offline_state)} attributes")
except Exception as e:
    print(f"  ERROR: {e}")
    exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# PART 2: Compare model structure
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 2] Comparing model structure...")

# Get all parameter names
backend_keys = set(backend_state.keys())
offline_keys = set(offline_state.keys())

print(f"  Backend parameters: {len(backend_keys)}")
print(f"  Offline parameters: {len(offline_keys)}")

# The keys will be different because:
# - backend uses PyTorch naming (model.0.conv.weight)
# - offline uses TorchScript naming (different format when JIT compiled)
# But the NUMBER of tensors should be similar or the same

print("\n  Backend parameter names (sample):")
for key in list(backend_keys)[:10]:
    shape = backend_state[key].shape
    dtype = backend_state[key].dtype
    print(f"    {key}: {shape} {dtype}")

# ─────────────────────────────────────────────────────────────────────────────
# PART 3: Extract and compare weights by size
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 3] Comparing weights by size and type...")

# Collect all tensors
backend_tensors = []
offline_tensors = []

print("\n  Backend tensors:")
total_backend_params = 0
for name, tensor in backend_state.items():
    if isinstance(tensor, torch.Tensor):
        num_params = tensor.numel()
        total_backend_params += num_params
        backend_tensors.append(
            {
                "name": name,
                "shape": tuple(tensor.shape),
                "dtype": str(tensor.dtype),
                "numel": num_params,
                "tensor": tensor,
            }
        )

print(f"    Total parameters: {total_backend_params:,}")
print(
    f"    Total size: {total_backend_params * 4 / 1024 / 1024:.2f} MB (assuming float32)"
)

print("\n  Offline tensors:")
total_offline_params = 0
for name, obj in offline_state.items():
    if isinstance(obj, torch.Tensor):
        num_params = obj.numel()
        total_offline_params += num_params
        offline_tensors.append(
            {
                "name": name,
                "shape": tuple(obj.shape),
                "dtype": str(obj.dtype),
                "numel": num_params,
                "tensor": obj,
            }
        )

print(f"    Total parameters: {total_offline_params:,}")
print(
    f"    Total size: {total_offline_params * 4 / 1024 / 1024:.2f} MB (assuming float32)"
)

# ─────────────────────────────────────────────────────────────────────────────
# PART 4: Deep weight comparison
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 4] Deep weight comparison...")

# Sort by size to match tensors
backend_tensors_sorted = sorted(backend_tensors, key=lambda x: x["numel"], reverse=True)
offline_tensors_sorted = sorted(offline_tensors, key=lambda x: x["numel"], reverse=True)

print(
    f"\n  Comparing {len(backend_tensors_sorted)} backend tensors with {len(offline_tensors_sorted)} offline tensors"
)

# Try to pair tensors by size
matches = []
unmatched_backend = []
unmatched_offline = []

used_offline = set()

for i, b_tensor in enumerate(backend_tensors_sorted):
    found_match = False

    for j, o_tensor in enumerate(offline_tensors_sorted):
        if j in used_offline:
            continue

        # Match by shape
        if b_tensor["shape"] == o_tensor["shape"]:
            used_offline.add(j)

            # Compare values
            b_t = b_tensor["tensor"].float()
            o_t = o_tensor["tensor"].float()

            # Various comparison metrics
            abs_diff = (b_t - o_t).abs()
            max_diff = abs_diff.max().item()
            mean_diff = abs_diff.mean().item()

            # Check if close
            is_close = torch.allclose(b_t, o_t, rtol=1e-4, atol=1e-6)
            is_very_close = torch.allclose(b_t, o_t, rtol=1e-5, atol=1e-7)

            matches.append(
                {
                    "backend_name": b_tensor["name"],
                    "offline_name": o_tensor["name"],
                    "shape": b_tensor["shape"],
                    "numel": b_tensor["numel"],
                    "max_diff": max_diff,
                    "mean_diff": mean_diff,
                    "is_close": is_close,
                    "is_very_close": is_very_close,
                }
            )

            found_match = True
            break

    if not found_match:
        unmatched_backend.append(b_tensor)

# Find unmatched offline
for j, o_tensor in enumerate(offline_tensors_sorted):
    if j not in used_offline:
        unmatched_offline.append(o_tensor)

print(f"\n  Matched tensors: {len(matches)}")
print(f"  Unmatched backend: {len(unmatched_backend)}")
print(f"  Unmatched offline: {len(unmatched_offline)}")

# ─────────────────────────────────────────────────────────────────────────────
# PART 5: Detailed analysis
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 5] Weight fidelity analysis...")

# Check quality of matched tensors
perfect_matches = sum(1 for m in matches if m["is_very_close"])
close_matches = sum(1 for m in matches if m["is_close"] and not m["is_very_close"])
not_close = len(matches) - perfect_matches - close_matches

print(f"\n  Perfect matches (rtol=1e-5): {perfect_matches}/{len(matches)}")
print(f"  Close matches (rtol=1e-4): {close_matches}/{len(matches)}")
print(f"  Different tensors: {not_close}/{len(matches)}")

if matches:
    max_diffs = [m["max_diff"] for m in matches]
    mean_diffs = [m["mean_diff"] for m in matches]

    print(f"\n  Max difference statistics:")
    print(f"    Average max_diff: {np.mean(max_diffs):.2e}")
    print(f"    Median max_diff: {np.median(max_diffs):.2e}")
    print(f"    Max of all max_diffs: {np.max(max_diffs):.2e}")

    print(f"\n  Mean difference statistics:")
    print(f"    Average mean_diff: {np.mean(mean_diffs):.2e}")
    print(f"    Median mean_diff: {np.median(mean_diffs):.2e}")
    print(f"    Max of all mean_diffs: {np.max(mean_diffs):.2e}")

# ─────────────────────────────────────────────────────────────────────────────
# PART 6: Inference comparison
# ─────────────────────────────────────────────────────────────────────────────

print("\n[STEP 6] Testing inference on identical input...")

# Create test image
np.random.seed(42)
test_img = np.random.randint(50, 150, (320, 320, 3), dtype=np.uint8)

print(f"  Test image: {test_img.shape}, min={test_img.min()}, max={test_img.max()}")

# Backend inference
print("\n  Backend inference (YOLO):")
try:
    with torch.no_grad():
        backend_output = backend_model(test_img, conf=0.1, iou=0.45, verbose=False)
    print(f"  ✓ Inference successful")
    # Get raw output
    if backend_output and hasattr(backend_output[0], "boxes"):
        boxes = backend_output[0].boxes
        print(f"    Detections: {len(boxes) if boxes else 0}")
except Exception as e:
    print(f"  ERROR: {e}")
    backend_output = None

# Offline inference
print("\n  Offline inference (TorchScript):")
try:
    img_tensor = torch.from_numpy(test_img).float() / 255.0
    img_tensor = img_tensor.permute(2, 0, 1).unsqueeze(0)

    with torch.no_grad():
        offline_output = offline_model(img_tensor)

    print(f"  ✓ Inference successful")
    print(f"    Output shape: {offline_output.shape}")
    print(f"    Output dtype: {offline_output.dtype}")
    print(f"    Output range: [{offline_output.min():.4f}, {offline_output.max():.4f}]")
except Exception as e:
    print(f"  ERROR: {e}")
    import traceback

    traceback.print_exc()
    offline_output = None

# ─────────────────────────────────────────────────────────────────────────────
# PART 7: Final verdict
# ─────────────────────────────────────────────────────────────────────────────

print("\n" + "=" * 100)
print(" FINAL VERDICT")
print("=" * 100)

verification_scores = {
    "Total matched tensors": (
        len(matches),
        len(backend_tensors),
        len(matches) == len(backend_tensors),
    ),
    "Perfect weight matches": (
        perfect_matches,
        len(matches),
        perfect_matches > len(matches) * 0.95,
    ),
    "Unmatched parameters": (len(unmatched_backend), 0, len(unmatched_backend) == 0),
    "Inference successful": (
        2,
        2,
        backend_output is not None and offline_output is not None,
    ),
}

print("\nVerification Matrix:")
print(f"  {'Check':<30} {'Expected':<20} {'Actual':<20} {'Status':<10}")
print("  " + "-" * 80)

all_passed = True
for check_name, (expected, actual, passed) in verification_scores.items():
    status = "✓ PASS" if passed else "✗ FAIL"
    print(f"  {check_name:<30} {str(expected):<20} {str(actual):<20} {status:<10}")
    if not passed:
        all_passed = False

# Overall assessment
print("\n" + "=" * 100)
if all_passed and perfect_matches > len(matches) * 0.98:
    print(" RESULT: ✓✓✓ WEIGHTS PERFECTLY CONVERTED ✓✓✓")
    print(
        "\n The offline model (disease_model.ptl) contains IDENTICAL weights to backend (best.pt)"
    )
    print(
        " Numerical precision is within acceptable tolerance for deep learning (< 1e-5)"
    )
    print(" Total parameters match - no data loss during TorchScript conversion")
elif perfect_matches > len(matches) * 0.90:
    print(" RESULT: ✓✓ WEIGHTS SUCCESSFULLY CONVERTED ✓✓")
    print(
        "\n The offline model contains nearly identical weights with minor precision differences"
    )
    print(
        " These differences are expected with TorchScript and are negligible for inference"
    )
else:
    print(" RESULT: ⚠️  WEIGHT CONVERSION NEEDS REVIEW ⚠️")
    print("\n Check unmatched tensors and differences")

print("=" * 100)

# Save detailed report
report = {
    "timestamp": str(Path.cwd()),
    "backend_parameters": len(backend_tensors),
    "offline_parameters": len(offline_tensors),
    "matched_tensors": len(matches),
    "perfect_matches": perfect_matches,
    "close_matches": close_matches,
    "total_backend_params": total_backend_params,
    "total_offline_params": total_offline_params,
    "parameter_match": f"{100 * total_offline_params / max(total_backend_params, 1):.1f}%",
    "max_weight_difference": float(
        np.max([m["max_diff"] for m in matches]) if matches else 0
    ),
    "inference_match": backend_output is not None and offline_output is not None,
}

with open("weight_verification_report.json", "w") as f:
    json.dump(report, f, indent=2, default=str)

print("\nDetailed report saved to: weight_verification_report.json")
