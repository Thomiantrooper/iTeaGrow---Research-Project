# # # # import os
# # # # import cv2
# # # # from glob import glob
# # # # import albumentations as A
# # # # import math

# # # # # ---------------- PARAMETERS ----------------
# # # # num_target_images = 1000  # desired per class
# # # # input_root = r"C:\Users\HP\Desktop\dataset DT1"  # root folder containing tender, matured, over_matured
# # # # output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_augmented"
# # # # os.makedirs(output_root, exist_ok=True)

# # # # # ------------- AUGMENTATION PIPELINE -------------
# # # # augment = A.Compose([
# # # #     A.HorizontalFlip(p=0.5),
# # # #     A.Rotate(limit=30, p=0.7),
# # # #     A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.7),
# # # #     A.GaussianBlur(blur_limit=(1,2), p=0.3),
# # # #     A.GaussNoise(var_limit=(10.0, 30.0), p=0.3),
# # # #     A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=15, val_shift_limit=15, p=0.5),
# # # #     A.RandomShadow(p=0.2),
# # # #     A.RandomScale(scale_limit=0.1, p=0.5)
# # # # ])

# # # # # ----------- PROCESS EACH CLASS ------------
# # # # classes = ["tender", "matured", "over_matured"]

# # # # for class_name in classes:
# # # #     class_input = os.path.join(input_root, class_name)
# # # #     class_output = os.path.join(output_root, class_name)
# # # #     os.makedirs(class_output, exist_ok=True)
    
# # # #     images = glob(class_input + "/*.jpg")
# # # #     num_images = len(images)
# # # #     augmentations_per_image = math.ceil(num_target_images / num_images)
    
# # # #     print(f"Processing class '{class_name}' with {num_images} original images. Each image will generate {augmentations_per_image} augmented images.")
    
# # # #     for img_path in images:
# # # #         img = cv2.imread(img_path)
# # # #         filename = os.path.basename(img_path).split('.')[0]
# # # #         # save original resized
# # # #         img_resized = cv2.resize(img, (224,224))
# # # #         cv2.imwrite(os.path.join(class_output, f"{filename}.jpg"), img_resized)
        
# # # #         for i in range(augmentations_per_image):
# # # #             aug_img = augment(image=img)["image"]
# # # #             aug_img = cv2.resize(aug_img, (224,224))
# # # #             cv2.imwrite(os.path.join(class_output, f"{filename}_aug{i}.jpg"), aug_img)




# # # #----------------------------------------------------------------------------------------------------
# # # # Script to augment dataset and split into train/valid/test sets

# # # import os
# # # import cv2
# # # from glob import glob
# # # import albumentations as A
# # # import math
# # # import random
# # # import shutil

# # # # ---------------- PARAMETERS ----------------
# # # num_target_images = 1000   # desired images per class
# # # input_root = r"C:\Users\HP\Desktop\dataset DT1"  # root folder containing tender, matured, over_matured
# # # output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# # # train_ratio, valid_ratio, test_ratio = 0.8, 0.1, 0.1  # split ratios

# # # classes = ["tender", "matured", "over_matured"]
# # # os.makedirs(output_root, exist_ok=True)

# # # # ------------- AUGMENTATION PIPELINE -------------
# # # augment = A.Compose([
# # #     A.HorizontalFlip(p=0.5),
# # #     A.Rotate(limit=30, p=0.7),
# # #     A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.7),
# # #     A.GaussianBlur(blur_limit=(1,2), p=0.3),
# # #     A.GaussNoise(var_limit=(10.0, 30.0), p=0.3),
# # #     A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=15, val_shift_limit=15, p=0.5),
# # #     A.RandomShadow(p=0.2),
# # #     A.RandomScale(scale_limit=0.1, p=0.5)
# # # ])

# # # # ------------- FUNCTION TO CREATE AUGMENTED IMAGES -------------
# # # def augment_class(class_name):
# # #     class_input = os.path.join(input_root, class_name)
# # #     class_output = os.path.join(output_root, "all_" + class_name)
# # #     os.makedirs(class_output, exist_ok=True)
    
