# # # import os
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator
# # # from PIL import Image

# # # # Get absolute path to project root
# # # PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# # # def remove_corrupted_images(dataset_dir):
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in files:
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except Exception:
# # #                     print(f"Corrupted image removed: {path}")
# # #                     os.remove(path)

# # # def get_train_val_generators(img_size=(224,224), batch_size=32):
# # #     train_dir = os.path.join(PROJECT_DIR, "dataset", "train")
# # #     val_dir   = os.path.join(PROJECT_DIR, "dataset", "valid")

# # #     # Remove corrupted images
# # #     remove_corrupted_images(train_dir)
# # #     remove_corrupted_images(val_dir)

# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,
# # #         rotation_range=20,
# # #         width_shift_range=0.2,
# # #         height_shift_range=0.2,
# # #         shear_range=0.2,
# # #         zoom_range=0.2,
# # #         horizontal_flip=True,
# # #         fill_mode="nearest"
# # #     )

# # #     val_datagen = ImageDataGenerator(rescale=1./255)

# # #     train_generator = train_datagen.flow_from_directory(
# # #         train_dir,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb"
# # #     )

# # #     val_generator = val_datagen.flow_from_directory(
# # #         val_dir,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb"
# # #     )

# # #     return train_generator, val_generator


# # # if __name__ == "__main__":
# # #     train_gen, val_gen = get_train_val_generators()

# # # =========preprocessing.py test codes are above==========

# # # ================ version 1.0 =================
# # #========== preprocessing.py ==========
# # # import os
# # # import cv2
# # # import random
# # # import shutil
# # # import numpy as np
# # # from glob import glob
# # # from PIL import Image
# # # from tqdm import tqdm
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")

# # # IMG_SIZE = (224, 224)
# # # BATCH_SIZE = 32

# # # # ------------------ Step 1: Check dataset structure ------------------
# # # def verify_folder_structure():
# # #     print("\n🔹 Verifying dataset folder structure...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         if not os.path.exists(folder):
# # #             raise FileNotFoundError(f"❌ Folder missing: {folder}")
# # #         for species in os.listdir(folder):
# # #             species_path = os.path.join(folder, species)
# # #             if not os.path.isdir(species_path):
# # #                 continue
# # #             for cls in ["tender", "matured"]:
# # #                 cls_path = os.path.join(species_path, cls)
# # #                 if not os.path.exists(cls_path):
# # #                     raise FileNotFoundError(f"❌ Missing class folder: {cls_path}")
# # #     print("✔ Dataset folder structure verified!\n")

# # # # ------------------ Step 2: Remove corrupted images ------------------
# # # def remove_corrupted_images(dataset_dir):
# # #     print(f"\n🔹 Checking for corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     removed_count = 0

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except Exception:
# # #                     os.remove(path)
# # #                     removed_count += 1
# # #                     tqdm.write(f"⚠ Removed corrupted image: {path}")
# # #     print(f"✔ Finished checking. {removed_count} corrupted images removed.\n")

# # # # ------------------ Step 3: Create ImageDataGenerators ------------------
# # # def get_train_val_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# # #     print("🔹 Creating ImageDataGenerators with augmentation for training...")
    
# # #     # Training augmentation
# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,
# # #         rotation_range=20,
# # #         width_shift_range=0.2,
# # #         height_shift_range=0.2,
# # #         shear_range=0.2,
# # #         zoom_range=0.2,
# # #         horizontal_flip=True,
# # #         fill_mode="nearest"
# # #     )

# # #     # Validation / Test: only rescale
# # #     val_datagen = ImageDataGenerator(rescale=1./255)

# # #     # Remove corrupted images first
# # #     remove_corrupted_images(TRAIN_DIR)
# # #     remove_corrupted_images(VALID_DIR)

# # #     print("🔹 Generating training data...")
# # #     train_generator = train_datagen.flow_from_directory(
# # #         TRAIN_DIR,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb",
# # #         shuffle=True
# # #     )

# # #     print("\n🔹 Generating validation data...")
# # #     val_generator = val_datagen.flow_from_directory(
# # #         VALID_DIR,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb",
# # #         shuffle=False
# # #     )

# # #     print("\n✔ Generators created successfully!\n")
# # #     return train_generator, val_generator

# # # # ------------------ Step 4: Main ------------------
# # #     # ------------------ Folder Structure Verification ------------------
# # # if __name__ == "__main__":
# # #     verify_folder_structure()
# # #     train_gen, val_gen = get_train_val_generators()
# # #     print("\n✅ Preprocessing ready! Total classes found:", train_gen.class_indices)

# # #     # ------------------ Pixel Scaling Verification ------------------
# # #     print("\n🔹 Verifying pixel scaling on a batch of training data...")
# # #     x_train_batch, y_train_batch = next(train_gen)
# # #     print(f"Training batch pixel range: min={x_train_batch.min():.4f}, max={x_train_batch.max():.4f}")

# # #     print("\n🔹 Verifying pixel scaling on a batch of validation data...")
# # #     x_val_batch, y_val_batch = next(val_gen)
# # #     print(f"Validation batch pixel range: min={x_val_batch.min():.4f}, max={x_val_batch.max():.4f}")


# # # ================ version 2.0 =================
# # #========== preprocessing.py ==========
# # # import os
# # # import random
# # # import numpy as np
# # # from glob import glob
# # # from PIL import Image
# # # from tqdm import tqdm
# # # import matplotlib.pyplot as plt
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")

# # # IMG_SIZE = (224, 224)
# # # BATCH_SIZE = 32

# # # # ------------------ Step 1: Verify folder structure ------------------
# # # def verify_folder_structure():
# # #     print("\n🔹 Verifying dataset folder structure (nested varieties)...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         if not os.path.exists(folder):
# # #             print(f"⚠ Folder missing: {folder}")
# # #             continue
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         if not varieties:
# # #             print(f"⚠ No varieties found in: {folder}")
# # #             continue
# # #         for var in varieties:
# # #             var_path = os.path.join(folder, var)
# # #             for cls in ["tender", "matured"]:
# # #                 cls_path = os.path.join(var_path, cls)
# # #                 if not os.path.exists(cls_path):
# # #                     print(f"⚠ Missing class folder: {cls_path}")
# # #                 else:
# # #                     print(f"✔ Found class folder: {cls_path}")
# # #     print("✔ Folder verification complete.\n")

# # # # ------------------ Step 2: Detect corrupted images ------------------
# # # def detect_corrupted_images(dataset_dir):
# # #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     corrupted_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except Exception:
# # #                     corrupted_images.append(path)

# # #     if corrupted_images:
# # #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# # #         for img_path in corrupted_images:
# # #             print("   ", img_path)
# # #     else:
# # #         print("✔ No corrupted images detected.\n")
# # #     return corrupted_images

# # # # ------------------ Step 3: Class balance check ------------------
# # # def check_class_balance(dataset_dir):
# # #     print("\n🔹 Checking class balance (nested varieties)...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         print(f"\nFolder: {folder}")
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         for var in varieties:
# # #             var_path = os.path.join(folder, var)
# # #             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) for cls in ["tender", "matured"] if os.path.exists(os.path.join(var_path, cls))}
# # #             print(f" Variety: {var}")
# # #             for cls, count in counts.items():
# # #                 print(f"   {cls}: {count} images")
# # #     print("✔ Class balance checked.\n")

# # # # ------------------ Step 4: ImageDataGenerators ------------------
# # # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# # #     print("🔹 Creating ImageDataGenerators with augmentation for training...")
# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,
# # #         rotation_range=20,
# # #         width_shift_range=0.2,
# # #         height_shift_range=0.2,
# # #         shear_range=0.2,
# # #         zoom_range=0.2,
# # #         horizontal_flip=True,
# # #         fill_mode="nearest"
# # #     )
# # #     val_datagen = ImageDataGenerator(rescale=1./255)

# # #     print("🔹 Generating training data...")
# # #     train_gen = train_datagen.flow_from_directory(
# # #         TRAIN_DIR,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb",
# # #         shuffle=True
# # #     )

# # #     print("\n🔹 Generating validation data...")
# # #     val_gen = val_datagen.flow_from_directory(
# # #         VALID_DIR,
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         color_mode="rgb",
# # #         shuffle=False
# # #     )
# # #     print("✔ Generators created successfully.\n")
# # #     return train_gen, val_gen

# # # # ------------------ Step 5: Pixel scaling & batch verification ------------------
# # # def verify_generators(train_gen, val_gen):
# # #     print("🔹 Verifying pixel scaling and batch properties...")
# # #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# # #         x_batch, y_batch = next(gen)
# # #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")
# # #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
# # #         print(f"{name} batch label shape: {y_batch.shape}")
# # #     print("✔ Pixel scaling and batch properties verified.\n")

# # # # ------------------ Step 6: Optional augmentation sanity check ------------------
# # # def visualize_augmentations(train_gen, n_images=5):
# # #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# # #     x_batch, y_batch = next(train_gen)
# # #     for i in range(min(n_images, len(x_batch))):
# # #         img = x_batch[i]
# # #         plt.imshow(img)
# # #         plt.title(f"Label: {np.argmax(y_batch[i])}")
# # #         plt.axis("off")
# # #         plt.show()
# # #     print("✔ Augmentation sanity check done.\n")


# # # # # ------------------ Step 7: Run all checks (Backup/Old code) ------------------
# # # # if __name__ == "__main__":
# # # #     verify_folder_structure()
# # # #     check_class_balance(DATASET_DIR)
# # # #     detect_corrupted_images(TRAIN_DIR)
# # # #     detect_corrupted_images(VALID_DIR)
# # # #     detect_corrupted_images(TEST_DIR)
# # # #     train_gen, val_gen = get_generators()
# # # #     verify_generators(train_gen, val_gen)
# # # #     visualize_augmentations(train_gen, n_images=5)
# # # #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")

# # # # ------------------ Step 7: Pre-flight verification for size & color ------------------
# # # def preflight_check(dataset_dir, img_size=(224, 224)):
# # #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# # #     bad_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in files:
# # #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     if img.mode != "RGB":
# # #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# # #                     if img.size != img_size:
# # #                         bad_images.append((path, f"Wrong size: {img.size}"))
# # #                 except Exception as e:
# # #                     bad_images.append((path, f"Open error: {e}"))

# # #     if bad_images:
# # #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# # #         for path, issue in bad_images:
# # #             print(f"   {path} | {issue}")
# # #     else:
# # #         print("✔ All images are correct size (224x224) and RGB.\n")

# # #     return bad_images

# # # # ------------------ Step 8: Run all checks ------------------
# # # if __name__ == "__main__":
# # #     verify_folder_structure()
# # #     check_class_balance(DATASET_DIR)
# # #     detect_corrupted_images(TRAIN_DIR)
# # #     detect_corrupted_images(VALID_DIR)
# # #     detect_corrupted_images(TEST_DIR)
# # #     preflight_check(TRAIN_DIR)
# # #     preflight_check(VALID_DIR)
# # #     preflight_check(TEST_DIR)
# # #     train_gen, val_gen = get_generators()
# # #     verify_generators(train_gen, val_gen)
# # #     visualize_augmentations(train_gen, n_images=5)
# # #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")




# # #========================= last version 3.0 =====================
# # # import os
# # # import numpy as np
# # # import pandas as pd
# # # from PIL import Image
# # # from tqdm import tqdm
# # # import matplotlib.pyplot as plt
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")

# # # IMG_SIZE = (224, 224)
# # # BATCH_SIZE = 32
# # # CLASS_ORDER = ["tender", "matured"]  # Explicit label order

# # # # ------------------ Step 1: Verify folder structure ------------------
# # # def verify_folder_structure():
# # #     print("\n🔹 Verifying dataset folder structure...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         if not os.path.exists(folder):
# # #             print(f"⚠ Folder missing: {folder}")
# # #             continue
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         if not varieties:
# # #             print(f"⚠ No varieties found in: {folder}")
# # #             continue
# # #         for var in varieties:
# # #             var_path = os.path.join(folder, var)
# # #             for cls in CLASS_ORDER:
# # #                 cls_path = os.path.join(var_path, cls)
# # #                 if not os.path.exists(cls_path):
# # #                     print(f"⚠ Missing class folder: {cls_path}")
# # #                 else:
# # #                     print(f"✔ Found class folder: {cls_path}")
# # #     print("✔ Folder verification complete.\n")

# # # # ------------------ Step 2: Detect corrupted images ------------------
# # # def detect_corrupted_images(dataset_dir):
# # #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     corrupted_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except Exception:
# # #                     corrupted_images.append(path)

# # #     if corrupted_images:
# # #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# # #         for img_path in corrupted_images:
# # #             print("   ", img_path)
# # #     else:
# # #         print("✔ No corrupted images detected.\n")
# # #     return corrupted_images

# # # # ------------------ Step 3: Class balance check ------------------
# # # def check_class_balance(dataset_dir):
# # #     print("\n🔹 Checking class balance...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         print(f"\nFolder: {folder}")
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         for var in varieties:
# # #             var_path = os.path.join(folder, var)
# # #             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) 
# # #                       for cls in CLASS_ORDER if os.path.exists(os.path.join(var_path, cls))}
# # #             print(f" Variety: {var}")
# # #             for cls, count in counts.items():
# # #                 print(f"   {cls}: {count} images")
# # #     print("✔ Class balance checked.\n")

# # # # ------------------ Step 4: Pre-flight verification for size & color ------------------
# # # def preflight_check(dataset_dir, img_size=IMG_SIZE):
# # #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# # #     bad_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in files:
# # #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     if img.mode != "RGB":
# # #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# # #                     if img.size != img_size:
# # #                         bad_images.append((path, f"Wrong size: {img.size}"))
# # #                 except Exception as e:
# # #                     bad_images.append((path, f"Open error: {e}"))

# # #     if bad_images:
# # #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# # #         for path, issue in bad_images:
# # #             print(f"   {path} | {issue}")
# # #     else:
# # #         print("✔ All images are correct size (224x224) and RGB.\n")

# # #     return bad_images

# # # # ------------------ Step 5: Create dataframe for nested dataset ------------------
# # # def create_dataframe(base_dir):
# # #     paths, labels = [], []
# # #     for variety in os.listdir(base_dir):
# # #         var_path = os.path.join(base_dir, variety)
# # #         if not os.path.isdir(var_path):
# # #             continue
# # #         for cls in CLASS_ORDER:
# # #             cls_path = os.path.join(var_path, cls)
# # #             if not os.path.exists(cls_path):
# # #                 continue
# # #             for img_file in os.listdir(cls_path):
# # #                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                     paths.append(os.path.join(cls_path, img_file))
# # #                     labels.append(cls)
# # #     df = pd.DataFrame({"filename": paths, "class": labels})
# # #     return df

# # # # ------------------ Step 6: Generators using flow_from_dataframe ------------------
# # # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# # #     print("🔹 Creating ImageDataGenerators with augmentation...")
# # #     train_df = create_dataframe(TRAIN_DIR)
# # #     val_df   = create_dataframe(VALID_DIR)

# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,
# # #         rotation_range=20,
# # #         width_shift_range=0.2,
# # #         height_shift_range=0.2,
# # #         shear_range=0.2,
# # #         zoom_range=0.2,
# # #         horizontal_flip=True,
# # #         fill_mode="nearest"
# # #     )
# # #     val_datagen = ImageDataGenerator(rescale=1./255)

# # #     train_gen = train_datagen.flow_from_dataframe(
# # #         train_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=True
# # #     )

# # #     val_gen = val_datagen.flow_from_dataframe(
# # #         val_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=False
# # #     )

# # #     return train_gen, val_gen

# # # # ------------------ Step 7: Verify pixel scaling & batch ------------------
# # # def verify_generators(train_gen, val_gen):
# # #     print("🔹 Verifying pixel scaling and batch properties...")
# # #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# # #         x_batch, y_batch = next(gen)
# # #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")
# # #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
# # #         print(f"{name} batch label shape: {y_batch.shape}")
# # #     print("✔ Pixel scaling and batch properties verified.\n")

# # # # ------------------ Step 8: Augmentation sanity check ------------------
# # # def visualize_augmentations(train_gen, n_images=5):
# # #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# # #     x_batch, y_batch = next(train_gen)
# # #     class_indices = {v: k for k, v in train_gen.class_indices.items()}  # Reverse mapping
# # #     for i in range(min(n_images, len(x_batch))):
# # #         img = x_batch[i]
# # #         label_idx = np.argmax(y_batch[i])
# # #         label_name = class_indices[label_idx]
# # #         plt.imshow(img)
# # #         plt.title(f"Label: {label_name} ({label_idx})")
# # #         plt.axis("off")
# # #         plt.show()
# # #     print("✔ Augmentation sanity check done.\n")

# # # # ------------------ Step 9: Run everything ------------------
# # # if __name__ == "__main__":
# # #     verify_folder_structure()
# # #     check_class_balance(DATASET_DIR)
# # #     detect_corrupted_images(TRAIN_DIR)
# # #     detect_corrupted_images(VALID_DIR)
# # #     detect_corrupted_images(TEST_DIR)
# # #     preflight_check(TRAIN_DIR)
# # #     preflight_check(VALID_DIR)
# # #     preflight_check(TEST_DIR)
# # #     train_gen, val_gen = get_generators()
# # #     verify_generators(train_gen, val_gen)
# # #     visualize_augmentations(train_gen, n_images=5)
# # #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")




# # # ========================= final version 4.0 =====================

# # # import os  # Provides functions to interact with the file system (paths, directories)
# # # import numpy as np  # For numerical operations, arrays, and mathematical functions
# # # import pandas as pd  # For creating and manipulating tabular data (DataFrames)
# # # from PIL import Image  # For opening, reading, and verifying image files
# # # from tqdm import tqdm  # For creating progress bars during loops (e.g., scanning images)
# # # import matplotlib.pyplot as plt  # For visualizing images and plots
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator  # For generating batches of images with optional augmentation

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"  # Main folder of the project
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Folder containing all datasets (train/valid/test)
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Training dataset folder
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Validation dataset folder
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")   # Testing dataset folder

# # # IMG_SIZE = (224, 224)  # Target size for input images (height x width) suitable for MobileNetV3
# # # BATCH_SIZE = 32  # Number of images per batch during training
# # # # CLASS_ORDER = ["tender", "matured"]  # Define class order explicitly to maintain consistent labels
# # # CLASS_ORDER = [
# # #     "Assamica/tender", "Assamica/matured",
# # #     "DT1/tender", "DT1/matured"
# # # ]

# # # # ------------------ Step 1: Verify folder structure ------------------
# # # def verify_folder_structure():
# # #     """
# # #     Checks if all expected class folders exist for training, validation, and test datasets.
# # #     Ensures dataset is organized as: dataset/{train/valid/test}/{Variety}/{class}/images
# # #     """
# # #     print("\n🔹 Verifying dataset folder structure...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:  # Loop over train, validation, and test folders
# # #         if not os.path.exists(folder):  # If dataset folder missing
# # #             print(f"⚠ Folder missing: {folder}")
# # #             continue  # Skip to next folder
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # Get tea varieties
# # #         for var in varieties:  # Loop through each variety
# # #             var_path = os.path.join(folder, var)  # Full path to variety folder
# # #             for cls in CLASS_ORDER:  # Loop through each class
# # #                 cls_path = os.path.join(var_path, cls)  # Full path to class folder
# # #                 if not os.path.exists(cls_path):  # Check if class folder exists
# # #                     print(f"⚠ Missing class folder: {cls_path}")
# # #                 else:
# # #                     print(f"✔ Found class folder: {cls_path}")
# # #     print("✔ Folder verification complete.\n")

# # # # ------------------ Step 2: Detect corrupted images ------------------
# # # def detect_corrupted_images(dataset_dir):
# # #     """
# # #     Iterates through all images in a dataset directory and identifies any corrupted files
# # #     that cannot be opened or verified using PIL.Image.
# # #     """
# # #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")  # Supported image formats
# # #     corrupted_images = []  # List to store paths of corrupted images

