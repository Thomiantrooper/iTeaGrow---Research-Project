# # # # # import os
# # # # # import shutil
# # # # # import random
# # # # # import math
# # # # # from glob import glob
# # # # # from tqdm import tqdm
# # # # # from sklearn.model_selection import train_test_split
# # # # # import cv2
# # # # # import albumentations as A

# # # # # # Note: You will need to install scikit-learn for train_test_split and imblearn for SMOTE features.

# # # # # # --- 1. CONFIGURATION ---
# # # # # BASE_INPUT_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset" # <--- POINT THIS TO YOUR RAW, UN-AUGMENTED IMAGES!
# # # # # FINAL_DATASET_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset"

# # # # # # --- 2. PARAMETERS ---
# # # # # TRAIN_RATIO, VALID_RATIO, TEST_RATIO = 0.8, 0.1, 0.1
# # # # # RANDOM_SEED = 42
# # # # # TARGET_IMAGES_PER_CLASS = 1200

# # # # # # --- 3. CLASS & VARIETY MAPPING (Based on your final folder structure) ---
# # # # # # Maps the physical folders to the final class name (e.g., 'DT1/tender')
# # # # # FINAL_CLASSES = {
# # # # #     'DT1/tender': os.path.join(BASE_INPUT_DIR, 'DT1', 'tender'),
# # # # #     'DT1/matured': os.path.join(BASE_INPUT_DIR, 'DT1', 'matured'),
# # # # #     'Assamica/tender': os.path.join(BASE_INPUT_DIR, 'Assamica', 'tender'),
# # # # #     'Assamica/matured': os.path.join(BASE_INPUT_DIR, 'Assamica', 'matured')
# # # # #     # Assuming 'over_matured' was condensed into 'matured' or excluded for the 4-class model
# # # # # }

# # # # # # --- 4. DATA COLLECTION & PRE-SPLIT ---
# # # # # all_files = []
# # # # # all_labels = []

# # # # # print("1. Collecting original file paths...")
# # # # # for label, path_root in FINAL_CLASSES.items():
# # # # #     file_paths = glob(os.path.join(path_root, "*.jpg"))
# # # # #     all_files.extend(file_paths)
# # # # #     all_labels.extend([label] * len(file_paths))

# # # # # print(f"Total original images found: {len(all_files)}")
# # # # # random.seed(RANDOM_SEED)

# # # # # # --- 5. LEAK-PROOF SPLIT (SPLIT FIRST, AUGMENT LATER) ---

# # # # # # First split: Train vs (Validation + Test)
# # # # # X_train, X_temp, y_train, y_temp = train_test_split(
# # # # #     all_files, all_labels, 
# # # # #     test_size=(VALID_RATIO + TEST_RATIO), 
# # # # #     stratify=all_labels, 
# # # # #     random_state=RANDOM_SEED
# # # # # )

# # # # # # Second split: Validation vs Test
# # # # # test_size_ratio = TEST_RATIO / (VALID_RATIO + TEST_RATIO) 
# # # # # X_val, X_test, y_val, y_test = train_test_split(
# # # # #     X_temp, y_temp, 
# # # # #     test_size=test_size_ratio, 
# # # # #     stratify=y_temp, 
# # # # #     random_state=RANDOM_SEED
# # # # # )

# # # # # SPLIT_MAP = {
# # # # #     'train': X_train, 
# # # # #     'valid': X_val, 
# # # # #     'test': X_test
# # # # # }

# # # # # print(f"Split results: Train={len(X_train)}, Valid={len(X_val)}, Test={len(X_test)}")
# # # # # print("2. Copying original images to final dataset structure...")

# # # # # # Clear and recreate the final structure
# # # # # for fold in ['train', 'valid', 'test']:
# # # # #     for label in FINAL_CLASSES.keys():
# # # # #         os.makedirs(os.path.join(FINAL_DATASET_DIR, fold, label.split('/')[0], label.split('/')[1]), exist_ok=True)

# # # # # for fold, file_list in SPLIT_MAP.items():
# # # # #     for src_path in tqdm(file_list, desc=f"Copying {fold} originals"):
# # # # #         # Determine the final sub-folder based on the original path
# # # # #         parts = src_path.split(os.path.sep)
# # # # #         cls_folder = parts[-2] 
# # # # #         var_folder = parts[-3]
        
# # # # #         dst_path = os.path.join(FINAL_DATASET_DIR, fold, var_folder, cls_folder, os.path.basename(src_path))
# # # # #         shutil.copy(src_path, dst_path)

# # # # # print("3. Augmenting ONLY the training set (Train set will be balanced)...")

# # # # # # --- 6. CONDITIONAL AUGMENTATION (SMOTE REPLACEMENT) ---


# # # # # # Use the same augmentation pipeline from your original script
# # # # # augment_pipeline = A.Compose([
# # # # #     A.HorizontalFlip(p=0.5),
# # # # #     A.Rotate(limit=10, p=0.4, border_mode=cv2.BORDER_REPLICATE),
# # # # #     A.RandomBrightnessContrast(brightness_limit=0.08, contrast_limit=0.08, p=0.3),
# # # # #     A.HueSaturationValue(hue_shift_limit=3, sat_shift_limit=5, val_shift_limit=5, p=0.2),
# # # # # ])

# # # # # def augment_to_target(train_dir, target_count=TARGET_IMAGES_PER_CLASS):
    
# # # # #     for var in ['Assamica', 'DT1']:
# # # # #         for cls in ['tender', 'matured']:
# # # # #             class_dir = os.path.join(train_dir, var, cls)
# # # # #             if not os.path.exists(class_dir): continue
            
# # # # #             original_files = glob(os.path.join(class_dir, "*.jpg"))
# # # # #             current_count = len(original_files)
            
# # # # #             if current_count < target_count:
# # # # #                 needed = target_count - current_count
# # # # #                 if needed <= 0: continue
                
# # # # #                 print(f"   -> Augmenting {var}/{cls}: {current_count} -> {target_count} (+{needed} images)")
                
# # # # #                 per_img_extra = math.ceil(needed / current_count)
                
# # # # #                 counter = 0
# # # # #                 for src_path in tqdm(original_files, desc=f"  Generating for {var}/{cls}", leave=False):
# # # # #                     img = cv2.imread(src_path)
# # # # #                     if img is None: continue
                    
# # # # #                     base_name = os.path.splitext(os.path.basename(src_path))[0]
                    
# # # # #                     for i in range(per_img_extra):
# # # # #                         aug_img = augment_pipeline(image=img)["image"]
# # # # #                         out_path = os.path.join(class_dir, f"{base_name}_A{i}_{random.randint(0, 99999)}.jpg")
# # # # #                         cv2.imwrite(out_path, aug_img)
# # # # #                         counter += 1
# # # # #                         if counter >= needed: break
# # # # #                     if counter >= needed: break