# # #     images = glob(class_input + "/*.jpg")
# # #     num_images = len(images)
# # #     augmentations_per_image = math.ceil(num_target_images / num_images)
    
# # #     print(f"[INFO] Processing class '{class_name}' with {num_images} original images. Each will generate {augmentations_per_image} augmented images.")
    
# # #     for img_path in images:
# # #         img = cv2.imread(img_path)
# # #         filename = os.path.basename(img_path).split('.')[0]
# # #         # save original resized
# # #         img_resized = cv2.resize(img, (224,224))
# # #         cv2.imwrite(os.path.join(class_output, f"{filename}.jpg"), img_resized)
        
# # #         for i in range(augmentations_per_image):
# # #             aug_img = augment(image=img)["image"]
# # #             aug_img = cv2.resize(aug_img, (224,224))
# # #             cv2.imwrite(os.path.join(class_output, f"{filename}_aug{i}.jpg"), aug_img)
    
# # #     # Return all image paths for splitting
# # #     return glob(class_output + "/*.jpg")

# # # # ------------- AUGMENT AND COLLECT ALL IMAGES -------------
# # # all_images = {}
# # # for cls in classes:
# # #     all_images[cls] = augment_class(cls)

# # # # ------------- SPLIT INTO TRAIN / VALID / TEST -------------
# # # def split_and_save():
# # #     for cls, img_paths in all_images.items():
# # #         random.shuffle(img_paths)
# # #         n = len(img_paths)
# # #         train_end = int(n * train_ratio)
# # #         valid_end = train_end + int(n * valid_ratio)
        
# # #         for i, path in enumerate(img_paths):
# # #             if i < train_end:
# # #                 subset = "train"
# # #             elif i < valid_end:
# # #                 subset = "valid"
# # #             else:
# # #                 subset = "test"
# # #             dst_dir = os.path.join(output_root, subset, cls)
# # #             os.makedirs(dst_dir, exist_ok=True)
# # #             shutil.copy(path, dst_dir)
# # #     print("[INFO] Dataset split complete. Ready for MobileNetV3 training!")

# # # split_and_save()




# # ##----------------------------------------------
# # import os
# # import cv2
# # from glob import glob
# # import albumentations as A
# # import math
# # import random
# # import shutil
# # import numpy as np

# # # ---------------- PARAMETERS ----------------
# # num_target_images = 1000  # desired images per class
# # input_root = r"C:\Users\HP\Desktop\dataset DT1"  # original dataset folder
# # output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# # train_ratio, valid_ratio, test_ratio = 0.8, 0.1, 0.1

# # classes = ["tender", "matured", "over_matured"]
# # os.makedirs(output_root, exist_ok=True)

# # # ------------- SAFE AUGMENTATION PIPELINE -------------
# # augment = A.Compose([
# #     A.HorizontalFlip(p=0.5),
# #     A.Rotate(limit=15, p=0.5),  # small rotation
# #     A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5),
# #     A.HueSaturationValue(hue_shift_limit=5, sat_shift_limit=10, val_shift_limit=10, p=0.3),
# #     A.RandomScale(scale_limit=0.05, p=0.3)
# # ])

# # # ------------- HELPER FUNCTION TO FILTER BAD IMAGES -------------
# # def is_image_valid(img):
# #     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# #     mean_intensity = np.mean(gray)
# #     return mean_intensity > 30  # discard too dark images

# # # ------------- AUGMENT AND SAVE FUNCTION -------------
# # def augment_class(class_name):
# #     class_input = os.path.join(input_root, class_name)
# #     class_output = os.path.join(output_root, "all_" + class_name)
# #     os.makedirs(class_output, exist_ok=True)
    
# #     images = glob(class_input + "/*.jpg")
# #     num_images = len(images)
# #     augmentations_per_image = math.ceil(num_target_images / num_images)
    
