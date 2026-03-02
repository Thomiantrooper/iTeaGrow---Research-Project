import torch
import zipfile
import os

path1 = r"models/best.pt"
path2 = r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl"

print("QUICK MODEL COMPARISON TEST")
print("=" * 70)

# Check if files are actually ZIP archives (PyTorch uses ZIP format)
print("\n1. Checking file formats:")
for fpath, fname in [(path1, "best.pt"), (path2, "disease_model.ptl")]:
    try:
        with open(fpath, "rb") as f:
            magic = f.read(4)
            if magic == b"PK\x03\x04":  # ZIP magic number
                print(f"   {fname}: Valid ZIP format ✓")
                # List contents
                with zipfile.ZipFile(fpath, "r") as z:
                    print(f"      Contains {len(z.namelist())} files:")
                    for name in sorted(z.namelist())[:10]:
                        info = z.getinfo(name)
                        print(f"        - {name} ({info.file_size} bytes)")
            else:
                print(f"   {fname}: Unknown format (magic: {magic.hex()})")
    except Exception as e:
        print(f"   {fname}: Error - {e}")

print("\n2. Loading models:")
try:
    m1 = torch.load(path1, map_location="cpu")
    print(f"   best.pt loaded ✓ (type: {type(m1).__name__})")
except Exception as e:
    print(f"   best.pt failed: {e}")
    m1 = None

try:
    m2 = torch.load(path2, map_location="cpu")
    print(f"   disease_model.ptl loaded ✓ (type: {type(m2).__name__})")
except Exception as e:
    print(f"   disease_model.ptl failed: {e}")
    m2 = None

if m1 and m2:
    print("\n3. Quick content check:")
    if type(m1) == type(m2):
        print("   Same type ✓")
        if isinstance(m1, dict) and isinstance(m2, dict):
            if len(m1) == len(m2):
                print(f"   Same number of keys ({len(m1)}) ✓")
                # Check if keys match
                if set(m1.keys()) == set(m2.keys()):
                    print("   Same keys ✓")
                    # Quick check first and last tensor
                    keys = list(m1.keys())
                    if keys:
                        k = keys[0]
                        if torch.is_tensor(m1[k]) and torch.is_tensor(m2[k]):
                            same = torch.equal(m1[k], m2[k])
                            print(f"   First tensor '{k}' matches: {same}")
                else:
                    print(f"   Different keys!")
                    print(f"      Only in best.pt: {set(m1.keys()) - set(m2.keys())}")
                    print(
                        f"      Only in disease_model.ptl: {set(m2.keys()) - set(m1.keys())}"
                    )
            else:
                print(f"   Different number of keys: {len(m1)} vs {len(m2)}")
    else:
        print(f"   Different types: {type(m1).__name__} vs {type(m2).__name__}")

print("\n4. VERDICT:")
print("=" * 70)
if m1 == m2:
    print("✅ Models are IDENTICAL (same data)")
else:
    print("❌ Models are DIFFERENT")
    print("\nPossible reasons for size difference:")
    print("  - .ptl includes optimizer states or metadata")
    print("  - Different PyTorch serialization versions")
    print("  - Conversion didn't properly strip weights")
    print("  - Both versions of the model were saved (old + optimized)")
