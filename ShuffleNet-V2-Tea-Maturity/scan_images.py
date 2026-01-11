# scan_images.py
import os
from PIL import Image

project_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
img_extensions = (".jpg", ".jpeg", ".png", ".webp")

print("\n=== Scanning Project Folder ===\n")

for root, dirs, files in os.walk(project_path):
    for d in dirs:
        print(f"📁 Folder: {os.path.join(root, d)}")
    for f in files:
        file_path = os.path.join(root, f)
        size_kb = round(os.path.getsize(file_path) / 1024, 2)
        print(f"📄 File: {file_path} | Size: {size_kb} KB")

print("\n=== Scanning Image Files ===\n")

for root, dirs, files in os.walk(project_path):
    for f in files:
        if f.lower().endswith(img_extensions):
            file_path = os.path.join(root, f)
            try:
                img = Image.open(file_path)
                img.verify()  # Check for corruption
                img = Image.open(file_path)
                print(f"✔ Valid: {file_path} -> Size: {img.size}, Mode: {img.mode}")
            except Exception as e:
                print(f"❌ Corrupted/Unreadable: {file_path} | Error: {e}")

print("\n=== Scan Complete ===\n")