# #     print(f"[INFO] Processing class '{class_name}' with {num_images} original images. Each will generate {augmentations_per_image} augmented images.")
    
# #     saved_paths = []
    
# #     for img_path in images:
# #         img = cv2.imread(img_path)
# #         filename = os.path.basename(img_path).split('.')[0]
        
# #         # save original resized if valid
# #         img_resized = cv2.resize(img, (224,224))
# #         if is_image_valid(img_resized):
# #             save_path = os.path.join(class_output, f"{filename}.jpg")
# #             cv2.imwrite(save_path, img_resized)
# #             saved_paths.append(save_path)
        
# #         # generate augmented images
# #         for i in range(augmentations_per_image):
# #             aug_img = augment(image=img)["image"]
# #             aug_img = cv2.resize(aug_img, (224,224))
# #             if is_image_valid(aug_img):
# #                 save_path = os.path.join(class_output, f"{filename}_aug{i}.jpg")
# #                 cv2.imwrite(save_path, aug_img)
# #                 saved_paths.append(save_path)
    
# #     return saved_paths

# # # ------------- AUGMENT ALL CLASSES -------------
# # all_images = {}
# # for cls in classes:
# #     all_images[cls] = augment_class(cls)

# # # ------------- SPLIT INTO TRAIN / VALID / TEST -------------
# # def split_and_save():
# #     for cls, img_paths in all_images.items():
# #         random.shuffle(img_paths)
# #         n = len(img_paths)
# #         train_end = int(n * train_ratio)
# #         valid_end = train_end + int(n * valid_ratio)
        
# #         for i, path in enumerate(img_paths):
# #             if i < train_end:
# #                 subset = "train"
# #             elif i < valid_end:
# #                 subset = "valid"
# #             else:
# #                 subset = "test"
# #             dst_dir = os.path.join(output_root, subset, cls)
# #             os.makedirs(dst_dir, exist_ok=True)
# #             shutil.copy(path, dst_dir)
    
# #     print("[INFO] Dataset split complete. Ready for MobileNetV3 training!")

# # split_and_save()



# ## above one is the best for now - less duplicates
# ## below one gave me more duplicates
# ## # #----------------------------------------------------------------------------------------------------

#     # import os
#     # import cv2
#     # import math
#     # import random
#     # import shutil
#     # import numpy as np
#     # from glob import glob
#     # from PIL import Image
#     # import hashlib
#     # import albumentations as A

#     # # ---------------- PARAMETERS ----------------
#     # num_target_images = 1000                # desired images per class
#     # input_root = r"C:\Users\HP\Desktop\dataset DT1"  # original dataset folder
#     # output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
#     # train_ratio, valid_ratio, test_ratio = 0.8, 0.1, 0.1
#     # classes = ["tender", "matured", "over_matured"]

#     # os.makedirs(output_root, exist_ok=True)

#     # # ---------------- AUGMENTATION PIPELINE ----------------
#     # augment = A.Compose([
#     #     A.HorizontalFlip(p=0.5),
#     #     A.Rotate(limit=15, p=0.5),
#     #     A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5),
#     #     A.HueSaturationValue(hue_shift_limit=5, sat_shift_limit=10, val_shift_limit=10, p=0.3),
#     #     A.RandomScale(scale_limit=0.05, p=0.3)
#     # ])

#     # # ---------------- HELPER FUNCTIONS ----------------
#     # def is_image_valid(img):
#     #     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     #     return np.mean(gray) > 30  # discard too dark images

#     # def get_image_hash(img):
#     #     """Compute MD5 hash of an image to prevent exact duplicates"""
#     #     pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
#     #     return hashlib.md5(pil_img.tobytes()).hexdigest()

#     # # ---------------- AUGMENT AND SAVE FUNCTION ----------------
#     # def augment_class(class_name, saved_hashes):
#     #     class_input = os.path.join(input_root, class_name)
#     #     class_temp = os.path.join(output_root, "all_" + class_name)
#     #     os.makedirs(class_temp, exist_ok=True)