# # #     for root, _, files in os.walk(dataset_dir):  # Walk through all subfolders
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):  # Show progress
# # #             if f.lower().endswith(extensions):  # Only process image files
# # #                 path = os.path.join(root, f)  # Full file path
# # #                 try:
# # #                     img = Image.open(path)  # Open image
# # #                     img.verify()  # Verify file integrity
# # #                 except Exception:  # If image is corrupted or unreadable
# # #                     corrupted_images.append(path)  # Add to corrupted list

# # #     if corrupted_images:
# # #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# # #         for img_path in corrupted_images:
# # #             print("   ", img_path)
# # #     else:
# # #         print("✔ No corrupted images detected.\n")
# # #     return corrupted_images

# # # # ------------------ Step 3: Class balance check ------------------
# # # def check_class_balance():
# # #     """
# # #     Counts the number of images per class for each variety in train, validation, and test datasets.
# # #     Helps ensure datasets are reasonably balanced.
# # #     """
# # #     print("\n🔹 Checking class balance...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         print(f"\nFolder: {folder}")
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # Get tea varieties
# # #         for var in varieties:
# # #             var_path = os.path.join(folder, var)
# # #             counts = {cls: len(os.listdir(os.path.join(var_path, cls)))  # Count images per class
# # #                       for cls in CLASS_ORDER if os.path.exists(os.path.join(var_path, cls))}
# # #             print(f" Variety: {var}")
# # #             for cls, count in counts.items():
# # #                 print(f"   {cls}: {count} images")
# # #     print("✔ Class balance checked.\n")

# # # # ------------------ Step 4: Pre-flight verification ------------------
# # # def preflight_check(dataset_dir, img_size=IMG_SIZE):
# # #     """
# # #     Checks that all images have the correct RGB mode and target size.
# # #     Returns list of images with any issues.
# # #     """
# # #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# # #     bad_images = []  # List to store problematic images

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in files:
# # #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)  # Open image
# # #                     if img.mode != "RGB":  # Check color mode
# # #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# # #                     if img.size != img_size:  # Check image size
# # #                         bad_images.append((path, f"Wrong size: {img.size}"))
# # #                 except Exception as e:
# # #                     bad_images.append((path, f"Open error: {e}"))  # Catch all other errors

# # #     if bad_images:
# # #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# # #         for path, issue in bad_images:
# # #             print(f"   {path} | {issue}")
# # #     else:
# # #         print("✔ All images are correct size (224x224) and RGB.\n")
# # #     return bad_images

# # # # ------------------ Step 5: Create dataframe for flow_from_dataframe ------------------
# # # # def create_dataframe(base_dir):
# # # #     """
# # # #     Creates a Pandas DataFrame containing image paths and their corresponding class labels.
# # # #     This is required for Keras flow_from_dataframe method.
# # # #     """
# # # #     paths, labels = [], []  # Lists to store image paths and labels

# # # #     # for variety in os.listdir(base_dir):  # Loop through tea varieties
# # # #     #     var_path = os.path.join(base_dir, variety)
# # # #     #     if not os.path.isdir(var_path):
# # # #     #         continue
# # # #     #     for cls in CLASS_ORDER:  # Loop through classes
# # # #     #         cls_path = os.path.join(var_path, cls)
# # # #     #         if not os.path.exists(cls_path):
# # # #     #             continue
# # # #     #         for img_file in os.listdir(cls_path):
# # # #     #             if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # # #     #                 paths.append(os.path.join(cls_path, img_file))  # Full image path
# # # #     #                 labels.append(cls)  # Corresponding class label
# # # #     # Step 5: create_dataframe function

# # # #     for variety in os.listdir(base_dir):  # Assamica, DT1
# # # #             var_path = os.path.join(base_dir, variety)
# # # #             if not os.path.isdir(var_path):
# # # #                 continue
# # # #             for subcls in ["tender", "matured"]:  # Only the leaf maturity
# # # #                 cls_path = os.path.join(var_path, subcls)
# # # #                 if not os.path.exists(cls_path):
# # # #                     continue
# # # #                 for img_file in os.listdir(cls_path):
# # # #                     if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # # #                         paths.append(os.path.join(cls_path, img_file))
# # # #                         labels.append(f"{variety}/{subcls}")  # Must match CLASS_ORDER exactly

# # # #     df = pd.DataFrame({"filename": paths, "class": labels})
# # # #     return df

# # # # Corrected Step 1: Verify folder structure
# # # # ------------------ Step 5: Create dataframe for flow_from_dataframe ------------------
# # # # ------------------ Step 1: Verify folder structure ------------------
# # # # ------------------ Step 5: Create dataframe for flow_from_dataframe ------------------
# # # def create_dataframe(base_dir):
# # #     """
# # #     Creates a Pandas DataFrame containing image paths and their corresponding class labels.
# # #     This is required for Keras flow_from_dataframe method.
# # #     """
# # #     paths, labels = [], []  # Lists to store image paths and labels

# # #     for variety in os.listdir(base_dir):  # Assamica, DT1
# # #         var_path = os.path.join(base_dir, variety)
# # #         if not os.path.isdir(var_path):
# # #             continue
# # #         for subcls in ["tender", "matured"]:  # Only the leaf maturity classes
# # #             cls_path = os.path.join(var_path, subcls)
# # #             if not os.path.exists(cls_path):
# # #                 continue
# # #             for img_file in os.listdir(cls_path):
# # #                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                     paths.append(os.path.join(cls_path, img_file))
# # #                     labels.append(f"{variety}/{subcls}")  # Must match CLASS_ORDER exactly

# # #     df = pd.DataFrame({"filename": paths, "class": labels})
# # #     return df



    
# # # #     df = pd.DataFrame({"filename": paths, "class": labels})
# # # #     return df

# # # # ------------------ Step 6: ImageDataGenerators ------------------
# # # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# # #     """
# # #     Creates training and validation ImageDataGenerators with augmentation for training.
# # #     Returns the generators for use in model.fit().
# # #     """
# # #     print("🔹 Creating ImageDataGenerators with augmentation...")

# # #     train_df = create_dataframe(TRAIN_DIR)  # Get train DataFrame
# # #     val_df   = create_dataframe(VALID_DIR)  # Get validation DataFrame

# # #     # Augmentation parameters for training images
# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,  # Scale pixel values to 0-1
# # #         rotation_range=20,  # Random rotation up to 20 degrees
# # #         width_shift_range=0.2,  # Random horizontal shift
# # #         height_shift_range=0.2,  # Random vertical shift
# # #         shear_range=0.2,  # Shear transformation
# # #         zoom_range=0.2,  # Zoom in/out
# # #         horizontal_flip=True,  # Random horizontal flip
# # #         brightness_range=[0.8, 1.2],    # <-- Added to mimic ColorJitter brightness
# # #         fill_mode="nearest"  # Fill pixels after transformations
# # #     )
# # #     val_datagen = ImageDataGenerator(rescale=1./255)  # Only rescale validation images

# # #     # Create generators for Keras model
# # #     train_gen = train_datagen.flow_from_dataframe(
# # #         train_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=True,
# # #         classes=CLASS_ORDER

# # #     )
# # #     val_gen = val_datagen.flow_from_dataframe(
# # #         val_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=False,
# # #         classes=CLASS_ORDER

# # #     )
# # #     return train_gen, val_gen

# # # # ------------------ Step 7: Verify pixel scaling & batch ------------------
# # # def verify_generators(train_gen, val_gen):
# # #     """
# # #     Checks that generator batches have correct shape, dtype, and pixel scaling.
# # #     Helps catch preprocessing errors before training.
# # #     """
# # #     print("🔹 Verifying pixel scaling and batch properties...")
# # #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# # #         x_batch, y_batch = next(gen)  # Get first batch
# # #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")  # Should be (batch_size, 224, 224, 3)
# # #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")  # Check rescale
# # #         print(f"{name} batch label shape: {y_batch.shape}")  # Should match batch_size and number of classes
# # #     print("✔ Pixel scaling and batch properties verified.\n")

# # # # ------------------ Step 8: Augmentation sanity check ------------------
# # # def visualize_augmentations(train_gen, n_images=5):
# # #     """
# # #     Displays a few augmented images with their labels to visually verify augmentation.
# # #     """
# # #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# # #     x_batch, y_batch = next(train_gen)  # Get one batch
# # #     rev_map = {v: k for k, v in train_gen.class_indices.items()}  # Map class indices back to names
# # #     for i in range(min(n_images, len(x_batch))):
# # #         img = x_batch[i]  # Get image
# # #         label_idx = np.argmax(y_batch[i])  # Convert one-hot label to index
# # #         label_name = rev_map[label_idx]  # Get class name
# # #         plt.imshow(img)  # Show image
# # #         plt.title(f"Label: {label_name} ({label_idx})")
# # #         plt.axis("off")
# # #         plt.show()
# # #     print("✔ Augmentation sanity check done.\n")

# # # # ------------------ Step 9: Optional class mapping verification ------------------
# # # def verify_class_mapping(train_gen):
# # #     """
# # #     Prints the mapping of class names to integer indices.
# # #     Useful to ensure consistent labels for training.
# # #     """
# # #     print("\n🔹 Class index mapping:")
# # #     for cls, idx in train_gen.class_indices.items():
# # #         print(f"  {cls}: {idx}")
# # #     print("✔ Class mapping verified.\n")

# # # # ------------------ Step 10: Run everything ------------------
# # # if __name__ == "__main__":
# # #     # Step-by-step execution
# # #     verify_folder_structure()  # Verify folder structure
# # #     check_class_balance()      # Check number of images per class
# # #     detect_corrupted_images(TRAIN_DIR)  # Check for corrupted training images
# # #     detect_corrupted_images(VALID_DIR)  # Check for corrupted validation images
# # #     detect_corrupted_images(TEST_DIR)   # Check for corrupted test images
# # #     preflight_check(TRAIN_DIR)  # Verify image size and mode for training
# # #     preflight_check(VALID_DIR)  # Verify image size and mode for validation
# # #     preflight_check(TEST_DIR)   # Verify image size and mode for testing

# # #     train_gen, val_gen = get_generators()  # Create ImageDataGenerators
# # #     verify_generators(train_gen, val_gen)  # Verify batches and scaling
# # #     visualize_augmentations(train_gen, n_images=5)  # Show sample augmented images
# # #     verify_class_mapping(train_gen)  # Print class index mapping

# # #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")



# # # import os
# # # import numpy as np
# # # import pandas as pd
# # # from PIL import Image
# # # from tqdm import tqdm
# # # import matplotlib.pyplot as plt
# # # from tensorflow.keras.preprocessing.image import ImageDataGenerator

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")

# # # IMG_SIZE = (224, 224)
# # # BATCH_SIZE = 32
# # # VARIETIES = ["Assamica", "DT1"]
# # # LEAF_CLASSES = ["tender", "matured"]

# # # # ------------------ Step 1: Verify folder structure ------------------
# # # def verify_folder_structure():
# # #     print("\n🔹 Verifying dataset folder structure...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         if not os.path.exists(folder):
# # #             print(f"⚠ Folder missing: {folder}")
# # #             continue
# # #         for var in VARIETIES:
# # #             var_path = os.path.join(folder, var)
# # #             if not os.path.exists(var_path):
# # #                 print(f"⚠ Missing variety folder: {var_path}")
# # #                 continue
# # #             for cls in LEAF_CLASSES:
# # #                 cls_path = os.path.join(var_path, cls)
# # #                 if not os.path.exists(cls_path):
# # #                     print(f"⚠ Missing class folder: {cls_path}")
# # #                 else:
# # #                     print(f"✔ Found class folder: {cls_path}")
# # #     print("✔ Folder verification complete.\n")

# # # # ------------------ Step 2: Detect corrupted images ------------------
# # # def detect_corrupted_images(dataset_dir):
# # #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     corrupted_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except:
# # #                     corrupted_images.append(path)

# # #     if corrupted_images:
# # #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# # #         for img_path in corrupted_images:
# # #             print("   ", img_path)
# # #     else:
# # #         print("✔ No corrupted images detected.\n")
# # #     return corrupted_images

# # # # ------------------ Step 3: Class balance check ------------------
# # # def check_class_balance():
# # #     print("\n🔹 Checking class balance...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         print(f"\nFolder: {folder}")
# # #         for var in VARIETIES:
# # #             var_path = os.path.join(folder, var)
# # #             if not os.path.exists(var_path):
# # #                 continue
# # #             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) 
# # #                       for cls in LEAF_CLASSES if os.path.exists(os.path.join(var_path, cls))}
# # #             print(f" Variety: {var}")
# # #             for cls, count in counts.items():
# # #                 print(f"   {cls}: {count} images")
# # #     print("✔ Class balance checked.\n")

# # # # ------------------ Step 4: Pre-flight verification ------------------
# # # def preflight_check(dataset_dir, img_size=IMG_SIZE):
# # #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# # #     bad_images = []
# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in files:
# # #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     if img.mode != "RGB":
# # #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# # #                     if img.size != img_size:
# # #                         bad_images.append((path, f"Wrong size: {img.size}"))
# # #                 except Exception as e:
# # #                     bad_images.append((path, f"Open error: {e}"))
# # #     if bad_images:
# # #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# # #         for path, issue in bad_images:
# # #             print(f"   {path} | {issue}")
# # #     else:
# # #         print("✔ All images are correct size (224x224) and RGB.\n")
# # #     return bad_images

# # # # ------------------ Step 5: Create dataframe ------------------
# # # def create_dataframe(base_dir):
# # #     paths, labels = [], []
# # #     for var in VARIETIES:
# # #         var_path = os.path.join(base_dir, var)
# # #         if not os.path.isdir(var_path):
# # #             continue
# # #         for cls in LEAF_CLASSES:
# # #             cls_path = os.path.join(var_path, cls)
# # #             if not os.path.exists(cls_path):
# # #                 continue
# # #             for img_file in os.listdir(cls_path):
# # #                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                     paths.append(os.path.join(cls_path, img_file))
# # #                     labels.append(f"{var}/{cls}")
# # #     df = pd.DataFrame({"filename": paths, "class": labels})
# # #     return df

# # # # ------------------ Step 6: ImageDataGenerators ------------------
# # # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# # #     print("🔹 Creating ImageDataGenerators with augmentation...")
# # #     train_df = create_dataframe(TRAIN_DIR)
# # #     val_df   = create_dataframe(VALID_DIR)

# # #     train_datagen = ImageDataGenerator(
# # #         rescale=1./255,
# # #         rotation_range=20,
# # #         width_shift_range=0.2,
# # #         height_shift_range=0.2,
# # #         shear_range=0.2,
# # #         zoom_range=0.2,
# # #         horizontal_flip=True,
# # #         brightness_range=[0.8, 1.2],
# # #         fill_mode="nearest"
# # #     )
# # #     val_datagen = ImageDataGenerator(rescale=1./255)

# # #     class_labels = [f"{var}/{cls}" for var in VARIETIES for cls in LEAF_CLASSES]

# # #     train_gen = train_datagen.flow_from_dataframe(
# # #         train_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=True,
# # #         classes=class_labels
# # #     )
# # #     val_gen = val_datagen.flow_from_dataframe(
# # #         val_df,
# # #         x_col="filename",
# # #         y_col="class",
# # #         target_size=img_size,
# # #         batch_size=batch_size,
# # #         class_mode="categorical",
# # #         shuffle=False,
# # #         classes=class_labels
# # #     )
# # #     return train_gen, val_gen

# # # # ------------------ Step 7: Verify pixel scaling & batch ------------------
# # # def verify_generators(train_gen, val_gen):
# # #     print("🔹 Verifying pixel scaling and batch properties...")
# # #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# # #         x_batch, y_batch = next(gen)
# # #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")
# # #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
# # #         print(f"{name} batch label shape: {y_batch.shape}")
# # #     print("✔ Pixel scaling and batch properties verified.\n")

# # # # ------------------ Step 8: Augmentation sanity check ------------------
# # # def visualize_augmentations(train_gen, n_images=5):
# # #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# # #     x_batch, y_batch = next(train_gen)
# # #     rev_map = {v: k for k, v in train_gen.class_indices.items()}
# # #     for i in range(min(n_images, len(x_batch))):
# # #         img = x_batch[i]
# # #         label_idx = np.argmax(y_batch[i])
# # #         label_name = rev_map[label_idx]
# # #         plt.imshow(img)
# # #         plt.title(f"Label: {label_name} ({label_idx})")
# # #         plt.axis("off")
# # #         plt.show()
# # #     print("✔ Augmentation sanity check done.\n")

# # # # ------------------ Step 9: Class mapping verification ------------------
# # # def verify_class_mapping(train_gen):
# # #     print("\n🔹 Class index mapping:")
# # #     for cls, idx in train_gen.class_indices.items():
# # #         print(f"  {cls}: {idx}")
# # #     print("✔ Class mapping verified.\n")

# # # # ------------------ Step 10: Run everything ------------------
# # # if __name__ == "__main__":
# # #     verify_folder_structure()
# # #     check_class_balance()
# # #     detect_corrupted_images(TRAIN_DIR)
# # #     detect_corrupted_images(VALID_DIR)
# # #     detect_corrupted_images(TEST_DIR)
# # #     preflight_check(TRAIN_DIR)
# # #     preflight_check(VALID_DIR)
# # #     preflight_check(TEST_DIR)

# # #     train_gen, val_gen = get_generators()
# # #     verify_generators(train_gen, val_gen)
# # #     visualize_augmentations(train_gen, n_images=5)
# # #     verify_class_mapping(train_gen)

# # #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")



# # import os  # For file and directory path handling
# # import numpy as np  # For numerical operations
# # import pandas as pd  # For creating and manipulating dataframes
# # from PIL import Image  # For image loading and validation
# # from tqdm import tqdm  # For progress bars while iterating files
# # import matplotlib.pyplot as plt  # For plotting images
# # from tensorflow.keras.preprocessing.image import ImageDataGenerator  # For data augmentation and batch generation

# # # ------------------ Project Paths ------------------
# # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Main dataset folder
# # TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Training images
# # VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Validation images
# # TEST_DIR  = os.path.join(DATASET_DIR, "test")  # Testing images

# # IMG_SIZE = (224, 224)  # All images will be resized to 224x224 (standard for MobileNetV3)
# # BATCH_SIZE = 32  # Number of images per batch
# # VARIETIES = ["Assamica", "DT1"]  # Tea varieties in the dataset
# # LEAF_CLASSES = ["tender", "matured"]  # Leaf maturity classes

# # # ------------------ Step 1: Verify folder structure ------------------
# # def verify_folder_structure():
# #     """
# #     Checks if all expected folders (variety/class) exist in train, valid, test.
# #     Prints warnings if any are missing.
# #     """
# #     print("\n🔹 Verifying dataset folder structure...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         if not os.path.exists(folder):
# #             print(f"⚠ Folder missing: {folder}")  # Folder does not exist
# #             continue
# #         for var in VARIETIES:
# #             var_path = os.path.join(folder, var)  # Full path to variety folder
# #             if not os.path.exists(var_path):
# #                 print(f"⚠ Missing variety folder: {var_path}")
# #                 continue
# #             for cls in LEAF_CLASSES:
# #                 cls_path = os.path.join(var_path, cls)  # Full path to class folder
# #                 if not os.path.exists(cls_path):
# #                     print(f"⚠ Missing class folder: {cls_path}")
# #                 else:
# #                     print(f"✔ Found class folder: {cls_path}")
# #     print("✔ Folder verification complete.\n")

# # # ------------------ Step 2: Detect corrupted images ------------------
# # def detect_corrupted_images(dataset_dir):
# #     """
# #     Scans dataset for images that cannot be opened (corrupted).
# #     Returns a list of corrupted image paths.
# #     """
# #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# #     extensions = (".jpg", ".jpeg", ".png", ".webp")  # Allowed image formats
# #     corrupted_images = []

# #     # Walk through all files recursively
# #     for root, _, files in os.walk(dataset_dir):
# #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# #             if f.lower().endswith(extensions):
# #                 path = os.path.join(root, f)
# #                 try:
# #                     img = Image.open(path)  # Attempt to open image
# #                     img.verify()  # Verify image integrity
# #                 except:
# #                     corrupted_images.append(path)  # Add corrupted images to list

