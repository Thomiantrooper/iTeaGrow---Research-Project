#!/usr/bin/env python
"""Test that writes output to a file"""
import sys
import torch

output = []

try:
    output.append("Starting model comparison...\n")

    path1 = r"models/best.pt"
    path2 = r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl"

    output.append(f"Loading {path1}...\n")
    m1 = torch.load(path1, map_location="cpu", weights_only=False)
    output.append(f"✓ Loaded best.pt - type: {type(m1).__name__}\n")

    output.append(f"Loading {path2}...\n")
    m2 = torch.load(path2, map_location="cpu", weights_only=False)
    output.append(f"✓ Loaded disease_model.ptl - type: {type(m2).__name__}\n")

    if type(m1) != type(m2):
        output.append(f"\n❌ DIFFERENT TYPES:\n")
        output.append(f"   best.pt: {type(m1).__name__}\n")
        output.append(f"   disease_model.ptl: {type(m2).__name__}\n")
    elif isinstance(m1, dict):
        output.append(f"\nBoth are dictionaries\n")
        output.append(f"best.pt keys: {len(m1)}\n")
        output.append(f"disease_model.ptl keys: {len(m2)}\n")

        if set(m1.keys()) == set(m2.keys()):
            output.append("✓ Same keys\n")
            # Check a few tensors
            keys_to_check = list(m1.keys())[:3]
            all_match = True
            for k in keys_to_check:
                try:
                    if isinstance(m1[k], torch.Tensor) and isinstance(
                        m2[k], torch.Tensor
                    ):
                        match = torch.allclose(
                            m1[k].float(), m2[k].float(), rtol=1e-5, atol=1e-8
                        )
                        output.append(f"  {k}: {'✓ MATCH' if match else '✗ DIFFER'}\n")
                        if not match:
                            all_match = False
                except Exception as e:
                    output.append(f"  {k}: ? (error comparing)\n")
                    all_match = False

            if all_match:
                output.append("\n✅ Models appear to be IDENTICAL or very similar\n")
            else:
                output.append("\n⚠️ Models have some differences\n")
        else:
            output.append("✗ Different keys\n")
            output.append(f"Only in best.pt: {set(m1.keys()) - set(m2.keys())}\n")
            output.append(
                f"Only in disease_model.ptl: {set(m2.keys()) - set(m1.keys())}\n"
            )
except Exception as e:
    output.append(f"ERROR: {type(e).__name__}: {e}\n")
    import traceback

    output.append(traceback.format_exc() + "\n")

with open("model_comparison_result.txt", "w") as f:
    f.writelines(output)

print("Output written to model_comparison_result.txt")
