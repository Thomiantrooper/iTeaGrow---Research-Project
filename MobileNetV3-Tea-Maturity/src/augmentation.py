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

TARGET_COUNT_TRAIN = 1200   # Train images per class -- expected to get 1200 images for train
TARGET_COUNT_EVAL  = 200    # Valid + Test images per class -- 200 per each class

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