#     #     images = glob(class_input + "/*.jpg")
#     #     num_images = len(images)
#     #     augmentations_per_image = math.ceil(num_target_images / num_images)

#     #     saved_paths = []

#     #     for img_path in images:
#     #         img = cv2.imread(img_path)
#     #         if img is None:
#     #             continue
#     #         filename = os.path.basename(img_path).split('.')[0]

#     #         # Save original image if valid and not duplicate
#     #         img_resized = cv2.resize(img, (224,224))
#     #         img_hash = get_image_hash(img_resized)
#     #         if is_image_valid(img_resized) and img_hash not in saved_hashes:
#     #             save_path = os.path.join(class_temp, f"{filename}.jpg")
#     #             cv2.imwrite(save_path, img_resized)
#     #             saved_hashes.add(img_hash)
#     #             saved_paths.append(save_path)

#     #         # Generate augmented images
#     #         for i in range(augmentations_per_image):
#     #             aug_img = augment(image=img)["image"]
#     #             aug_img = cv2.resize(aug_img, (224,224))
#     #             aug_hash = get_image_hash(aug_img)

#     #             if is_image_valid(aug_img) and aug_hash not in saved_hashes:
#     #                 save_path = os.path.join(class_temp, f"{filename}_aug{i}.jpg")
#     #                 cv2.imwrite(save_path, aug_img)
#     #                 saved_hashes.add(aug_hash)
#     #                 saved_paths.append(save_path)

#     #     return saved_paths

#     # # ---------------- AUGMENT ALL CLASSES ----------------
#     # all_images = {}
#     # saved_hashes = set()

#     # for cls in classes:
#     #     all_images[cls] = augment_class(cls, saved_hashes)

#     # # ---------------- SPLIT INTO TRAIN / VALID / TEST ----------------
#     # def split_and_save():
#     #     for cls, img_paths in all_images.items():
#     #         random.shuffle(img_paths)
#     #         n = len(img_paths)
#     #         train_end = int(n * train_ratio)
#     #         valid_end = train_end + int(n * valid_ratio)

#     #         for i, path in enumerate(img_paths):
#     #             if i < train_end:
#     #                 subset = "train"
#     #             elif i < valid_end:
#     #                 subset = "valid"
#     #             else:
#     #                 subset = "test"
#     #             dst_dir = os.path.join(output_root, subset, cls)
#     #             os.makedirs(dst_dir, exist_ok=True)
#     #             shutil.copy(path, dst_dir)

#     #     print("[✅] Dataset augmentation & split complete! Ready for MobileNetV3 training.")

#     # split_and_save()


# ## #----------------------------------------------------------------------------------------------------
# import os
# import cv2
# import math
# import random
# import shutil
# import numpy as np
# from glob import glob
# from PIL import Image
# import albumentations as A
# import imagehash

# # ---------------- PARAMETERS ----------------
# num_target_images = 1000                   # target images per class
# input_root = r"C:\Users\HP\Desktop\dataset DT1"  # original dataset
# output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# train_ratio, valid_ratio, test_ratio = 0.8, 0.1, 0.1
# classes = ["tender", "matured", "over_matured"]

# os.makedirs(output_root, exist_ok=True)

# # ---------------- AUGMENTATION PIPELINE ----------------
# augment = A.Compose([
#     A.HorizontalFlip(p=0.5),
#     A.Rotate(limit=15, p=0.5),
#     A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5),
#     A.HueSaturationValue(hue_shift_limit=5, sat_shift_limit=10, val_shift_limit=10, p=0.3),
#     A.RandomScale(scale_limit=0.05, p=0.3)
# ])

# # ---------------- HELPER FUNCTIONS ----------------
# def is_image_valid(img):
#     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     return np.mean(gray) > 30  # discard too dark

# def get_image_phash(img):
#     """Compute perceptual hash for near-duplicate detection"""
#     pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
#     return str(imagehash.phash(pil_img))

