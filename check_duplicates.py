# # import os
# # import cv2
# # import numpy as np
# # from skimage.metrics import structural_similarity as ssim
# # from PIL import Image
# # import hashlib

# # # ------------------------------
# # # Dataset Paths
# # # ------------------------------
# # dataset_paths = [
# #     r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# # ]

# # # ------------------------------
# # # Parameters
# # # ------------------------------
# # resize_dim = (256, 256)            # For fuzzy similarity
# # similarity_threshold = 0.95        # 95% similarity considered duplicate
# # hash_exact = True                  # True: exact duplicates, False: skip exact hash

# # # ------------------------------
# # # Helper functions
# # # ------------------------------
# # def load_image_gray(path, resize=True):
# #     """Load image as grayscale and optionally resize"""
# #     img = cv2.imread(path)
# #     if img is None:
# #         return None
# #     img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# #     if resize:
# #         img = cv2.resize(img, resize_dim)
# #     return img

# # def image_hash(img_path):
# #     """Compute hash for exact duplicate detection"""
# #     try:
# #         with Image.open(img_path).convert("RGB") as img:
# #             return hashlib.md5(img.tobytes()).hexdigest()
# #     except:
# #         return None

# # # ------------------------------
# # # Duplicate detection
# # # ------------------------------
# # report_file = "duplicate_report.txt"
# # with open(report_file, "w", encoding="utf-8") as report:
# #     report.write("Duplicate & Similar Images Report\n")
# #     report.write("================================\n\n")

# #     for dataset_path in dataset_paths:
# #         report.write(f"Scanning dataset: {dataset_path}\n")
# #         print(f"\nScanning dataset: {dataset_path}")

# #         # --------------------------
# #         # Exact duplicates
# #         # --------------------------
# #         if hash_exact:
# #             print("🔹 Checking exact duplicates...")
# #             report.write("Exact Duplicates:\n")
# #             hashes = {}
# #             duplicates_exact = []

# #             for root, _, files in os.walk(dataset_path):
# #                 for file in files:
# #                     if file.lower().endswith((".jpg", ".jpeg", ".png")):
# #                         path = os.path.join(root, file)
# #                         h = image_hash(path)
# #                         if h:
# #                             if h in hashes:
# #                                 duplicates_exact.append((path, hashes[h]))
# #                             else:
# #                                 hashes[h] = path

# #             if duplicates_exact:
# #                 for dup, orig in duplicates_exact:
# #                     report.write(f"Exact Duplicate: {dup} -> Original: {orig}\n")
# #                     print(f"Exact Duplicate: {dup} -> Original: {orig}")
# #             else:
# #                 report.write("No exact duplicates found.\n")
# #                 print("No exact duplicates found.")

# #         # --------------------------
# #         # Fuzzy duplicates
# #         # --------------------------
# #         print("🔹 Checking fuzzy duplicates...")
# #         report.write("\nFuzzy Similar Images:\n")
# #         images = []
# #         paths = []

# #         for root, _, files in os.walk(dataset_path):
# #             for file in files:
# #                 if file.lower().endswith((".jpg", ".jpeg", ".png")):
# #                     path = os.path.join(root, file)
# #                     img = load_image_gray(path)
# #                     if img is not None:
# #                         images.append(img)
# #                         paths.append(path)

# #         duplicates_fuzzy = []
# #         n = len(images)
# #         for i in range(n):
# #             for j in range(i + 1, n):
# #                 score = ssim(images[i], images[j])
# #                 if score >= similarity_threshold:
# #                     duplicates_fuzzy.append((paths[i], paths[j], score))

# #         if duplicates_fuzzy:
# #             for img1, img2, score in duplicates_fuzzy:
# #                 report.write(f"Fuzzy Duplicate: {img1} ~~~ {img2} | SSIM={score:.3f}\n")
# #                 print(f"Fuzzy Duplicate: {img1} ~~~ {img2} | SSIM={score:.3f}")
# #         else:
# #             report.write("No fuzzy duplicates found.\n")
# #             print("No fuzzy duplicates found.")

# # print(f"\n✅ Duplicate checking complete. Report saved as '{report_file}'")




# #-----------------------------------------------------

# import os
# import cv2
# import numpy as np
# from skimage.metrics import structural_similarity as ssim
# from PIL import Image
# import hashlib

# # ------------------------------
# # Paths
# # ------------------------------
# dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
# train_path = os.path.join(dataset_root, "train")
# valid_path = os.path.join(dataset_root, "valid")
# test_path = os.path.join(dataset_root, "test")

# # ------------------------------
# # Parameters
# # ------------------------------
# resize_dim = (256, 256)         # For fuzzy similarity
# similarity_threshold = 0.95     # 95% similarity considered fuzzy duplicate

