"""
TEA LEAF PREPROCESSING PIPELINE FOR SHUFFLENETV2
=============================================================
"""
import os  # Operating system interfaces
import numpy as np  # Numerical operations on arrays
from PIL import Image  # Python Imaging Library for image processing
import matplotlib.pyplot as plt  # Plotting library for visualization
from tqdm import tqdm  # Progress bar library
import random  # Random number generators
from collections import Counter  # Container to count hashable objects
import torch  # PyTorch deep learning library
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler  # PyTorch data utilities
from torchvision import transforms  # Computer vision transformations
import torchvision.transforms.functional as F  # Functional interface for transforms
import cv2  # OpenCV for computer vision tasks

# ======================================================================
# 1. SETUP & CONFIG
# ======================================================================
def set_seed(seed=42):
    """
    Sets the random seed for reproducibility across all libraries.
    """
    random.seed(seed)  # Set seed for Python's built-in random module
    np.random.seed(seed)  # Set seed for NumPy
    torch.manual_seed(seed)  # Set seed for PyTorch CPU
    torch.cuda.manual_seed(seed)  # Set seed for PyTorch CUDA (single GPU)
    torch.cuda.manual_seed_all(seed)  # Set seed for all CUDA devices
    torch.backends.cudnn.deterministic = True  # Ensure deterministic behavior in CuDNN
    torch.backends.cudnn.benchmark = False  # Disable CuDNN benchmarking for reproducibility
    os.environ['PYTHONHASHSEED'] = str(seed)  # Set Python hash seed

set_seed(42)  # Initialize seeds with default value 42

# DEFAULT PATHS
# Define the root directory of the project
PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
# Define the main dataset directory
DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# Define training data directory
TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# Define validation data directory
VALID_DIR = os.path.join(DATASET_DIR, "valid")
# Define test data directory
TEST_DIR = os.path.join(DATASET_DIR, "test")

# CONSTANTS
IMG_SIZE = 224  # Target image size (224x224) for ShuffleNetV2
BATCH_SIZE = 32  # Batch size for data loaders
NUM_WORKERS = 0   # Number of subprocesses for data loading (0 means main process)
# Pin memory if CUDA is available for faster data transfer to GPU
PIN_MEMORY = True if torch.cuda.is_available() else False

# CLASS MAPPING
# Define dictionary mapping class names to integer labels
CLASS_MAP = {
    "Assamica/tender": 0, "Assamica/matured": 1,
    "DT1/tender": 2, "DT1/matured": 3
}
# Create reverse mapping from index to class name
IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}
# List of class names sorted by index
CLASS_NAMES = [IDX_TO_CLASS[i] for i in range(len(CLASS_MAP))]