# # # # # augment_to_target(os.path.join(FINAL_DATASET_DIR, 'train'))
# # # # # print("\n✅ Data preparation complete. The train/valid/test sets are now leak-proof.")



# # # # import os
# # # # import cv2
# # # # import random
# # # # import numpy as np
# # # # from glob import glob
# # # # from tqdm import tqdm
# # # # import albumentations as A
# # # # from multiprocessing import Pool
# # # # import shutil

# # # # # ==============================================
# # # # # CONFIGURATION - CHANGE THESE PATHS
# # # # # ==============================================
# # # # SOURCE_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset"  # Your original raw images
# # # # TARGET_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset"  # Where to save augmented images

# # # # # BASE_INPUT_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset" # <--- POINT THIS TO YOUR RAW, UN-AUGMENTED IMAGES!
# # # # # FINAL_DATASET_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset"

# # # # # How many total images you want PER CLASS (original + augmented)
# # # # TARGET_COUNT_PER_CLASS = 1200  

# # # # # Split ratios for Train/Valid/Test
# # # # TRAIN_RATIO = 0.8
# # # # VALID_RATIO = 0.1
# # # # TEST_RATIO = 0.1

# # # # # ==============================================
# # # # # ADVANCED AUGMENTATION PIPELINE
# # # # # ==============================================
# # # # def get_augmentation_pipeline():
# # # #     """Returns a strong augmentation pipeline for tea leaves"""
# # # #     return A.Compose([
# # # #         # Geometric transformations
# # # #         A.HorizontalFlip(p=0.5),
# # # #         A.VerticalFlip(p=0.2),
# # # #         A.Rotate(limit=20, p=0.6, border_mode=cv2.BORDER_REFLECT_101),
        
# # # #         # Scale and crop
# # # #         A.RandomResizedCrop(height=224, width=224, scale=(0.7, 1.0), p=0.5),
        
# # # #         # Color transformations
# # # #         A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.5),
# # # #         A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=20, val_shift_limit=10, p=0.5),
        
# # # #         # Noise and blur
# # # #         A.GaussNoise(var_limit=(10.0, 50.0), p=0.3),
# # # #         A.GaussianBlur(blur_limit=(3, 7), p=0.3),
        
# # # #         # Weather effects (optional - makes model robust)
# # # #         A.RandomFog(fog_coef_lower=0.1, fog_coef_upper=0.3, alpha_coef=0.08, p=0.2),
# # # #         A.RandomShadow(num_shadows_lower=1, num_shadows_upper=2, shadow_dimension=5, p=0.2),
        
# # # #         # Quality transformations
# # # #         A.ISONoise(color_shift=(0.01, 0.05), intensity=(0.1, 0.5), p=0.2),
# # # #         A.ImageCompression(quality_lower=60, quality_upper=90, p=0.2),
# # # #     ])

# # # # # ==============================================
# # # # # HELPER FUNCTIONS
# # # # # ==============================================
# # # # def create_augmented_image(img_path, output_path, augment_pipeline, is_augmented=True):
# # # #     """Load image, apply augmentation, and save"""
# # # #     try:
# # # #         # Read image
# # # #         img = cv2.imread(img_path)
# # # #         if img is None:
# # # #             print(f"Warning: Could not read {img_path}")
# # # #             return False
        
# # # #         # Resize to 224x224 if not already
# # # #         if img.shape[:2] != (224, 224):
# # # #             img = cv2.resize(img, (224, 224), interpolation=cv2.INTER_AREA)
        
# # # #         # Apply augmentation if requested
# # # #         if is_augmented:
# # # #             augmented = augment_pipeline(image=img)
# # # #             img = augmented["image"]
        
# # # #         # Save image
# # # #         cv2.imwrite(output_path, img)
# # # #         return True
        
# # # #     except Exception as e:
# # # #         print(f"Error processing {img_path}: {e}")
# # # #         return False

# # # # def augment_class_images(class_name, source_path, target_base_path, augment_pipeline):
# # # #     """Augment images for a single class"""
# # # #     print(f"\n🔧 Augmenting class: {class_name}")
    
# # # #     # Get all original images
# # # #     image_paths = glob(os.path.join(source_path, "*.jpg")) + \
# # # #                   glob(os.path.join(source_path, "*.jpeg")) + \
# # # #                   glob(os.path.join(source_path, "*.png"))
    
# # # #     if not image_paths:
# # # #         print(f"  ⚠ No images found for {class_name}")
# # # #         return []
    
# # # #     original_count = len(image_paths)
# # # #     print(f"  Found {original_count} original images")
    
# # # #     # Calculate how many augmented images we need
# # # #     images_needed = TARGET_COUNT_PER_CLASS - original_count
# # # #     if images_needed <= 0:
# # # #         print(f"  ✓ Already have enough images ({original_count}/{TARGET_COUNT_PER_CLASS})")
# # # #         return image_paths
    
# # # #     print(f"  Need to generate {images_needed} augmented images")
    
# # # #     # Create output directory
# # # #     os.makedirs(target_base_path, exist_ok=True)
    
# # # #     # Copy original images first
# # # #     saved_paths = []
# # # #     for i, img_path in enumerate(tqdm(image_paths, desc="  Copying originals")):
# # # #         filename = os.path.basename(img_path)
# # # #         output_path = os.path.join(target_base_path, f"original_{i:04d}_{filename}")
# # # #         if create_augmented_image(img_path, output_path, augment_pipeline, is_augmented=False):
# # # #             saved_paths.append(output_path)
    
# # # #     # Generate augmented images
# # # #     augmentations_per_image = max(1, images_needed // original_count)
# # # #     print(f"  Generating {augmentations_per_image} variations per image")
    
# # # #     augmented_count = 0
# # # #     for img_idx, img_path in enumerate(tqdm(image_paths, desc="  Creating augmentations")):
# # # #         if augmented_count >= images_needed:
# # # #             break
            
# # # #         for aug_idx in range(augmentations_per_image):
# # # #             if augmented_count >= images_needed:
# # # #                 break
                
# # # #             filename = os.path.basename(img_path)
# # # #             name_without_ext = os.path.splitext(filename)[0]
# # # #             output_path = os.path.join(target_base_path, f"aug_{img_idx:04d}_{aug_idx:03d}_{name_without_ext}.jpg")
            
# # # #             if create_augmented_image(img_path, output_path, augment_pipeline, is_augmented=True):
# # # #                 saved_paths.append(output_path)
# # # #                 augmented_count += 1
    
# # # #     print(f"  ✓ Generated {augmented_count} augmented images")
# # # #     print(f"  ✓ Total for {class_name}: {len(saved_paths)} images")
    
# # # #     return saved_paths

