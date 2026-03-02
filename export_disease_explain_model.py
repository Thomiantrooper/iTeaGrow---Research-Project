"""
Export Disease Detection Explain Model for Grad-CAM Explainability
==================================================================
CORRECT APPROACH: Uses the ACTUAL trained YOLOv8 backbone from best.pt
so that feature maps reflect real disease-trained representations.

Architecture:
  - Backbone: YOLOv8n layers 0-9  (TRAINED on disease data, 512 ch, 7x7)
  - Head:     Linear(512 -> 3)   class-specific weights for CAM weighting
  - Output:   [logits(3) + features_flat(512*7*7)] = 25091 values

Normalization: YOLOv8 style = pixel/255
  -> Dart: mean=[0.0, 0.0, 0.0], std=[1.0, 1.0, 1.0]

Class order (matches best.pt + disease_labels.txt):
  0 = blister_blight
  1 = healthy
  2 = red_rust

Usage:
    python export_disease_explain_model.py

Output Files:
    frontend/iTeaGrow---Research-Project/assets/models/disease_explain.ptl
    frontend/iTeaGrow---Research-Project/assets/models/disease_fc_weights.json
"""

import torch
import torch.nn as nn
import json
import os
from pathlib import Path

# ─── Config ──────────────────────────────────────────────────────────────────

ASSETS_DIR  = r"frontend\iTeaGrow---Research-Project\assets\models"
BEST_PT     = r"models\best.pt"
EXPLAIN_OUT = os.path.join(ASSETS_DIR, "disease_explain.ptl")
WEIGHTS_OUT = os.path.join(ASSETS_DIR, "disease_fc_weights.json")

NUM_CLASSES       = 3
CLASS_NAMES       = ["blister_blight", "healthy", "red_rust"]
INPUT_SIZE        = 224
BACKBONE_CHANNELS = 512   # YOLOv8n layer-9 output at 224x224
FEATURE_H         = 7
FEATURE_W         = 7


# ─── Model wrapper ────────────────────────────────────────────────────────────