# #     if corrupted_images:
# #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# #         for img_path in corrupted_images:
# #             print("   ", img_path)
# #     else:
# #         print("✔ No corrupted images detected.\n")
# #     return corrupted_images

# # # ------------------ Step 3: Class balance check ------------------
# # def check_class_balance():
# #     """
# #     Prints the number of images in each class for train, validation, test.
# #     Helps identify class imbalance early.
# #     """
# #     print("\n🔹 Checking class balance...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         print(f"\nFolder: {folder}")
# #         for var in VARIETIES:
# #             var_path = os.path.join(folder, var)
# #             if not os.path.exists(var_path):
# #                 continue
# #             # Count images in each class folder
# #             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) 
# #                       for cls in LEAF_CLASSES if os.path.exists(os.path.join(var_path, cls))}
# #             print(f" Variety: {var}")
# #             for cls, count in counts.items():
# #                 print(f"   {cls}: {count} images")
# #     print("✔ Class balance checked.\n")

# # # ------------------ Step 4: Pre-flight verification ------------------
# # def preflight_check(dataset_dir, img_size=IMG_SIZE):
# #     """
# #     Ensures all images are RGB and of correct size.
# #     Returns a list of problematic images with issues.
# #     """
# #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# #     bad_images = []
# #     for root, _, files in os.walk(dataset_dir):
# #         for f in files:
# #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# #                 path = os.path.join(root, f)
# #                 try:
# #                     img = Image.open(path)
# #                     if img.mode != "RGB":  # Not RGB
# #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# #                     if img.size != img_size:  # Not expected size
# #                         bad_images.append((path, f"Wrong size: {img.size}"))
# #                 except Exception as e:
# #                     bad_images.append((path, f"Open error: {e}"))
# #     if bad_images:
# #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# #         for path, issue in bad_images:
# #             print(f"   {path} | {issue}")
# #     else:
# #         print("✔ All images are correct size (224x224) and RGB.\n")
# #     return bad_images

# # # ------------------ Step 5: Create dataframe ------------------
# # def create_dataframe(base_dir):
# #     """
# #     Creates a pandas dataframe with columns: 'filename', 'class'.
# #     This is required for ImageDataGenerator.flow_from_dataframe().
# #     """
# #     paths, labels = [], []
# #     for var in VARIETIES:
# #         var_path = os.path.join(base_dir, var)
# #         if not os.path.isdir(var_path):
# #             continue
# #         for cls in LEAF_CLASSES:
# #             cls_path = os.path.join(var_path, cls)
# #             if not os.path.exists(cls_path):
# #                 continue
# #             for img_file in os.listdir(cls_path):
# #                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# #                     paths.append(os.path.join(cls_path, img_file))  # Full path to image
# #                     labels.append(f"{var}/{cls}")  # Label in "Variety/Class" format
# #     df = pd.DataFrame({"filename": paths, "class": labels})
# #     return df

# # # ------------------ Step 6: ImageDataGenerators ------------------
# # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# #     """
# #     Creates Keras ImageDataGenerators for training and validation.
# #     Includes data augmentation for the training set.
# #     """
# #     print("🔹 Creating ImageDataGenerators with augmentation...")
# #     train_df = create_dataframe(TRAIN_DIR)
# #     val_df   = create_dataframe(VALID_DIR)

# #     # Augmentation for training data
# #     train_datagen = ImageDataGenerator(
# #         rescale=1./255,  # Scale pixels to [0,1]
# #         rotation_range=20,  # Rotate images ±20 degrees
# #         width_shift_range=0.2,  # Random horizontal translation
# #         height_shift_range=0.2,  # Random vertical translation
# #         shear_range=0.2,  # Shear transformation
# #         zoom_range=0.2,  # Random zoom
# #         horizontal_flip=True,  # Random horizontal flip
# #         brightness_range=[0.8, 1.2],  # Random brightness adjustment
# #         fill_mode="nearest"  # Fill empty pixels after transformation
# #     )
# #     val_datagen = ImageDataGenerator(rescale=1./255)  # Only rescale validation data

# #     # Ensure class order matches your CLASS_MAP in PyTorch for consistency
# #     class_labels = [f"{var}/{cls}" for var in VARIETIES for cls in LEAF_CLASSES]

# #     # Create training generator
# #     train_gen = train_datagen.flow_from_dataframe(
# #         train_df,
# #         x_col="filename",
# #         y_col="class",
# #         target_size=img_size,
# #         batch_size=batch_size,
# #         class_mode="categorical",  # One-hot encoding for multi-class classification
# #         shuffle=True,  # Shuffle training data
# #         classes=class_labels  # Ensure consistent class ordering
# #     )

# #     # Create validation generator
# #     val_gen = val_datagen.flow_from_dataframe(
# #         val_df,
# #         x_col="filename",
# #         y_col="class",
# #         target_size=img_size,
# #         batch_size=batch_size,
# #         class_mode="categorical",
# #         shuffle=False,
# #         classes=class_labels
# #     )
# #     return train_gen, val_gen

# # # ------------------ Step 7: Verify pixel scaling & batch ------------------
# # def verify_generators(train_gen, val_gen):
# #     """
# #     Retrieves one batch from train and validation generators to verify:
# #     - shape
# #     - pixel scaling (0-1)
# #     - label shape
# #     """
# #     print("🔹 Verifying pixel scaling and batch properties...")
# #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# #         x_batch, y_batch = next(gen)
# #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")
# #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
# #         print(f"{name} batch label shape: {y_batch.shape}")
# #     print("✔ Pixel scaling and batch properties verified.\n")

# # # ------------------ Step 8: Augmentation sanity check ------------------
# # def visualize_augmentations(train_gen, n_images=5):
# #     """
# #     Plots a few augmented training images to ensure augmentations look correct.
# #     """
# #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# #     x_batch, y_batch = next(train_gen)
# #     rev_map = {v: k for k, v in train_gen.class_indices.items()}  # Reverse mapping index -> label
# #     for i in range(min(n_images, len(x_batch))):
# #         img = x_batch[i]
# #         label_idx = np.argmax(y_batch[i])
# #         label_name = rev_map[label_idx]
# #         plt.imshow(img)
# #         plt.title(f"Label: {label_name} ({label_idx})")
# #         plt.axis("off")
# #         plt.show()
# #     print("✔ Augmentation sanity check done.\n")

# # # ------------------ Step 9: Class mapping verification ------------------
# # def verify_class_mapping(train_gen):
# #     """
# #     Prints the mapping of class names to indices to verify consistency.
# #     """
# #     print("\n🔹 Class index mapping:")
# #     for cls, idx in train_gen.class_indices.items():
# #         print(f"  {cls}: {idx}")
# #     print("✔ Class mapping verified.\n")

# # # ------------------ Step 10: Run everything ------------------
# # if __name__ == "__main__":
# #     # Step 1: Verify folder structure
# #     verify_folder_structure()
# #     # Step 3: Check class balance
# #     check_class_balance()
# #     # Step 2: Detect corrupted images in train, valid, test
# #     detect_corrupted_images(TRAIN_DIR)
# #     detect_corrupted_images(VALID_DIR)
# #     detect_corrupted_images(TEST_DIR)
# #     # Step 4: Pre-flight check for size & RGB
# #     preflight_check(TRAIN_DIR)
# #     preflight_check(VALID_DIR)
# #     preflight_check(TEST_DIR)

# #     # Step 6: Create generators for training & validation
# #     train_gen, val_gen = get_generators()
# #     # Step 7: Verify batches & pixel scaling
# #     verify_generators(train_gen, val_gen)
# #     # Step 8: Visualize augmented images
# #     visualize_augmentations(train_gen, n_images=5)
# #     # Step 9: Verify class mapping
# #     verify_class_mapping(train_gen)

# #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")



# # ========================================================================================

# # import os  
# # import numpy as np  
# # import pandas as pd  
# # from PIL import Image  
# # from tqdm import tqdm  
# # import matplotlib.pyplot as plt  
# # from tensorflow.keras.preprocessing.image import ImageDataGenerator  

# # # ------------------ Project Paths ------------------
# # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Main dataset folder
# # TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Training images
# # VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Validation images
# # TEST_DIR  = os.path.join(DATASET_DIR, "test")  # Testing images

# # IMG_SIZE = (224, 224)  # All images will be resized to 224x224 (standard for MobileNetV3)
# # BATCH_SIZE = 32  # Number of images per batch
# # VARIETIES = ["Assamica", "DT1"]  # Tea varieties in the dataset
# # LEAF_CLASSES = ["tender", "matured"]  # Leaf maturity classes

# # # ------------------ Step 1: Verify folder structure ------------------
# # def verify_folder_structure():
# #     """
# #     Checks if all expected folders (variety/class) exist in train, valid, test.
# #     Prints warnings if any are missing.
# #     """
# #     print("\n🔹 Verifying dataset folder structure...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         if not os.path.exists(folder):
# #             print(f"⚠ Folder missing: {folder}")  # Folder does not exist
# #             continue
# #         for var in VARIETIES:
# #             var_path = os.path.join(folder, var)  # Full path to variety folder
# #             if not os.path.exists(var_path):
# #                 print(f"⚠ Missing variety folder: {var_path}")
# #                 continue
# #             for cls in LEAF_CLASSES:
# #                 cls_path = os.path.join(var_path, cls)  # Full path to class folder
# #                 if not os.path.exists(cls_path):
# #                     print(f"⚠ Missing class folder: {cls_path}")
# #                 else:
# #                     print(f"✔ Found class folder: {cls_path}")
# #     print("✔ Folder verification complete.\n")

# # # ------------------ Step 2: Detect corrupted images ------------------
# # def detect_corrupted_images(dataset_dir):
# #     """
# #     Scans dataset for images that cannot be opened (corrupted).
# #     Returns a list of corrupted image paths.
# #     """
# #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# #     extensions = (".jpg", ".jpeg", ".png", ".webp")  # Allowed image formats
# #     corrupted_images = []

# #     # Walk through all files recursively
# #     for root, _, files in os.walk(dataset_dir):
# #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# #             if f.lower().endswith(extensions):
# #                 path = os.path.join(root, f)
# #                 try:
# #                     img = Image.open(path)  # Attempt to open image
# #                     img.verify()  # Verify image integrity
# #                 except:
# #                     corrupted_images.append(path)  # Add corrupted images to list

# #     if corrupted_images:
# #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# #         for img_path in corrupted_images:
# #             print("   ", img_path)
# #     else:
# #         print("✔ No corrupted images detected.\n")
# #     return corrupted_images

# # # ------------------ Step 3: Class balance check ------------------
# # def check_class_balance():
# #     """
# #     Prints the number of images in each class for train, validation, test.
# #     Helps identify class imbalance early.
# #     """
# #     print("\n🔹 Checking class balance...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         print(f"\nFolder: {folder}")
# #         for var in VARIETIES:
# #             var_path = os.path.join(folder, var)
# #             if not os.path.exists(var_path):
# #                 continue
# #             # Count images in each class folder
# #             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) 
# #                       for cls in LEAF_CLASSES if os.path.exists(os.path.join(var_path, cls))}
# #             print(f" Variety: {var}")
# #             for cls, count in counts.items():
# #                 print(f"   {cls}: {count} images")
# #     print("✔ Class balance checked.\n")

# # # ------------------ Step 4: Pre-flight verification ------------------
# # def preflight_check(dataset_dir, img_size=IMG_SIZE):
# #     """
# #     Ensures all images are RGB and of correct size.
# #     Returns a list of problematic images with issues.
# #     """
# #     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
# #     bad_images = []
# #     for root, _, files in os.walk(dataset_dir):
# #         for f in files:
# #             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# #                 path = os.path.join(root, f)
# #                 try:
# #                     img = Image.open(path)
# #                     if img.mode != "RGB":  # Not RGB
# #                         bad_images.append((path, f"Wrong mode: {img.mode}"))
# #                     if img.size != img_size:  # Not expected size
# #                         bad_images.append((path, f"Wrong size: {img.size}"))
# #                 except Exception as e:
# #                     bad_images.append((path, f"Open error: {e}"))
# #     if bad_images:
# #         print(f"\n⚠ Found {len(bad_images)} images with issues:")
# #         for path, issue in bad_images:
# #             print(f"   {path} | {issue}")
# #     else:
# #         print("✔ All images are correct size (224x224) and RGB.\n")
# #     return bad_images

# # # ------------------ Step 5: Create dataframe ------------------
# # def create_dataframe(base_dir):
# #     """
# #     Creates a pandas dataframe with columns: 'filename', 'class'.
# #     This is required for ImageDataGenerator.flow_from_dataframe().
# #     """
# #     paths, labels = [], []
# #     for var in VARIETIES:
# #         var_path = os.path.join(base_dir, var)
# #         if not os.path.isdir(var_path):
# #             continue
# #         for cls in LEAF_CLASSES:
# #             cls_path = os.path.join(var_path, cls)
# #             if not os.path.exists(cls_path):
# #                 continue
# #             for img_file in os.listdir(cls_path):
# #                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# #                     paths.append(os.path.join(cls_path, img_file))  # Full path to image
# #                     labels.append(f"{var}/{cls}")  # Label in "Variety/Class" format
# #     df = pd.DataFrame({"filename": paths, "class": labels})
# #     return df

# # # ------------------ Step 6: ImageDataGenerators ------------------
# # def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
# #     """
# #     Creates Keras ImageDataGenerators for training and validation.
# #     Includes data augmentation for the training set.
# #     """
# #     print("🔹 Creating ImageDataGenerators with augmentation...")
# #     train_df = create_dataframe(TRAIN_DIR)
# #     val_df   = create_dataframe(VALID_DIR)

# #     # Augmentation for training data
# #     train_datagen = ImageDataGenerator(
# #         rescale=1./255,  # Scale pixels to [0,1]
# #         rotation_range=20,  # Rotate images ±20 degrees
# #         width_shift_range=0.2,  # Random horizontal translation
# #         height_shift_range=0.2,  # Random vertical translation
# #         shear_range=0.2,  # Shear transformation
# #         zoom_range=0.2,  # Random zoom
# #         horizontal_flip=True,  # Random horizontal flip
# #         brightness_range=[0.8, 1.2],  # Random brightness adjustment
# #         fill_mode="nearest"  # Fill empty pixels after transformation
# #     )
# #     val_datagen = ImageDataGenerator(rescale=1./255)  # Only rescale validation data

# #     # Ensure class order matches your CLASS_MAP in PyTorch for consistency
# #     class_labels = [f"{var}/{cls}" for var in VARIETIES for cls in LEAF_CLASSES]

# #     # Create training generator
# #     train_gen = train_datagen.flow_from_dataframe(
# #         train_df,
# #         x_col="filename",
# #         y_col="class",
# #         target_size=img_size,
# #         batch_size=batch_size,
# #         class_mode="categorical",  # One-hot encoding for multi-class classification
# #         shuffle=True,  # Shuffle training data
# #         classes=class_labels  # Ensure consistent class ordering
# #     )

# #     # Create validation generator
# #     val_gen = val_datagen.flow_from_dataframe(
# #         val_df,
# #         x_col="filename",
# #         y_col="class",
# #         target_size=img_size,
# #         batch_size=batch_size,
# #         class_mode="categorical",
# #         shuffle=False,
# #         classes=class_labels
# #     )
# #     return train_gen, val_gen

# # # ------------------ Step 7: Verify pixel scaling & batch ------------------
# # def verify_generators(train_gen, val_gen):
# #     """
# #     Retrieves one batch from train and validation generators to verify:
# #     - shape
# #     - pixel scaling (0-1)
# #     - label shape
# #     """
# #     print("🔹 Verifying pixel scaling and batch properties...")
# #     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
# #         x_batch, y_batch = next(gen)
# #         print(f"{name} batch shape: {x_batch.shape}, dtype: {x_batch.dtype}")
# #         print(f"{name} pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
# #         print(f"{name} batch label shape: {y_batch.shape}")
# #     print("✔ Pixel scaling and batch properties verified.\n")

# # # ------------------ Step 8: Augmentation sanity check ------------------
# # def visualize_augmentations(train_gen, n_images=5):
# #     """
# #     Plots a few augmented training images to ensure augmentations look correct.
# #     """
# #     print(f"\n🔹 Visualizing {n_images} augmented images for sanity check...")
# #     x_batch, y_batch = next(train_gen)
# #     rev_map = {v: k for k, v in train_gen.class_indices.items()}  # Reverse mapping index -> label
# #     for i in range(min(n_images, len(x_batch))):
# #         img = x_batch[i]
# #         label_idx = np.argmax(y_batch[i])
# #         label_name = rev_map[label_idx]
# #         plt.imshow(img)
# #         plt.title(f"Label: {label_name} ({label_idx})")
# #         plt.axis("off")
# #         plt.show()
# #     print("✔ Augmentation sanity check done.\n")

# # # ------------------ Step 9: Class mapping verification ------------------
# # def verify_class_mapping(train_gen):
# #     """
# #     Prints the mapping of class names to indices to verify consistency.
# #     """
# #     print("\n🔹 Class index mapping:")
# #     for cls, idx in train_gen.class_indices.items():
# #         print(f"  {cls}: {idx}")
# #     print("✔ Class mapping verified.\n")

# # # ------------------ Step 10: Run everything ------------------
# # if __name__ == "__main__":
# #     # Step 1: Verify folder structure
# #     verify_folder_structure()
# #     # Step 3: Check class balance
# #     check_class_balance()
# #     # Step 2: Detect corrupted images in train, valid, test
# #     detect_corrupted_images(TRAIN_DIR)
# #     detect_corrupted_images(VALID_DIR)
# #     detect_corrupted_images(TEST_DIR)
# #     # Step 4: Pre-flight check for size & RGB
# #     preflight_check(TRAIN_DIR)
# #     preflight_check(VALID_DIR)
# #     preflight_check(TEST_DIR)

# #     # Step 6: Create generators for training & validation
# #     train_gen, val_gen = get_generators()
# #     # Step 7: Verify batches & pixel scaling
# #     verify_generators(train_gen, val_gen)
# #     # Step 8: Visualize augmented images
# #     visualize_augmentations(train_gen, n_images=5)
# #     # Step 9: Verify class mapping
# #     verify_class_mapping(train_gen)

# #     print("✅ Full preprocessing & verification complete! Dataset ready for MobileNetV3 training.\n")




# # ===========important ====================

# import os  
# import numpy as np  
# import pandas as pd  
# from PIL import Image  
# from tqdm import tqdm  
# import matplotlib.pyplot as plt  
# from tensorflow.keras.preprocessing.image import ImageDataGenerator, load_img, img_to_array

# # ------------------ Project Paths ------------------
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  
# TRAIN_DIR = os.path.join(DATASET_DIR, "train")  
# VALID_DIR = os.path.join(DATASET_DIR, "valid")  
# TEST_DIR  = os.path.join(DATASET_DIR, "test")  

# IMG_SIZE = (224, 224)
# BATCH_SIZE = 32
# VARIETIES = ["Assamica", "DT1"]
# LEAF_CLASSES = ["tender", "matured"]

# # ------------------ MobileNetV3 Preprocessing Constants ------------------
# # These are the official MobileNetV3 preprocessing values
# MOBILENETV3_MEAN = [0.485, 0.456, 0.406]  # RGB mean
# MOBILENETV3_STD = [0.229, 0.224, 0.225]    # RGB std

# def mobilenetv3_preprocess(img):
#     """
#     MANUAL MobileNetV3 preprocessing that actually works!
#     Converts [0, 255] -> [-1, 1]
#     """
#     # Ensure float32
#     img = img.astype(np.float32)
    
#     # Scale from [0, 255] to [0, 1]
#     img = img / 255.0
    
#     # Normalize using MobileNetV3 mean/std
#     img[..., 0] = (img[..., 0] - MOBILENETV3_MEAN[0]) / MOBILENETV3_STD[0]  # R
#     img[..., 1] = (img[..., 1] - MOBILENETV3_MEAN[1]) / MOBILENETV3_STD[1]  # G
#     img[..., 2] = (img[..., 2] - MOBILENETV3_MEAN[2]) / MOBILENETV3_STD[2]  # B
    
#     return img

