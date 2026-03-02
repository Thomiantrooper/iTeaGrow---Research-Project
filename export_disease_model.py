"""
Export Disease Classification Model (.ptl) for Offline Fallback
================================================================
Creates a standalone 3-class softmax classifier from the YOLOv8 backbone
that is compatible with pytorch_lite's loadClassificationModel().

Architecture:
  - Backbone: YOLOv8n layers 0-9  (TRAINED on disease data, 512 ch, 7×7)
  - Head:     GAP → Linear(512→3) → Softmax
  - Output:   [3]  (blister_blight / healthy / red_rust probabilities)

Normalization:
  pytorch_lite applies pixel/255 before calling the model → model receives
  float values in [0, 1].  No internal /255 in this model's forward().
  Dart: getImagePredictionListProbabilities(bytes) — no extra mean/std needed.

FC weights:
  Loaded from disease_fc_weights.json (written by export_disease_explain_model.py)
  so BOTH models are byte-for-byte consistent on the FC head.

Usage:
    python export_disease_model.py

Output:
    frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl
"""

import torch
import torch.nn as nn
import json
import os
from pathlib import Path

# ─── Config ──────────────────────────────────────────────────────────────────

ASSETS_DIR  = r"frontend\iTeaGrow---Research-Project\assets\models"
BEST_PT     = r"models\best.pt"
MODEL_OUT   = os.path.join(ASSETS_DIR, "disease_model.ptl")
WEIGHTS_IN  = os.path.join(ASSETS_DIR, "disease_fc_weights.json")

NUM_CLASSES       = 3
CLASS_NAMES       = ["blister_blight", "healthy", "red_rust"]
INPUT_SIZE        = 224
BACKBONE_CHANNELS = 512
FEATURE_H         = 7
FEATURE_W         = 7


# ─── Model ────────────────────────────────────────────────────────────────────

