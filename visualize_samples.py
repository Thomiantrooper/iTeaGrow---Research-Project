import os

dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
min_images_threshold = 10  # flag classes with fewer than 10 images

for subset in ["train", "valid", "test"]:
    print(f"\nSubset: {subset}")
    for cls in ["tender", "matured", "over_matured"]:
        folder = os.path.join(dataset_root, subset, cls)
        if not os.path.exists(folder):
            print(f"⚠️ Missing folder: {folder}")
            continue
        image_count = len([f for f in os.listdir(folder) if f.lower().endswith(('.jpg','.jpeg','.png'))])
        flag = "⚠️ Too few images!" if image_count < min_images_threshold else ""
        print(f"Class: {cls}, Images: {image_count} {flag}")
