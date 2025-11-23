import os

dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"

subsets = ["train", "valid", "test"]
classes = ["tender", "matured", "over_matured"]

for subset in subsets:
    subset_path = os.path.join(dataset_root, subset)
    if not os.path.exists(subset_path):
        print(f"❌ Missing folder: {subset_path}")
        continue
    print(f"\nSubset: {subset}")
    for cls in classes:
        class_path = os.path.join(subset_path, cls)
        if not os.path.exists(class_path):
            print(f"❌ Missing class folder: {class_path}")
        else:
            count = len([f for f in os.listdir(class_path) if f.lower().endswith(('.jpg','.jpeg','.png'))])
            print(f"✅ Class '{cls}' exists, {count} images")
