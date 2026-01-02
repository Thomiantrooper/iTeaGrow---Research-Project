#!/usr/bin/env python3
"""
Dataset Verification Script
=============================
Validates dataset structure, labels, and class distribution.
"""

import os
from pathlib import Path
from collections import defaultdict
import sys


def verify_dataset(base_dir: str = "./data"):
    """Verify dataset structure and content."""
    base_path = Path(base_dir)
    errors = []
    warnings = []
    stats = defaultdict(lambda: defaultdict(int))

    print("=" * 60)
    print("DATASET VERIFICATION")
    print("=" * 60)
    print(f"Dataset path: {base_path.absolute()}")
    print("-" * 60)

    # Check directory structure
    print("\n[1/5] Checking directory structure...")
    required_dirs = [
        "images/train",
        "images/val",
        "labels/train",
        "labels/val",
    ]
    optional_dirs = ["images/test", "labels/test"]

    for dir_path in required_dirs:
        full_path = base_path / dir_path
        if not full_path.exists():
            errors.append(f"Missing required directory: {dir_path}")
        else:
            print(f"  ✓ {dir_path}")

    for dir_path in optional_dirs:
        full_path = base_path / dir_path
        if full_path.exists():
            print(f"  ✓ {dir_path}")
        else:
            print(f"  ○ {dir_path} (optional, not found)")

    if errors:
        print("\n❌ Directory structure errors found!")
        for error in errors:
            print(f"   - {error}")
        print("\nRun: python scripts/setup_dataset.py")
        return False

    # Check data.yaml
    print("\n[2/5] Checking configuration files...")
    yaml_path = base_path / "data.yaml"
    if yaml_path.exists():
        print(f"  ✓ data.yaml")
    else:
        warnings.append("data.yaml not found - will be created during training")
        print(f"  ⚠ data.yaml (will be auto-generated)")

    # Check image-label pairs
    print("\n[3/5] Checking image-label pairs...")
    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

    for split in ["train", "val", "test"]:
        images_dir = base_path / "images" / split
        labels_dir = base_path / "labels" / split

        if not images_dir.exists():
            continue

        images = [f for f in images_dir.iterdir() if f.suffix.lower() in image_extensions]
        stats[split]["images"] = len(images)

        missing_labels = 0
        for img_path in images:
            label_path = labels_dir / (img_path.stem + ".txt")
            if not label_path.exists():
                missing_labels += 1
                if missing_labels <= 3:
                    warnings.append(f"Missing label for: {img_path.name}")

        if missing_labels > 3:
            warnings.append(f"... and {missing_labels - 3} more missing labels in {split}")

        stats[split]["missing_labels"] = missing_labels
        print(f"  {split}: {len(images)} images, {missing_labels} missing labels")

    # Check label format and class distribution
    print("\n[4/5] Checking label format and class distribution...")
    class_names = ["healthy", "red_rust", "blister_blight"]
    class_counts = defaultdict(lambda: defaultdict(int))

    for split in ["train", "val", "test"]:
        labels_dir = base_path / "labels" / split

        if not labels_dir.exists():
            continue

        for label_path in labels_dir.glob("*.txt"):
            try:
                with open(label_path, "r") as f:
                    lines = f.readlines()

                for line_num, line in enumerate(lines, 1):
                    line = line.strip()
                    if not line:
                        continue

                    parts = line.split()
                    if len(parts) != 5:
                        errors.append(f"{label_path.name}:{line_num} - Invalid format (expected 5 values)")
                        continue

                    try:
                        class_id = int(parts[0])
                        x, y, w, h = map(float, parts[1:])

                        if class_id not in [0, 1, 2]:
                            errors.append(f"{label_path.name}:{line_num} - Invalid class_id {class_id}")

                        if not (0 <= x <= 1 and 0 <= y <= 1 and 0 <= w <= 1 and 0 <= h <= 1):
                            warnings.append(f"{label_path.name}:{line_num} - Coordinates out of range [0,1]")

                        class_counts[split][class_id] += 1
                        stats[split]["annotations"] += 1

                    except ValueError:
                        errors.append(f"{label_path.name}:{line_num} - Invalid number format")

            except Exception as e:
                errors.append(f"Error reading {label_path.name}: {e}")

    # Print class distribution
    print("\n  Class distribution:")
    for split in ["train", "val", "test"]:
        if split not in class_counts or not class_counts[split]:
            continue
        print(f"\n  {split}:")
        total = sum(class_counts[split].values())
        for class_id, count in sorted(class_counts[split].items()):
            class_name = class_names[class_id] if class_id < len(class_names) else f"unknown_{class_id}"
            percentage = (count / total * 100) if total > 0 else 0
            print(f"    {class_name}: {count} ({percentage:.1f}%)")

    # Check for class imbalance
    print("\n[5/5] Checking for issues...")

    if "train" in class_counts:
        train_counts = class_counts["train"]
        if train_counts:
            max_count = max(train_counts.values())
            min_count = min(train_counts.values())
            if max_count > min_count * 3:
                warnings.append("Significant class imbalance detected - consider data augmentation")

    # Summary
    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)

    total_images = sum(stats[s]["images"] for s in stats)
    total_annotations = sum(stats[s]["annotations"] for s in stats)

    print(f"\nDataset Statistics:")
    print(f"  Total images:      {total_images}")
    print(f"  Total annotations: {total_annotations}")

    for split in ["train", "val", "test"]:
        if split in stats and stats[split]["images"] > 0:
            print(f"  {split.capitalize()}: {stats[split]['images']} images, {stats[split].get('annotations', 0)} annotations")

    if errors:
        print(f"\n❌ ERRORS ({len(errors)}):")
        for error in errors[:10]:
            print(f"   - {error}")
        if len(errors) > 10:
            print(f"   ... and {len(errors) - 10} more errors")

    if warnings:
        print(f"\n⚠️  WARNINGS ({len(warnings)}):")
        for warning in warnings[:10]:
            print(f"   - {warning}")
        if len(warnings) > 10:
            print(f"   ... and {len(warnings) - 10} more warnings")

    if not errors and not warnings:
        print("\n✅ Dataset is valid and ready for training!")
    elif not errors:
        print("\n✅ Dataset is valid (with some warnings)")
    else:
        print("\n❌ Please fix errors before training")
        return False

    print("\nNext step:")
    if total_images == 0:
        print("  Add your images and labels to the data/ directory")
        print("  Or run: python scripts/create_demo_data.py")
    else:
        print("  python scripts/train_model.py --data ./data --epochs 100")

    return len(errors) == 0


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Verify dataset structure and content")
    parser.add_argument("--path", type=str, default="./data", help="Dataset path")

    args = parser.parse_args()

    success = verify_dataset(args.path)
    sys.exit(0 if success else 1)