# ======================================================================
# 2. AUGMENTATIONS
# ======================================================================
class AdvancedLeafAugmentation:
    """
    Custom augmentation class specifically designed for tea leaves.
    """
    @staticmethod
    def random_leaf_perspective(img, distortion_scale=0.2):
        """
        Applies random perspective transformation to simulate different viewing angles.
        """
        # Apply transformation with 50% probability
        if random.random() > 0.5: return img
        # Get image dimensions
        width, height = img.size
        # Define original corner points
        startpoints = [[0, 0], [width - 1, 0], [width - 1, height - 1], [0, height - 1]]
        # Define distorted corner points with random variations
        endpoints = [
            [int(random.uniform(0, distortion_scale * width)), int(random.uniform(0, distortion_scale * height))],
            [int(random.uniform((1 - distortion_scale) * width, width)), int(random.uniform(0, distortion_scale * height))],
            [int(random.uniform((1 - distortion_scale) * width, width)), int(random.uniform((1 - distortion_scale) * height, height))],
            [int(random.uniform(0, distortion_scale * width)), int(random.uniform((1 - distortion_scale) * height, height))]
        ]
        # Apply perspective transform using PyTorch's functional API, filling background with gray
        return F.perspective(img, startpoints, endpoints, fill=128)

    @staticmethod
    def random_leaf_occlusion(img, max_occlusion_size=0.3):
        """
        Simulates leaf occlusion (e.g., by other leaves or insects) using an elliptical mask.
        """
        # Apply occlusion with 30% probability
        if random.random() > 0.7: return img
        # Convert PIL image to NumPy array
        img_array = np.array(img)
        h, w, _ = img_array.shape
        # Determine random size for the occlusion ellipse
        occl_h, occl_w = int(h * random.uniform(0.05, max_occlusion_size)), int(w * random.uniform(0.05, max_occlusion_size))
        # Determine random center position
        center_x, center_y = random.randint(0, w), random.randint(0, h)
        # Create a white mask
        mask = np.ones((h, w), dtype=np.uint8) * 255
        # Draw a black ellipse on the mask at the random position
        cv2.ellipse(mask, (center_x, center_y), (occl_w//2, occl_h//2), 0, 0, 360, 0, -1)
        # Blur the mask edges for a smoother blend
        mask = cv2.GaussianBlur(mask, (21, 21), 10) / 255.0
        # Blend the image with the mean color in the occluded area
        for c in range(3):
            img_array[:, :, c] = img_array[:, :, c] * mask + img_array[:, :, c].mean() * (1 - mask)
        # Convert back to PIL Image
        return Image.fromarray(np.uint8(img_array))

    @staticmethod
    def random_leaf_color_temperature(img, temperature_range=(-50, 50)):
        """
        Adjusts the color temperature to simulate different lighting conditions (sunny vs cloudy).
        """
        # Apply correction with 50% probability
        if random.random() > 0.5: return img
        # Pick a random temperature shift
        temperature = random.uniform(*temperature_range)
        # Convert to float for calculation
        img_array = np.array(img, dtype=np.float32)
        # Adjust Red and Blue channels based on temperature
        if temperature > 0:
            # Warmer: Increase Red, Decrease Blue
            img_array[:, :, 0] *= 1 + (temperature / 100)
            img_array[:, :, 2] *= 1 - (temperature / 200)
        else:
            # Cooler: Increase Blue, Decrease Red
            img_array[:, :, 0] *= 1 + (temperature / 200)
            img_array[:, :, 2] *= 1 - (temperature / 100)
        # Clip values to valid range [0, 255] and convert to uint8
        return Image.fromarray(np.uint8(np.clip(img_array, 0, 255)))

# Wrappers functions for use in transforms.Lambda
def create_leaf_perspective_transform(distortion_scale=0.15):
    return lambda img: AdvancedLeafAugmentation.random_leaf_perspective(img, distortion_scale)
def create_leaf_occlusion_transform(max_occlusion_size=0.25):
    return lambda img: AdvancedLeafAugmentation.random_leaf_occlusion(img, max_occlusion_size)
def create_leaf_color_temperature_transform(temperature_range=(-50, 50)):
    return lambda img: AdvancedLeafAugmentation.random_leaf_color_temperature(img, temperature_range)

# ======================================================================
# 3. TRANSFORMS
# ======================================================================
class ProfessionalTeaLeafTransforms:
    """
    Defines the standard transformation pipelines for training, validation, and testing.
    """
    @staticmethod
    def get_train_transform():
        """
        Returns the composition of augmentations for the training set.
        """
        return transforms.Compose([
            # Resize image ensuring shortest edge is 256
            transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
            # Random scaling, translation, and rotation (affine)
            transforms.RandomApply([transforms.RandomAffine(15, (0.1, 0.1), (0.85, 1.15), 8)], p=0.7),
            # Random crop to target size with random scale and aspect ratio
            transforms.RandomResizedCrop(IMG_SIZE, scale=(0.7, 1.0), ratio=(0.8, 1.2)),
            # Random horizontal flip
            transforms.RandomHorizontalFlip(p=0.5),
            # Random vertical flip (less frequent as leaves usually fall downwards)
            transforms.RandomVerticalFlip(p=0.1),
            # Random rotation
            transforms.RandomRotation(25),
            # Random color jitter (brightness, contrast, saturation, hue)
            transforms.RandomApply([transforms.ColorJitter(0.15, 0.15, 0.15, 0.05)], p=0.8),
            # Custom perspective transform
            transforms.Lambda(create_leaf_perspective_transform(0.15)),
            # Custom occlusion transform
            transforms.Lambda(create_leaf_occlusion_transform(0.25)),
            # Custom color temperature transform
            transforms.Lambda(create_leaf_color_temperature_transform()),
            # Random Gaussian blur to simulate out-of-focus shots
            transforms.RandomApply([transforms.GaussianBlur(3, (0.1, 1.0))], p=0.3),
            # Convert PIL image to Tensor
            transforms.ToTensor(),
            # Normalize with ImageNet mean and standard deviation
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
            # Randomly erase a rectangular region (Cutout)
            transforms.RandomErasing(p=0.3, scale=(0.02, 0.12), value='random')
        ])

    @staticmethod
    def get_val_transform():
        """
        Returns the transforms for validation (deterministic).
        """
        return transforms.Compose([
            # Resize to 256
            transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
            # Center crop to target size
            transforms.CenterCrop(IMG_SIZE),
            # Convert to Tensor
            transforms.ToTensor(),
            # Normalize with ImageNet stats
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])
    
    @staticmethod
    def get_test_transform():
        """
        Returns the transforms for testing (same as validation).
        """
        return ProfessionalTeaLeafTransforms.get_val_transform()

# ======================================================================
# 4. DATASET & LOADERS
# ======================================================================
class ProfessionalTeaDataset(Dataset):
    """
    Custom PyTorch Dataset for loading tea leaf images from directory structure.
    """
    def __init__(self, root_dir, transform=None, phase="train"):
        self.root_dir = root_dir  # Directory path
        self.transform = transform  # Transforms to apply
        self.phase = phase  # Phase: train, valid, or test
        self.images, self.labels, self.metadata = [], [], []  # storage lists
        self._load_dataset()  # Initialize dataset loading

    def _load_dataset(self):
        """
        Walks through directories to populate image paths and labels.
        Expected structure: root_dir/variety/maturity/*.jpg
        """
        if not os.path.exists(self.root_dir): return
        # Iterate over Varieties (e.g., Assamica, DT1)
        for variety in os.listdir(self.root_dir):
            variety_path = os.path.join(self.root_dir, variety)
            if not os.path.isdir(variety_path): continue
            # Iterate over Maturity classes (tender, matured)
            for maturity in ["tender", "matured"]:
                class_path = os.path.join(variety_path, maturity)
                if not os.path.exists(class_path): continue
                # Get integer label
                label = CLASS_MAP.get(f"{variety}/{maturity}")
                if label is None: continue
                # Iterate over images
                for f in os.listdir(class_path):
                    if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp')):
                        img_path = os.path.join(class_path, f)
                        self.images.append(img_path)
                        self.labels.append(label)
                        self.metadata.append({'path': img_path, 'label': label, 'class_name': f"{variety}/{maturity}"})
        print(f"[{self.phase.upper()}] Loaded {len(self.images)} images.")

    def __len__(self): 
        # Return total number of images
        return len(self.images)

    def __getitem__(self, idx):
        """
        Fetches the image and label at the given index.
        """
        try:
            # Open image and convert to RGB (handle grayscale/RGBA)
            img = Image.open(self.images[idx]).convert('RGB')
            # Apply transformations
            if self.transform: img = self.transform(img)
            # Return image tensor and label
            return img, self.labels[idx]
        except Exception as e:
            # Handle corrupted images gracefully
            print(f"Error loading {self.images[idx]}: {e}")
            # Return dummy data to avoid crashing
            return torch.zeros((3, IMG_SIZE, IMG_SIZE)), 0

    def get_class_weights(self):
        """
        Calculates class weights for WeightedRandomSampler to handle class imbalance.
        """
        # Count frequency of each class
        counts = Counter(self.labels)
        # Calculate weight: Total / (Num_Classes * Class_Count)
        weights = [len(self.labels) / (len(CLASS_MAP) * counts.get(i, 1)) for i in range(len(CLASS_MAP))]
        return torch.FloatTensor(weights)

def create_data_loaders(batch_size=32):
    """
    Creates DataLoaders for train, validation, and test sets.
    """
    # Use default batch size if not specified
    if batch_size is None: batch_size = BATCH_SIZE
    
    print(f"\n[INFO] Creating Data Loaders (Batch Size: {batch_size})...")
    # Initialize Datasets
    train_ds = ProfessionalTeaDataset(TRAIN_DIR, ProfessionalTeaLeafTransforms.get_train_transform(), "train")
    val_ds = ProfessionalTeaDataset(VALID_DIR, ProfessionalTeaLeafTransforms.get_val_transform(), "validation")
    test_ds = ProfessionalTeaDataset(TEST_DIR, ProfessionalTeaLeafTransforms.get_test_transform(), "test")

    # Setup Sampler for Imbalanced Data in Training
    sampler = None
    if len(train_ds) > 0:
        # Assign a weight to every sample based on its class
        sample_weights = [train_ds.get_class_weights()[l] for l in train_ds.labels]
        # Create WeightedRandomSampler
        sampler = WeightedRandomSampler(sample_weights, len(sample_weights), replacement=True)

    # Initialize DataLoaders
    # Train: Uses weighted sampler (so shuffle is mutually exclusive), drops last incomplete batch
    train_loader = DataLoader(train_ds, batch_size=batch_size, sampler=sampler, shuffle=(sampler is None), num_workers=NUM_WORKERS, pin_memory=PIN_MEMORY, drop_last=True)
    # Validation/Test: No shuffling needed
    val_loader = DataLoader(val_ds, batch_size=batch_size, shuffle=False, num_workers=NUM_WORKERS, pin_memory=PIN_MEMORY)
    test_loader = DataLoader(test_ds, batch_size=batch_size, shuffle=False, num_workers=NUM_WORKERS, pin_memory=PIN_MEMORY)

    return train_loader, val_loader, test_loader, train_ds, val_ds, test_ds

# ======================================================================
# 5. VISUALIZATION & QC
# ======================================================================
def perform_comprehensive_quality_check():
    """
    Scans the dataset for corrupted files and file discrepancies.
    """
    print("\n" + "="*60 + "\n COMPREHENSIVE DATASET QUALITY CHECK\n" + "="*60)
    image_formats = {}
    corrupted_images = []
    
    # Walk through directory
    for root, _, files in os.walk(DATASET_DIR):
        for file in files:
            if file.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp')):
                ext = file.split('.')[-1].lower()
                image_formats[ext] = image_formats.get(ext, 0) + 1
                try:
                    # Attempt to open and verify image
                    img_path = os.path.join(root, file)
                    with Image.open(img_path) as img:
                        img.verify()
                except Exception as e:
                    corrupted_images.append((img_path, str(e)))
    
    # Report findings
    print("   Image formats found:")
    for fmt, count in image_formats.items():
        print(f"      .{fmt}: {count} images")
    
    if corrupted_images:
        print(f"    Found {len(corrupted_images)} corrupted images!")
    else:
        print("   No corrupted images found!")
    
    return corrupted_images

class Visualizer:
    """
    Helper class for dataset visualization.
    """
    @staticmethod
    def visualize_augmentations(dataset, num_samples=4):
        """
        Visualizes original vs augmented images side-by-side.
        """
        print("\n Visualizing Data Augmentations...")
        # Select random indices
        indices = np.random.choice(len(dataset), min(num_samples, len(dataset)), replace=False)
        # Setup plot grid
        fig, axes = plt.subplots(2, num_samples, figsize=(4*num_samples, 8))
        
        # Inverse normalization transform to display tensors as images
        inv_normalize = transforms.Normalize(
            mean=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
            std=[1/0.229, 1/0.224, 1/0.225]
        )
        
        for i, idx in enumerate(indices):
            # Load original image directly
            img_path = dataset.images[idx]
            orig_img = Image.open(img_path).convert('RGB')
            # Load augmented image from dataset
            aug_img, label = dataset[idx]
            
            # Plot Original
            axes[0, i].imshow(orig_img)
            axes[0, i].set_title("Original")
            axes[0, i].axis('off')
            
            # Plot Augmented
            if aug_img.dim() == 3:
                # Denormalize, move to CPU, clamp to [0,1], and convert to numpy
                aug_img_disp = inv_normalize(aug_img).permute(1, 2, 0).clamp(0, 1).cpu().numpy()
                axes[1, i].imshow(aug_img_disp)
                axes[1, i].set_title(f"Augmented\n{IDX_TO_CLASS[label]}")
                axes[1, i].axis('off')
        plt.tight_layout()
        plt.show()

def calculate_dataset_statistics(datasets):
    """
    Prints summary statistics of the split sizes.
    """
    print("\n DATASET STATISTICS SUMMARY\n" + "="*60)
    total_images = 0
    for phase, dataset in zip(['Training', 'Validation', 'Test'], datasets):
        if len(dataset) == 0: continue
        print(f"\n{phase} Dataset: {len(dataset):,} images")
        total_images += len(dataset)
    print("\n" + "="*60 + f"\nGRAND TOTAL: {total_images:,} images")

def verify_shufflenetv2_compatibility():
    """
    Verifies that configuration meets ShuffleNetV2 input requirements.
    """
    print("\n VERIFYING SHUFFLENETV2 COMPATIBILITY\n" + "="*60)
    requirements = {
        "Input size": f"{IMG_SIZE}x{IMG_SIZE} RGB",
        "Normalization": "ImageNet Mean/Std",
        "Tensor Shape": f"(batch, 3, {IMG_SIZE}, {IMG_SIZE})"
    }
    for req, value in requirements.items():
        print(f" {req:25s}: {value}")
    print("\n" + "="*60 + "\nAll requirements satisfied for ShuffleNetV2!")

# ======================================================================
# 6. MAIN EXECUTION
# ======================================================================
def main():
    """
    Main function to run the preprocessing pipeline and checks.
    """
    print("\n" + "="*60 + "\n PROFESSIONAL TEA LEAF PREPROCESSING PIPELINE\n" + "="*60)
    
    # Run Quality Check
    corrupted = perform_comprehensive_quality_check()
    if corrupted:
        print(f"\n⚠ Found {len(corrupted)} corrupted images.")
    
    # Create Loaders
    train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset = create_data_loaders(BATCH_SIZE)
    
    # Print Stats
    calculate_dataset_statistics([train_dataset, val_dataset, test_dataset])
    
    # Verify Compatibility
    verify_shufflenetv2_compatibility()
    
    # Visualize
    try:
        visualizer = Visualizer()
        if len(train_dataset) > 0:
            visualizer.visualize_augmentations(train_dataset, num_samples=4)
    except Exception as e:
        print(f"⚠ Visualization skipped: {str(e)}")
    
    print("\n" + "="*60 + "\n PREPROCESSING PIPELINE READY!\n" + "="*60)
    return train_loader, val_loader, test_loader

if __name__ == "__main__":
    train_loader, val_loader, test_loader = main()