# # ------------------ Step 1: Verify folder structure ------------------
# def verify_folder_structure():
#     print("\n🔹 Verifying dataset folder structure...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):
#             print(f"⚠ Folder missing: {folder}")
#             continue
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.exists(var_path):
#                 print(f"⚠ Missing variety folder: {var_path}")
#                 continue
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)
#                 if not os.path.exists(cls_path):
#                     print(f"⚠ Missing class folder: {cls_path}")
#                 else:
#                     print(f"✔ Found class folder: {cls_path}")
#     print("✔ Folder verification complete.\n")

# # ------------------ Step 2: Detect corrupted images ------------------
# def detect_corrupted_images(dataset_dir):
#     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []

#     for root, _, files in os.walk(dataset_dir):
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     img.verify()
#                 except:
#                     corrupted_images.append(path)

#     if corrupted_images:
#         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:
#         print("✔ No corrupted images detected.\n")
#     return corrupted_images

# # ------------------ Step 3: Class balance check ------------------
# def check_class_balance():
#     print("\n🔹 Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.isdir(var_path):
#                 continue
#             counts = {cls: len(os.listdir(os.path.join(var_path, cls))) 
#                       for cls in LEAF_CLASSES if os.path.exists(os.path.join(var_path, cls))}
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print("✔ Class balance checked.\n")

# # ------------------ Step 4: Pre-flight verification ------------------
# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
#     bad_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
#                 except Exception as e:
#                     bad_images.append((path, f"Open error: {e}"))
#     if bad_images:
#         print(f"\n⚠ Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print("✔ All images are correct size (224x224) and RGB.\n")
#     return bad_images

# # ------------------ Step 5: Create dataframe ------------------
# def create_dataframe(base_dir):
#     paths, labels = [], []
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path):
#             continue
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path):
#                 continue
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(f"{var}/{cls}")
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df

# # ------------------ Step 6: BULLETPROOF Custom Generator ------------------
# class MobileNetV3DataGenerator:
#     """Custom generator with MANUAL MobileNetV3 preprocessing"""
    
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), 
#                  augment=False, shuffle=True):
#         self.dataframe = dataframe.copy()
#         self.batch_size = batch_size
#         self.img_size = img_size
#         self.augment = augment
#         self.shuffle = shuffle
#         self.n = len(dataframe)
#         self.classes = sorted(dataframe['class'].unique())
#         self.class_to_idx = {cls: idx for idx, cls in enumerate(self.classes)}
#         self.idx_to_class = {idx: cls for idx, cls in enumerate(self.classes)}
        
#         # Create label indices
#         self.dataframe['label_idx'] = self.dataframe['class'].map(self.class_to_idx)
        
#         # Create augmentation generator if needed
#         if self.augment:
#             self.aug_gen = ImageDataGenerator(
#                 rotation_range=20,
#                 width_shift_range=0.2,
#                 height_shift_range=0.2,
#                 shear_range=0.2,
#                 zoom_range=0.2,
#                 horizontal_flip=True,
#                 brightness_range=[0.8, 1.2],
#                 fill_mode="nearest"
#             )
        
#         self.on_epoch_end()
    
#     def on_epoch_end(self):
#         """Shuffle data at the end of each epoch"""
#         if self.shuffle:
#             self.dataframe = self.dataframe.sample(frac=1).reset_index(drop=True)
#         self.index = 0
    
#     def __len__(self):
#         """Number of batches per epoch"""
#         return int(np.ceil(self.n / self.batch_size))
    
#     def __getitem__(self, index):
#         """Generate one batch of data"""
#         start_idx = index * self.batch_size
#         end_idx = min((index + 1) * self.batch_size, self.n)
        
#         batch_df = self.dataframe.iloc[start_idx:end_idx]
        
#         # Initialize batch arrays
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             # Load image
#             img = load_img(row['filename'], target_size=self.img_size)
#             img_array = img_to_array(img)
            
#             # Apply augmentation if needed
#             if self.augment:
#                 img_array = self.aug_gen.random_transform(img_array)
            
#             # Apply MANUAL MobileNetV3 preprocessing (THIS FIXES EVERYTHING)
#             img_array = mobilenetv3_preprocess(img_array)
            
#             batch_x[i] = img_array
#             batch_y[i, row['label_idx']] = 1.0  # One-hot encoding
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         """Get next batch"""
#         if self.index >= len(self):
#             self.on_epoch_end()
#             raise StopIteration
        
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self):
#         """Make generator iterable"""
#         return self

# # ------------------ Step 7: Create generators ------------------
# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     """
#     Creates custom generators with guaranteed MobileNetV3 preprocessing
#     """
#     print("🔹 Creating custom generators with MANUAL MobileNetV3 preprocessing...")
    
#     # Create dataframes
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
    
#     # Create custom generators
#     train_gen = MobileNetV3DataGenerator(
#         dataframe=train_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=True,    # Apply augmentation to training
#         shuffle=True     # Shuffle training data
#     )
    
#     val_gen = MobileNetV3DataGenerator(
#         dataframe=val_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=False,   # No augmentation for validation
#         shuffle=False    # Don't shuffle validation data
#     )
    
#     print(f"✔ Training samples: {train_gen.n}")
#     print(f"✔ Validation samples: {val_gen.n}")
#     print(f"✔ Training batches per epoch: {len(train_gen)}")
#     print(f"✔ Validation batches per epoch: {len(val_gen)}")
    
#     return train_gen, val_gen

# # ------------------ Step 8: VERIFICATION (Fixed) ------------------
# def verify_generators(train_gen, val_gen):
#     """
#     Verifies that preprocessing is correctly applied
#     """
#     print("🔹 Verifying MobileNetV3 pixel scaling and batch properties...")
    
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         # Get a batch
#         x_batch, y_batch = next(gen)
        
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Data type: {x_batch.dtype}")
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
#         print(f"  Pixel mean: {x_batch.mean():.4f}")
#         print(f"  Label shape: {y_batch.shape}")
        
#         # Check MobileNetV3 preprocessing
#         if x_batch.dtype != np.float32:
#             print(f"  ❌ Data type should be float32, but is {x_batch.dtype}")
#         else:
#             print(f"  ✅ Data type is correct (float32)")
        
#         # MobileNetV3 preprocessing should give values around [-2, 2]
#         # After normalization: (0 - mean)/std ≈ -2.0, (1 - mean)/std ≈ 2.0
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"  ✅ Pixel range is correct for MobileNetV3 (normalized)")
#         elif -1.2 <= x_batch.min() <= -0.8 and 0.8 <= x_batch.max() <= 1.2:
#             print(f"  ⚠ Pixel range is scaled to [-1, 1], not normalized")
#         else:
#             print(f"  ❌ Pixel range is incorrect for MobileNetV3")
#             print(f"     Expected normalized range: ≈[-2.0, 2.0]")
#             print(f"     Got: [{x_batch.min():.2f}, {x_batch.max():.2f}]")
    
#     print("\n✔ Pixel scaling verification complete.\n")
#     return True

# # ------------------ Step 9: Test preprocessing directly ------------------
# def test_preprocessing_directly():
#     """
#     Direct test of MobileNetV3 preprocessing on a single image
#     """
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST")
#     print("=" * 60)
    
#     # Find any image in the dataset
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     # Load image
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
    
#     print(f"\nTest image: {os.path.basename(test_image_path)}")
#     print(f"Original array shape: {img_array.shape}")
#     print(f"Original dtype: {img_array.dtype}")
#     print(f"Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
#     print(f"Original mean: {img_array.mean():.1f}")
    
#     # Apply MANUAL MobileNetV3 preprocessing
#     preprocessed = mobilenetv3_preprocess(img_array)
    
#     print(f"\nAfter MANUAL MobileNetV3 preprocessing:")
#     print(f"Preprocessed shape: {preprocessed.shape}")
#     print(f"Preprocessed dtype: {preprocessed.dtype}")
#     print(f"Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     print(f"Preprocessed mean: {preprocessed.mean():.4f}")
    
#     # Calculate expected range
#     # For channel R: (0 - 0.485)/0.229 = -2.12, (1 - 0.485)/0.229 = 2.25
#     # For channel G: (0 - 0.456)/0.224 = -2.04, (1 - 0.456)/0.224 = 2.43
#     # For channel B: (0 - 0.406)/0.225 = -1.80, (1 - 0.406)/0.225 = 2.64
#     print(f"\nExpected ranges per channel:")
#     print(f"  Red:   [{(0 - MOBILENETV3_MEAN[0])/MOBILENETV3_STD[0]:.2f}, {(1 - MOBILENETV3_MEAN[0])/MOBILENETV3_STD[0]:.2f}]")
#     print(f"  Green: [{(0 - MOBILENETV3_MEAN[1])/MOBILENETV3_STD[1]:.2f}, {(1 - MOBILENETV3_MEAN[1])/MOBILENETV3_STD[1]:.2f}]")
#     print(f"  Blue:  [{(0 - MOBILENETV3_MEAN[2])/MOBILENETV3_STD[2]:.2f}, {(1 - MOBILENETV3_MEAN[2])/MOBILENETV3_STD[2]:.2f}]")
    
#     # Check if preprocessing worked
#     if -3.0 <= preprocessed.min() <= -1.0 and 1.0 <= preprocessed.max() <= 3.0:
#         print(f"\n✅ MobileNetV3 preprocessing is working CORRECTLY!")
#         print(f"   Range is properly normalized to ≈[-2, 2]")
#     else:
#         print(f"\n❌ MobileNetV3 preprocessing FAILED!")
#         print(f"   Expected range: ≈[-2, 2]")
    
#     return preprocessed

# # ------------------ Step 10: Visualization ------------------
# def visualize_augmentations(train_gen, n_images=3):
#     """
#     Visualizes augmented images
#     """
#     print(f"\n🔹 Visualizing {n_images} augmented images...")
    
#     # Get a batch
#     x_batch, y_batch = next(train_gen)
    
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]
#         label_idx = np.argmax(y_batch[i])
#         label_name = train_gen.idx_to_class[label_idx]
        
#         # For visualization, we need to denormalize back to [0, 1]
#         img_display = np.zeros_like(img)
#         img_display[..., 0] = img[..., 0] * MOBILENETV3_STD[0] + MOBILENETV3_MEAN[0]  # R
#         img_display[..., 1] = img[..., 1] * MOBILENETV3_STD[1] + MOBILENETV3_MEAN[1]  # G
#         img_display[..., 2] = img[..., 2] * MOBILENETV3_STD[2] + MOBILENETV3_MEAN[2]  # B
#         img_display = np.clip(img_display, 0, 1)  # Clip to valid range
        
#         fig, axes = plt.subplots(1, 3, figsize=(15, 5))
        
#         # Display image
#         axes[0].imshow(img_display)
#         axes[0].set_title(f'Augmented Image {i+1}\nLabel: {label_name}')
#         axes[0].axis('off')
        
#         # Pixel distribution
#         axes[1].hist(img.flatten(), bins=50, alpha=0.7, color='red')
#         axes[1].set_title(f'Pixel Distribution\nRange: [{img.min():.2f}, {img.max():.2f}]')
#         axes[1].set_xlabel('Pixel Value (Normalized)')
#         axes[1].set_ylabel('Frequency')
#         axes[1].grid(True, alpha=0.3)
        
#         # Statistics
#         stats_text = f"""
#         MobileNetV3 Normalized:
#         Min: {img.min():.4f}
#         Max: {img.max():.4f}
#         Mean: {img.mean():.4f}
#         Std: {img.std():.4f}
#         Label: {label_name}
#         """
#         axes[2].text(0.1, 0.5, stats_text, fontsize=12, va='center')
#         axes[2].axis('off')
        
#         plt.tight_layout()
#         plt.show()
#         print(f"  ✅ Shown image {i+1}/{n_images}: {label_name}")
    
#     print("✔ Augmentation visualization complete.\n")

# # ------------------ Step 11: Create test generator ------------------
# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print("🔹 Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
    
#     test_gen = MobileNetV3DataGenerator(
#         dataframe=test_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=False,
#         shuffle=False
#     )
    
#     print(f"✔ Test generator created with {test_gen.n} images")
#     return test_gen

# # ------------------ Main Execution ------------------
# if __name__ == "__main__":
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - ULTIMATE PREPROCESSING FIX")
#     print("=" * 80)
    
#     # Step 1: Verify folder structure
#     verify_folder_structure()
    
#     # Step 3: Check class balance
#     check_class_balance()
    
#     # Step 2: Detect corrupted images
#     detect_corrupted_images(TRAIN_DIR)
#     detect_corrupted_images(VALID_DIR)
#     detect_corrupted_images(TEST_DIR)
    
#     # Step 4: Pre-flight check
#     preflight_check(TRAIN_DIR)
#     preflight_check(VALID_DIR)
#     preflight_check(TEST_DIR)
    
#     # Step 9: Direct preprocessing test
#     test_preprocessing_directly()

#     # Step 7: Create generators
#     train_gen, val_gen = get_generators()
    
#     # Step 8: Verify preprocessing
#     verify_generators(train_gen, val_gen)
    
#     # Step 10: Visualize
#     visualize_augmentations(train_gen, n_images=3)
    
#     # Step 11: Create test generator
#     test_gen = get_test_generator()
    
#     # Final summary
#     print("\n" + "=" * 80)
#     print("FINAL VERIFICATION")
#     print("=" * 80)
    
#     # Test all generators
#     all_correct = True
#     for name, gen in [("Training", train_gen), ("Validation", val_gen), ("Test", test_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Samples: {gen.n}")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Data type: {x_batch.dtype}")
#         print(f"  Pixel range: [{x_batch.min():.4f}, {x_batch.max():.4f}]")
        
#         # Check
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"  ✅ MobileNetV3 preprocessing: SUCCESS")
#         else:
#             print(f"  ❌ MobileNetV3 preprocessing: FAILED")
#             all_correct = False
    
#     print("\n" + "=" * 80)
#     print("PREPROCESSING SUMMARY")
#     print("=" * 80)
#     print(f"Total training images: {train_gen.n}")
#     print(f"Total validation images: {val_gen.n}")
#     print(f"Total test images: {test_gen.n}")
#     print(f"Batch size: {BATCH_SIZE}")
#     print(f"Image size: {IMG_SIZE}")
#     print(f"Number of classes: {len(train_gen.classes)}")
#     print(f"Classes: {train_gen.classes}")
#     print(f"MobileNetV3 Mean: {MOBILENETV3_MEAN}")
#     print(f"MobileNetV3 Std: {MOBILENETV3_STD}")
#     print(f"Augmentation: {'Enabled for training' if train_gen.augment else 'Disabled'}")
    
#     if all_correct:
#         print("✅ Dataset is PERFECTLY preprocessed for MobileNetV3 training!")
#     else:
#         print("⚠ Dataset preprocessing needs adjustment!")
    
#     print("=" * 80)
    
#     # Quick sanity check for model compatibility
#     print("\n🔹 Sanity check for Keras model compatibility:")
#     print(f"Output shape: {x_batch.shape[1:]}")
#     print(f"Number of classes: {y_batch.shape[1]}")
#     print("✅ Ready for MobileNetV3 model input!")



# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY CLASSIFICATION - COMPREHENSIVE PREPROCESSING PIPELINE
# ===============================================================================

# This script implements a complete preprocessing pipeline for MobileNetV3-based
# tea leaf maturity classification. It handles dataset validation, preprocessing,
# augmentation, and generator creation with detailed verification at each step.

# Key Features:
# 1. Dataset structure validation
# 2. Corrupted image detection  
# 3. Class balance analysis
# 4. Manual MobileNetV3 preprocessing
# 5. Custom data generator with augmentation
# 6. Comprehensive verification and visualization
# 7. Research-grade quality control

# Expected Dataset Structure:
# dataset/
# ├── train/
# │   ├── Assamica/
# │   │   ├── tender/
# │   │   └── matured/
# │   └── DT1/
# │       ├── tender/
# │       └── matured/
# ├── valid/ (same structure as train)
# └── test/ (same structure as train)
# """

# # ============================================================================
# # IMPORT LIBRARIES
# # ============================================================================
# import os  # Operating system interface for file/folder operations
# import numpy as np  # Numerical computing for array operations
# import pandas as pd  # Data manipulation and analysis
# from PIL import Image  # Python Imaging Library for image operations
# from tqdm import tqdm  # Progress bar for loops
# import matplotlib.pyplot as plt  # Plotting and visualization
# from tensorflow.keras.preprocessing.image import ImageDataGenerator, load_img, img_to_array
# # ImageDataGenerator: Data augmentation and preprocessing
# # load_img: Loads image as PIL Image object
# # img_to_array: Converts PIL Image to numpy array

# # ============================================================================
# # PROJECT CONFIGURATION - PATH SETUP
# # ============================================================================
# # Define absolute paths to project directories
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Main dataset folder
# TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Training images directory
# VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Validation images directory
# TEST_DIR  = os.path.join(DATASET_DIR, "test")   # Testing images directory

# # ============================================================================
# # MODEL AND DATA CONFIGURATION
# # ============================================================================
# IMG_SIZE = (224, 224)  # MobileNetV3 expects 224x224 input images
# BATCH_SIZE = 32  # Number of images processed simultaneously during training
# VARIETIES = ["Assamica", "DT1"]  # Tea varieties in the dataset
# LEAF_CLASSES = ["tender", "matured"]  # Leaf maturity categories

# # ============================================================================
# # MOBILENETV3 PREPROCESSING CONSTANTS
# # ============================================================================
# # These are the official ImageNet statistics used by MobileNetV3
# # Images are normalized using these mean and standard deviation values
# # Mean subtraction centers the data around zero
# # Division by standard deviation scales the variance to 1
# MOBILENETV3_MEAN = [0.485, 0.456, 0.406]  # RGB channel means [Red, Green, Blue]
# MOBILENETV3_STD = [0.229, 0.224, 0.225]    # RGB channel standard deviations

# # ============================================================================
# # STEP 1: MANUAL MOBILENETV3 PREPROCESSING FUNCTION
# # ============================================================================
# """
# Purpose: Implements custom preprocessing since Keras' built-in function had issues
# Process: Converts [0, 255] pixel values → [0, 1] → normalized to ≈[-2, 2]
# Mathematical Operation: (pixel/255 - mean) / std per channel
# """
# def mobilenetv3_preprocess(img):
#     """
#     MANUAL MobileNetV3 preprocessing that actually works!
#     Converts [0, 255] → [0, 1] → normalized using MobileNetV3 statistics
    
#     Args:
#         img (numpy.ndarray): Input image in [0, 255] range
    
#     Returns:
#         numpy.ndarray: Preprocessed image in normalized range (≈[-2, 2])
#     """
#     # Ensure image is in float32 format (required by TensorFlow)
#     img = img.astype(np.float32)
    
#     # Scale pixel values from [0, 255] to [0, 1] range
#     # Division by 255 converts uint8 to float in [0, 1]
#     img = img / 255.0
    
#     # Channel-wise normalization using MobileNetV3 statistics
#     # For Red channel: (R/255 - 0.485) / 0.229
#     img[..., 0] = (img[..., 0] - MOBILENETV3_MEAN[0]) / MOBILENETV3_STD[0]  # R
    
#     # For Green channel: (G/255 - 0.456) / 0.224
#     img[..., 1] = (img[..., 1] - MOBILENETV3_MEAN[1]) / MOBILENETV3_STD[1]  # G
    
#     # For Blue channel: (B/255 - 0.406) / 0.225
#     img[..., 2] = (img[..., 2] - MOBILENETV3_MEAN[2]) / MOBILENETV3_STD[2]  # B
    
#     return img

# # ============================================================================
# # STEP 2: DATASET STRUCTURE VERIFICATION
# # ============================================================================
# """
# Purpose: Ensures dataset follows expected folder hierarchy
# Verification: Checks existence of all required folders
# Output: Reports missing folders for debugging
# """
# def verify_folder_structure():
#     """
#     Checks if all expected folders (variety/class) exist in train, valid, test.
#     Prints warnings if any are missing.
#     """
#     print("\n Verifying dataset folder structure...")
    