# # # # def split_dataset(augmented_images_dict):
# # # #     """Split augmented images into train/valid/test folders"""
# # # #     print("\n📊 Splitting dataset into train/valid/test...")
    
# # # #     # Create output structure
# # # #     split_structure = {
# # # #         'train': os.path.join(TARGET_DIR, 'train'),
# # # #         'valid': os.path.join(TARGET_DIR, 'valid'),
# # # #         'test': os.path.join(TARGET_DIR, 'test')
# # # #     }
    
# # # #     for split_path in split_structure.values():
# # # #         for variety in ['Assamica', 'DT1']:
# # # #             for maturity in ['tender', 'matured']:
# # # #                 os.makedirs(os.path.join(split_path, variety, maturity), exist_ok=True)
    
# # # #     # Split each class
# # # #     for class_name, image_paths in augmented_images_dict.items():
# # # #         variety, maturity = class_name.split('/')
        
# # # #         # Shuffle images
# # # #         random.shuffle(image_paths)
        
# # # #         # Calculate split indices
# # # #         total = len(image_paths)
# # # #         train_end = int(total * TRAIN_RATIO)
# # # #         valid_end = train_end + int(total * VALID_RATIO)
        
# # # #         # Copy images to respective folders
# # # #         for idx, img_path in enumerate(tqdm(image_paths, desc=f"Splitting {class_name}")):
# # # #             if idx < train_end:
# # # #                 dest_folder = split_structure['train']
# # # #             elif idx < valid_end:
# # # #                 dest_folder = split_structure['valid']
# # # #             else:
# # # #                 dest_folder = split_structure['test']
            
# # # #             dest_path = os.path.join(dest_folder, variety, maturity, os.path.basename(img_path))
# # # #             shutil.copy2(img_path, dest_path)
    
# # # #     print("✅ Dataset split complete!")

# # # # # ==============================================
# # # # # MAIN EXECUTION
# # # # # ==============================================
# # # # def main():
# # # #     print("=" * 80)
# # # #     print("TEA LEAF AUGMENTATION PIPELINE")
# # # #     print("=" * 80)
    
# # # #     # Check source directory
# # # #     if not os.path.exists(SOURCE_DIR):
# # # #         print(f"❌ Source directory not found: {SOURCE_DIR}")
# # # #         return
    
# # # #     # Create target directory
# # # #     os.makedirs(TARGET_DIR, exist_ok=True)
    
# # # #     # Get augmentation pipeline
# # # #     augment_pipeline = get_augmentation_pipeline()
    
# # # #     # Define classes to augment
# # # #     classes_to_augment = {
# # # #         'Assamica/matured': os.path.join(SOURCE_DIR, 'Assamica', 'matured'),
# # # #         'Assamica/tender': os.path.join(SOURCE_DIR, 'Assamica', 'tender'),
# # # #         'DT1/matured': os.path.join(SOURCE_DIR, 'DT1', 'matured'),
# # # #         'DT1/tender': os.path.join(SOURCE_DIR, 'DT1', 'tender')
# # # #     }
    
# # # #     # Augment each class
# # # #     all_augmented_images = {}
# # # #     for class_name, source_path in classes_to_augment.items():
# # # #         target_path = os.path.join(TARGET_DIR, "augmented_temp", class_name.replace('/', '_'))
# # # #         augmented_images = augment_class_images(class_name, source_path, target_path, augment_pipeline)
# # # #         all_augmented_images[class_name] = augmented_images
    
# # # #     # Split into train/valid/test
# # # #     split_dataset(all_augmented_images)
    
# # # #     # Clean up temp directory
# # # #     temp_dir = os.path.join(TARGET_DIR, "augmented_temp")
# # # #     if os.path.exists(temp_dir):
# # # #         shutil.rmtree(temp_dir)
    
# # # #     # Print summary
# # # #     print("\n" + "=" * 80)
# # # #     print("AUGMENTATION SUMMARY")
# # # #     print("=" * 80)
# # # #     for split in ['train', 'valid', 'test']:
# # # #         split_path = os.path.join(TARGET_DIR, split)
# # # #         print(f"\n{split.upper()} SET:")
# # # #         for variety in ['Assamica', 'DT1']:
# # # #             for maturity in ['tender', 'matured']:
# # # #                 class_path = os.path.join(split_path, variety, maturity)
# # # #                 if os.path.exists(class_path):
# # # #                     count = len([f for f in os.listdir(class_path) if f.endswith(('.jpg', '.jpeg', '.png'))])
# # # #                     print(f"  {variety}/{maturity}: {count} images")
    
# # # #     print("\n✅ Augmentation complete! Your data is ready for preprocessing.")
# # # #     print(f"📁 Output directory: {TARGET_DIR}")
# # # #     print("=" * 80)

# # # # if __name__ == "__main__":
# # # #     main()




# # # import os
# # # import cv2
# # # import random
# # # import numpy as np
# # # from glob import glob
# # # from tqdm import tqdm
# # # import albumentations as A
# # # import shutil
# # # from sklearn.model_selection import train_test_split
# # # import math

# # # # ==============================================
# # # # CONFIGURATION
# # # # ==============================================
# # # # IMPORTANT: These paths must be correctly set.
# # # SOURCE_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset" # Your raw, original images
# # # TARGET_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset_augmented_clean" # New, fixed dataset structure

# # # TARGET_COUNT_PER_CLASS = 1200 # Target number of images for the training set
# # # RANDOM_SEED = 42

# # # # Set random seed for reproducibility
# # # random.seed(RANDOM_SEED)
# # # np.random.seed(RANDOM_SEED)

# # # # ==============================================
# # # # 1. AUGMENTATION PIPELINE (Used for Training Set only)
# # # # ==============================================
# # # def get_simple_augmentation():
# # #     """Robust, dynamic augmentation for training set, includes final resize."""
# # #     return A.Compose([
# # #         # Ensure 224x224 after smart-crop for MobileNetV3 input
# # #         A.Resize(224, 224, interpolation=cv2.INTER_AREA), 
# # #         A.HorizontalFlip(p=0.5),
# # #         A.Rotate(limit=10, p=0.3, border_mode=cv2.BORDER_CONSTANT, value=0),
# # #         # Increased regularization to fight over-confidence
# # #         A.RandomBrightnessContrast(brightness_limit=0.1, contrast_limit=0.1, p=0.3), 
# # #         A.HueSaturationValue(hue_shift_limit=5, sat_shift_limit=10, val_shift_limit=5, p=0.3),
# # #     ])

# # # # ==============================================
# # # # 2. IMAGE PROCESSING FUNCTIONS (Handling Smart Crop and Resize)
# # # # ==============================================

# # # def smart_crop_background(img, padding=10):
# # #     """Remove black background and crop/resize to 224x224."""
# # #     if img is None: return None
    