# # ---------------- AUGMENT AND SAVE FUNCTION ----------------
# def augment_class(class_name):
#     class_input = os.path.join(input_root, class_name)
#     class_temp = os.path.join(output_root, "all_" + class_name)
#     os.makedirs(class_temp, exist_ok=True)

#     images = glob(class_input + "/*.jpg")
#     num_images = len(images)
#     augmentations_per_image = math.ceil(num_target_images / num_images)

#     saved_paths = []
#     saved_hashes = set()  # per-class

#     for img_path in images:
#         img = cv2.imread(img_path)
#         if img is None:
#             continue
#         filename = os.path.basename(img_path).split('.')[0]

#         # Save original image if valid and not duplicate
#         img_resized = cv2.resize(img, (224,224))
#         img_hash = get_image_phash(img_resized)
#         if is_image_valid(img_resized) and img_hash not in saved_hashes:
#             save_path = os.path.join(class_temp, f"{filename}.jpg")
#             cv2.imwrite(save_path, img_resized)
#             saved_paths.append(save_path)
#             saved_hashes.add(img_hash)

#         # Generate augmented images until target reached
#         i = 0
#         while len(saved_paths) < num_target_images:
#             aug_img = augment(image=img)["image"]
#             aug_img_resized = cv2.resize(aug_img, (224,224))
#             aug_hash = get_image_phash(aug_img_resized)

#             if is_image_valid(aug_img_resized) and aug_hash not in saved_hashes:
#                 save_path = os.path.join(class_temp, f"{filename}_aug{i}.jpg")
#                 cv2.imwrite(save_path, aug_img_resized)
#                 saved_paths.append(save_path)
#                 saved_hashes.add(aug_hash)
#                 i += 1
#             if i >= augmentations_per_image * 3:  # safety break to avoid infinite loop
#                 break

#     print(f"[INFO] Class '{class_name}' processed. Total images: {len(saved_paths)}")
#     return saved_paths

# # ---------------- AUGMENT ALL CLASSES ----------------
# all_images = {}
# for cls in classes:
#     all_images[cls] = augment_class(cls)

# # ---------------- SPLIT INTO TRAIN / VALID / TEST ----------------
# def split_and_save():
#     for cls, img_paths in all_images.items():
#         random.shuffle(img_paths)
#         n = len(img_paths)
#         train_end = int(n * train_ratio)
#         valid_end = train_end + int(n * valid_ratio)

#         for i, path in enumerate(img_paths):
#             if i < train_end:
#                 subset = "train"
#             elif i < valid_end:
#                 subset = "valid"
#             else:
#                 subset = "test"
#             dst_dir = os.path.join(output_root, subset, cls)
#             os.makedirs(dst_dir, exist_ok=True)
#             shutil.copy(path, dst_dir)

#     print("[✅] Dataset augmentation & split complete! Ready for MobileNetV3 & YOLO training.")

# split_and_save()



# -----------------------------------------------------------------------------------------------------------------------
# unbiased version

# import os
# import cv2
# import math
# import random
# import shutil
# import numpy as np
# from glob import glob
# from PIL import Image
# import albumentations as A
# import imagehash
# from tqdm import tqdm  

# # ---------------- PARAMETERS ----------------
# num_target_images = 1000
# input_root = r"C:\Users\HP\Desktop\dataset DT1"
# output_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# train_ratio, valid_ratio, test_ratio = 0.8, 0.1, 0.1
# classes = ["tender", "matured", "over_matured"]

# os.makedirs(output_root, exist_ok=True)

# # ---------------- AUGMENTATION PIPELINE ----------------
# augment = A.Compose([
#     A.HorizontalFlip(p=0.5),
#     A.Rotate(limit=15, p=0.5),
#     A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5),
#     A.HueSaturationValue(hue_shift_limit=5, sat_shift_limit=10, val_shift_limit=10, p=0.3),
#     A.RandomScale(scale_limit=0.05, p=0.3)
# ])

