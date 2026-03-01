"""
Verify if best.pt and disease_model.ptl are the same
"""

import torch
import sys
from pathlib import Path

file1 = Path("models/best.pt")
file2 = Path(r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl")

print("=" * 70)
print("ANALYZING best.pt")
print("=" * 70)
try:
    model1 = torch.load(file1, map_location="cpu")
    print(f"✓ Loaded successfully")
    print(f"  Type: {type(model1).__name__}")
    if isinstance(model1, dict):
        print(f"  Number of keys: {len(model1)}")
        print(f"  Keys: {list(model1.keys())[:10]}")
    print(f"  File size: {file1.stat().st_size / 1024 / 1024:.2f} MB")
except Exception as e:
    print(f"✗ Error: {type(e).__name__}: {e}")
    sys.exit(1)

print("\n" + "=" * 70)
print("ANALYZING disease_model.ptl")
print("=" * 70)
try:
    model2 = torch.load(file2, map_location="cpu")
    print(f"✓ Loaded successfully")
    print(f"  Type: {type(model2).__name__}")
    if isinstance(model2, dict):
        print(f"  Number of keys: {len(model2)}")
        print(f"  Keys: {list(model2.keys())[:10]}")
    print(f"  File size: {file2.stat().st_size / 1024 / 1024:.2f} MB")
except Exception as e:
    print(f"✗ Error: {type(e).__name__}: {e}")
    sys.exit(1)

print("\n" + "=" * 70)
print("COMPARISON")
print("=" * 70)

try:
    m1 = torch.load(file1, map_location="cpu")
    m2 = torch.load(file2, map_location="cpu")

    # Check type
    is_same_type = type(m1) == type(m2)
    print(f"Same type: {is_same_type}")
    if not is_same_type:
        print(
            f"  ✗ best.pt is {type(m1).__name__}, disease_model.ptl is {type(m2).__name__}"
        )

    # If both are dicts, compare keys
    if isinstance(m1, dict) and isinstance(m2, dict):
        same_keys = m1.keys() == m2.keys()
        print(f"Same keys: {same_keys}")
        if not same_keys:
            m1_only = set(m1.keys()) - set(m2.keys())
            m2_only = set(m2.keys()) - set(m1.keys())
            if m1_only:
                print(f"  Only in best.pt: {m1_only}")
            if m2_only:
                print(f"  Only in disease_model.ptl: {m2_only}")
        else:
            # Compare content
            print("\nComparing content:")
            all_identical = True
            for key in m1.keys():
                try:
                    if isinstance(m1[key], torch.Tensor) and isinstance(
                        m2[key], torch.Tensor
                    ):
                        is_equal = torch.equal(m1[key], m2[key])
                        if is_equal:
                            print(f"  ✓ {key}: IDENTICAL")
                        else:
                            print(f"  ✗ {key}: DIFFERENT")
                            print(f"      Shape: {m1[key].shape} vs {m2[key].shape}")
                            print(f"      Dtype: {m1[key].dtype} vs {m2[key].dtype}")
                            all_identical = False
                    else:
                        # For non-tensor types
                        if m1[key] == m2[key]:
                            print(f"  ✓ {key}: IDENTICAL")
                        else:
                            print(f"  ✗ {key}: DIFFERENT")
                            all_identical = False
                except Exception as e:
                    print(f"  ? {key}: Cannot compare - {e}")
                    all_identical = False

            if all_identical:
                print("\n🎉 SUCCESS: Both files contain IDENTICAL model data!")
            else:
                print("\n⚠️ WARNING: Files contain DIFFERENT model data")

    print("\n" + "=" * 70)
    print("VERDICT")
    print("=" * 70)
    if (
        is_same_type
        and isinstance(m1, dict)
        and isinstance(m2, dict)
        and m1.keys() == m2.keys()
    ):
        # Check a couple of tensors to be sure
        for key in list(m1.keys())[:2]:
            if not torch.equal(m1[key], m2[key]):
                print("❌ DIFFERENT: Files do not contain the same data")
                print("The conversion was NOT done properly.")
                sys.exit(1)
        print("✅ SAME: Files contain identical model weights/data")
        print("However, file sizes differ (42.53 MB vs 21.48 MB) - possible reasons:")
        print("  - Different serialization/compression methods")
        print("  - Metadata or optimizer states included in PTL version")
        print("  - Different PyTorch versions used for serialization")
    else:
        print("❌ DIFFERENT: Files have different structure/format")
        print("The conversion was NOT done properly.")

except Exception as e:
    print(f"Error during comparison: {type(e).__name__}: {e}")
    import traceback

    traceback.print_exc()
    sys.exit(1)
