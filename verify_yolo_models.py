#!/usr/bin/env python
"""Compare models using YOLO"""
import sys
import os
from pathlib import Path

output = []

try:
    output.append("=" * 70 + "\n")
    output.append("MODEL VERIFICATION REPORT\n")
    output.append("=" * 70 + "\n\n")

    # File paths
    path1 = Path("models/best.pt")
    path2 = Path(
        r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl"
    )

    # Check existence and size
    output.append("FILE INFORMATION:\n")
    output.append(f"  best.pt:          {path1.stat().st_size / 1024 / 1024:.2f} MB\n")
    output.append(f"  disease_model.ptl: {path2.stat().st_size / 1024 / 1024:.2f} MB\n")
    size_ratio = path2.stat().st_size / path1.stat().st_size
    output.append(f"  Size ratio: PTL is {size_ratio:.2f}x larger\n\n")

    # Try loading with ultralytics
    output.append("LOADING WITH ULTRALYTICS YOLO:\n")
    try:
        from ultralytics import YOLO

        output.append("  Loading best.pt with YOLO...\n")
        m1 = YOLO("models/best.pt")
        output.append(f"  [OK] Loaded successfully\n")
        output.append(f"    Model: {m1.model.__class__.__name__}\n")
        output.append(f"    Classes: {m1.names}\n\n")
    except Exception as e:
        output.append(f"  [ERROR] Error loading best.pt: {e}\n\n")
        m1 = None

    try:
        output.append("  Loading disease_model.ptl with YOLO...\n")
        m2 = YOLO(
            "frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl"
        )
        output.append(f"  [OK] Loaded successfully\n")
        output.append(f"    Model: {m2.model.__class__.__name__}\n")
        output.append(f"    Classes: {m2.names}\n\n")
    except Exception as e:
        output.append(f"  [ERROR] Error loading disease_model.ptl: {e}\n\n")
        m2 = None

    output.append("\nDETAILED ANALYSIS:\n")
    output.append("-" * 70 + "\n")

    if m1 and m2:
        # Compare model structures
        output.append(
            f"same_model_type: {m1.model.__class__.__name__ == m2.model.__class__.__name__}\n"
        )
        output.append(f"same_classes: {m1.names == m2.names}\n")

        # Try to compare weights
        try:
            import torch

            output.append("\nAttempting detailed weights comparison...\n")

            # Get the underlying PyTorch model
            state1 = m1.model.state_dict()
            state2 = m2.model.state_dict()

            output.append(f"State dict 1 keys: {len(state1)}\n")
            output.append(f"State dict 2 keys: {len(state2)}\n")

            if set(state1.keys()) == set(state2.keys()):
                output.append("[OK] Same state dict keys\n")

                # Compare first few tensors
                matching = 0
                different = 0
                for key in list(state1.keys())[:10]:
                    t1 = state1[key]
                    t2 = state2[key]
                    if torch.allclose(t1.float(), t2.float(), rtol=1e-4, atol=1e-6):
                        matching += 1
                    else:
                        different += 1

                output.append(
                    f"Random weight check (first 10): {matching} matching, {different} different\n"
                )

                if different == 0:
                    output.append(
                        "\n[SUCCESS] CONCLUSION: Models appear to be IDENTICAL\n"
                    )
                elif matching > different:
                    output.append(
                        "\n[WARNING] CONCLUSION: Models are mostly similar but have some differences\n"
                    )
                else:
                    output.append("\n[FAIL] CONCLUSION: Models are VERY DIFFERENT\n")
            else:
                output.append("[ERROR] Different state dict keys\n")
                output.append(
                    f"Only in best.pt: {set(state1.keys()) - set(state2.keys())}\n"
                )
                output.append(
                    f"Only in disease_model.ptl: {set(state2.keys()) - set(state1.keys())}\n"
                )
                output.append("\n[FAIL] CONCLUSION: Models have different structure\n")
        except Exception as e:
            output.append(f"Error during detailed comparison: {e}\n")

    output.append("\n" + "=" * 70 + "\n")

except Exception as e:
    output.append(f"ERROR: {type(e).__name__}: {e}\n")
    import traceback

    output.append(traceback.format_exc() + "\n")

# Write output
with open("model_verification_report.txt", "w") as f:
    f.writelines(output)

print("Report written to model_verification_report.txt")