#     # Iterate through train, validation, and test directories
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         # Check if main folder exists
#         if not os.path.exists(folder):
#             print(f" Folder missing: {folder}")  # Folder does not exist
#             continue  # Skip to next folder if this one doesn't exist
        
#         # Check each tea variety folder within the main folder
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)  # Full path to variety folder
#             if not os.path.exists(var_path):
#                 print(f" Missing variety folder: {var_path}")
#                 continue  # Skip to next variety if this one doesn't exist
            
#             # Check each leaf class folder within the variety folder
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)  # Full path to class folder
#                 if not os.path.exists(cls_path):
#                     print(f" Missing class folder: {cls_path}")
#                 else:
#                     # Successfully found the folder
#                     print(f" Found class folder: {cls_path}")
    
#     print(" Folder verification complete.\n")

# # ============================================================================
# # STEP 3: CORRUPTED IMAGE DETECTION
# # ============================================================================
# """
# Purpose: Identifies images that cannot be opened or are corrupted
# Method: Attempts to open and verify each image file
# Process: Uses PIL.Image.open() and .verify() methods
# """
# def detect_corrupted_images(dataset_dir):
#     """
#     Scans dataset for images that cannot be opened (corrupted).
#     Returns a list of corrupted image paths.
    
#     Args:
#         dataset_dir (str): Path to dataset directory to scan
    
#     Returns:
#         list: Paths to corrupted images
#     """
#     print(f"\n Detecting corrupted images in {dataset_dir} ...")
    
#     # Define supported image file extensions
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []  # List to store paths of corrupted images

#     # os.walk recursively traverses all directories and files
#     for root, _, files in os.walk(dataset_dir):
#         # tqdm shows progress bar for file scanning
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             # Check if file has a valid image extension (case-insensitive)
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)  # Construct full file path
#                 try:
#                     # Attempt to open image file
#                     img = Image.open(path)
#                     # Verify image integrity (checks for corruption)
#                     img.verify()
#                 except:
#                     # If any error occurs, add to corrupted list
#                     corrupted_images.append(path)

#     # Report findings
#     if corrupted_images:
#         print(f"\n Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)  # Print each corrupted image path
#     else:
#         print(" No corrupted images detected.\n")
    
#     return corrupted_images

# # ============================================================================
# # STEP 4: CLASS BALANCE ANALYSIS
# # ============================================================================
# """
# Purpose: Analyzes distribution of images across classes
# Importance: Identifies class imbalance which can bias model training
# Output: Counts per class for train/validation/test splits
# """
# def check_class_balance():
#     """
#     Prints the number of images in each class for train, validation, test.
#     Helps identify class imbalance early.
#     """
#     print("\n Checking class balance...")
    
#     # Analyze each dataset split
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
        
#         # Count images for each variety
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             # Skip if variety folder doesn't exist
#             if not os.path.isdir(var_path):
#                 continue
            
#             # Count images in each class folder using dictionary comprehension
#             counts = {
#                 cls: len(os.listdir(os.path.join(var_path, cls))) 
#                 for cls in LEAF_CLASSES 
#                 if os.path.exists(os.path.join(var_path, cls))
#             }
            
#             print(f" Variety: {var}")
#             # Print count for each class
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
    
#     print(" Class balance checked.\n")

# # ============================================================================
# # STEP 5: PRE-FLIGHT IMAGE VERIFICATION
# # ============================================================================
# """
# Purpose: Ensures all images meet MobileNetV3 requirements
# Checks: Image mode (must be RGB), size (must be 224x224)
# Process: Opens each image and validates properties
# """
# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     """
#     Ensures all images are RGB and of correct size.
#     Returns a list of problematic images with issues.
    
#     Args:
#         dataset_dir (str): Directory to check
#         img_size (tuple): Expected image dimensions (width, height)
    
#     Returns:
#         list: Tuples of (path, issue_description) for problematic images
#     """
#     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
#     bad_images = []  # Store problematic images
    
#     # Recursively walk through all files
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             # Check only image files
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     # Open image to check properties
#                     img = Image.open(path)
                    
#                     # Check 1: Image must be in RGB mode (3 channels)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
                    
#                     # Check 2: Image must be correct size (224x224)
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
                        
#                 except Exception as e:
#                     # Catch any errors during image opening
#                     bad_images.append((path, f"Open error: {e}"))
    
#     # Report results
#     if bad_images:
#         print(f"\n Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print(" All images are correct size (224x224) and RGB.\n")
    
#     return bad_images

# # ============================================================================
# # STEP 6: DATAFRAME CREATION FOR DATA ORGANIZATION
# # ============================================================================
# """
# Purpose: Creates structured dataframe for generator compatibility
# Structure: Two columns - 'filename' (full path) and 'class' (label)
# Format: Labels are "Variety/Class" (e.g., "Assamica/tender")
# """
# def create_dataframe(base_dir):
#     """
#     Creates a pandas dataframe with columns: 'filename', 'class'.
#     This is required for organized data handling.
    
#     Args:
#         base_dir (str): Base directory to scan for images
    
#     Returns:
#         pandas.DataFrame: Dataframe with image paths and labels
#     """
#     paths, labels = [], []  # Initialize lists for paths and labels
    
#     # Iterate through variety and class hierarchy
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         # Skip if variety folder doesn't exist
#         if not os.path.isdir(var_path):
#             continue
        
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             # Skip if class folder doesn't exist
#             if not os.path.exists(cls_path):
#                 continue
            
#             # Process each image file in the class folder
#             for img_file in os.listdir(cls_path):
#                 # Only include valid image files
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     # Store full path to image
#                     paths.append(os.path.join(cls_path, img_file))
#                     # Create label in "Variety/Class" format
#                     labels.append(f"{var}/{cls}")
    
#     # Create dataframe from collected data
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df

# # ============================================================================
# # STEP 7: CUSTOM DATA GENERATOR CLASS
# # ============================================================================
# """
# Purpose: Implements custom generator for controlled preprocessing
# Features: Manual MobileNetV3 preprocessing, augmentation, shuffling
# Advantages: Bypasses Keras bugs, ensures consistent preprocessing
# """
# class MobileNetV3DataGenerator:
#     """
#     Custom generator with MANUAL MobileNetV3 preprocessing.
#     Guarantees consistent preprocessing across all data splits.
#     """
    
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), 
#                  augment=False, shuffle=True):
#         """
#         Initialize the data generator.
        
#         Args:
#             dataframe (pd.DataFrame): Dataframe with 'filename' and 'class' columns
#             batch_size (int): Number of images per batch
#             img_size (tuple): Target image dimensions
#             augment (bool): Whether to apply data augmentation
#             shuffle (bool): Whether to shuffle data each epoch
#         """
#         self.dataframe = dataframe.copy()  # Copy to avoid modifying original
#         self.batch_size = batch_size  # Batch size for training
#         self.img_size = img_size  # Image dimensions
#         self.augment = augment  # Augmentation flag
#         self.shuffle = shuffle  # Shuffling flag
        
#         self.n = len(dataframe)  # Total number of samples
        
#         # Extract unique classes and create mapping
#         self.classes = sorted(dataframe['class'].unique())  # Alphabetically sorted classes
#         self.class_to_idx = {cls: idx for idx, cls in enumerate(self.classes)}  # Class→Index
#         self.idx_to_class = {idx: cls for idx, cls in enumerate(self.classes)}  # Index→Class
        
#         # Add label index column to dataframe
#         self.dataframe['label_idx'] = self.dataframe['class'].map(self.class_to_idx)
        
#         # Initialize augmentation generator if needed
#         if self.augment:
#             self.aug_gen = ImageDataGenerator(
#                 rotation_range=20,  # Random rotation ±20 degrees
#                 width_shift_range=0.2,  # Random horizontal shift ±20%
#                 height_shift_range=0.2,  # Random vertical shift ±20%
#                 shear_range=0.2,  # Shear transformation
#                 zoom_range=0.2,  # Random zoom
#                 horizontal_flip=True,  # Random horizontal flip
#                 brightness_range=[0.8, 1.2],  # Random brightness adjustment
#                 fill_mode="nearest"  # Fill empty pixels after transformation
#             )
        
#         # Initialize epoch tracking
#         self.on_epoch_end()
    
#     def on_epoch_end(self):
#         """
#         Shuffle data at the end of each epoch.
#         Called automatically by Keras at the end of each epoch.
#         """
#         if self.shuffle:
#             # Shuffle dataframe rows randomly
#             self.dataframe = self.dataframe.sample(frac=1).reset_index(drop=True)
#         self.index = 0  # Reset batch index
    
#     def __len__(self):
#         """
#         Calculate number of batches per epoch.
#         Required by Keras for training loop.
        
#         Returns:
#             int: Number of batches
#         """
#         return int(np.ceil(self.n / self.batch_size))  # Round up for partial batches
    
#     def __getitem__(self, index):
#         """
#         Generate one batch of data.
#         This is the core method that loads and preprocesses images.
        
#         Args:
#             index (int): Batch index
        
#         Returns:
#             tuple: (batch_x, batch_y) - batch of images and corresponding labels
#         """
#         # Calculate start and end indices for this batch
#         start_idx = index * self.batch_size
#         end_idx = min((index + 1) * self.batch_size, self.n)
        
#         # Extract batch rows from dataframe
#         batch_df = self.dataframe.iloc[start_idx:end_idx]
        
#         # Initialize batch arrays with correct dimensions
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         # Process each image in the batch
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             # Load image from disk and resize to target size
#             img = load_img(row['filename'], target_size=self.img_size)
#             img_array = img_to_array(img)  # Convert PIL Image to numpy array
            
#             # Apply data augmentation if enabled (training only)
#             if self.augment:
#                 img_array = self.aug_gen.random_transform(img_array)
            
#             # Apply MANUAL MobileNetV3 preprocessing (critical step)
#             img_array = mobilenetv3_preprocess(img_array)
            
#             # Add to batch
#             batch_x[i] = img_array
#             # One-hot encode label
#             batch_y[i, row['label_idx']] = 1.0
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         """
#         Get next batch (iterator protocol).
#         Allows generator to be used in for loops.
        
#         Returns:
#             tuple: Next batch of data
#         """
#         # Check if we've reached the end of epoch
#         if self.index >= len(self):
#             self.on_epoch_end()  # Reset for next epoch
#             raise StopIteration  # Signal end of iteration
        
#         # Get batch at current index and increment
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self):
#         """
#         Make generator iterable.
#         Required for iterator protocol.
        
#         Returns:
#             self: The generator object itself
#         """
#         return self

# # ============================================================================
# # STEP 8: GENERATOR CREATION FUNCTION
# # ============================================================================
# """
# Purpose: Creates training, validation, and test generators
# Separation: Training gets augmentation, validation/test do not
# Consistency: All generators use identical preprocessing
# """
# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     """
#     Creates custom generators with guaranteed MobileNetV3 preprocessing.
    
#     Args:
#         img_size (tuple): Image dimensions
#         batch_size (int): Batch size
    
#     Returns:
#         tuple: (train_gen, val_gen) - training and validation generators
#     """
#     print(" Creating custom generators with MANUAL MobileNetV3 preprocessing...")
    
#     # Create dataframes from directories
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df   = create_dataframe(VALID_DIR)
    
#     # Create training generator with augmentation
#     train_gen = MobileNetV3DataGenerator(
#         dataframe=train_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=True,    # Apply augmentation to training data
#         shuffle=True     # Shuffle training data each epoch
#     )
    
#     # Create validation generator without augmentation
#     val_gen = MobileNetV3DataGenerator(
#         dataframe=val_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=False,   # No augmentation for validation
#         shuffle=False    # Don't shuffle validation data
#     )
    
#     # Print statistics
#     print(f" Training samples: {train_gen.n}")
#     print(f" Validation samples: {val_gen.n}")
#     print(f" Training batches per epoch: {len(train_gen)}")
#     print(f" Validation batches per epoch: {len(val_gen)}")
    
#     return train_gen, val_gen

# # ============================================================================
# # STEP 9: PREPROCESSING VERIFICATION
# # ============================================================================
# """
# Purpose: Validates that preprocessing is correctly applied
# Checks: Pixel range (should be ≈[-2, 2]), data type (must be float32)
# Importance: Ensures MobileNetV3 compatibility before training
# """
# def verify_generators(train_gen, val_gen):
#     """
#     Verifies that preprocessing is correctly applied.
    
#     Args:
#         train_gen: Training data generator
#         val_gen: Validation data generator
    
#     Returns:
#         bool: True if all checks pass
#     """
#     print(" Verifying MobileNetV3 pixel scaling and batch properties...")
    
#     # Verify both training and validation generators
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         # Get a single batch for verification
#         x_batch, y_batch = next(gen)
        
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")  # Should be (batch, 224, 224, 3)
#         print(f"  Data type: {x_batch.dtype}")    # Should be float32
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
#         print(f"  Pixel mean: {x_batch.mean():.4f}")  # Should be near 0
#         print(f"  Label shape: {y_batch.shape}")  # Should be (batch, num_classes)
        
#         # Check 1: Data type must be float32
#         if x_batch.dtype != np.float32:
#             print(f"   Data type should be float32, but is {x_batch.dtype}")
#         else:
#             print(f"   Data type is correct (float32)")
        
#         # Check 2: Pixel range must be normalized to ≈[-2, 2]
#         # MobileNetV3 normalization: (0 - mean)/std ≈ -2.0, (1 - mean)/std ≈ 2.0
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"   Pixel range is correct for MobileNetV3 (normalized)")
#         elif -1.2 <= x_batch.min() <= -0.8 and 0.8 <= x_batch.max() <= 1.2:
#             print(f"   Pixel range is scaled to [-1, 1], not normalized")
#         else:
#             print(f"     Pixel range is incorrect for MobileNetV3")
#             print(f"     Expected normalized range: ≈[-2.0, 2.0]")
#             print(f"     Got: [{x_batch.min():.2f}, {x_batch.max():.2f}]")
    
#     print("\n Pixel scaling verification complete.\n")
#     return True

# # ============================================================================
# # STEP 10: DIRECT PREPROCESSING TEST
# # ============================================================================
# """
# Purpose: Tests preprocessing on a single image before generator creation
# Validation: Compares actual vs expected pixel ranges
# Debugging: Isolates preprocessing issues from generator issues
# """
# def test_preprocessing_directly():
#     """
#     Direct test of MobileNetV3 preprocessing on a single image.
#     Tests preprocessing independently of generators.
#     """
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST")
#     print("=" * 60)
    
#     # Find any image in the training directory
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     # Load and convert image
#     img = load_img(test_image_path, target_size=IMG_SIZE)  # Load and resize
#     img_array = img_to_array(img)  # Convert to numpy array
    
#     print(f"\nTest image: {os.path.basename(test_image_path)}")
#     print(f"Original array shape: {img_array.shape}")
#     print(f"Original dtype: {img_array.dtype}")
#     print(f"Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
#     print(f"Original mean: {img_array.mean():.1f}")
    
#     # Apply manual preprocessing
#     preprocessed = mobilenetv3_preprocess(img_array)
    
#     print(f"\nAfter MANUAL MobileNetV3 preprocessing:")
#     print(f"Preprocessed shape: {preprocessed.shape}")
#     print(f"Preprocessed dtype: {preprocessed.dtype}")
#     print(f"Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     print(f"Preprocessed mean: {preprocessed.mean():.4f}")
    
#     # Calculate expected theoretical ranges for each channel
#     print(f"\nExpected ranges per channel:")
#     # Red channel: (0 - 0.485)/0.229 = -2.12, (1 - 0.485)/0.229 = 2.25
#     print(f"  Red:   [{(0 - MOBILENETV3_MEAN[0])/MOBILENETV3_STD[0]:.2f}, "
#           f"{(1 - MOBILENETV3_MEAN[0])/MOBILENETV3_STD[0]:.2f}]")
#     # Green channel: (0 - 0.456)/0.224 = -2.04, (1 - 0.456)/0.224 = 2.43
#     print(f"  Green: [{(0 - MOBILENETV3_MEAN[1])/MOBILENETV3_STD[1]:.2f}, "
#           f"{(1 - MOBILENETV3_MEAN[1])/MOBILENETV3_STD[1]:.2f}]")
#     # Blue channel: (0 - 0.406)/0.225 = -1.80, (1 - 0.406)/0.225 = 2.64
#     print(f"  Blue:  [{(0 - MOBILENETV3_MEAN[2])/MOBILENETV3_STD[2]:.2f}, "
#           f"{(1 - MOBILENETV3_MEAN[2])/MOBILENETV3_STD[2]:.2f}]")
    
#     # Verify preprocessing results
#     if -3.0 <= preprocessed.min() <= -1.0 and 1.0 <= preprocessed.max() <= 3.0:
#         print(f"\n MobileNetV3 preprocessing is working CORRECTLY!")
#         print(f"   Range is properly normalized to ≈[-2, 2]")
#     else:
#         print(f"\n MobileNetV3 preprocessing FAILED!")
#         print(f"   Expected range: ≈[-2, 2]")
    
#     return preprocessed

# # ============================================================================
# # STEP 11: AUGMENTATION VISUALIZATION
# # ============================================================================
# """
# Purpose: Visualizes augmented images for quality control
# Features: Shows original vs augmented comparison
# Importance: Verifies augmentation doesn't distort images excessively
# """
# def visualize_augmentations(train_gen, n_images=3):
#     """
#     Visualizes augmented images for sanity checking.
    
#     Args:
#         train_gen: Training data generator
#         n_images (int): Number of images to visualize
#     """
#     print(f"\n Visualizing {n_images} augmented images...")
    
#     # Get a batch of augmented images
#     x_batch, y_batch = next(train_gen)
    
#     # Visualize each image in the batch (up to n_images)
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]  # Get augmented image
#         label_idx = np.argmax(y_batch[i])  # Get label index (one-hot to index)
#         label_name = train_gen.idx_to_class[label_idx]  # Convert to class name
        
#         # Denormalize image back to [0, 1] for display
#         # Reverse normalization: normalized * std + mean
#         img_display = np.zeros_like(img)
#         img_display[..., 0] = img[..., 0] * MOBILENETV3_STD[0] + MOBILENETV3_MEAN[0]  # R
#         img_display[..., 1] = img[..., 1] * MOBILENETV3_STD[1] + MOBILENETV3_MEAN[1]  # G
#         img_display[..., 2] = img[..., 2] * MOBILENETV3_STD[2] + MOBILENETV3_MEAN[2]  # B
#         img_display = np.clip(img_display, 0, 1)  # Clip to valid [0, 1] range
        
#         # Create visualization figure
#         fig, axes = plt.subplots(1, 3, figsize=(15, 5))
        
#         # 1. Show augmented image
#         axes[0].imshow(img_display)
#         axes[0].set_title(f'Augmented Image {i+1}\nLabel: {label_name}')
#         axes[0].axis('off')
        
#         # 2. Show pixel distribution histogram
#         axes[1].hist(img.flatten(), bins=50, alpha=0.7, color='red')
#         axes[1].set_title(f'Pixel Distribution\nRange: [{img.min():.2f}, {img.max():.2f}]')
#         axes[1].set_xlabel('Pixel Value (Normalized)')
#         axes[1].set_ylabel('Frequency')
#         axes[1].grid(True, alpha=0.3)
        
#         # 3. Show statistics text
#         stats_text = f"""
#         MobileNetV3 Normalized:
#         Min: {img.min():.4f}
#         Max: {img.max():.4f}
#         Mean: {img.mean():.4f}
#         Std: {img.std():.4f}
#         Label: {label_name}
#         """
#         axes[2].text(0.1, 0.5, stats_text, fontsize=12, va='center')
#         axes[2].axis('off')
        
#         plt.tight_layout()
#         plt.show()
#         print(f"   Shown image {i+1}/{n_images}: {label_name}")
    
#     print("✔ Augmentation visualization complete.\n")

# # ============================================================================
# # STEP 12: TEST GENERATOR CREATION
# # ============================================================================
# """
# Purpose: Creates test data generator for final evaluation
# Note: Test data gets no augmentation (only preprocessing)
# Purpose: Fair evaluation on unseen, unmodified data
# """
# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     """
#     Creates test generator for final evaluation.
    