# # ------------------------------
# # Helper Functions
# # ------------------------------
# def image_hash(img_path):
#     """Compute hash for exact duplicate detection"""
#     try:
#         with Image.open(img_path).convert("RGB") as img:
#             return hashlib.md5(img.tobytes()).hexdigest()
#     except:
#         return None

# def load_image_gray(path, resize=True):
#     """Load image as grayscale for fuzzy duplicate detection"""
#     img = cv2.imread(path)
#     if img is None:
#         return None
#     img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     if resize:
#         img = cv2.resize(img, resize_dim)
#     return img

# def get_all_images(folder_path):
#     """Recursively collect image paths"""
#     images = []
#     for root, _, files in os.walk(folder_path):
#         for file in files:
#             if file.lower().endswith((".jpg", ".jpeg", ".png")):
#                 images.append(os.path.join(root, file))
#     return images

# # ------------------------------
# # REPORT FILE
# # ------------------------------
# report_file = "duplicates_full_report.txt"
# with open(report_file, "w", encoding="utf-8") as report:

#     report.write("Duplicate Checking Report\n")
#     report.write("========================\n\n")

#     # --------------------------
#     # 1️⃣ Check Train internally (exact + fuzzy)
#     # --------------------------
#     report.write("🔹 Checking TRAIN folder internally\n")
#     print("\n🔹 Checking TRAIN folder internally")

#     train_images = get_all_images(train_path)

#     # Exact duplicates
#     report.write("\nExact duplicates in TRAIN:\n")
#     hashes = {}
#     duplicates_exact = []
#     for path in train_images:
#         h = image_hash(path)
#         if h:
#             if h in hashes:
#                 duplicates_exact.append((path, hashes[h]))
#             else:
#                 hashes[h] = path
#     if duplicates_exact:
#         for dup, orig in duplicates_exact:
#             report.write(f"Exact Duplicate: {dup} -> Original: {orig}\n")
#             print(f"Exact Duplicate: {dup} -> Original: {orig}")
#     else:
#         report.write("No exact duplicates in TRAIN.\n")
#         print("No exact duplicates in TRAIN.")

#     # Fuzzy duplicates
#     report.write("\nFuzzy duplicates in TRAIN:\n")
#     images_gray = [load_image_gray(p) for p in train_images]
#     duplicates_fuzzy = []
#     n = len(images_gray)
#     for i in range(n):
#         for j in range(i + 1, n):
#             score = ssim(images_gray[i], images_gray[j])
#             if score >= similarity_threshold:
#                 duplicates_fuzzy.append((train_images[i], train_images[j], score))
#     if duplicates_fuzzy:
#         for img1, img2, score in duplicates_fuzzy:
#             report.write(f"Fuzzy Duplicate: {img1} ~~~ {img2} | SSIM={score:.3f}\n")
#             print(f"Fuzzy Duplicate: {img1} ~~~ {img2} | SSIM={score:.3f}")
#     else:
#         report.write("No fuzzy duplicates in TRAIN.\n")
#         print("No fuzzy duplicates in TRAIN.")

#     # --------------------------
#     # 2️⃣ Check VALID vs TRAIN (exact only)
#     # --------------------------
#     report.write("\n🔹 Checking VALID folder against TRAIN (exact duplicates only)\n")
#     print("\n🔹 Checking VALID folder against TRAIN")

#     valid_images = get_all_images(valid_path)
#     train_hashes = {image_hash(p): p for p in train_images}
#     duplicates_valid_train = []
#     for path in valid_images:
#         h = image_hash(path)
#         if h and h in train_hashes:
#             duplicates_valid_train.append((path, train_hashes[h]))
#     if duplicates_valid_train:
#         for dup, orig in duplicates_valid_train:
#             report.write(f"VALID duplicate of TRAIN: {dup} -> Original: {orig}\n")
#             print(f"VALID duplicate of TRAIN: {dup} -> Original: {orig}")
#     else:
#         report.write("No exact duplicates between VALID and TRAIN.\n")
#         print("No exact duplicates between VALID and TRAIN.")

#     # --------------------------
#     # 3️⃣ Check TEST vs TRAIN (exact only)
#     # --------------------------
#     report.write("\n🔹 Checking TEST folder against TRAIN (exact duplicates only)\n")
#     print("\n🔹 Checking TEST folder against TRAIN")

#     test_images = get_all_images(test_path)
#     duplicates_test_train = []
#     for path in test_images:
#         h = image_hash(path)
#         if h and h in train_hashes:
#             duplicates_test_train.append((path, train_hashes[h]))
#     if duplicates_test_train:
#         for dup, orig in duplicates_test_train:
#             report.write(f"TEST duplicate of TRAIN: {dup} -> Original: {orig}\n")
#             print(f"TEST duplicate of TRAIN: {dup} -> Original: {orig}")
#     else:
#         report.write("No exact duplicates between TEST and TRAIN.\n")
#         print("No exact duplicates between TEST and TRAIN.")

