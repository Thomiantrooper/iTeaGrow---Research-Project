# import os
# import cv2
# import numpy as np
# from tensorflow.keras.applications.mobilenet_v3 import preprocess_input

# dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# target_size = (224, 224)  # MobileNetV3 default input

# for subset in ["train", "valid", "test"]:
#     for cls in ["tender","matured","over_matured"]:
#         folder = os.path.join(dataset_root, subset, cls)
#         for img_name in os.listdir(folder):
#             path = os.path.join(folder, img_name)
#             img = cv2.imread(path)
#             if img is None:
#                 print(f"Corrupt image: {path}")
#                 continue
#             img_resized = cv2.resize(img, target_size)
#             img_array = np.expand_dims(img_resized, axis=0)
#             img_preprocessed = preprocess_input(img_array)



##------------------------------------------------------------------------

import os
import cv2
import numpy as np
from tensorflow.keras.applications.mobilenet_v3 import preprocess_input

DATASET_ROOT = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
TARGET_SIZE = (224, 224)
SUBSETS = ["train", "valid", "test"]
CLASSES = ["tender", "matured", "over_matured"]

corrupt_images = {}
valid_count = {}

for subset in SUBSETS:
    for cls in CLASSES:
        folder = os.path.join(DATASET_ROOT, subset, cls)
        if not os.path.exists(folder):
            continue

        corrupt_images[cls] = []
        valid_count[cls] = 0

        for img_name in os.listdir(folder):
            path = os.path.join(folder, img_name)
            if not img_name.lower().endswith(('.jpg', '.jpeg', '.png')):
                continue  # skip non-images

            img = cv2.imread(path)
            if img is None:
                corrupt_images[cls].append(path)
                continue

            # Resize and preprocess
            img_resized = cv2.resize(img, TARGET_SIZE)
            img_array = np.expand_dims(img_resized, axis=0)
            img_preprocessed = preprocess_input(img_array)

            valid_count[cls] += 1

# ----------------- REPORT -----------------
for cls in CLASSES:
    print(f"Class '{cls}': {valid_count[cls]} valid images")
    if corrupt_images[cls]:
        print(f"  Corrupt/unreadable images ({len(corrupt_images[cls])}):")
        for img in corrupt_images[cls]:
            print(f"    {img}")