# # #     # Convert to grayscale
# # #     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    
# # #     # Create mask (non-black pixels)
# # #     _, mask = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)
    
# # #     contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
# # #     if contours:
# # #         largest_contour = max(contours, key=cv2.contourArea)
# # #         x, y, w, h = cv2.boundingRect(largest_contour)
        
# # #         # Add padding and ensure bounds are within image limits
# # #         h, w_orig, _ = img.shape
# # #         x = max(0, x - padding)
# # #         y = max(0, y - padding)
# # #         w = min(w_orig - x, w + 2*padding)
# # #         h = min(h - y, h + 2*padding)
        
# # #         cropped = img[y:y+h, x:x+w]
        
# # #         # Resize to 224x224
# # #         resized = cv2.resize(cropped, (224, 224), interpolation=cv2.INTER_AREA)
# # #         return resized
    
# # #     # If no contours found (all black or invalid image), resize the whole thing
# # #     return cv2.resize(img, (224, 224), interpolation=cv2.INTER_AREA)


# # # def process_image(img_path, output_path, augment_pipeline, is_augmented=False):
# # #     """Loads, processes (smart-crops), and optionally augments a single image."""
# # #     try:
# # #         img = cv2.imread(img_path)
# # #         if img is None: return False
        
# # #         # Ensure 3 channels
# # #         if len(img.shape) == 2: img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
# # #         if img.shape[2] != 3: img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
        
# # #         # 1. Apply Smart Cropping and Resizing to 224x224 (Base Processing)
# # #         img = smart_crop_background(img)

# # #         if img is None or img.mean() < 5: return False # Skip dark/invalid images
        
# # #         # 2. Apply Augmentation (Only for the Training Set)
# # #         if is_augmented and augment_pipeline:
# # #             # Augment pipeline includes the final 224x224 resize
# # #             augmented = augment_pipeline(image=img)
# # #             img = augmented["image"]
        
# # #         # 3. Save the final image
# # #         cv2.imwrite(output_path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
# # #         return True
        
# # #     except Exception as e:
# # #         print(f"Error processing {img_path}: {e}")
# # #         return False

# # # # ==============================================
# # # # 3. LEAK-PROOF DATA PREP MAIN FUNCTION
# # # # ==============================================

# # # def run_leak_proof_data_prep():
# # #     print("=" * 80)
# # #     print("TEA LEAF AUGMENTATION (LEAK-PROOF METHOD)")
# # #     print("=" * 80)

# # #     # Clean target directory before starting
# # #     if os.path.exists(TARGET_DIR):
# # #         shutil.rmtree(TARGET_DIR)
# # #     os.makedirs(TARGET_DIR)
    
# # #     # 1. Collect all original files and labels
# # #     all_files, all_labels = [], []
# # #     classes_map = {
# # #         'Assamica/matured': os.path.join(SOURCE_DIR, 'Assamica', 'matured'),
# # #         'Assamica/tender': os.path.join(SOURCE_DIR, 'Assamica', 'tender'),
# # #         'DT1/matured': os.path.join(SOURCE_DIR, 'DT1', 'matured'),
# # #         'DT1/tender': os.path.join(SOURCE_DIR, 'DT1', 'tender')
# # #     }

# # #     for label in classes_map.keys():
# # #         var, maturity = label.split('/')
# # #         source_path = os.path.join(SOURCE_DIR, var, maturity)
        
# # #         image_paths = glob(os.path.join(source_path, "*.jpg"))
# # #         all_files.extend(image_paths)
# # #         all_labels.extend([label] * len(image_paths))

# # #     print(f"📊 Found {len(all_files)} total original images across 4 classes.")

# # #     # 2. LEAK-PROOF SPLIT (80/10/10 on Original Files)
# # #     X_train, X_temp, y_train, y_temp = train_test_split(
# # #         all_files, all_labels, test_size=0.2, stratify=all_labels, random_state=RANDOM_SEED
# # #     )
# # #     X_valid, X_test, y_valid, y_test = train_test_split(
# # #         X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=RANDOM_SEED
# # #     )

# # #     SPLIT_DATA = {
# # #         'train': (X_train, y_train), 
# # #         'valid': (X_valid, y_valid), 
# # #         'test': (X_test, y_test)
# # #     }
# # #     print(f"Split size: Train={len(X_train)}, Valid={len(X_valid)}, Test={len(X_test)}")

# # #     # 3. Process and Copy Valid/Test sets (Resizing only)
# # #     # These sets are now finalized and clean.
# # #     print("\n📦 Step 1: Processing Validation and Test sets (RESIZING ONLY)...")
# # #     total_valid_test = 0
# # #     for fold in ['valid', 'test']:
# # #         files, labels = SPLIT_DATA[fold]
# # #         for src_path, label in tqdm(zip(files, labels), total=len(files), desc=f"  Copying {fold}"):
# # #             var, maturity = label.split('/')
# # #             dest_dir = os.path.join(TARGET_DIR, fold, var, maturity)
# # #             os.makedirs(dest_dir, exist_ok=True)
            
# # #             output_path = os.path.join(dest_dir, os.path.basename(src_path))
# # #             # No augmentation: is_augmented=False
# # #             if process_image(src_path, output_path, None, is_augmented=False):
# # #                 total_valid_test += 1

# # #     # 4. Process and Augment Training Set
# # #     print("\n🧪 Step 2: Processing and Augmenting Training Set...")
# # #     train_files, train_labels = SPLIT_DATA['train']
    
# # #     # Organize training originals by class
# # #     train_originals_by_class = {}
# # #     for path, label in zip(train_files, train_labels):
# # #         if label not in train_originals_by_class:
# # #             train_originals_by_class[label] = []
# # #         train_originals_by_class[label].append(path)

# # #     augment_pipeline = get_simple_augmentation()
# # #     total_generated = 0
    
# # #     for label, originals in train_originals_by_class.items():
# # #         var, maturity = label.split('/')
# # #         train_class_dir = os.path.join(TARGET_DIR, 'train', var, maturity)
# # #         os.makedirs(train_class_dir, exist_ok=True)
        
# # #         current_count = len(originals)
# # #         images_needed = TARGET_COUNT_PER_CLASS - current_count
        
# # #         if images_needed <= 0:
# # #             print(f"  {label}: Already enough ({current_count}). Copying originals.")
# # #             for src_path in originals:
# # #                  output_path = os.path.join(train_class_dir, os.path.basename(src_path))
# # #                  process_image(src_path, output_path, None, is_augmented=False)
# # #             continue
            
# # #         print(f"  {label}: Augmenting {current_count} -> {TARGET_COUNT_PER_CLASS} (+{images_needed})")
        
# # #         # Copy originals first (which are resized)
# # #         for i, src_path in enumerate(originals):
# # #             output_path = os.path.join(train_class_dir, os.path.basename(src_path))
# # #             process_image(src_path, output_path, None, is_augmented=False)
        