# # ---------------- HELPERS ----------------
# def is_image_valid(img):
#     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     return np.mean(gray) > 30

# def get_phash(img):
#     pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
#     return str(imagehash.phash(pil))


# # ---------------- BALANCED AUGMENTATION ----------------
# def augment_class_balanced(class_name):
#     print(f"\n🔵 Processing Class: {class_name}")

#     class_input = os.path.join(input_root, class_name)
#     class_temp = os.path.join(output_root, "all_" + class_name)
#     os.makedirs(class_temp, exist_ok=True)

#     img_paths = glob(class_input + "/*.jpg")
#     total_imgs = len(img_paths)
#     target_per_img = math.ceil(num_target_images / total_imgs)

#     print(f"   → Found {total_imgs} original images")
#     print(f"   → Generating ~{target_per_img} per image\n")

#     saved_hashes = set()
#     saved_paths = []

#     # tqdm progress bar for images
#     for img_path in tqdm(img_paths, desc=f"{class_name} images", colour="cyan"):
#         img = cv2.imread(img_path)
#         if img is None:
#             continue

#         base = os.path.splitext(os.path.basename(img_path))[0]

#         # resize original
#         img_resized = cv2.resize(img, (224,224))
#         h = get_phash(img_resized)

#         # save original if unique
#         if is_image_valid(img_resized) and h not in saved_hashes:
#             out = os.path.join(class_temp, f"{base}.jpg")
#             cv2.imwrite(out, img_resized)
#             saved_paths.append(out)
#             saved_hashes.add(h)

#         # tqdm inner bar for augmentations
#         for i in tqdm(range(1, target_per_img),
#                       desc=f"Augmenting {base}", leave=False, colour="magenta"):

#             aug = augment(image=img)["image"]
#             aug_resized = cv2.resize(aug, (224,224))
#             h2 = get_phash(aug_resized)

#             if is_image_valid(aug_resized) and h2 not in saved_hashes:
#                 out = os.path.join(class_temp, f"{base}_aug{i}.jpg")
#                 cv2.imwrite(out, aug_resized)
#                 saved_paths.append(out)
#                 saved_hashes.add(h2)

#     print(f"\n✅ Completed class '{class_name}'. Total images: {len(saved_paths)}\n")
#     return saved_paths


# # ---------------- PROCESS ALL CLASSES ----------------
# all_images = {}
# for cls in classes:
#     all_images[cls] = augment_class_balanced(cls)

# # ---------------- SPLIT ----------------
# def split_and_save():
#     print("\n📦 Splitting into train, valid, test...")

#     for cls, paths in all_images.items():
#         random.shuffle(paths)
#         n = len(paths)
#         train_end = int(n * train_ratio)
#         valid_end = train_end + int(n * valid_ratio)

#         # tqdm for split
#         for i, src in tqdm(list(enumerate(paths)), desc=f"Splitting {cls}", colour="yellow"):
#             if i < train_end:
#                 folder = "train"
#             elif i < valid_end:
#                 folder = "valid"
#             else:
#                 folder = "test"

#             dest = os.path.join(output_root, folder, cls)
#             os.makedirs(dest, exist_ok=True)
#             shutil.copy(src, dest)

#     print("\n🎉 ALL DONE! Dataset is now perfectly balanced & YOLO-ready.")

# split_and_save()




#--------------------------------------------------------------------------------
#think this will work adjusted according to research papers reference

import os
import cv2
import math
import random
import shutil
import numpy as np
from glob import glob
from PIL import Image
import albumentations as A
import imagehash
from tqdm import tqdm

# ---------------- PARAMETERS ----------------
TARGET_IMAGES_PER_CLASS = 1200
INPUT_ROOT = r"C:\Users\HP\Desktop\dataset DT1"
OUTPUT_ROOT = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
TRAIN_RATIO, VALID_RATIO, TEST_RATIO = 0.8, 0.1, 0.1
CLASSES = ["tender", "matured", "over_matured"]

