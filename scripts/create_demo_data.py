#!/usr/bin/env python3
"""
Demo Data Generator
====================
Creates synthetic demo images and labels for testing the pipeline.
Use real data for production training!
"""

import os
import numpy as np
from pathlib import Path
import random

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    print("Installing Pillow...")
    os.system("pip install Pillow")
    from PIL import Image, ImageDraw, ImageFilter


def create_synthetic_leaf(size=(200, 150), disease_type="healthy"):
    """Create a synthetic leaf image."""
    img = Image.new("RGB", size, color=(34, 139, 34))  # Forest green base
    draw = ImageDraw.Draw(img)

    # Leaf shape (ellipse)
    margin = 10
    draw.ellipse([margin, margin, size[0] - margin, size[1] - margin], fill=(50, 160, 50))

    # Add some natural variation
    for _ in range(20):
        x = random.randint(margin, size[0] - margin)
        y = random.randint(margin, size[1] - margin)
        r = random.randint(2, 5)
        shade = random.randint(40, 70)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(shade, 140 + shade, shade))

    if disease_type == "red_rust":
        # Add orange/rust spots
        for _ in range(random.randint(5, 15)):
            x = random.randint(margin + 20, size[0] - margin - 20)
            y = random.randint(margin + 20, size[1] - margin - 20)
            r = random.randint(5, 15)
            draw.ellipse(
                [x - r, y - r, x + r, y + r],
                fill=(200 + random.randint(-30, 30), 100 + random.randint(-30, 30), 50),
            )

    elif disease_type == "blister_blight":
        # Add white/pale blisters
        for _ in range(random.randint(3, 10)):
            x = random.randint(margin + 20, size[0] - margin - 20)
            y = random.randint(margin + 20, size[1] - margin - 20)
            r = random.randint(8, 20)
            draw.ellipse(
                [x - r, y - r, x + r, y + r],
                fill=(220 + random.randint(-20, 35), 220 + random.randint(-20, 35), 200),
            )

    # Slight blur for realism
    img = img.filter(ImageFilter.GaussianBlur(radius=1))

    return img


def create_demo_image(size=(640, 640), num_leaves=5):
    """Create a demo image with multiple leaves."""
    # Background (soil/ground)
    bg_color = (100 + random.randint(-20, 20), 80 + random.randint(-20, 20), 60 + random.randint(-20, 20))
    img = Image.new("RGB", size, color=bg_color)
    draw = ImageDraw.Draw(img)

    # Add some background texture
    for _ in range(500):
        x = random.randint(0, size[0])
        y = random.randint(0, size[1])
        r = random.randint(1, 3)
        shade = random.randint(-20, 20)
        color = tuple(max(0, min(255, c + shade)) for c in bg_color)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    labels = []

    for _ in range(num_leaves):
        # Random leaf properties
        leaf_w = random.randint(80, 180)
        leaf_h = random.randint(60, 120)
        x = random.randint(50, size[0] - leaf_w - 50)
        y = random.randint(50, size[1] - leaf_h - 50)

        # Random disease type
        disease_types = ["healthy", "healthy", "healthy", "red_rust", "blister_blight"]
        disease = random.choice(disease_types)
        class_id = {"healthy": 0, "red_rust": 1, "blister_blight": 2}[disease]

        # Create leaf
        leaf = create_synthetic_leaf((leaf_w, leaf_h), disease)

        # Random rotation
        angle = random.randint(-30, 30)
        leaf = leaf.rotate(angle, expand=True, fillcolor=None)

        # Paste onto background
        img.paste(leaf, (x, y), leaf.convert("RGBA").split()[-1] if leaf.mode == "RGBA" else None)

        # Create YOLO label (normalized coordinates)
        x_center = (x + leaf.width / 2) / size[0]
        y_center = (y + leaf.height / 2) / size[1]
        width = leaf.width / size[0]
        height = leaf.height / size[1]

        labels.append(f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}")

    return img, labels


def generate_demo_dataset(base_dir: str = "./data", num_train: int = 100, num_val: int = 30, num_test: int = 20):
    """Generate complete demo dataset."""
    base_path = Path(base_dir)

    # Ensure directories exist
    for split in ["train", "val", "test"]:
        (base_path / "images" / split).mkdir(parents=True, exist_ok=True)
        (base_path / "labels" / split).mkdir(parents=True, exist_ok=True)

    splits = [
        ("train", num_train),
        ("val", num_val),
        ("test", num_test),
    ]

    print("Generating demo dataset...")
    print("-" * 50)

    total_healthy = 0
    total_red_rust = 0
    total_blister = 0

    for split_name, count in splits:
        print(f"\nGenerating {split_name} set ({count} images)...")

        for i in range(count):
            # Generate image and labels
            num_leaves = random.randint(3, 8)
            img, labels = create_demo_image(num_leaves=num_leaves)

            # Save image
            img_path = base_path / "images" / split_name / f"{split_name}_{i:04d}.jpg"
            img.save(img_path, "JPEG", quality=90)

            # Save labels
            label_path = base_path / "labels" / split_name / f"{split_name}_{i:04d}.txt"
            with open(label_path, "w") as f:
                f.write("\n".join(labels))

            # Count classes
            for label in labels:
                class_id = int(label.split()[0])
                if class_id == 0:
                    total_healthy += 1
                elif class_id == 1:
                    total_red_rust += 1
                else:
                    total_blister += 1

            if (i + 1) % 20 == 0:
                print(f"  Generated {i + 1}/{count} images")

        print(f"  Completed {split_name}: {count} images")

    print("\n" + "-" * 50)
    print("Demo dataset generated successfully!")
    print(f"\nClass distribution:")
    print(f"  Healthy:        {total_healthy}")
    print(f"  Red Rust:       {total_red_rust}")
    print(f"  Blister Blight: {total_blister}")
    print(f"  Total:          {total_healthy + total_red_rust + total_blister}")

    print("\n⚠️  NOTE: This is SYNTHETIC data for testing only!")
    print("    For production, use REAL annotated tea leaf images.")

    print("\nNext steps:")
    print("  python scripts/verify_dataset.py")
    print("  python scripts/train_model.py --data ./data --epochs 50")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate demo training data")
    parser.add_argument("--path", type=str, default="./data", help="Output path")
    parser.add_argument("--train", type=int, default=100, help="Number of training images")
    parser.add_argument("--val", type=int, default=30, help="Number of validation images")
    parser.add_argument("--test", type=int, default=20, help="Number of test images")

    args = parser.parse_args()

    generate_demo_dataset(
        base_dir=args.path,
        num_train=args.train,
        num_val=args.val,
        num_test=args.test,
    )