# print(f"\n✅ Duplicate checking complete! Report saved as '{report_file}'")


#----------------------------------------------------------------
import os
from PIL import Image
import imagehash

# ------------------------------
# Paths
# ------------------------------
dataset_root = r"C:\Users\HP\Desktop\dataset DT1\dataset_final"
train_path = os.path.join(dataset_root, "train")
valid_path = os.path.join(dataset_root, "valid")
test_path = os.path.join(dataset_root, "test")

# ------------------------------
# Parameters
# ------------------------------
hash_size = 16           # pHash size, higher = more precision
similarity_threshold = 5 # Hamming distance threshold for "fuzzy" duplicates

# ------------------------------
# Helper Functions
# ------------------------------
def get_all_images(folder_path):
    images = []
    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.lower().endswith((".jpg", ".jpeg", ".png")):
                images.append(os.path.join(root, file))
    return images

def compute_phash(img_path):
    try:
        img = Image.open(img_path).convert("RGB")
        return imagehash.phash(img, hash_size=hash_size)
    except:
        return None

# ------------------------------
# REPORT FILE
# ------------------------------
report_file = "duplicates_fast_report.txt"
with open(report_file, "w", encoding="utf-8") as report:

    report.write("Optimized Duplicate Checking Report\n")
    report.write("==================================\n\n")

    # --------------------------
    # 1️⃣ Train folder internal check (exact + fuzzy)
    # --------------------------
    print("\n🔹 Checking TRAIN folder internally")
    report.write("🔹 TRAIN folder internal check\n")

    train_images = get_all_images(train_path)
    hashes_exact = {}
    hashes_phash = {}

    duplicates_exact = []
    duplicates_fuzzy = []

    for path in train_images:
        # Exact hash
        h_md5 = compute_phash(path)  # Using pHash as main comparison
        if h_md5 is None:
            continue

        # Check exact duplicates
        if h_md5 in hashes_phash:
            duplicates_exact.append((path, hashes_phash[h_md5]))
        else:
            hashes_phash[h_md5] = path

    # Now check fuzzy duplicates using Hamming distance
    paths_list = list(hashes_phash.values())
    phashes_list = [compute_phash(p) for p in paths_list]
    n = len(paths_list)

    for i in range(n):
        for j in range(i + 1, n):
            if phashes_list[i] - phashes_list[j] <= similarity_threshold:
                duplicates_fuzzy.append((paths_list[i], paths_list[j], phashes_list[i]-phashes_list[j]))

    # Report
    if duplicates_exact:
        report.write("\nExact duplicates in TRAIN:\n")
        for dup, orig in duplicates_exact:
            report.write(f"{dup} -> Original: {orig}\n")
            print(f"Exact Duplicate: {dup} -> Original: {orig}")
    else:
        report.write("No exact duplicates in TRAIN.\n")
        print("No exact duplicates in TRAIN.")

    if duplicates_fuzzy:
        report.write("\nFuzzy duplicates in TRAIN (phash):\n")
        for img1, img2, dist in duplicates_fuzzy:
            report.write(f"{img1} ~~~ {img2} | Hamming Distance={dist}\n")
            print(f"Fuzzy Duplicate: {img1} ~~~ {img2} | Hamming Distance={dist}")
    else:
        report.write("No fuzzy duplicates in TRAIN.\n")
        print("No fuzzy duplicates in TRAIN.")

    # --------------------------
    # 2️⃣ Valid vs Train exact duplicates
    # --------------------------
    print("\n🔹 Checking VALID folder against TRAIN")
    report.write("\n🔹 VALID vs TRAIN exact duplicates\n")
    valid_images = get_all_images(valid_path)
    for path in valid_images:
        h = compute_phash(path)
        if h and h in hashes_phash:
            report.write(f"VALID duplicate of TRAIN: {path} -> Original: {hashes_phash[h]}\n")
            print(f"VALID duplicate of TRAIN: {path} -> Original: {hashes_phash[h]}")

    # --------------------------
    # 3️⃣ Test vs Train exact duplicates
    # --------------------------
    print("\n🔹 Checking TEST folder against TRAIN")
    report.write("\n🔹 TEST vs TRAIN exact duplicates\n")
    test_images = get_all_images(test_path)
    for path in test_images:
        h = compute_phash(path)
        if h and h in hashes_phash:
            report.write(f"TEST duplicate of TRAIN: {path} -> Original: {hashes_phash[h]}\n")
            print(f"TEST duplicate of TRAIN: {path} -> Original: {hashes_phash[h]}")

print(f"\n✅ Duplicate checking complete! Report saved as '{report_file}'")