os.makedirs(OUTPUT_ROOT, exist_ok=True)

# ---------------- AUGMENTATION PIPELINE (SAFE) ----------------
augment_pipeline = A.Compose([
    A.HorizontalFlip(p=0.5),
    A.Rotate(limit=10, p=0.4, border_mode=cv2.BORDER_REPLICATE),
    A.RandomBrightnessContrast(brightness_limit=0.08, contrast_limit=0.08, p=0.3),
    A.HueSaturationValue(hue_shift_limit=3, sat_shift_limit=5, val_shift_limit=5, p=0.2),
])

# ---------------- HELPER FUNCTIONS ----------------
def is_valid(img):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    return np.mean(gray) > 30  # discard very dark images

def phash(img):
    pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    return str(imagehash.phash(pil_img))

def dhash(img):
    pil_img = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    return str(imagehash.dhash(pil_img))

# ---------------- AUGMENT & SAVE ONE CLASS ----------------
def augment_class(cls_name):
    print(f"\nProcessing class: {cls_name}")
    in_dir = os.path.join(INPUT_ROOT, cls_name)
    out_dir = os.path.join(OUTPUT_ROOT, cls_name + "_aug")
    os.makedirs(out_dir, exist_ok=True)

    img_paths = glob(os.path.join(in_dir, "*.jpg"))
    total_imgs = len(img_paths)
    per_img_target = math.ceil(TARGET_IMAGES_PER_CLASS / total_imgs)

    saved_hashes = set()
    saved_paths = []

    for img_path in tqdm(img_paths, desc=f"{cls_name} originals", colour="cyan"):
        img = cv2.imread(img_path)
        if img is None:
            continue
        base = os.path.splitext(os.path.basename(img_path))[0]

        resized = cv2.resize(img, (224, 224))
        h0 = phash(resized) + "_" + dhash(resized)

        if is_valid(resized) and h0 not in saved_hashes:
            out_path = os.path.join(out_dir, f"{base}.jpg")
            cv2.imwrite(out_path, resized)
            saved_paths.append(out_path)
            saved_hashes.add(h0)

        count = 1
        attempts = 0
        with tqdm(total=per_img_target, desc=f"Augmenting {base}", leave=False, colour="magenta") as pbar:
            while count < per_img_target and attempts < per_img_target * 10:
                aug_img = augment_pipeline(image=img)["image"]
                aug_resized = cv2.resize(aug_img, (224, 224))
                h1 = phash(aug_resized) + "_" + dhash(aug_resized)

                if is_valid(aug_resized) and h1 not in saved_hashes:
                    out_aug = os.path.join(out_dir, f"{base}_aug{count}.jpg")
                    cv2.imwrite(out_aug, aug_resized)
                    saved_paths.append(out_aug)
                    saved_hashes.add(h1)
                    count += 1
                    pbar.update(1)
                attempts += 1

    print(f"Saved {len(saved_paths)} images for class '{cls_name}'")
    return saved_paths

# ---------------- RUN AUGMENTATION ----------------
all_augmented = {}
for cls in CLASSES:
    all_augmented[cls] = augment_class(cls)

# ---------------- SPLIT DATASET ----------------
def split_dataset():
    print("\nSplitting dataset into train/valid/test ...")
    for cls, imgs in all_augmented.items():
        random.shuffle(imgs)
        total = len(imgs)
        train_end = int(total * TRAIN_RATIO)
        valid_end = train_end + int(total * VALID_RATIO)

        for i, src in tqdm(list(enumerate(imgs)), desc=f"Splitting {cls}", colour="yellow"):
            if i < train_end:
                fold = "train"
            elif i < valid_end:
                fold = "valid"
            else:
                fold = "test"

            dst_dir = os.path.join(OUTPUT_ROOT, fold, cls)
            os.makedirs(dst_dir, exist_ok=True)
            shutil.copy(src, dst_dir)

    print("\nDataset split complete! ✅")

split_dataset()