class YOLOBackboneClassifier(nn.Module):
    """
    Pure classification wrapper around YOLOv8n backbone (layers 0-9).

    Forward:  x [B, 3, 224, 224]  (float in [0,1] — pytorch_lite pre-divides)
           -> backbone -> [B, 512, 7, 7]
           -> GAP      -> [B, 512]
           -> FC       -> logits [B, 3]
           -> Softmax  -> probabilities [B, 3]

    Compatible with PytorchLite.loadClassificationModel(path, 224, 224, 3)
    and getImagePredictionListProbabilities(bytes).
    """

    def __init__(self, backbone_layers: nn.ModuleList, num_classes: int = 3):
        super().__init__()
        self.backbone   = backbone_layers
        self.classifier = nn.Linear(BACKBONE_CHANNELS, num_classes)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x is already normalised to [0,1] by pytorch_lite before this call
        for layer in self.backbone:
            x = layer(x)                        # purely sequential (all f=-1)
        pooled = x.mean(dim=[2, 3])             # GAP → [B, 512]
        logits = self.classifier(pooled)        # [B, 3]
        return torch.softmax(logits, dim=1)     # [B, 3] probabilities


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print(" Disease Classifier Model Export  (YOLOv8 backbone → softmax)")
    print("=" * 70)

    if not Path(BEST_PT).exists():
        print(f"\n❌  best.pt not found at: {BEST_PT}")
        print("    Run from iTeaGrow-Prod root directory.")
        return

    os.makedirs(ASSETS_DIR, exist_ok=True)

    # ── 1. Load YOLOv8 -------------------------------------------------------
    print(f"\n[1] Loading YOLOv8 from {BEST_PT}...")
    from ultralytics import YOLO
    yolo = YOLO(BEST_PT)
    print(f"    Classes  : {yolo.names}")
    print(f"    Task     : {yolo.task}")

    for idx, expected in enumerate(CLASS_NAMES):
        actual = yolo.names.get(idx, "?")
        mark   = "OK" if actual == expected else "MISMATCH"
        print(f"    [{mark}] index {idx}: expected={expected}, model={actual}")

    # ── 2. Extract backbone layers 0-9 ----------------------------------------
    backbone_layers = nn.ModuleList(list(yolo.model.model[:10]))

    # ── 3. Build classifier model --------------------------------------------
    print("\n[2] Building YOLOBackboneClassifier...")
    model = YOLOBackboneClassifier(backbone_layers, num_classes=NUM_CLASSES)
    model.eval()

    # ── 4. Load FC weights from explain model (ensures consistency) ----------
    if Path(WEIGHTS_IN).exists():
        print(f"\n[3] Loading FC weights from {WEIGHTS_IN}...")
        with open(WEIGHTS_IN) as f:
            wd = json.load(f)
        fc_w = wd["fc_weights"]   # [3][512]
        fc_b = wd.get("fc_bias", [[0.0, 0.0, 0.0]])[0] if isinstance(
            wd.get("fc_bias"), list) else [0.0, 0.0, 0.0]
        # Handle bias stored as flat list vs nested
        if isinstance(wd.get("fc_bias"), list) and len(wd["fc_bias"]) == NUM_CLASSES:
            fc_b = wd["fc_bias"]

        w_tensor = torch.tensor(fc_w, dtype=torch.float32)  # [3, 512]
        b_tensor = torch.tensor(fc_b, dtype=torch.float32)  # [3]
        model.classifier.weight = nn.Parameter(w_tensor)
        model.classifier.bias   = nn.Parameter(b_tensor)
        print(f"    OK  FC weights loaded: {w_tensor.shape} weights + {b_tensor.shape} biases")
    else:
        print(f"\n[3] {WEIGHTS_IN} not found — run export_disease_explain_model.py first!")
        print("    Using kaiming_uniform init for FC head.")
        nn.init.kaiming_uniform_(model.classifier.weight, a=0,
                                 mode='fan_in', nonlinearity='relu')
        nn.init.zeros_(model.classifier.bias)

    # ── 5. Test forward -------------------------------------------------------
    print("\n[4] Testing forward pass (224×224)...")
    # pytorch_lite sends float in [0,1]; simulate that here
    dummy = torch.rand(1, 3, INPUT_SIZE, INPUT_SIZE)   # [0,1] range
    with torch.no_grad():
        out = model(dummy)

    assert out.shape == (1, NUM_CLASSES), \
        f"Unexpected output shape: {out.shape}  (expected [1, {NUM_CLASSES}])"
    probs_sum = out.sum().item()
    assert abs(probs_sum - 1.0) < 1e-4, f"Softmax sum ≠ 1.0: {probs_sum}"

    print(f"    Output shape : {out.shape}  ✓")
    print(f"    Probabilities: {[round(v, 4) for v in out[0].tolist()]}")
    print(f"    Sum          : {probs_sum:.6f}  ✓")
    print("    OK: Forward pass verified")

    # ── 6. Trace → optimize → save as PTL ------------------------------------
    print("\n[5] Tracing for PyTorch Mobile...")
    try:
        traced = torch.jit.trace(model, dummy)
        with torch.no_grad():
            assert traced(dummy).shape == (1, NUM_CLASSES)
        print("    OK: Tracing succeeded")
    except Exception as e:
        print(f"    Tracing failed ({e}), trying script mode...")
        traced = torch.jit.script(model)

    print("\n[6] Mobile optimisation...")
    try:
        from torch.utils.mobile_optimizer import optimize_for_mobile
        optimized = optimize_for_mobile(traced)
        print("    OK: Mobile optimisation applied")
    except Exception as e:
        print(f"    Skipped ({e})")
        optimized = traced

    print(f"\n[7] Saving to {MODEL_OUT}...")
    optimized._save_for_lite_interpreter(MODEL_OUT)
    size_mb = Path(MODEL_OUT).stat().st_size / 1024 / 1024
    print(f"    OK  Saved ({size_mb:.2f} MB)")

    # ── 7. Verify round-trip -------------------------------------------------
    print("\n[8] Verifying round-trip...")
    loaded = torch.jit.load(MODEL_OUT, map_location="cpu")
    loaded.eval()
    with torch.no_grad():
        v = loaded(dummy)
    assert v.shape == (1, NUM_CLASSES), f"Round-trip failed: {v.shape}"
    round_trip_sum = v.sum().item()
    assert abs(round_trip_sum - 1.0) < 1e-3, f"Round-trip softmax sum: {round_trip_sum}"
    print(f"    OK  Output shape: {v.shape}  sum={round_trip_sum:.6f}")

    print("\n" + "=" * 70)
    print(" EXPORT COMPLETE")
    print("=" * 70)
    print(f"\n  {MODEL_OUT}  ({size_mb:.2f} MB)")
    print()
    print("Flutter Dart service (.ptl fallback classifier) must use:")
    print("  PytorchLite.loadClassificationModel(path, 224, 224, 3)")
    print("  getImagePredictionListProbabilities(bytes)")
    print("  Classes: blister_blight / healthy / red_rust  (indices 0/1/2)")
    print()
    print("pytorch_lite pre-normalises pixels to [0,1] before calling model.")
    print("Do NOT add extra mean/std normalisation in Dart for this model.")


if __name__ == "__main__":
    main()
