#!/usr/bin/env python3
"""
Dataset Directory Setup Script
===============================
Creates the required directory structure for training data.
"""

import os
from pathlib import Path


def create_dataset_structure(base_dir: str = "./data"):
    """Create dataset directory structure."""
    base_path = Path(base_dir)

    # Directories to create
    directories = [
        "images/train",
        "images/val",
        "images/test",
        "labels/train",
        "labels/val",
        "labels/test",
    ]

    print("Creating dataset directory structure...")
    print(f"Base directory: {base_path.absolute()}")
    print("-" * 50)

    for dir_path in directories:
        full_path = base_path / dir_path
        full_path.mkdir(parents=True, exist_ok=True)
        print(f"  Created: {full_path}")

    # Create classes.txt
    classes_file = base_path / "classes.txt"
    with open(classes_file, "w") as f:
        f.write("healthy\n")
        f.write("red_rust\n")
        f.write("blister_blight\n")
    print(f"  Created: {classes_file}")

    # Create data.yaml for YOLO
    yaml_content = f"""# Tea Leaf Disease Detection Dataset
# Auto-generated configuration file

path: {base_path.absolute()}
train: images/train
val: images/val
test: images/test

# Classes
nc: 3
names:
  0: healthy
  1: red_rust
  2: blister_blight

# Class descriptions
# healthy: Normal green tea leaf without any disease symptoms
# red_rust: Infected with Cephaleuros virescens - orange/rust colored spots
# blister_blight: Infected with Exobasidium vexans - white/pale blisters on young leaves
"""
    yaml_file = base_path / "data.yaml"
    with open(yaml_file, "w") as f:
        f.write(yaml_content)
    print(f"  Created: {yaml_file}")

    # Create README
    readme_content = """# Tea Leaf Disease Dataset

## Directory Structure
```
data/
├── images/
│   ├── train/     <- Training images (70%)
│   ├── val/       <- Validation images (20%)
│   └── test/      <- Test images (10%)
├── labels/
│   ├── train/     <- Training labels
│   ├── val/       <- Validation labels
│   └── test/      <- Test labels
├── classes.txt    <- Class names
└── data.yaml      <- YOLO configuration
```

## Image Requirements
- Format: JPG or PNG
- Minimum resolution: 640x640 recommended
- Naming: Use consistent naming (e.g., img_0001.jpg)

## Label Format (YOLO)
Each image needs a corresponding .txt file with the same name.

Format: `class_id x_center y_center width height`
- All values normalized (0.0 to 1.0)
- class_id: 0=healthy, 1=red_rust, 2=blister_blight

Example (image001.txt):
```
0 0.45 0.32 0.15 0.12
1 0.67 0.55 0.18 0.14
2 0.25 0.75 0.22 0.20
```

## Annotation Tools
- LabelImg: `pip install labelImg` then `labelImg`
- Roboflow: https://roboflow.com (online, free tier)
- CVAT: https://cvat.ai (online, open source)

## Recommended Dataset Size
- Minimum: 500 images per class
- Recommended: 1000+ images per class
- More data = better accuracy

## Tips for Good Annotations
1. Draw tight bounding boxes around each leaf
2. Include the entire leaf in the box
3. Label ALL visible leaves in each image
4. Be consistent with class labels
5. Include variety: different lighting, angles, backgrounds
"""
    readme_file = base_path / "README.md"
    with open(readme_file, "w") as f:
        f.write(readme_content)
    print(f"  Created: {readme_file}")

    print("-" * 50)
    print("\nDataset structure created successfully!")
    print("\nNext steps:")
    print("1. Add your images to data/images/train/, val/, test/")
    print("2. Add corresponding labels to data/labels/train/, val/, test/")
    print("3. Run: python scripts/verify_dataset.py")
    print("4. Run: python scripts/train_model.py --data ./data --epochs 100")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Setup dataset directory structure")
    parser.add_argument("--path", type=str, default="./data", help="Base path for dataset")

    args = parser.parse_args()
    create_dataset_structure(args.path)
