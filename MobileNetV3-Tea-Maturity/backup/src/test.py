"""
===============================================================================
DATA LEAKAGE CHECK SCRIPT
===============================================================================
"""

import os
import numpy as np
import hashlib

def check_data_leakage(train_dir, val_dir, test_dir):
    """Check for duplicate images across train/val/test splits"""
    
    def get_image_hashes(directory):
        """Get MD5 hashes of all images in directory"""
        hashes = {}
        for root, _, files in os.walk(directory):
            for file in files:
                if file.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                    filepath = os.path.join(root, file)
                    with open(filepath, 'rb') as f:
                        file_hash = hashlib.md5(f.read()).hexdigest()
                    hashes[file_hash] = filepath
        return hashes
    
    print("🔍 Checking for data leakage...")
    
    # Get hashes for each split
    train_hashes = get_image_hashes(train_dir)
    val_hashes = get_image_hashes(val_dir)
    test_hashes = get_image_hashes(test_dir)
    
    print(f"  Train images: {len(train_hashes)}")
    print(f"  Validation images: {len(val_hashes)}")
    print(f"  Test images: {len(test_hashes)}")
    
    # Check for duplicates
    duplicates = []
    
    # Check train vs validation
    train_val_dups = set(train_hashes.keys()) & set(val_hashes.keys())
    if train_val_dups:
        print(f"  ⚠️  Found {len(train_val_dups)} duplicates between train and validation!")
        for dup in list(train_val_dups)[:5]:  # Show first 5
            print(f"    - {train_hashes[dup]} and {val_hashes[dup]}")
        duplicates.extend(train_val_dups)
    
    # Check train vs test
    train_test_dups = set(train_hashes.keys()) & set(test_hashes.keys())
    if train_test_dups:
        print(f"  ⚠️  Found {len(train_test_dups)} duplicates between train and test!")
        for dup in list(train_test_dups)[:5]:
            print(f"    - {train_hashes[dup]} and {test_hashes[dup]}")
        duplicates.extend(train_test_dups)
    
    # Check validation vs test
    val_test_dups = set(val_hashes.keys()) & set(test_hashes.keys())
    if val_test_dups:
        print(f"  ⚠️  Found {len(val_test_dups)} duplicates between validation and test!")
        for dup in list(val_test_dups)[:5]:
            print(f"    - {val_hashes[dup]} and {test_hashes[dup]}")
        duplicates.extend(val_test_dups)
    
    if not duplicates:
        print("  ✅ No duplicate images found across splits")
    else:
        print(f"  🚨 TOTAL DUPLICATES FOUND: {len(set(duplicates))}")
    
    return len(set(duplicates))

# Run the check
TRAIN_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset\train"
VALID_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset\valid"
TEST_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\dataset\test"

duplicate_count = check_data_leakage(TRAIN_DIR, VALID_DIR, TEST_DIR)