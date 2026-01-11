# project_model_scanner.py
import os

project_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
model_extensions = (".keras", ".h5", ".hdf5")  # Include common Keras/TensorFlow model formats

print("\n=== Scanning for Model Files ===\n")

found_models = []

for root, dirs, files in os.walk(project_path):
    for f in files:
        if f.lower().endswith(model_extensions):
            file_path = os.path.join(root, f)
            size_mb = round(os.path.getsize(file_path) / (1024 * 1024), 2)
            print(f"✔ Model Found: {file_path} | Size: {size_mb} MB")
            found_models.append(file_path)

if not found_models:
    print("❌ No model files found (.keras/.h5/.hdf5) in the project folder.")

print("\n=== Scan Complete ===\n")