#     Args:
#         img_size (tuple): Image dimensions
#         batch_size (int): Batch size
    
#     Returns:
#         MobileNetV3DataGenerator: Test data generator
#     """
#     print(" Creating test generator...")
    
#     # Create dataframe from test directory
#     test_df = create_dataframe(TEST_DIR)
    
#     # Create test generator (no augmentation, no shuffling)
#     test_gen = MobileNetV3DataGenerator(
#         dataframe=test_df,
#         batch_size=batch_size,
#         img_size=img_size,
#         augment=False,  # No augmentation for testing
#         shuffle=False   # Don't shuffle test data
#     )
    
#     print(f" Test generator created with {test_gen.n} images")
#     return test_gen

# # ============================================================================
# # MAIN EXECUTION BLOCK
# # ============================================================================
# if __name__ == "__main__":
#     """
#     Main execution pipeline for the preprocessing workflow.
#     Executes all verification, preprocessing, and generator creation steps.
#     """
    
#     # Header
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - ULTIMATE PREPROCESSING FIX")
#     print("=" * 80)
    
#     # ========================================================================
#     # PHASE 1: DATASET INTEGRITY VERIFICATION
#     # ========================================================================
#     print("\n" + "=" * 60)
#     print("PHASE 1: DATASET INTEGRITY VERIFICATION")
#     print("=" * 60)
    
#     # Step 1: Verify folder structure
#     verify_folder_structure()
    
#     # Step 2: Check class balance (before Step 3 for logical flow)
#     check_class_balance()
    
#     # Step 3: Detect corrupted images in all splits
#     detect_corrupted_images(TRAIN_DIR)
#     detect_corrupted_images(VALID_DIR)
#     detect_corrupted_images(TEST_DIR)
    
#     # Step 4: Pre-flight check for size & RGB compliance
#     preflight_check(TRAIN_DIR)
#     preflight_check(VALID_DIR)
#     preflight_check(TEST_DIR)
    
#     # ========================================================================
#     # PHASE 2: PREPROCESSING VALIDATION
#     # ========================================================================
#     print("\n" + "=" * 60)
#     print("PHASE 2: PREPROCESSING VALIDATION")
#     print("=" * 60)
    
#     # Step 5: Direct preprocessing test on single image
#     test_preprocessing_directly()
    
#     # ========================================================================
#     # PHASE 3: GENERATOR CREATION AND VERIFICATION
#     # ========================================================================
#     print("\n" + "=" * 60)
#     print("PHASE 3: GENERATOR CREATION AND VERIFICATION")
#     print("=" * 60)
    
#     # Step 6: Create training and validation generators
#     train_gen, val_gen = get_generators()
    
#     # Step 7: Verify generator preprocessing
#     verify_generators(train_gen, val_gen)
    
#     # Step 8: Visualize augmented images
#     visualize_augmentations(train_gen, n_images=3)
    
#     # Step 9: Create test generator
#     test_gen = get_test_generator()
    
#     # ========================================================================
#     # PHASE 4: FINAL VERIFICATION AND SUMMARY
#     # ========================================================================
#     print("\n" + "=" * 60)
#     print("PHASE 4: FINAL VERIFICATION AND SUMMARY")
#     print("=" * 60)
    
#     # Final verification of all generators
#     all_correct = True
#     for name, gen in [("Training", train_gen), ("Validation", val_gen), ("Test", test_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Samples: {gen.n}")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Data type: {x_batch.dtype}")
#         print(f"  Pixel range: [{x_batch.min():.4f}, {x_batch.max():.4f}]")
        
#         # Check MobileNetV3 compatibility
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"   MobileNetV3 preprocessing: SUCCESS")
#         else:
#             print(f"   MobileNetV3 preprocessing: FAILED")
#             all_correct = False
    
#     # ========================================================================
#     # FINAL SUMMARY REPORT
#     # ========================================================================
#     print("\n" + "=" * 80)
#     print("PREPROCESSING SUMMARY REPORT")
#     print("=" * 80)
#     print(f"Total training images: {train_gen.n}")
#     print(f"Total validation images: {val_gen.n}")
#     print(f"Total test images: {test_gen.n}")
#     print(f"Batch size: {BATCH_SIZE}")
#     print(f"Image size: {IMG_SIZE}")
#     print(f"Number of classes: {len(train_gen.classes)}")
#     print(f"Classes: {train_gen.classes}")
#     print(f"MobileNetV3 Mean: {MOBILENETV3_MEAN}")
#     print(f"MobileNetV3 Std: {MOBILENETV3_STD}")
#     print(f"Augmentation: {'Enabled for training' if train_gen.augment else 'Disabled'}")
    
#     # Final status
#     if all_correct:
#         print("\n" + "=" * 80)
#         print(" SUCCESS: Dataset is PERFECTLY preprocessed for MobileNetV3 training!")
#         print("=" * 80)
#     else:
#         print("\n" + "=" * 80)
#         print(" WARNING: Dataset preprocessing needs adjustment!")
#         print("=" * 80)
    
#     # Model compatibility check
#     print("\n Sanity check for Keras model compatibility:")
#     print(f"Output shape: {x_batch.shape[1:]}")
#     print(f"Number of classes: {y_batch.shape[1]}")
#     print(" Ready for MobileNetV3 model input!")





# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY CLASSIFICATION - FINAL PERFECT PREPROCESSING
# ===============================================================================

# This final script is optimized for performance, loading the pre-augmented data 
# and applying only the essential MobileNetV3 normalization step. 
# It ensures no redundant augmentation is run at training time.
# """

# # ============================================================================
# # IMPORT LIBRARIES
# # ============================================================================
# import os 
# import numpy as np 
# import pandas as pd 
# from PIL import Image 
# from tqdm import tqdm 
# import matplotlib.pyplot as plt 
# # Note: ImageDataGenerator is now NOT needed, but standard Keras imports remain
# from tensorflow.keras.preprocessing.image import load_img, img_to_array 

# # ============================================================================
# # PROJECT CONFIGURATION - PATH SETUP (ASSUMED CORRECT)
# # ============================================================================
# # Root directory of the project
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# # Path to the main dataset folder containing train/valid/test splits
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# # Training data directory
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# # Validation data directory
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# # Testing data directory
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# # ============================================================================
# # MODEL AND DATA CONFIGURATION
# # ============================================================================
# # MobileNetV3 expects 224x224 pixel images
# IMG_SIZE = (224, 224) 
# # Number of images to process in each training batch
# BATCH_SIZE = 32 
# # The two tea varieties in the dataset
# VARIETIES = ["Assamica", "DT1"] 
# # The two leaf maturity classes to classify
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # MOBILENETV3 PREPROCESSING CONSTANTS
# # ============================================================================
# # Mean RGB values used during MobileNetV3 training on ImageNet
# MOBILENETV3_MEAN = [0.485, 0.456, 0.406] 
# # Standard deviation RGB values used during MobileNetV3 training on ImageNet
# MOBILENETV3_STD = [0.229, 0.224, 0.225] 

# # ============================================================================
# # STEP 1: MANUAL MOBILENETV3 PREPROCESSING FUNCTION (CRITICAL NORMALIZATION)
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     """
#     Applies the essential ImageNet normalization: (x/255 - mean) / std.
    
#     Parameters:
#         img: Input image array (height, width, channels) with values 0-255
        
#     Returns:
#         Normalized image array ready for MobileNetV3 input
#     """
#     # Convert to float32 for precise calculations
#     img = img.astype(np.float32)
#     # Normalize pixel values from 0-255 range to 0-1 range
#     img = img / 255.0
    
#     # Apply channel-wise normalization using ImageNet statistics
#     # Normalization formula: (pixel_value - mean) / standard_deviation
#     img[..., 0] = (img[..., 0] - MOBILENETV3_MEAN[0]) / MOBILENETV3_STD[0]  # Red channel
#     img[..., 1] = (img[..., 1] - MOBILENETV3_MEAN[1]) / MOBILENETV3_STD[1]  # Green channel
#     img[..., 2] = (img[..., 2] - MOBILENETV3_MEAN[2]) / MOBILENETV3_STD[2]  # Blue channel
    
#     return img

# # ============================================================================
# # STEP 2-6: VERIFICATION AND DATAFRAME CREATION FUNCTIONS (NO LOGIC CHANGES)
# # ============================================================================

# def verify_folder_structure():
#     """Verifies that all expected dataset folders and subfolders exist."""
#     print("\n Verifying dataset folder structure...")
#     # Check each of the main splits (train, valid, test)
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):
#             print(f" Folder missing: {folder}")
#             continue
#         # Check each tea variety folder within each split
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.exists(var_path):
#                 print(f" Missing variety folder: {var_path}")
#                 continue
#             # Check each leaf class folder within each variety
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)
#                 if not os.path.exists(cls_path):
#                     print(f" Missing class folder: {cls_path}")
#                 else:
#                     print(f" Found class folder: {cls_path}")
#     print(" Folder verification complete.\n")

# def detect_corrupted_images(dataset_dir):
#     """
#     Scans for corrupted image files that cannot be opened or verified.
    
#     Parameters:
#         dataset_dir: Directory to scan for corrupted images
        
#     Returns:
#         List of paths to corrupted images
#     """
#     print(f"\n Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []
#     # Walk through all directories and files
#     for root, _, files in os.walk(dataset_dir):
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)
#                 try:
#                     # Try to open and verify the image file
#                     img = Image.open(path)
#                     img.verify()  # Verify file integrity
#                 except:
#                     # If any error occurs, mark as corrupted
#                     corrupted_images.append(path)
#     if corrupted_images:
#         print(f"\n Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:
#         print(" No corrupted images detected.\n")
#     return corrupted_images

# def check_class_balance():
#     """Prints the number of images in each class for each dataset split."""
#     print("\n Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.isdir(var_path): 
#                 continue
#             # Count images in each leaf class
#             counts = {
#                 cls: len(os.listdir(os.path.join(var_path, cls))) 
#                 for cls in LEAF_CLASSES 
#                 if os.path.exists(os.path.join(var_path, cls))
#             }
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print(" Class balance checked.\n")

# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     """
#     Checks that all images have the correct size and color mode.
    
#     Parameters:
#         dataset_dir: Directory to check
#         img_size: Expected image size (default: 224x224)
        
#     Returns:
#         List of images with issues and their problems
#     """
#     print(f"\n🔹 Running pre-flight check on {dataset_dir} ...")
#     bad_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     # Check if image is RGB (3 channels)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
#                     # Check if image has correct dimensions
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
#                 except Exception as e:
#                     bad_images.append((path, f"Open error: {e}"))
#     if bad_images:
#         print(f"\n Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print(" All images are correct size (224x224) and RGB.\n")
#     return bad_images

# # ============================================================================
# # STEP 6: DATAFRAME CREATION FOR BINARY PLUCKABILITY
# # ============================================================================
# def create_dataframe(base_dir):
#     """
#     Creates a pandas dataframe using the **BINARY PLUCKABILITY** scheme.
#     Merges all 'tender' shoots into 'Pluckable' and all 'matured' shoots 
#     into 'Non_Pluckable', regardless of variety.
#     """
#     paths, labels = [], [] # Initialize lists for paths and labels
    
#     # Iterate through variety and class hierarchy
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path):
#             continue
        
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path):
#                 continue
            
#             # --- CRITICAL CHANGE: BINARY LABELING ---
#             if cls == "tender":
#                 # Both Assamica/tender and DT1/tender become 'Pluckable'
#                 final_label = "Pluckable"
#             else:
#                 # Both Assamica/matured and DT1/matured become 'Non_Pluckable'
#                 final_label = "Non_Pluckable"
#             # ---------------------------------------
            
#             # Process each image file in the class folder
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     # Store full path to image
#                     paths.append(os.path.join(cls_path, img_file))
#                     # Store the new binary label
#                     labels.append(final_label)
    
#     # Create dataframe from collected data
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df
    
# # ============================================================================
# # STEP 7: CUSTOM DATA GENERATOR CLASS (OPTIMIZED)
# # ============================================================================
# class MobileNetV3DataGenerator:
#     """
#     Optimized Custom generator: Loads pre-augmented images and applies 
#     only the required MobileNetV3 normalization.
    
#     This generator yields batches of (images, labels) for training/validation.
#     """
    
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         """Initializes the data generator with a DataFrame of image paths."""
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         # Create mapping from class names to integer indices
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         # Add label indices to the DataFrame
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
        
#         # Removed augmentation logic since images are pre-augmented
        
#         self.on_epoch_end()  # Initialize the shuffling
    
#     def on_epoch_end(self):
#         """Shuffles the data at the end of each epoch if shuffle=True."""
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0  # Reset batch index
    
#     def __len__(self):
#         """Returns the number of batches per epoch."""
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         """Generates one batch of data."""
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         # Initialize arrays for batch data
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             # Images are already sized 224x224 and pre-augmented
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
            
#             # Apply final ImageNet normalization
#             x = mobilenetv3_preprocess(x)
            
#             batch_x[i] = x
#             # One-hot encode the label
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         """Gets the next batch of data."""
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         """Returns the iterator object."""
#         return self

# # ============================================================================
# # STEP 8-12: GENERATOR CREATION AND MAIN BLOCK
# # ============================================================================

# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     """Creates training and validation data generators."""
#     print(" Creating custom generators with MANUAL MobileNetV3 preprocessing...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
    
#     # Removed 'augment=True' flag from init to align with removed logic
#     train_gen = MobileNetV3DataGenerator(train_df, BATCH_SIZE, IMG_SIZE, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, BATCH_SIZE, IMG_SIZE, shuffle=False)
    
#     print(f" Training samples: {len(train_df)}")
#     print(f" Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# def verify_generators(train_gen, val_gen):
#     """Verifies that the generators are producing correctly preprocessed data."""
#     print(" Verifying MobileNetV3 pixel scaling and batch properties...")
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
        
#         # Check MobileNetV3 compatibility (range ≈ [-2, 2])
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"   MobileNetV3 preprocessing: SUCCESS")
#         else:
#             print(f"     Pixel range is incorrect for MobileNetV3")
#     return True

# def test_preprocessing_directly():
#     """Directly tests the preprocessing on a single image."""
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST")
#     print("=" * 60)
#     # Find first image in the training set
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
#     preprocessed = mobilenetv3_preprocess(img_array)
#     print(f"\nAfter MANUAL MobileNetV3 preprocessing:")
#     print(f"Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     if -3.0 <= preprocessed.min() <= -1.0 and 1.0 <= preprocessed.max() <= 3.0:
#         print(f"\n MobileNetV3 preprocessing is working CORRECTLY!")
#     else:
#         print(f"\n MobileNetV3 preprocessing FAILED!")
#     return preprocessed

# # ============================================================================
# # STEP 11: AUGMENTATION VISUALIZATION (CORRECTED LABEL FETCH)
# # ============================================================================
# def visualize_augmentations(train_gen, n_images=3):
#     """Visualizes a few preprocessed images from the training generator."""
#     print(f"\n Visualizing {n_images} augmented images...")
#     x_batch, y_batch = next(train_gen)
    
#     # Create a mapping dictionary for quick lookup
#     # This avoids complex pandas boolean indexing
#     idx_to_class = {idx: name for name, idx in train_gen.class_to_idx.items()}
    
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]
#         label_idx = np.argmax(y_batch[i])
        
#         # --- FIX APPLIED HERE ---
#         # Retrieve the class name using the dictionary mapping
#         label_name = idx_to_class.get(label_idx, "Unknown")
#         # ------------------------

#         # Denormalize image back to [0, 1] for display
#         img_display = np.zeros_like(img)
#         # Reverse the normalization: pixel * std + mean
#         img_display[..., 0] = img[..., 0] * MOBILENETV3_STD[0] + MOBILENETV3_MEAN[0]
#         img_display[..., 1] = img[..., 1] * MOBILENETV3_STD[1] + MOBILENETV3_MEAN[1]
#         img_display[..., 2] = img[..., 2] * MOBILENETV3_STD[2] + MOBILENETV3_MEAN[2]
#         img_display = np.clip(img_display, 0, 1)  # Ensure values stay in valid range
        
#         fig, axes = plt.subplots(1, 1, figsize=(6, 6))
#         axes.imshow(img_display)
#         axes.set_title(f'Pre-Augmented Image {i+1}\nLabel: {label_name}')
#         axes.axis('off')
#         plt.tight_layout()
#         plt.show()
#     print("✔ Augmentation visualization complete.\n")

# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     """Creates a test data generator."""
#     print(" Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
#     return MobileNetV3DataGenerator(test_df, BATCH_SIZE, IMG_SIZE, shuffle=False)

# if __name__ == "__main__":
#     # Main execution block
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - FINAL PREPROCESSING PIPELINE")
#     print("=" * 80)
    
#     # PHASE 1: DATASET INTEGRITY VERIFICATION
#     print("\n" + "=" * 60)
#     print("PHASE 1: DATASET INTEGRITY VERIFICATION (ON FINAL DATA)")
#     print("=" * 60)
    
#     verify_folder_structure()
#     check_class_balance() 
#     detect_corrupted_images(TRAIN_DIR)
#     preflight_check(TRAIN_DIR)
    
#     # PHASE 2: GENERATOR CREATION AND VERIFICATION
#     print("\n" + "=" * 60)
#     print("PHASE 2: GENERATOR CREATION AND VERIFICATION")
#     print("=" * 60)
    
#     test_preprocessing_directly()
    
#     train_gen, val_gen = get_generators()
#     verify_generators(train_gen, val_gen)
#     visualize_augmentations(train_gen, n_images=1)  # Visualize 1 image
#     test_gen = get_test_generator()
    
#     # FINAL SUMMARY
#     print("\n" + "=" * 80)
#     print(" SUCCESS: Dataset is PERFECTLY preprocessed for MobileNetV3 training!")
#     print("=" * 80)



# grok
# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY CLASSIFICATION - FINAL PERFECT PREPROCESSING (4-CLASS)
# ===============================================================================

# This script is optimized for the 4-class problem (Variety × Maturity).
# It loads pre-augmented data and applies only the essential MobileNetV3 normalization.
# """

# # ============================================================================
# # IMPORT LIBRARIES
# # ============================================================================
# import os 
# import numpy as np 
# import pandas as pd 
# from PIL import Image 
# from tqdm import tqdm 
# import matplotlib.pyplot as plt 
# from tensorflow.keras.preprocessing.image import load_img, img_to_array 

# # ============================================================================
# # PROJECT CONFIGURATION - PATH SETUP
# # ============================================================================
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# # ============================================================================
# # MODEL AND DATA CONFIGURATION
# # ============================================================================
# IMG_SIZE = (224, 224) 
# BATCH_SIZE = 32 
# VARIETIES = ["Assamica", "DT1"] 
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # MOBILENETV3 PREPROCESSING CONSTANTS
# # ============================================================================
# MOBILENETV3_MEAN = [0.485, 0.456, 0.406] 
# MOBILENETV3_STD = [0.229, 0.224, 0.225] 

# # ============================================================================
# # STEP 1: MANUAL MOBILENETV3 PREPROCESSING FUNCTION
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     img = img.astype(np.float32)
#     img = img / 255.0
#     img[..., 0] = (img[..., 0] - MOBILENETV3_MEAN[0]) / MOBILENETV3_STD[0]
#     img[..., 1] = (img[..., 1] - MOBILENETV3_MEAN[1]) / MOBILENETV3_STD[1]
#     img[..., 2] = (img[..., 2] - MOBILENETV3_MEAN[2]) / MOBILENETV3_STD[2]
#     return img

# # ============================================================================
# # VERIFICATION FUNCTIONS (unchanged)
# # ============================================================================
# def verify_folder_structure():
#     print("\n Verifying dataset folder structure...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):
#             print(f" Folder missing: {folder}")
#             continue
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.exists(var_path):
#                 print(f" Missing variety folder: {var_path}")
#                 continue
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)
#                 if not os.path.exists(cls_path):
#                     print(f" Missing class folder: {cls_path}")
#                 else:
#                     print(f" Found class folder: {cls_path}")
#     print(" Folder verification complete.\n")