# # #         # Determine how many times to re-use each image
# # #         aug_per_image = max(1, math.ceil(images_needed / current_count))
# # #         augmented_created = 0
        
# # #         with tqdm(total=images_needed, desc=f"  Generating {label}") as pbar:
# # #             while augmented_created < images_needed:
# # #                 for img_idx, src_path in enumerate(originals):
# # #                     if augmented_created >= images_needed: break
                    
# # #                     for aug_idx in range(aug_per_image):
# # #                         if augmented_created >= images_needed: break
                        
# # #                         output_path = os.path.join(train_class_dir, 
# # #                                                    f"aug_{img_idx:04d}_{aug_idx:03d}_{random.randint(0, 9999)}.jpg")
                        
# # #                         # Apply augmentation
# # #                         if process_image(src_path, output_path, augment_pipeline, is_augmented=True):
# # #                             augmented_created += 1
# # #                             total_generated += 1
# # #                             pbar.update(1)
                
# # #                 # If target not met, loop over originals again until filled
# # #                 if augmented_created < images_needed: continue 
        
# # #     print(f"\n✅ Data Preparation Complete. Total augmented files created: {total_generated}")

# # # if __name__ == "__main__":
# # #     run_leak_proof_data_prep()



# # import os
# # import cv2
# # import random
# # import numpy as np
# # from glob import glob
# # from tqdm import tqdm
# # import albumentations as A
# # import shutil
# # from sklearn.model_selection import train_test_split
# # import math
# # from collections import defaultdict # Used for organizing originals

# # # ==============================================
# # # CONFIGURATION
# # # ==============================================
# # SOURCE_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset" 
# # TARGET_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset_augmented_clean" 

# # TARGET_COUNT_TRAIN = 1200    # Train target count PER CLASS
# # TARGET_COUNT_EVAL = 200      # Valid/Test target count PER CLASS

# # RANDOM_SEED = 42
# # random.seed(RANDOM_SEED)
# # np.random.seed(RANDOM_SEED)

# # # ==============================================
# # # 1. AUGMENTATION PIPELINES (DISJOINT STRATEGY)
# # # ==============================================

# # # Pipeline A (Training): Focuses on color/lighting shifts
# # def get_training_augmentation():
# #     """Robust, dynamic augmentation for TRAINING SET."""
# #     return A.Compose([
# #         A.Resize(224, 224, interpolation=cv2.INTER_AREA), 
# #         A.HorizontalFlip(p=0.5),
# #         A.Rotate(limit=10, p=0.3, border_mode=cv2.BORDER_CONSTANT, value=0),
# #         # A. Random Brightness/Hue is the key differentiator for the training set
# #         A.RandomBrightnessContrast(brightness_limit=0.15, contrast_limit=0.15, p=0.5), 
# #         A.HueSaturationValue(hue_shift_limit=10, sat_shift_limit=20, val_shift_limit=10, p=0.5),
# #     ])

# # # Pipeline B (Valid/Test): Focuses on geometric/noise shifts (Disjoint from A)
# # def get_eval_inflation_pipeline():
# #     """Aggressive, DISJOINT augmentation for Valid/Test sets."""
# #     return A.Compose([
# #         A.Resize(224, 224, interpolation=cv2.INTER_AREA),
# #         # Use stronger geometric shifts, different from training set
# #         A.ShiftScaleRotate(
# #             shift_limit=0.15, scale_limit=0.3, 
# #             rotate_limit=30, 
# #             p=1.0, border_mode=cv2.BORDER_CONSTANT, value=0
# #         ),
# #         # Use noise/mild blur that wasn't primarily used in training
# #         A.GaussNoise(var_limit=(10.0, 50.0), p=0.4), 
# #         A.VerticalFlip(p=0.3), # Use this only if Vertical Flip is rare/absent in training set
# #     ])

# # # ==============================================
# # # 2. IMAGE PROCESSING FUNCTIONS 
# # # ==============================================

# # def smart_crop_background(img, padding=10):
# #     """Remove black background and crop/resize to 224x224."""
# #     if img is None: return None
# #     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
# #     _, mask = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)
# #     contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
# #     if contours:
# #         largest_contour = max(contours, key=cv2.contourArea)
# #         x, y, w, h = cv2.boundingRect(largest_contour)
# #         h_orig, w_orig, _ = img.shape
# #         x = max(0, x - padding)
# #         y = max(0, y - padding)
# #         w = min(w_orig - x, w + 2*padding)
# #         h = min(h_orig - y, h + 2*padding)
# #         cropped = img[y:y+h, x:x+w]
# #         resized = cv2.resize(cropped, (224, 224), interpolation=cv2.INTER_AREA)
# #         return resized
    
# #     return cv2.resize(img, (224, 224), interpolation=cv2.INTER_AREA)


# # def process_image(img_path, output_path, augment_pipeline, is_augmented=False):
# #     """Loads, processes (smart-crops), and optionally augments a single image."""
# #     try:
# #         img = cv2.imread(img_path)
# #         if img is None: return False
        
# #         if len(img.shape) == 2: img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
# #         if img.shape[2] != 3: img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
        
# #         # Base Processing: Smart Cropping and Resizing
# #         img = smart_crop_background(img)

# #         if img is None or img.mean() < 5: return False 
        
# #         # Apply Augmentation
# #         if is_augmented and augment_pipeline:
# #             augmented = augment_pipeline(image=img)
# #             img = augmented["image"]
        
# #         cv2.imwrite(output_path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
# #         return True
        
# #     except Exception as e:
# #         # In a production script, you'd log this instead of printing
# #         # print(f"Error processing {img_path}: {e}")
# #         return False

# # # ==============================================
# # # 3. MAIN LEAK-PROOF DATA PREP FUNCTION
# # # ==============================================

# # def run_leak_proof_data_prep():
# #     print("=" * 80)
# #     print("TEA LEAF AUGMENTATION (LEAK-PROOF METHOD W/ INFLATION)")
# #     print("=" * 80)

# #     # Clean and setup directories
# #     if os.path.exists(TARGET_DIR): shutil.rmtree(TARGET_DIR)
# #     os.makedirs(TARGET_DIR)
    
# #     # Collect all original files and labels
# #     all_files, all_labels = [], []
# #     classes_map = {
# #         'Assamica/matured': os.path.join(SOURCE_DIR, 'Assamica', 'matured'),
# #         'Assamica/tender': os.path.join(SOURCE_DIR, 'Assamica', 'tender'),
# #         'DT1/matured': os.path.join(SOURCE_DIR, 'DT1', 'matured'),
# #         'DT1/tender': os.path.join(SOURCE_DIR, 'DT1', 'tender')
# #     }

