# import cv2, os

# dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# threshold_brightness = 30  # below this is too dark

# for subset in ["train", "valid", "test"]:
#     for cls in ["tender","matured","over_matured"]:
#         folder = os.path.join(dataset_root, subset, cls)
#         for img_name in os.listdir(folder):
#             path = os.path.join(folder, img_name)
#             img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
#             if img is None:
#                 print(f"Corrupt: {path}")
#                 continue
#             if img.mean() < threshold_brightness:
#                 print(f"Too dark: {path}")


#------------------------------------------------------------------------
import os
import cv2
import numpy as np
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input

# ---------------- PARAMETERS ----------------
DATASET_ROOT = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
TARGET_SIZE = (224, 224)  # MobileNetV3 default input
SUBSETS = ["train", "valid", "test"]
CLASSES = ["tender", "matured", "over_matured"]

corrupt_images = []

# ---------------- FUNCTION ----------------
def check_and_preprocess_image(img_path):
    img = cv2.imread(img_path)
    if img is None:
        return None
    img_resized = cv2.resize(img, TARGET_SIZE)
    img_array = np.expand_dims(img_resized, axis=0)
    return preprocess_input(img_array)

# ---------------- LOOP THROUGH DATASET ----------------
for subset in SUBSETS:
    for cls in CLASSES:
        folder = os.path.join(DATASET_ROOT, subset, cls)
        if not os.path.exists(folder):
            print(f"Folder does not exist: {folder}")
            continue

        for entry in os.scandir(folder):
            if entry.is_file() and entry.name.lower().endswith((".jpg", ".jpeg", ".png")):
                preprocessed = check_and_preprocess_image(entry.path)
                if preprocessed is None:
                    corrupt_images.append(entry.path)

# ---------------- REPORT ----------------
if corrupt_images:
    print(f"\nFound {len(corrupt_images)} corrupt/unreadable images:")
    for img in corrupt_images:
        print(img)
else:
    print("\nAll images are valid and preprocessed successfully ✅")