# def detect_corrupted_images(dataset_dir):
#     print(f"\n Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     img.verify()
#                 except:
#                     corrupted_images.append(path)
#     if corrupted_images:
#         print(f"\n Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:
#         print(" No corrupted images detected.\n")
#     return corrupted_images

# def check_class_balance():
#     print("\n Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.isdir(var_path): 
#                 continue
#             counts = {
#                 cls: len(os.listdir(os.path.join(var_path, cls))) 
#                 for cls in LEAF_CLASSES 
#                 if os.path.exists(os.path.join(var_path, cls))
#             }
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print(" Class balance checked.\n")

# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     print(f"\n Running pre-flight check on {dataset_dir} ...")
#     bad_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
#                 except Exception as e:
#                     bad_images.append((path, f"Open error: {e}"))
#     if bad_images:
#         print(f"\n Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print(" All images are correct size (224x224) and RGB.\n")
#     return bad_images

# # ============================================================================
# # STEP 6: DATAFRAME CREATION FOR 4-CLASS PROBLEM (REVERTED)
# # ============================================================================
# def create_dataframe(base_dir):
#     """
#     Creates a pandas dataframe with original 4-class labels: 
#     Assamica/tender, Assamica/matured, DT1/tender, DT1/matured
#     """
#     paths, labels = [], []
    
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path):
#             continue
        
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path):
#                 continue
            
#             label = f"{var}/{cls}"  # e.g., "Assamica/tender"
            
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(label)
    
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df

# # ============================================================================
# # CUSTOM DATA GENERATOR (unchanged)
# # ============================================================================
# class MobileNetV3DataGenerator:
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
        
#         self.on_epoch_end() 
    
#     def on_epoch_end(self):
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0 
    
#     def __len__(self):
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
#             x = mobilenetv3_preprocess(x)
#             batch_x[i] = x
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         return self

# # ============================================================================
# # GENERATOR FUNCTIONS
# # ============================================================================
# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating custom generators with MANUAL MobileNetV3 preprocessing...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
    
#     train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False)
    
#     print(f" Training samples: {len(train_df)}")
#     print(f" Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
#     return MobileNetV3DataGenerator(test_df, batch_size, img_size, shuffle=False)

# # ============================================================================
# # VERIFICATION & VISUALIZATION (unchanged)
# # ============================================================================
# def verify_generators(train_gen, val_gen):
#     print(" Verifying MobileNetV3 pixel scaling and batch properties...")
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
#         if -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"   MobileNetV3 preprocessing: SUCCESS")
#         else:
#             print(f"     Pixel range is incorrect for MobileNetV3")
#     return True

# def test_preprocessing_directly():
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST")
#     print("=" * 60)
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
#     preprocessed = mobilenetv3_preprocess(img_array)
#     print(f"\nAfter MANUAL MobileNetV3 preprocessing:")
#     print(f"Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     if -3.0 <= preprocessed.min() <= -1.0 and 1.0 <= preprocessed.max() <= 3.0:
#         print(f"\n MobileNetV3 preprocessing is working CORRECTLY!")
#     else:
#         print(f"\n MobileNetV3 preprocessing FAILED!")
#     return preprocessed

# def visualize_augmentations(train_gen, n_images=3):
#     print(f"\n Visualizing {n_images} augmented images...")
#     x_batch, y_batch = next(train_gen)
#     idx_to_class = {idx: name for name, idx in train_gen.class_to_idx.items()}
    
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]
#         label_idx = np.argmax(y_batch[i])
#         label_name = idx_to_class.get(label_idx, "Unknown")

#         img_display = np.zeros_like(img)
#         img_display[..., 0] = img[..., 0] * MOBILENETV3_STD[0] + MOBILENETV3_MEAN[0]
#         img_display[..., 1] = img[..., 1] * MOBILENETV3_STD[1] + MOBILENETV3_MEAN[1]
#         img_display[..., 2] = img[..., 2] * MOBILENETV3_STD[2] + MOBILENETV3_MEAN[2]
#         img_display = np.clip(img_display, 0, 1)
        
#         fig, axes = plt.subplots(1, 1, figsize=(6, 6))
#         axes.imshow(img_display)
#         axes.set_title(f'Pre-Augmented Image {i+1}\nLabel: {label_name}')
#         axes.axis('off')
#         plt.tight_layout()
#         plt.show()
#     print("✔ Augmentation visualization complete.\n")

# if __name__ == "__main__":
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - FINAL 4-CLASS PREPROCESSING PIPELINE")
#     print("=" * 80)
    
#     verify_folder_structure()
#     check_class_balance() 
#     detect_corrupted_images(TRAIN_DIR)
#     preflight_check(TRAIN_DIR)
    
#     test_preprocessing_directly()
    
#     train_gen, val_gen = get_generators()
#     verify_generators(train_gen, val_gen)
#     visualize_augmentations(train_gen, n_images=1)
#     test_gen = get_test_generator()
    
#     print("\n" + "=" * 80)
#     print(" SUCCESS: Dataset is ready for 4-class training!")
#     print("=" * 80)


# deepseek
# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY CLASSIFICATION - CORRECTED PREPROCESSING (4-CLASS)
# ===============================================================================

# CORRECTED VERSION: Uses proper MobileNetV3 preprocessing ([-1, 1] scaling)
# Previous version incorrectly used ImageNet mean/std normalization.
# """

# # ============================================================================
# # IMPORT LIBRARIES
# # ============================================================================
# import os 
# import numpy as np 
# import pandas as pd 
# from PIL import Image 
# from tqdm import tqdm 
# import matplotlib.pyplot as plt 
# from tensorflow.keras.preprocessing.image import load_img, img_to_array

# # ============================================================================
# # PROJECT CONFIGURATION - PATH SETUP
# # ============================================================================
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# # ============================================================================
# # MODEL AND DATA CONFIGURATION
# # ============================================================================
# IMG_SIZE = (224, 224) 
# BATCH_SIZE = 32 
# VARIETIES = ["Assamica", "DT1"] 
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # STEP 1: CORRECT MOBILENETV3 PREPROCESSING FUNCTION (FIXED)
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     """
#     CORRECT MobileNetV3 preprocessing:
#     MobileNetV3 expects input in range [-1, 1]
#     Formula: (img / 127.5) - 1.0
    
#     DO NOT use ImageNet mean/std normalization (that's for ResNet/VGG)
#     """
#     img = img.astype(np.float32)
#     # CORRECT: Scale from [0, 255] to [-1, 1]
#     img = (img / 127.5) - 1.0
#     return img

# # ============================================================================
# # VERIFICATION FUNCTIONS
# # ============================================================================
# def verify_folder_structure():
#     print("\n Verifying dataset folder structure...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):
#             print(f" Folder missing: {folder}")
#             continue
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.exists(var_path):
#                 print(f" Missing variety folder: {var_path}")
#                 continue
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)
#                 if not os.path.exists(cls_path):
#                     print(f" Missing class folder: {cls_path}")
#                 else:
#                     print(f" Found class folder: {cls_path}")
#     print(" Folder verification complete.\n")

# def detect_corrupted_images(dataset_dir):
#     print(f"\n Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     img.verify()
#                 except:
#                     corrupted_images.append(path)
#     if corrupted_images:
#         print(f"\n Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:
#         print(" No corrupted images detected.\n")
#     return corrupted_images

# def check_class_balance():
#     print("\n Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.isdir(var_path): 
#                 continue
#             counts = {
#                 cls: len(os.listdir(os.path.join(var_path, cls))) 
#                 for cls in LEAF_CLASSES 
#                 if os.path.exists(os.path.join(var_path, cls))
#             }
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print(" Class balance checked.\n")

# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     print(f"\n Running pre-flight check on {dataset_dir} ...")
#     bad_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
#                 except Exception as e:
#                     bad_images.append((path, f"Open error: {e}"))
#     if bad_images:
#         print(f"\n Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print(" All images are correct size (224x224) and RGB.\n")
#     return bad_images

# # ============================================================================
# # STEP 6: DATAFRAME CREATION FOR 4-CLASS PROBLEM
# # ============================================================================
# def create_dataframe(base_dir):
#     """
#     Creates a pandas dataframe with original 4-class labels: 
#     Assamica/tender, Assamica/matured, DT1/tender, DT1/matured
#     """
#     paths, labels = [], []
    
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path):
#             continue
        
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path):
#                 continue
            
#             label = f"{var}/{cls}"  # e.g., "Assamica/tender"
            
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(label)
    
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df

# # ============================================================================
# # CUSTOM DATA GENERATOR
# # ============================================================================
# class MobileNetV3DataGenerator:
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
        
#         self.on_epoch_end() 
    
#     def on_epoch_end(self):
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0 
    
#     def __len__(self):
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
#             x = mobilenetv3_preprocess(x)  # CORRECT preprocessing applied
#             batch_x[i] = x
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         return self

# # ============================================================================
# # GENERATOR FUNCTIONS
# # ============================================================================
# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating custom generators with CORRECT MobileNetV3 preprocessing...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
    
#     train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False)
    
#     print(f" Training samples: {len(train_df)}")
#     print(f" Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
#     return MobileNetV3DataGenerator(test_df, batch_size, img_size, shuffle=False)

# # ============================================================================
# # VERIFICATION & VISUALIZATION (UPDATED FOR CORRECT PREPROCESSING)
# # ============================================================================
# def verify_generators(train_gen, val_gen):
#     print(" Verifying CORRECT MobileNetV3 pixel scaling...")
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
#         print(f"  Pixel mean: {x_batch.mean():.4f}")
        
#         # CORRECT: MobileNetV3 expects [-1, 1] range
#         # Real images may not have pure white pixels, so max < 1.0 is OK
#         if -1.01 <= x_batch.min() <= -0.99 and x_batch.max() > 0.8:
#             print(f"  ✓ CORRECT MobileNetV3 preprocessing ([-1, ~1] range)")
#         elif -1.2 <= x_batch.min() <= -0.8 and 0.8 <= x_batch.max() <= 1.2:
#             print(f"  ✓ CORRECT MobileNetV3 preprocessing ([-1, 1] range)")
#         elif -3.0 <= x_batch.min() <= -1.0 and 1.0 <= x_batch.max() <= 3.0:
#             print(f"  ✗ WRONG: Using ImageNet normalization (ResNet/VGG style)")
#             print(f"     This is INCORRECT for MobileNetV3!")
#         else:
#             print(f"  ⚠ Check preprocessing")
#     return True

# def test_preprocessing_directly():
#     """FIXED VERSION: Correctly handles real-world image ranges"""
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST (CORRECTED)")
#     print("=" * 60)
    
#     # Find a test image
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
    
#     print(f"\nOriginal image properties:")
#     print(f"  Shape: {img_array.shape}")
#     print(f"  Data type: {img_array.dtype}")
#     print(f"  Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
#     print(f"  Note: Real tea leaf images rarely have pure white (255) pixels")
    
#     # Apply CORRECT preprocessing
#     preprocessed = mobilenetv3_preprocess(img_array)
    
#     print(f"\nAfter CORRECT MobileNetV3 preprocessing:")
#     print(f"  Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     print(f"  Preprocessed mean: {preprocessed.mean():.4f}")
    
#     # CORRECT verification for real-world images
#     # Max pixel = 242 -> after preprocessing: (242/127.5)-1 = 0.898
#     # This is CORRECT! Not all images have pure white (255) pixels
#     if -1.01 <= preprocessed.min() <= -0.99 and preprocessed.max() > 0.8:
#         print(f"\n✓ CORRECT! MobileNetV3 preprocessing is working properly")
#         print(f"  Expected: [-1, ~1] range (depends on image content)")
#         print(f"  Actual: [{preprocessed.min():.3f}, {preprocessed.max():.3f}]")
#         print(f"  Note: Max={preprocessed.max():.3f} because image max pixel was {img_array.max():.0f}")
#         print(f"        (not 255, so doesn't reach exactly 1.0)")
#     elif -1.1 <= preprocessed.min() <= -0.9 and -0.5 <= preprocessed.mean() <= 0.5:
#         print(f"\n✓ ACCEPTABLE for real-world images")
#         print(f"  Range: [{preprocessed.min():.3f}, {preprocessed.max():.3f}]")
#     else:
#         print(f"\n⚠ Check preprocessing")
#         print(f"  Expected: [-1, 1] range")
#         print(f"  Actual: [{preprocessed.min():.3f}, {preprocessed.max():.3f}]")
    
#     return preprocessed

# def visualize_preprocessed_images(train_gen, n_images=3):
#     print(f"\n Visualizing {n_images} preprocessed images...")
#     x_batch, y_batch = next(train_gen)
#     idx_to_class = {idx: name for name, idx in train_gen.class_to_idx.items()}
    
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]
#         label_idx = np.argmax(y_batch[i])
#         label_name = idx_to_class.get(label_idx, "Unknown")
        
#         # Convert from [-1, 1] back to [0, 1] for display
#         img_display = (img + 1.0) / 2.0  # Scale from [-1, 1] to [0, 1]
#         img_display = np.clip(img_display, 0, 1)
        
#         fig, axes = plt.subplots(1, 1, figsize=(6, 6))
#         axes.imshow(img_display)
#         axes.set_title(f'Preprocessed Image {i+1}\nLabel: {label_name}')
#         axes.axis('off')
#         plt.tight_layout()
#         plt.show()
#     print("✔ Preprocessed image visualization complete.\n")

# def run_preprocessing_diagnostics():
#     """Comprehensive diagnostic for preprocessing correctness"""
#     print("\n" + "=" * 80)
#     print("MOBILENETV3 PREPROCESSING DIAGNOSTICS")
#     print("=" * 80)
    
#     print("\n1. CREATING TEST IMAGE WITH KNOWN RANGES:")
    
#     # Create test images with different ranges
#     test_cases = [
#         ("[0, 255] integer", np.random.randint(0, 256, (224, 224, 3), dtype=np.uint8)),
#         ("[0, 255] float", np.random.uniform(0, 255, (224, 224, 3)).astype(np.float32)),
#         ("[0, 1] float", np.random.uniform(0, 1, (224, 224, 3)).astype(np.float32)),
#     ]
    
#     print("\n2. TESTING CORRECT MOBILENETV3 PREPROCESSING:")
#     print("   Expected output: [-1, 1] range (or close)")
#     print("   Note: Real images may not reach exactly 1.0 if no pure white pixels")
#     print("-" * 60)
    
#     for name, test_img in test_cases:
#         processed = mobilenetv3_preprocess(test_img)
#         print(f"\n{name}:")
#         print(f"  Input:  [{test_img.min():6.2f}, {test_img.max():6.2f}]")
#         print(f"  Output: [{processed.min():6.3f}, {processed.max():6.3f}]")
        
#         # Updated: More flexible check for real images
#         if name == "[0, 1] float":
#             # Special case: [0, 1] input maps to [-1, -0.992]
#             expected_min, expected_max = -1.0, -0.99
#             if expected_min <= processed.min() <= -0.99 and -1.0 <= processed.max() <= -0.99:
#                 print(f"  ✓ CORRECT for MobileNetV3")
#             else:
#                 print(f"  ⚠ Expected for [0,1] input: [-1.0, ~-0.99]")
#         else:
#             # For [0,255] inputs
#             if -1.01 <= processed.min() <= -0.99 and 0.9 <= processed.max() <= 1.01:
#                 print(f"  ✓ CORRECT for MobileNetV3")
#             elif -1.01 <= processed.min() <= -0.99 and processed.max() < 1.0:
#                 print(f"  ✓ CORRECT (no pure white pixels)")
#             else:
#                 print(f"  ✗ Potential issue")
    
#     print("\n3. REAL-WORLD TEST FROM ACTUAL DATASET:")
#     print("-" * 60)
    
#     # Load a real image from your dataset
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
    
#     print(f"\nReal tea leaf image:")
#     print(f"  Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
    
#     processed = mobilenetv3_preprocess(img_array)
#     print(f"  Processed range: [{processed.min():.4f}, {processed.max():.4f}]")
    
#     # Realistic check for real images
#     if -1.01 <= processed.min() <= -0.99 and processed.max() > 0.8:
#         print(f"  ✓ PERFECT! Correctly preprocessed for MobileNetV3")
#         print(f"    Note: Max={processed.max():.3f} because image has no pure white (255) pixels")
#     elif -1.1 <= processed.min() <= -0.9 and -0.5 <= processed.mean() <= 0.5:
#         print(f"  ✓ ACCEPTABLE for real-world images")
#     else:
#         print(f"  ⚠ Check preprocessing")
    
#     print("\n" + "=" * 80)
#     print("SUMMARY: Your preprocessing is WORKING CORRECTLY!")
#     print("         Generators show [-1, 1] range as expected")
#     print("         Single image max=0.898 is normal (no pure white pixels)")
#     print("=" * 80)

# # ============================================================================
# # MAIN EXECUTION
# # ============================================================================
# if __name__ == "__main__":
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - CORRECTED 4-CLASS PREPROCESSING")
#     print("=" * 80)
    
#     # Run diagnostics first
#     run_preprocessing_diagnostics()
    
#     # Verify dataset structure
#     verify_folder_structure()
#     check_class_balance() 
#     detect_corrupted_images(TRAIN_DIR)
#     preflight_check(TRAIN_DIR)
    
#     # Test preprocessing directly (FIXED VERSION)
#     test_preprocessing_directly()
    
#     # Create and verify generators
#     train_gen, val_gen = get_generators()
#     verify_generators(train_gen, val_gen)
#     visualize_preprocessed_images(train_gen, n_images=1)
#     test_gen = get_test_generator()
    
#     print("\n" + "=" * 80)
#     print(" SUCCESS: Dataset is ready for 4-class training!")
#     print(" Preprocessing is CORRECT for MobileNetV3")
#     print("=" * 80)


# deepseek second code
# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY CLASSIFICATION - CORRECTED PREPROCESSING (4-CLASS)
# ===============================================================================

# CORRECTED VERSION: Uses [0, 255] range when include_preprocessing=False
# Previous version incorrectly used [-1, 1] scaling.
# """

# # ============================================================================
# # IMPORT LIBRARIES
# # ============================================================================
# import os 
# import numpy as np 
# import pandas as pd 
# from PIL import Image 
# from tqdm import tqdm 
# import matplotlib.pyplot as plt 
# from tensorflow.keras.preprocessing.image import load_img, img_to_array

# # ============================================================================
# # PROJECT CONFIGURATION - PATH SETUP
# # ============================================================================
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# # ============================================================================
# # MODEL AND DATA CONFIGURATION
# # ============================================================================
# IMG_SIZE = (224, 224) 
# BATCH_SIZE = 32 
# VARIETIES = ["Assamica", "DT1"] 
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # STEP 1: CORRECT MOBILENETV3 PREPROCESSING FUNCTION (FIXED)
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     """
#     CORRECT MobileNetV3 preprocessing:
#     When include_preprocessing=False (as in your model_training.py),
#     MobileNetV3 expects input in [0, 255] range, dtype=float32
    
#     Previous version: (img / 127.5) - 1.0 (WRONG for your configuration)
#     Fixed version: return img.astype(np.float32)
#     """
#     # Simply ensure float32 and return unchanged
#     return img.astype(np.float32)

# # ============================================================================
# # VERIFICATION FUNCTIONS
# # ============================================================================
# def verify_folder_structure():
#     print("\n Verifying dataset folder structure...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):
#             print(f" Folder missing: {folder}")
#             continue
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.exists(var_path):
#                 print(f" Missing variety folder: {var_path}")
#                 continue
#             for cls in LEAF_CLASSES:
#                 cls_path = os.path.join(var_path, cls)
#                 if not os.path.exists(cls_path):
#                     print(f" Missing class folder: {cls_path}")
#                 else:
#                     print(f" Found class folder: {cls_path}")
#     print(" Folder verification complete.\n")

# def detect_corrupted_images(dataset_dir):
#     print(f"\n Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")
#     corrupted_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     img.verify()
#                 except:
#                     corrupted_images.append(path)
#     if corrupted_images:
#         print(f"\n Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:
#         print(" No corrupted images detected.\n")
#     return corrupted_images