# #     for label in classes_map.keys():
# #         var, maturity = label.split('/')
# #         source_path = os.path.join(SOURCE_DIR, var, maturity)
# #         image_paths = glob(os.path.join(source_path, "*.jpg"))
# #         all_files.extend(image_paths)
# #         all_labels.extend([label] * len(image_paths))

# #     print(f"📊 Found {len(all_files)} total original images across 4 classes.")

# #     # 2. LEAK-PROOF SPLIT (80/10/10 on Original Files)
# #     X_train, X_temp, y_train, y_temp = train_test_split(
# #         all_files, all_labels, test_size=0.2, stratify=all_labels, random_state=RANDOM_SEED
# #     )
# #     X_valid, X_test, y_valid, y_test = train_test_split(
# #         X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=RANDOM_SEED
# #     )

# #     SPLIT_DATA = {
# #         'train': (X_train, y_train), 'valid': (X_valid, y_valid), 'test': (X_test, y_test)
# #     }
    
# #     # 3. INFLATE Validation and Test sets
# #     print("\n📦 Step 1: Inflating Validation and Test sets (200 images/class)...")
    
# #     # Initialize pipelines
# #     train_augmentation_pipeline = get_training_augmentation()
# #     eval_inflation_pipeline = get_eval_inflation_pipeline()
# #     total_inflated = 0

# #     for fold in ['valid', 'test']:
# #         files, labels = SPLIT_DATA[fold]
        
# #         # Group the tiny original files by class
# #         originals_by_class = defaultdict(list)
# #         for path, label in zip(files, labels):
# #             originals_by_class[label].append(path)

# #         for label, originals in originals_by_class.items():
# #             current_count = len(originals)
# #             images_needed = TARGET_COUNT_EVAL - current_count
            
# #             if images_needed <= 0: continue
            
# #             print(f"  {fold}/{label}: Inflating {current_count} -> {TARGET_COUNT_EVAL} (+{images_needed})")
            
# #             var, maturity = label.split('/')
# #             eval_class_dir = os.path.join(TARGET_DIR, fold, var, maturity)
# #             os.makedirs(eval_class_dir, exist_ok=True)

# #             # Copy the originals first (Base case)
# #             for src_path in originals:
# #                  output_path = os.path.join(eval_class_dir, os.path.basename(src_path))
# #                  process_image(src_path, output_path, None, is_augmented=False)

# #             # Generate augmented files using the DISJOINT pipeline
# #             aug_per_image = max(1, math.ceil(images_needed / current_count))
# #             augmented_created = 0

# #             with tqdm(total=images_needed, desc=f"  Generating {fold}/{label}", leave=False) as pbar:
# #                 while augmented_created < images_needed:
# #                     for img_idx, src_path in enumerate(originals):
# #                         if augmented_created >= images_needed: break
                        
# #                         for aug_idx in range(aug_per_image):
# #                             if augmented_created >= images_needed: break
                            
# #                             output_path = os.path.join(eval_class_dir, 
# #                                                        f"INF_{img_idx:04d}_{aug_idx:03d}_{random.randint(0, 9999)}.jpg")
                            
# #                             if process_image(src_path, output_path, eval_inflation_pipeline, is_augmented=True):
# #                                 augmented_created += 1
# #                                 total_inflated += 1
# #                                 pbar.update(1)
                    
# #                     if augmented_created < images_needed: continue 
    
# #     # 4. Augment Training Set
# #     print("\n🧪 Step 2: Processing and Augmenting Training Set (1200 images/class)...")
# #     train_files, train_labels = SPLIT_DATA['train']
    
# #     train_originals_by_class = defaultdict(list)
# #     for path, label in zip(train_files, train_labels):
# #         train_originals_by_class[label].append(path)

# #     total_generated_train = 0
    
# #     for label, originals in train_originals_by_class.items():
# #         train_class_dir = os.path.join(TARGET_DIR, 'train', label.split('/')[0], label.split('/')[1])
# #         os.makedirs(train_class_dir, exist_ok=True)
        
# #         current_count = len(originals)
# #         images_needed = TARGET_COUNT_TRAIN - current_count
        
# #         if images_needed <= 0:
# #             print(f"  {label}: Already enough ({current_count}). Copying originals.")
# #             for src_path in originals:
# #                  output_path = os.path.join(train_class_dir, os.path.basename(src_path))
# #                  process_image(src_path, output_path, None, is_augmented=False)
# #             continue
            
# #         print(f"  {label}: Augmenting {current_count} -> {TARGET_COUNT_TRAIN} (+{images_needed})")
        
# #         # Copy originals first 
# #         for i, src_path in enumerate(originals):
# #             output_path = os.path.join(train_class_dir, os.path.basename(src_path))
# #             process_image(src_path, output_path, None, is_augmented=False)
        
# #         aug_per_image = max(1, math.ceil(images_needed / current_count))
# #         augmented_created = 0
        
# #         with tqdm(total=images_needed, desc=f"  Generating {label}", leave=False) as pbar:
# #             while augmented_created < images_needed:
# #                 for img_idx, src_path in enumerate(originals):
# #                     if augmented_created >= images_needed: break
                    
# #                     for aug_idx in range(aug_per_image):
# #                         if augmented_created >= images_needed: break
                        
# #                         output_path = os.path.join(train_class_dir, 
# #                                                    f"TRAIN_AUG_{img_idx:04d}_{aug_idx:03d}_{random.randint(0, 9999)}.jpg")
                        
# #                         # Apply TRAINING augmentation (PIPELINE A)
# #                         if process_image(src_path, output_path, train_augmentation_pipeline, is_augmented=True):
# #                             augmented_created += 1
# #                             total_generated_train += 1
# #                             pbar.update(1)
                    
# #                     if augmented_created < images_needed: continue 
        
# #     print(f"\n✅ Data Preparation Complete. Total files generated: {total_generated_train + total_inflated}")

# # if __name__ == "__main__":
# #     run_leak_proof_data_prep()



# # FINAL_PERFECT_AUGMENTATION.py  ← Save with this name and run only this
# import os
# import cv2
# import random
# import numpy as np
# from glob import glob
# from tqdm import tqdm
# import albumentations as A
# import shutil
# from sklearn.model_selection import train_test_split
# import math
# from collections import defaultdict

# # ==============================================
# # CONFIGURATION — ONLY CHANGE THESE TWO LINES
# # ==============================================
# SOURCE_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset"          # Raw originals
# TARGET_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset_final"     # Final clean dataset

# TARGET_COUNT_TRAIN = 1200    # Train images per class
# TARGET_COUNT_EVAL  = 200     # Valid + Test images per class

# RANDOM_SEED = 42
# random.seed(RANDOM_SEED)
# np.random.seed(RANDOM_SEED)

