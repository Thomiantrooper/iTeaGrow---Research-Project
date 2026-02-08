#!/usr/bin/env python3
"""
Dataset Preparation Script for Tea Leaf Disease Detection.

Creates a properly structured YOLO-format dataset from raw images and annotations.

Usage:
    python scripts/prepare_dataset.py --input raw_data/ --output datasets/tealeaf/
"""

import argparse
import sys
import shutil
import random
from pathlib import Path
from datetime import datetime
import yaml


def setup_paths():
    """Add project root to Python path."""
    project_root = Path(__file__).parent.parent
    sys.path.insert(0, str(project_root))


setup_paths()


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Prepare dataset for YOLOv8 training"
    )

    parser.add_argument(
        "--input",
        type=str,
        required=True,
        help="Path to raw data directory"
    )
    parser.add_argument(
        "--output",
        type=str,
        required=True,
        help="Output directory for processed dataset"
    )
    parser.add_argument(
        "--train-ratio",
        type=float,
        default=0.8,
        help="Training set ratio (default: 0.8)"
    )
    parser.add_argument(
        "--val-ratio",
        type=float,
        default=0.1,
        help="Validation set ratio (default: 0.1)"
    )
    parser.add_argument(
        "--test-ratio",
        type=float,
        default=0.1,
        help="Test set ratio (default: 0.1)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility (default: 42)"
    )
    parser.add_argument(
        "--augment",
        action="store_true",
        help="Generate augmented training samples"
    )

    return parser.parse_args()


def create_directory_structure(output_dir: Path) -> dict:
    """Create YOLO-format directory structure."""
    dirs = {
        "train_images": output_dir / "train" / "images",
        "train_labels": output_dir / "train" / "labels",
        "val_images": output_dir / "val" / "images",
        "val_labels": output_dir / "val" / "labels",
        "test_images": output_dir / "test" / "images",
        "test_labels": output_dir / "test" / "labels",
    }

    for dir_path in dirs.values():
        dir_path.mkdir(parents=True, exist_ok=True)

    return dirs


def collect_samples(input_dir: Path) -> list:
    """
    Collect image-label pairs from input directory.

    Expects structure:
    input_dir/
    ├── images/
    │   ├── img001.jpg
    │   └── ...
    └── labels/
        ├── img001.txt
        └── ...
    """
    images_dir = input_dir / "images"
    labels_dir = input_dir / "labels"

    if not images_dir.exists():
        images_dir = input_dir

    samples = []

    image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}

    for image_path in images_dir.iterdir():
        if image_path.suffix.lower() not in image_extensions:
            continue

        label_path = labels_dir / f"{image_path.stem}.txt"

        if not label_path.exists():
            print(f"Warning: No label for {image_path.name}")
            continue

        samples.append({
            "image": image_path,
            "label": label_path,
        })

    return samples


def split_dataset(
    samples: list,
    train_ratio: float,
    val_ratio: float,
    test_ratio: float,
    seed: int,
) -> dict:
    """Split samples into train/val/test sets."""
    total = len(samples)

    if abs(train_ratio + val_ratio + test_ratio - 1.0) > 0.01:
        raise ValueError("Split ratios must sum to 1.0")

    random.seed(seed)
    random.shuffle(samples)

    train_end = int(total * train_ratio)
    val_end = train_end + int(total * val_ratio)

    return {
        "train": samples[:train_end],
        "val": samples[train_end:val_end],
        "test": samples[val_end:],
    }


def copy_samples(
    samples: list,
    images_dir: Path,
    labels_dir: Path,
) -> int:
    """Copy samples to destination directories."""
    copied = 0

    for sample in samples:
        shutil.copy(sample["image"], images_dir / sample["image"].name)
        shutil.copy(sample["label"], labels_dir / sample["label"].name)
        copied += 1

    return copied


def create_data_yaml(
    output_dir: Path,
    class_names: list = None,
) -> Path:
    """Create data.yaml configuration file."""
    if class_names is None:
        class_names = ["healthy", "red_rust", "blister_blight"]

    config = {
        "path": str(output_dir.absolute()),
        "train": "train/images",
        "val": "val/images",
        "test": "test/images",
        "nc": len(class_names),
        "names": class_names,
    }

    yaml_path = output_dir / "data.yaml"

    with open(yaml_path, "w") as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)

    return yaml_path


def verify_labels(samples: list, num_classes: int = 3) -> dict:
    """Verify label format and class distribution."""
    stats = {
        "total_annotations": 0,
        "class_distribution": {i: 0 for i in range(num_classes)},
        "invalid_files": [],
    }

    for sample in samples:
        try:
            with open(sample["label"], "r") as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) < 5:
                        continue

                    class_id = int(parts[0])
                    if 0 <= class_id < num_classes:
                        stats["class_distribution"][class_id] += 1
                        stats["total_annotations"] += 1
                    else:
                        stats["invalid_files"].append(str(sample["label"]))

        except Exception as e:
            stats["invalid_files"].append(f"{sample['label']}: {e}")

    return stats


def prepare_dataset(args):
    """
    Prepare the dataset for training.

    Args:
        args: Command line arguments
    """
    print("=" * 60)
    print("Tea Leaf Disease Detection - Dataset Preparation")
    print("=" * 60)
    print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

    input_dir = Path(args.input)
    output_dir = Path(args.output)

    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory not found: {input_dir}")

    print("Creating directory structure...")
    dirs = create_directory_structure(output_dir)

    print("Collecting samples...")
    samples = collect_samples(input_dir)
    print(f"Found {len(samples)} image-label pairs")

    if len(samples) == 0:
        raise ValueError("No valid samples found in input directory")

    print("\nVerifying labels...")
    stats = verify_labels(samples)
    print(f"Total annotations: {stats['total_annotations']}")
    print("Class distribution:")

    class_names = ["healthy", "red_rust", "blister_blight"]
    for class_id, count in stats["class_distribution"].items():
        print(f"  {class_names[class_id]}: {count}")

    if stats["invalid_files"]:
        print(f"\nWarning: {len(stats['invalid_files'])} invalid label files")

    print("\nSplitting dataset...")
    splits = split_dataset(
        samples,
        args.train_ratio,
        args.val_ratio,
        args.test_ratio,
        args.seed,
    )

    print(f"  Train: {len(splits['train'])} samples ({args.train_ratio*100:.0f}%)")
    print(f"  Val: {len(splits['val'])} samples ({args.val_ratio*100:.0f}%)")
    print(f"  Test: {len(splits['test'])} samples ({args.test_ratio*100:.0f}%)")

    print("\nCopying files...")
    for split_name, split_samples in splits.items():
        images_dir = dirs[f"{split_name}_images"]
        labels_dir = dirs[f"{split_name}_labels"]
        copied = copy_samples(split_samples, images_dir, labels_dir)
        print(f"  {split_name}: copied {copied} samples")

    print("\nCreating data.yaml...")
    yaml_path = create_data_yaml(output_dir, class_names)
    print(f"Configuration saved to: {yaml_path}")

    print("\n" + "=" * 60)
    print("Dataset preparation complete!")
    print("=" * 60)
    print(f"\nDataset ready at: {output_dir}")
    print("\nTo train the model, run:")
    print(f"  python scripts/train.py --data {yaml_path}")

    print(f"\nEnd time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


def main():
    """Main entry point."""
    args = parse_arguments()

    try:
        prepare_dataset(args)
    except Exception as e:
        print(f"\nDataset preparation failed: {e}")
        raise


if __name__ == "__main__":
    main()