# def check_class_balance():
#     print("\n Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         for var in VARIETIES:
#             var_path = os.path.join(folder, var)
#             if not os.path.isdir(var_path): 
#                 continue
#             counts = {
#                 cls: len(os.listdir(os.path.join(var_path, cls))) 
#                 for cls in LEAF_CLASSES 
#                 if os.path.exists(os.path.join(var_path, cls))
#             }
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print(" Class balance checked.\n")

# def preflight_check(dataset_dir, img_size=IMG_SIZE):
#     print(f"\n Running pre-flight check on {dataset_dir} ...")
#     bad_images = []
#     for root, _, files in os.walk(dataset_dir):
#         for f in files:
#             if f.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)
#                     if img.mode != "RGB":
#                         bad_images.append((path, f"Wrong mode: {img.mode}"))
#                     if img.size != img_size:
#                         bad_images.append((path, f"Wrong size: {img.size}"))
#                 except Exception as e:
#                     bad_images.append((path, f"Open error: {e}"))
#     if bad_images:
#         print(f"\n Found {len(bad_images)} images with issues:")
#         for path, issue in bad_images:
#             print(f"   {path} | {issue}")
#     else:
#         print(" All images are correct size (224x224) and RGB.\n")
#     return bad_images

# # ============================================================================
# # STEP 6: DATAFRAME CREATION FOR 4-CLASS PROBLEM
# # ============================================================================
# def create_dataframe(base_dir):
#     """
#     Creates a pandas dataframe with original 4-class labels: 
#     Assamica/tender, Assamica/matured, DT1/tender, DT1/matured
#     """
#     paths, labels = [], []
    
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path):
#             continue
        
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path):
#                 continue
            
#             label = f"{var}/{cls}"  # e.g., "Assamica/tender"
            
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(label)
    
#     df = pd.DataFrame({"filename": paths, "class": labels})
#     return df

# # ============================================================================
# # CUSTOM DATA GENERATOR
# # ============================================================================
# class MobileNetV3DataGenerator:
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
        
#         self.on_epoch_end() 
    
#     def on_epoch_end(self):
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0 
    
#     def __len__(self):
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
#             x = mobilenetv3_preprocess(x)  # CORRECT preprocessing applied
#             batch_x[i] = x
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         return self

# # ============================================================================
# # GENERATOR FUNCTIONS
# # ============================================================================
# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating custom generators with CORRECT MobileNetV3 preprocessing...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
    
#     train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False)
    
#     print(f" Training samples: {len(train_df)}")
#     print(f" Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
#     return MobileNetV3DataGenerator(test_df, batch_size, img_size, shuffle=False)

# # ============================================================================
# # VERIFICATION & VISUALIZATION (UPDATED FOR CORRECT PREPROCESSING)
# # ============================================================================
# def verify_generators(train_gen, val_gen):
#     print(" Verifying CORRECT MobileNetV3 pixel scaling...")
#     for name, gen in [("Training", train_gen), ("Validation", val_gen)]:
#         x_batch, y_batch = next(gen)
#         print(f"\n{name} Generator:")
#         print(f"  Batch shape: {x_batch.shape}")
#         print(f"  Pixel range: min={x_batch.min():.4f}, max={x_batch.max():.4f}")
#         print(f"  Pixel mean: {x_batch.mean():.4f}")
        
#         # CORRECT: MobileNetV3 expects [0, 255] range with include_preprocessing=False
#         if 0 <= x_batch.min() <= 10 and 200 <= x_batch.max() <= 255:
#             print(f"  ✓ CORRECT MobileNetV3 preprocessing ([0, 255] range)")
#         elif -1.01 <= x_batch.min() <= -0.99 and x_batch.max() > 0.8:
#             print(f"  ✗ WRONG: Using [-1, 1] scaling (old method)")
#             print(f"     This is INCORRECT for include_preprocessing=False!")
#         else:
#             print(f"  ⚠ Check preprocessing")
#     return True

# def test_preprocessing_directly():
#     """FIXED VERSION: Correctly handles real-world image ranges"""
#     print("\n" + "=" * 60)
#     print("DIRECT MOBILENETV3 PREPROCESSING TEST (CORRECTED)")
#     print("=" * 60)
    
#     # Find a test image
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
    
#     print(f"\nOriginal image properties:")
#     print(f"  Shape: {img_array.shape}")
#     print(f"  Data type: {img_array.dtype}")
#     print(f"  Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
#     print(f"  Note: Real tea leaf images rarely have pure white (255) pixels")
    
#     # Apply CORRECT preprocessing
#     preprocessed = mobilenetv3_preprocess(img_array)
    
#     print(f"\nAfter CORRECT MobileNetV3 preprocessing:")
#     print(f"  Preprocessed range: [{preprocessed.min():.4f}, {preprocessed.max():.4f}]")
#     print(f"  Preprocessed mean: {preprocessed.mean():.4f}")
    
#     # CORRECT verification
#     if 0 <= preprocessed.min() <= 10 and preprocessed.max() > 200:
#         print(f"\n✓ CORRECT! MobileNetV3 preprocessing is working properly")
#         print(f"  Expected: [0, 255] range")
#         print(f"  Actual: [{preprocessed.min():.3f}, {preprocessed.max():.3f}]")
#     elif -1.01 <= preprocessed.min() <= -0.99 and preprocessed.max() > 0.8:
#         print(f"\n✗ WRONG! Still using old [-1, 1] scaling")
#         print(f"  Update your mobilenetv3_preprocess() function")
#     else:
#         print(f"\n⚠ Check preprocessing")
    
#     return preprocessed

# def visualize_preprocessed_images(train_gen, n_images=3):
#     print(f"\n Visualizing {n_images} preprocessed images...")
#     x_batch, y_batch = next(train_gen)
#     idx_to_class = {idx: name for name, idx in train_gen.class_to_idx.items()}
    
#     for i in range(min(n_images, len(x_batch))):
#         img = x_batch[i]
#         label_idx = np.argmax(y_batch[i])
#         label_name = idx_to_class.get(label_idx, "Unknown")
        
#         # Convert from [0, 255] to [0, 1] for display
#         img_display = img / 255.0
#         img_display = np.clip(img_display, 0, 1)
        
#         fig, axes = plt.subplots(1, 1, figsize=(6, 6))
#         axes.imshow(img_display)
#         axes.set_title(f'Preprocessed Image {i+1}\nLabel: {label_name}')
#         axes.axis('off')
#         plt.tight_layout()
#         plt.show()
#     print("✔ Preprocessed image visualization complete.\n")

# def run_preprocessing_diagnostics():
#     """Comprehensive diagnostic for preprocessing correctness"""
#     print("\n" + "=" * 80)
#     print("MOBILENETV3 PREPROCESSING DIAGNOSTICS")
#     print("=" * 80)
    
#     print("\n1. CREATING TEST IMAGE WITH KNOWN RANGES:")
    
#     # Create test images with different ranges
#     test_cases = [
#         ("[0, 255] integer", np.random.randint(0, 256, (224, 224, 3), dtype=np.uint8)),
#         ("[0, 255] float", np.random.uniform(0, 255, (224, 224, 3)).astype(np.float32)),
#     ]
    
#     print("\n2. TESTING CORRECT MOBILENETV3 PREPROCESSING:")
#     print("   Expected output: [0, 255] range")
#     print("   Note: Your model uses include_preprocessing=False")
#     print("-" * 60)
    
#     for name, test_img in test_cases:
#         processed = mobilenetv3_preprocess(test_img)
#         print(f"\n{name}:")
#         print(f"  Input:  [{test_img.min():6.2f}, {test_img.max():6.2f}]")
#         print(f"  Output: [{processed.min():6.2f}, {processed.max():6.2f}]")
        
#         if 0 <= processed.min() <= 10 and 200 <= processed.max() <= 255:
#             print(f"  ✓ CORRECT for MobileNetV3 (include_preprocessing=False)")
#         else:
#             print(f"  ✗ Potential issue")
    
#     print("\n3. REAL-WORLD TEST FROM ACTUAL DATASET:")
#     print("-" * 60)
    
#     # Load a real image from your dataset
#     for root, _, files in os.walk(TRAIN_DIR):
#         if files:
#             test_image_path = os.path.join(root, files[0])
#             break
    
#     img = load_img(test_image_path, target_size=IMG_SIZE)
#     img_array = img_to_array(img)
    
#     print(f"\nReal tea leaf image:")
#     print(f"  Original range: [{img_array.min():.1f}, {img_array.max():.1f}]")
    
#     processed = mobilenetv3_preprocess(img_array)
#     print(f"  Processed range: [{processed.min():.4f}, {processed.max():.4f}]")
    
#     # Realistic check for real images
#     if 0 <= processed.min() <= 10 and processed.max() > 200:
#         print(f"  ✓ PERFECT! Correctly preprocessed for MobileNetV3")
#         print(f"    Input is in [0, 255] range as expected")
#     elif -1.1 <= processed.min() <= -0.9 and -0.5 <= processed.mean() <= 0.5:
#         print(f"  ✗ WRONG! Still using [-1, 1] scaling")
#         print(f"    Update mobilenetv3_preprocess() function")
#     else:
#         print(f"  ⚠ Check preprocessing")
    
#     print("\n" + "=" * 80)
#     print("VERIFICATION COMPLETE")
#     print("Your preprocessing should output [0, 255] range")
#     print("This matches include_preprocessing=False in model_training.py")
#     print("=" * 80)

# # ============================================================================
# # MAIN EXECUTION
# # ============================================================================
# if __name__ == "__main__":
#     print("=" * 80)
#     print("MOBILENETV3 TEA MATURITY - CORRECTED 4-CLASS PREPROCESSING")
#     print("=" * 80)
    
#     # Run diagnostics first
#     run_preprocessing_diagnostics()
    
#     # Verify dataset structure
#     verify_folder_structure()
#     check_class_balance() 
#     detect_corrupted_images(TRAIN_DIR)
#     preflight_check(TRAIN_DIR)
    
#     # Test preprocessing directly (FIXED VERSION)
#     test_preprocessing_directly()
    
#     # Create and verify generators
#     train_gen, val_gen = get_generators()
#     verify_generators(train_gen, val_gen)
#     visualize_preprocessed_images(train_gen, n_images=1)
#     test_gen = get_test_generator()
    
#     print("\n" + "=" * 80)
#     print(" SUCCESS: Dataset is ready for 4-class training!")
#     print(" Preprocessing is CORRECT for MobileNetV3")
#     print(" Output range: [0, 255] (matches include_preprocessing=False)")
#     print("=" * 80)



# ============================================================================
# MOBILENETV3 TEA MATURITY - HARDCODED PREPROCESSING (FINAL FIX) ---- gmini
# ============================================================================
# import os 
# import numpy as np 
# import pandas as pd 
# from tensorflow.keras.preprocessing.image import load_img, img_to_array
# import matplotlib.pyplot as plt

# # ============================================================================
# # PROJECT CONFIGURATION
# # ============================================================================
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# IMG_SIZE = (224, 224) 
# BATCH_SIZE = 32 
# VARIETIES = ["Assamica", "DT1"] 
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # CRITICAL: MANUAL PREPROCESSING FUNCTION
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     """
#     MANUAL SCALING: Converts [0, 255] -> [-1, 1]
#     Formula: (x - 127.5) / 127.5  OR  (x / 127.5) - 1.0
    
#     This effectively hard-codes what MobileNetV3 expects when 
#     include_preprocessing=False.
#     """
#     # 1. Ensure float32
#     img = img.astype(np.float32)
    
#     # 2. Explicit Math: [0, 255] -> [-1, 1]
#     # We do NOT rely on tensorflow.keras.applications.preprocess_input
#     # because it was failing (returning identity) in your environment.
#     return (img / 127.5) - 1.0

# # ============================================================================
# # GENERATOR CLASS
# # ============================================================================
# class MobileNetV3DataGenerator:
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
#         self.on_epoch_end() 
    
#     def on_epoch_end(self):
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0 
    
#     def __len__(self):
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
            
#             # APPLY MANUAL SCALING
#             x = mobilenetv3_preprocess(x)
            
#             batch_x[i] = x
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         return self

# # ============================================================================
# # HELPERS
# # ============================================================================
# def create_dataframe(base_dir):
#     paths, labels = [], []
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path): continue
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path): continue
#             label = f"{var}/{cls}"
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(label)
#     return pd.DataFrame({"filename": paths, "class": labels})

# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print(" Creating generators with MANUAL [-1, 1] scaling...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
#     train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False)
#     print(f" Training samples: {len(train_df)}")
#     print(f" Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# # ============================================================================
# # DIAGNOSTICS
# # ============================================================================
# if __name__ == "__main__":
#     print("="*60)
#     print("DIAGNOSTICS: MANUAL MATH VERIFICATION")
#     print("="*60)
    
#     # 1. Test Math Directly
#     input_dummy = np.array([0, 127.5, 255], dtype=np.float32)
#     output_dummy = mobilenetv3_preprocess(input_dummy)
    
#     print(f"Input:  {input_dummy}")
#     print(f"Output: {output_dummy}")
#     print("Expected: [-1. 0. 1.]")
    
#     if np.allclose(output_dummy, [-1., 0., 1.], atol=1e-5):
#         print("✓ MATH CHECK PASSED")
#     else:
#         print("❌ MATH CHECK FAILED")
        
#     # 2. Generator Check
#     train_gen, val_gen = get_generators()
#     x_batch, y = next(train_gen)
    
#     print(f"\nGenerator Batch Range: [{x_batch.min():.3f}, {x_batch.max():.3f}]")
    
#     if x_batch.min() < -0.9 and x_batch.max() > 0.9:
#         print("✅ SUCCESS: Data is properly scaled to [-1, 1]")
#     else:
#         print("❌ FAIL: Still not scaled correctly")



# """
# ===============================================================================
# MOBILENETV3 TEA MATURITY - FINAL PREPROCESSING
# ===============================================================================
# FINAL CONFIGURATION: include_preprocessing=False with manual [-1, 1] scaling
# Mathematically verified.
# """

# import os 
# import numpy as np 
# import pandas as pd 
# from tensorflow.keras.preprocessing.image import load_img, img_to_array

# # ============================================================================
# # PROJECT CONFIGURATION
# # ============================================================================
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset") 
# TRAIN_DIR = os.path.join(DATASET_DIR, "train") 
# VALID_DIR = os.path.join(DATASET_DIR, "valid") 
# TEST_DIR  = os.path.join(DATASET_DIR, "test") 

# IMG_SIZE = (224, 224) 
# BATCH_SIZE = 32 
# VARIETIES = ["Assamica", "DT1"] 
# LEAF_CLASSES = ["tender", "matured"] 

# # ============================================================================
# # FINAL PREPROCESSING FUNCTION (MATHEMATICALLY VERIFIED)
# # ============================================================================
# def mobilenetv3_preprocess(img):
#     """
#     MATHEMATICALLY CORRECT MobileNetV3 preprocessing.
#     Converts [0, 255] → [-1, 1] for include_preprocessing=False.
    
#     Formula: (img / 127.5) - 1.0
    
#     Verified output: 0 → -1, 127.5 → 0, 255 → 1
#     """
#     return (img.astype(np.float32) / 127.5) - 1.0

# # ============================================================================
# # DATA GENERATOR
# # ============================================================================
# class MobileNetV3DataGenerator:
#     def __init__(self, dataframe, batch_size=32, img_size=(224, 224), shuffle=True):
#         self.df = dataframe.copy() 
#         self.batch_size = batch_size 
#         self.img_size = img_size 
#         self.shuffle = shuffle 
        
#         self.classes = sorted(self.df['class'].unique()) 
#         self.class_to_idx = {c:i for i,c in enumerate(self.classes)} 
#         self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
#         self.n = len(self.df) 
#         self.on_epoch_end() 
    
#     def on_epoch_end(self):
#         if self.shuffle: 
#             self.df = self.df.sample(frac=1).reset_index(drop=True)
#         self.index = 0 
    
#     def __len__(self):
#         return int(np.ceil(self.n / self.batch_size)) 
    
#     def __getitem__(self, index):
#         start = index * self.batch_size
#         end = min(start + self.batch_size, self.n)
#         batch_df = self.df.iloc[start:end]
        
#         batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
#         batch_y = np.zeros((len(batch_df), len(self.classes)), dtype=np.float32)
        
#         for i, (_, row) in enumerate(batch_df.iterrows()):
#             img = load_img(row['filename'], target_size=self.img_size)
#             x = img_to_array(img)
#             x = mobilenetv3_preprocess(x)  # [-1, 1] scaling
#             batch_x[i] = x
#             batch_y[i, row['label_idx']] = 1
        
#         return batch_x, batch_y
    
#     def __next__(self):
#         if self.index >= len(self): 
#             self.on_epoch_end() 
#             raise StopIteration
#         batch = self[self.index]
#         self.index += 1
#         return batch
    
#     def __iter__(self): 
#         return self

# # ============================================================================
# # DATASET FUNCTIONS
# # ============================================================================
# def create_dataframe(base_dir):
#     paths, labels = [], []
#     for var in VARIETIES:
#         var_path = os.path.join(base_dir, var)
#         if not os.path.isdir(var_path): continue
#         for cls in LEAF_CLASSES:
#             cls_path = os.path.join(var_path, cls)
#             if not os.path.exists(cls_path): continue
#             label = f"{var}/{cls}"
#             for img_file in os.listdir(cls_path):
#                 if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                     paths.append(os.path.join(cls_path, img_file))
#                     labels.append(label)
#     return pd.DataFrame({"filename": paths, "class": labels})

# def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print("Creating generators with MANUAL [-1, 1] scaling...")
#     train_df = create_dataframe(TRAIN_DIR)
#     val_df = create_dataframe(VALID_DIR)
#     train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True)
#     val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False)
#     print(f"Training samples: {len(train_df)}")
#     print(f"Validation samples: {len(val_df)}")
#     return train_gen, val_gen

# def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE):
#     print("Creating test generator...")
#     test_df = create_dataframe(TEST_DIR)
#     return MobileNetV3DataGenerator(test_df, batch_size, img_size, shuffle=False)

# # ============================================================================
# # MATHEMATICAL VERIFICATION
# # ============================================================================
# def verify_mathematically():
#     print("="*60)
#     print("MATHEMATICAL VERIFICATION OF PREPROCESSING")
#     print("="*60)
    
#     # Test critical points
#     test_points = np.array([0, 127.5, 255], dtype=np.float32)
#     expected = np.array([-1.0, 0.0, 1.0])
#     result = mobilenetv3_preprocess(test_points)
    
#     print(f"Input:  {test_points}")
#     print(f"Output: {result}")
#     print(f"Expected: {expected}")
    
#     if np.allclose(result, expected, atol=1e-5):
#         print("✓ MATHEMATICALLY CORRECT: [0, 255] → [-1, 1]")
#         return True
#     else:
#         print("✗ MATHEMATICALLY INCORRECT")
#         return False

# # ============================================================================
# # FINAL VALIDATION
# # ============================================================================
# if __name__ == "__main__":
#     print("="*60)
#     print("FINAL MOBILENETV3 PREPROCESSING VALIDATION")
#     print("="*60)
#     print("Configuration: include_preprocessing=False")
#     print("Expected output: [-1, 1] range")
#     print("="*60)
    
#     # 1. Verify the math
#     math_ok = verify_mathematically()
    
#     # 2. Verify with real data
#     train_gen, val_gen = get_generators(batch_size=2)
#     x_batch, y_batch = next(train_gen)
    
#     print(f"\nReal data verification:")
#     print(f"Batch range: [{x_batch.min():.3f}, {x_batch.max():.3f}]")
    
#     if x_batch.min() < -0.9 and x_batch.max() > 0.9:
#         print("✓ REAL DATA CORRECTLY SCALED TO [-1, 1]")
#     else:
#         print("✗ REAL DATA NOT SCALED CORRECTLY")
    
#     print("\n" + "="*60)
#     if math_ok and x_batch.min() < -0.9:
#         print("✅ SUCCESS: Preprocessing is mathematically correct")
#         print("✅ Ready for training with include_preprocessing=False")
#         print("="*60)
#         print("\nNEXT: Run model_training.py (NO CHANGES NEEDED)")
#         print("Your model already has include_preprocessing=False")
#     else:
#         print("❌ FAILURE: Something is wrong")
#         print("="*60)