# # ==============================================
# # 1. NON-DISTORTING LEAF CROPPING — THIS FIXES LEAF SIZE DAMAGE
# # ==============================================
# def preserve_leaf_shape_and_crop(img, padding=15):
#     """Crops leaf → pads to square → resizes to 224×224 WITHOUT squishing."""
#     if img is None: return None

#     gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     _, mask = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)
#     contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

#     if not contours:
#         return cv2.resize(img, (224, 224), interpolation=cv2.INTER_AREA)

#     largest = max(contours, key=cv2.contourArea)
#     x, y, w, h = cv2.boundingRect(largest)

#     h_img, w_img = img.shape[:2]
#     x1 = max(0, x - padding)
#     y1 = max(0, y - padding)
#     x2 = min(w_img, x + w + padding)
#     y2 = min(h_img, y + h + padding)

#     cropped = img[y1:y2, x1:x2]

#     # PAD TO SQUARE → this is the magic that stops leaf distortion
#     h_crop, w_crop = cropped.shape[:2]
#     size = max(h_crop, w_crop)
#     square = np.zeros((size, size, 3), dtype=np.uint8)
#     top = (size - h_crop) // 2
#     left = (size - w_crop) // 2
#     square[top:top+h_crop, left:left+w_crop] = cropped

#     final = cv2.resize(square, (224, 224), interpolation=cv2.INTER_AREA)
#     return final

# # ==============================================
# # 2. DISJOINT AUGMENTATION PIPELINES
# # ==============================================
# def get_training_augmentation():
#     return A.Compose([
#         A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.7),
#         A.HueSaturationValue(hue_shift_limit=15, sat_shift_limit=25, val_shift_limit=20, p=0.7),
#         A.HorizontalFlip(p=0.5),
#         A.Rotate(limit=15, border_mode=cv2.BORDER_CONSTANT, value=0, p=0.5),
#     ])

# def get_eval_augmentation():
#     return A.Compose([
#         A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.2, rotate_limit=25,
#                            border_mode=cv2.BORDER_CONSTANT, value=0, p=0.8),
#         A.GaussNoise(var_limit=(10, 40), p=0.4),
#         A.VerticalFlip(p=0.3),
#         A.RandomFog(p=0.2),
#     ])

# # ==============================================
# # 3. PROCESS ONE IMAGE
# # ==============================================
# def process_and_save(src_path, dst_path, pipeline=None):
#     img = cv2.imread(src_path)
#     if img is None: return False
#     img = preserve_leaf_shape_and_crop(img)           # ← Leaf size preserved
#     if pipeline:
#         img = pipeline(image=img)["image"]
#     cv2.imwrite(dst_path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
#     return True

# # ==============================================
# # 4. MAIN — LEAK-PROOF + INFLATION
# # ==============================================
# def run_final_perfect_augmentation():
#     print("FINAL PERFECT AUGMENTATION STARTING".center(80, "="))

#     if os.path.exists(TARGET_DIR):
#         shutil.rmtree(TARGET_DIR)
#     os.makedirs(TARGET_DIR)

#     # Collect originals
#     classes = {
#         'Assamica/matured': os.path.join(SOURCE_DIR, 'Assamica', 'matured'),
#         'Assamica/tender':  os.path.join(SOURCE_DIR, 'Assamica', 'tender'),
#         'DT1/matured':      os.path.join(SOURCE_DIR, 'DT1', 'matured'),
#         'DT1/tender':       os.path.join(SOURCE_DIR, 'DT1', 'tender')
#     }

#     files, labels = [], []
#     for label, path in classes.items():
#         imgs = glob(os.path.join(path, "*.jpg"))
#         files.extend(imgs)
#         labels.extend([label] * len(imgs))

#     print(f"Found {len(files)} original images")

#     # LEAK-PROOF SPLIT FIRST
#     X_train, X_temp, y_train, y_temp = train_test_split(
#         files, labels, test_size=0.2, stratify=labels, random_state=RANDOM_SEED)
#     X_val, X_test, y_val, y_test = train_test_split(
#         X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=RANDOM_SEED)

#     splits = {'train': (X_train, y_train), 'valid': (X_val, y_val), 'test': (X_test, y_test)}

#     train_aug = get_training_augmentation()
#     eval_aug = get_eval_augmentation()

#     total_generated = 0

#     for split_name, (paths, labels_list) in splits.items():
#         print(f"\nProcessing {split_name.upper()} set...")
#         groups = defaultdict(list)
#         for p, l in zip(paths, labels_list):
#             groups[l].append(p)

#         for label, originals in groups.items():
#             var, mat = label.split('/')
#             class_dir = os.path.join(TARGET_DIR, split_name, var, mat)
#             os.makedirs(class_dir, exist_ok=True)

#             current = len(originals)
#             target = TARGET_COUNT_TRAIN if split_name == 'train' else TARGET_COUNT_EVAL
#             needed = target - current

#             # Copy originals
#             for i, src in enumerate(originals):
#                 dst = os.path.join(class_dir, f"ORIG_{i:04d}_{os.path.basename(src)}")
#                 process_and_save(src, dst)

#             if needed <= 0:
#                 print(f"  {label}: Already enough ({current})")
#                 continue

#             print(f"  {label}: {current} → {target} (+{needed})")
#             pipeline = train_aug if split_name == 'train' else eval_aug
#             per_img = math.ceil(needed / current)
#             created = 0

#             with tqdm(total=needed, desc="    Generating", leave=False) as pbar:
#                 while created < needed:
#                     for idx, src in enumerate(originals):
#                         if created >= needed: break
#                         for aug_idx in range(per_img):
#                             if created >= needed: break
#                             dst = os.path.join(class_dir,
#                                                f"AUG_{idx:04d}_{aug_idx:03d}_{random.randint(0,9999)}.jpg")
#                             if process_and_save(src, dst, pipeline):
#                                 created += 1
#                                 total_generated += 1
#                                 pbar.update(1)

#     print(f"\nDONE! Generated {total_generated} images")
#     print(f"Final dataset location: {TARGET_DIR}")
#     print("You are now 100% ready for training.")
#     print("="*80)

# if __name__ == "__main__":
#     run_final_perfect_augmentation()



# FINAL PERFECT AUGMENTATION SCRIPT — RUN THIS
import os
import cv2
import random
import numpy as np
from glob import glob
from tqdm import tqdm
import albumentations as A
import shutil
from sklearn.model_selection import train_test_split
import math
from collections import defaultdict

# ==============================================
# CONFIGURATION — ONLY CHANGE THESE TWO LINES
# ==============================================
SOURCE_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset"          # Raw originals
TARGET_DIR = r"C:\Users\HP\Desktop\Tea Leaf Maturity Dataset\dataset_final"    # Final output folder

TARGET_COUNT_TRAIN = 1200   # Train images per class
TARGET_COUNT_EVAL  = 200    # Valid + Test images per class

RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# ==============================================
# 1. NON-DISTORTING LEAF CROPPING — FIXES SIZE DAMAGE
# ==============================================
def preserve_leaf_shape_and_crop(img, padding=15):
    """Crops leaf, pads to square, resizes to 224x224 WITHOUT distortion."""
    if img is None: return None
    
    # Ensure color space
    if len(img.shape) == 2: img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    if img.shape[2] != 3: img = cv2.cvtColor(img, cv2.COLOR_BGRA2BGR)
    
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, mask = cv2.threshold(gray, 10, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if contours:
        largest_contour = max(contours, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(largest_contour)
        
        # 1. Apply safety padding and crop coordinates
        h_orig, w_orig = img.shape[:2]
        x_start = max(0, x - padding)
        y_start = max(0, y - padding)
        x_end = min(w_orig, x + w + padding)
        y_end = min(h_orig, y + h + padding)
        
        cropped = img[y_start:y_end, x_start:x_end]
        
        # 2. ***CRITICAL FIX: PAD TO SQUARE*** (Preserves Aspect Ratio)
        c_h, c_w = cropped.shape[:2]
        max_dim = max(c_h, c_w)
        
        square_img = np.zeros((max_dim, max_dim, 3), dtype=np.uint8) 
        
        # Center the leaf onto the black square canvas
        x_center = (max_dim - c_w) // 2
        y_center = (max_dim - c_h) // 2
        square_img[y_center:y_center + c_h, x_center:x_center + c_w] = cropped
        
        # 3. Final resize to 224x224 (Now perfectly distortion-free)
        resized = cv2.resize(square_img, (224, 224), interpolation=cv2.INTER_AREA)
        return resized
    
    # Fallback if no leaf contour is found
    return cv2.resize(img, (224, 224), interpolation=cv2.INTER_AREA)

# ==============================================
# 2. DISJOINT AUGMENTATION PIPELINES
# ==============================================
def get_training_augmentation():
    """Pipeline A: Used only for training - color/lighting focus"""
    return A.Compose([
        A.RandomBrightnessContrast(brightness_limit=0.2, contrast_limit=0.2, p=0.7),
        A.HueSaturationValue(hue_shift_limit=15, sat_shift_limit=25, val_shift_limit=20, p=0.7),
        A.HorizontalFlip(p=0.5),
        A.Rotate(limit=15, border_mode=cv2.BORDER_CONSTANT, value=0, p=0.5),
    ])

def get_eval_augmentation():
    """Pipeline B: Used only for valid/test - geometry/noise focus (disjoint)"""
    return A.Compose([
        A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.2, rotate_limit=25, 
                           border_mode=cv2.BORDER_CONSTANT, value=0, p=0.8),
        A.GaussNoise(var_limit=(10, 40), p=0.4),
        A.VerticalFlip(p=0.3),
        A.RandomFog(p=0.2),
    ])

# ==============================================
# 3. PROCESS ONE IMAGE
# ==============================================
def process_and_save(src_path, dst_path, pipeline=None):
    """Applies base cropping + optional augmentation"""
    img = cv2.imread(src_path)
    if img is None: return False
    img = preserve_leaf_shape_and_crop(img)
    if img is None or img.mean() < 5: return False
    if pipeline:
        img = pipeline(image=img)["image"]
    cv2.imwrite(dst_path, img, [cv2.IMWRITE_JPEG_QUALITY, 95])
    return True

# ==============================================
# 4. MAIN — LEAK-PROOF + INFLATION
# ==============================================
def run_perfect_augmentation():
    print("FINAL PERFECT AUGMENTATION STARTING".center(80, "="))
    
    # Clean output
    if os.path.exists(TARGET_DIR):
        shutil.rmtree(TARGET_DIR)
    os.makedirs(TARGET_DIR)
    
    # Collect originals
    classes = {
        'Assamica/matured': os.path.join(SOURCE_DIR, 'Assamica', 'matured'),
        'Assamica/tender':  os.path.join(SOURCE_DIR, 'Assamica', 'tender'),
        'DT1/matured':      os.path.join(SOURCE_DIR, 'DT1', 'matured'),
        'DT1/tender':       os.path.join(SOURCE_DIR, 'DT1', 'tender')
    }
    
    files, labels = [], []
    for label, path in classes.items():
        imgs = glob(os.path.join(path, "*.jpg"))
        files.extend(imgs)
        labels.extend([label] * len(imgs))
    
    print(f"Found {len(files)} original images")
    
    # LEAK-PROOF SPLIT FIRST
    X_train, X_temp, y_train, y_temp = train_test_split(
        files, labels, test_size=0.2, stratify=labels, random_state=RANDOM_SEED)
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, stratify=y_temp, random_state=RANDOM_SEED)
    
    splits = {'train': (X_train, y_train), 'valid': (X_val, y_val), 'test': (X_test, y_test)}
    
    train_aug = get_training_augmentation()
    eval_aug = get_eval_augmentation()
    
    total_generated = 0
    
    for split_name, (paths, labels_list) in splits.items():
        print(f"\n→ Processing {split_name.upper()} set...")
        groups = defaultdict(list)
        for p, l in zip(paths, labels_list):
            groups[l].append(p)
        
        for label, originals in groups.items():
            var, mat = label.split('/')
            class_dir = os.path.join(TARGET_DIR, split_name, var, mat)
            os.makedirs(class_dir, exist_ok=True)
            
            current = len(originals)
            target = TARGET_COUNT_TRAIN if split_name == 'train' else TARGET_COUNT_EVAL
            needed = target - current
            
            # Copy originals
            for i, src in enumerate(originals):
                dst = os.path.join(class_dir, f"ORIG_{i:04d}_{os.path.basename(src)}")
                process_and_save(src, dst)
            
            if needed <= 0:
                print(f"  {label}: {current} ≥ {target} → Done")
                continue
                
            print(f"  {label}: {current} → {target} (+{needed})")
            pipeline = train_aug if split_name == 'train' else eval_aug
            per_img = math.ceil(needed / current)
            created = 0
            
            with tqdm(total=needed, desc="    Generating", leave=False) as pbar:
                while created < needed:
                    for idx, src in enumerate(originals):
                        if created >= needed: break
                        for aug_idx in range(per_img):
                            if created >= needed: break
                            dst = os.path.join(class_dir, f"AUG_{idx:04d}_{aug_idx:03d}_{random.randint(0,9999)}.jpg")
                            if process_and_save(src, dst, pipeline):
                                created += 1
                                total_generated += 1
                                pbar.update(1)

    print(f"\nSUCCESS! Generated {total_generated} augmented images")
    print(f"Final dataset ready at: {TARGET_DIR}")
    print("You are now 100% ready for training.")
    print("="*80)

if __name__ == "__main__":
    run_perfect_augmentation()