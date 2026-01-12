#!/usr/bin/env python3
"""
Dataset Augmentation Script for Tea Leaf Disease Detection.

This script creates augmented copies of training images to expand the dataset.
More training data = better accuracy.
"""

import os
import cv2
import numpy as np
from pathlib import Path
import shutil
from datetime import datetime
import random


def augment_image(image, idx):
    """Apply various augmentations to an image."""
    augmented = []
    h, w = image.shape[:2]

    # 1. Horizontal flip
    flipped_h = cv2.flip(image, 1)
    augmented.append(('hflip', flipped_h))

    # 2. Vertical flip
    flipped_v = cv2.flip(image, 0)
    augmented.append(('vflip', flipped_v))

    # 3. Rotation 90
    rotated_90 = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)
    augmented.append(('rot90', rotated_90))

    # 4. Rotation 180
    rotated_180 = cv2.rotate(image, cv2.ROTATE_180)
    augmented.append(('rot180', rotated_180))

    # 5. Brightness increase
    bright = cv2.convertScaleAbs(image, alpha=1.3, beta=30)
    augmented.append(('bright', bright))

    # 6. Brightness decrease (darker)
    dark = cv2.convertScaleAbs(image, alpha=0.7, beta=-20)
    augmented.append(('dark', dark))

    # 7. Saturation boost (for disease colors)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV).astype(np.float32)
    hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 1.4, 0, 255)
    saturated = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)
    augmented.append(('sat', saturated))

    # 8. Slight blur (simulates different camera focus)
    blurred = cv2.GaussianBlur(image, (3, 3), 0)
    augmented.append(('blur', blurred))

    return augmented


def transform_bbox_hflip(bbox, img_w):
    """Transform bounding box for horizontal flip."""
    cx, cy, bw, bh = bbox
    return [1.0 - cx, cy, bw, bh]


def transform_bbox_vflip(bbox, img_h):
    """Transform bounding box for vertical flip."""
    cx, cy, bw, bh = bbox
    return [cx, 1.0 - cy, bw, bh]


def transform_bbox_rot90(bbox):
    """Transform bounding box for 90 degree rotation."""
    cx, cy, bw, bh = bbox
    return [1.0 - cy, cx, bh, bw]


def transform_bbox_rot180(bbox):
    """Transform bounding box for 180 degree rotation."""
    cx, cy, bw, bh = bbox
    return [1.0 - cx, 1.0 - cy, bw, bh]


def transform_labels(labels, aug_type, img_w, img_h):
    """Transform labels based on augmentation type."""
    new_labels = []
    for label in labels:
        parts = label.strip().split()
        if len(parts) >= 5:
            class_id = parts[0]
            bbox = [float(x) for x in parts[1:5]]

            if aug_type == 'hflip':
                bbox = transform_bbox_hflip(bbox, img_w)
            elif aug_type == 'vflip':
                bbox = transform_bbox_vflip(bbox, img_h)
            elif aug_type == 'rot90':
                bbox = transform_bbox_rot90(bbox)
            elif aug_type == 'rot180':
                bbox = transform_bbox_rot180(bbox)
            # For brightness/saturation/blur, bbox stays the same

            new_labels.append(f"{class_id} {bbox[0]:.6f} {bbox[1]:.6f} {bbox[2]:.6f} {bbox[3]:.6f}")

    return new_labels


def main():
    print("=" * 60)
    print("  DATASET AUGMENTATION")
    print("  Expanding training data for better accuracy")
    print("=" * 60)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    # Paths
    project_root = Path(__file__).parent.parent
    train_images = project_root / "raw_data" / "train" / "images"
    train_labels = project_root / "raw_data" / "train" / "labels"

    # Count original images
    original_images = list(train_images.glob("*.jpg")) + list(train_images.glob("*.jpeg")) + list(train_images.glob("*.png"))
    print(f"Original training images: {len(original_images)}")

    # Create augmented images
    augmented_count = 0
    skipped_count = 0

    for img_path in original_images:
        # Read image
        image = cv2.imread(str(img_path))
        if image is None:
            print(f"  Skipping (can't read): {img_path.name}")
            skipped_count += 1
            continue

        h, w = image.shape[:2]

        # Read corresponding label file
        label_path = train_labels / (img_path.stem + ".txt")
        if not label_path.exists():
            print(f"  Skipping (no label): {img_path.name}")
            skipped_count += 1
            continue

        with open(label_path, 'r') as f:
            labels = f.readlines()

        # Generate augmented versions
        augmented = augment_image(image, augmented_count)

        for aug_type, aug_img in augmented:
            # Save augmented image
            new_img_name = f"{img_path.stem}_aug_{aug_type}{img_path.suffix}"
            new_img_path = train_images / new_img_name

            # Skip if already exists
            if new_img_path.exists():
                continue

            cv2.imwrite(str(new_img_path), aug_img)

            # Transform and save labels
            new_labels = transform_labels(labels, aug_type, w, h)
            new_label_path = train_labels / f"{img_path.stem}_aug_{aug_type}.txt"

            with open(new_label_path, 'w') as f:
                f.write('\n'.join(new_labels))

            augmented_count += 1

    # Count final images
    final_images = list(train_images.glob("*.jpg")) + list(train_images.glob("*.jpeg")) + list(train_images.glob("*.png"))

    print()
    print("=" * 60)
    print("  AUGMENTATION COMPLETE")
    print("=" * 60)
    print(f"  Original images: {len(original_images)}")
    print(f"  New augmented images: {augmented_count}")
    print(f"  Total training images: {len(final_images)}")
    print(f"  Skipped: {skipped_count}")
    print()
    print(f"  Dataset expanded by {augmented_count / len(original_images):.1f}x!")
    print()
    print("  You can now retrain with the expanded dataset.")
    print(f"End time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    main()