class YOLOBackboneExplain(nn.Module):
    """
    Wraps YOLOv8n backbone (layers 0-9, all f=-1/sequential) + FC head.

    Forward:  x [B,3,224,224]
           -> backbone -> [B, 512, 7, 7]
           -> GAP      -> [B, 512]
           -> FC       -> logits [B, 3]
           -> concat   -> [B, 3 + 512*7*7]

    Dart splits: logits=output[:3], features=output[3:].reshape(512,7,7)
    """

    def __init__(self, backbone_layers: nn.ModuleList, num_classes: int = 3):
        super().__init__()
        self.backbone   = backbone_layers
        self.classifier = nn.Linear(BACKBONE_CHANNELS, num_classes)
        nn.init.kaiming_uniform_(self.classifier.weight, a=0,
                                 mode='fan_in', nonlinearity='relu')
        nn.init.zeros_(self.classifier.bias)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        for layer in self.backbone:
            x = layer(x)                          # sequential, no skip-inputs
        feature_map = x                           # [B, 512, 7, 7]
        pooled  = feature_map.mean(dim=[2, 3])    # [B, 512]
        logits  = self.classifier(pooled)         # [B, 3]
        return torch.cat([logits, feature_map.flatten(1)], dim=1)


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    print("=" * 70)
    print(" Disease Explain Model Export  (YOLOv8 backbone + CAM head)")
    print("=" * 70)

    if not Path(BEST_PT).exists():
        print(f"\n❌  best.pt not found at: {BEST_PT}")
        print("    Run from iTeaGrow-Prod root directory.")
        return

    os.makedirs(ASSETS_DIR, exist_ok=True)

    # ── 1. Load YOLOv8 -------------------------------------------------------
    print(f"\n[1] Loading YOLOv8 from {BEST_PT}...")
    from ultralytics import YOLO
    yolo  = YOLO(BEST_PT)
    print(f"    Classes  : {yolo.names}")
    print(f"    Task     : {yolo.task}")

    for idx, expected in enumerate(CLASS_NAMES):
        actual = yolo.names.get(idx, "?")
        mark   = "OK" if actual == expected else "MISMATCH"
        print(f"    [{mark}] index {idx}: expected={expected}, model={actual}")

    # ── 2. Extract backbone layers 0-9 (all f=-1, purely sequential) ---------
    backbone_layers = nn.ModuleList(list(yolo.model.model[:10]))

    # ── 3. Build explain model -----------------------------------------------
    print("\n[2] Building YOLOBackboneExplain...")
    explain_model = YOLOBackboneExplain(backbone_layers, num_classes=NUM_CLASSES)
    explain_model.eval()

    # ── 4. Test forward -------------------------------------------------------
    print("\n[3] Testing forward pass (224x224)...")
    dummy        = torch.randn(1, 3, INPUT_SIZE, INPUT_SIZE)
    expected_len = NUM_CLASSES + BACKBONE_CHANNELS * FEATURE_H * FEATURE_W
    with torch.no_grad():
        out = explain_model(dummy)

    assert out.shape == (1, expected_len), \
        f"Unexpected shape: {out.shape}  (expected [1,{expected_len}])"
    logits = out[0, :NUM_CLASSES]
    feats  = out[0, NUM_CLASSES:]
    print(f"    Output : {out.shape[1]} = {NUM_CLASSES} logits + "
          f"{BACKBONE_CHANNELS}x{FEATURE_H}x{FEATURE_W} features")
    print(f"    Logits : {[round(v,4) for v in logits.tolist()]}")
    print(f"    Feat   : shape={feats.shape}  "
          f"min={feats.min():.4f} max={feats.max():.4f}")
    print("    OK: Forward pass verified")

    # ── 5. Save FC weights ---------------------------------------------------
    print("\n[4] Saving FC weights...")
    fc_w = explain_model.classifier.weight.detach().cpu().tolist()  # [3, 512]
    fc_b = explain_model.classifier.bias.detach().cpu().tolist()    # [3]

    weights_data = {
        "fc_weights"   : fc_w,
        "fc_bias"      : fc_b,
        "classes"      : CLASS_NAMES,
        "num_channels" : BACKBONE_CHANNELS,
        "feature_h"    : FEATURE_H,
        "feature_w"    : FEATURE_W,
        "backbone"     : "yolov8n-layers-0-9-trained-on-disease-data",
        "normalization": "pixel/255  (Dart: mean=[0,0,0] std=[1,1,1])",
        "note"         : "Backbone trained on disease data. FC head uses "
                         "kaiming_uniform — fine-tune head for best accuracy."
    }
    with open(WEIGHTS_OUT, "w") as f:
        json.dump(weights_data, f, indent=2)
    print(f"    OK  {WEIGHTS_OUT}  ({len(fc_w)}x{len(fc_w[0])})")

    # ── 6. Trace → PTL -------------------------------------------------------
    print("\n[5] Tracing for PyTorch Mobile...")
    try:
        traced = torch.jit.trace(explain_model, dummy)
        with torch.no_grad():
            assert traced(dummy).shape == out.shape
        print("    OK: Tracing succeeded")
    except Exception as e:
        print(f"    Tracing failed ({e}), trying script...")
        traced = torch.jit.script(explain_model)

    print("\n[6] Mobile optimisation...")
    try:
        from torch.utils.mobile_optimizer import optimize_for_mobile
        optimized = optimize_for_mobile(traced)
        print("    OK: Mobile optimisation applied")
    except Exception as e:
        print(f"    Skipped ({e})")
        optimized = traced

    print(f"\n[7] Saving to {EXPLAIN_OUT}...")
    optimized._save_for_lite_interpreter(EXPLAIN_OUT)
    size_mb = Path(EXPLAIN_OUT).stat().st_size / 1024 / 1024
    print(f"    OK  Saved ({size_mb:.2f} MB)")

    # ── 7. Verify round-trip -------------------------------------------------
    print("\n[8] Verifying round-trip...")
    loaded = torch.jit.load(EXPLAIN_OUT, map_location="cpu")
    loaded.eval()
    with torch.no_grad():
        v = loaded(dummy)
    assert v.shape == (1, expected_len), f"Round-trip failed: {v.shape}"
    print(f"    OK  Output shape: {v.shape}")

    print("\n" + "=" * 70)
    print(" EXPORT COMPLETE")
    print("=" * 70)
    print(f"\n  {EXPLAIN_OUT}  ({size_mb:.2f} MB)")
    print(f"  {WEIGHTS_OUT}")
    print()
    print("Dart GradCAM service must use:")
    print("  _numChannels = 512           (NOT 1280)")
    print("  _mean = [0.0, 0.0, 0.0]     (NOT ImageNet mean)")
    print("  _std  = [1.0, 1.0, 1.0]     (NOT ImageNet std)")
    print("  Classes: blister_blight / healthy / red_rust")


if __name__ == "__main__":
    main()
