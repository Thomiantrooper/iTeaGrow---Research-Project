import zipfile
import os

pt_path = "models/best.pt"
ptl_path = r"frontend/iTeaGrow---Research-Project/assets/models/disease_model.ptl"

print("FILE FORMAT ANALYSIS")
print("=" * 70)

print("\n[best.pt]")
try:
    with open(pt_path, "rb") as f:
        magic = f.read(4)
        is_zip = magic == b"PK\x03\x04"
        print(f"  Is ZIP format: {is_zip}")
        if is_zip:
            z = zipfile.ZipFile(pt_path, "r")
            files = z.namelist()
            print(f"  Number of files in ZIP: {len(files)}")
            print(f"  Files:")
            for name in sorted(files):
                info = z.getinfo(name)
                size_kb = info.file_size / 1024
                print(f"    - {name} ({size_kb:.1f} KB)")
except Exception as e:
    print(f"  Error: {e}")

print("\n[disease_model.ptl]")
try:
    with open(ptl_path, "rb") as f:
        magic = f.read(4)
        is_zip = magic == b"PK\x03\x04"
        print(f"  Is ZIP format: {is_zip}")
        if is_zip:
            z = zipfile.ZipFile(ptl_path, "r")
            files = z.namelist()
            print(f"  Number of files in ZIP: {len(files)}")
            print(f"  Files:")
            for name in sorted(files):
                info = z.getinfo(name)
                size_kb = info.file_size / 1024
                print(f"    - {name} ({size_kb:.1f} KB)")
        else:
            print(f"  NOT a ZIP file")
            print(f"  Magic bytes: {magic.hex()}")
except Exception as e:
    print(f"  Error: {e}")

with open("file_format_analysis.txt", "w") as f:
    f.write("File format analysis written to console")
