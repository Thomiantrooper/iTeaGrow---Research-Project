"""
===============================================================================
MOBILENETV3 TEA MATURITY - PREPROCESSING WITH SAFE AUGMENTATION
===============================================================================
- Manual [-1, 1] scaling (mathematically verified)
- Training-time augmentation: horizontal flip, small rotation, brightness, safe zoom
- All augmentations preserve [-1, 1] range with clipping
- Augmentation only for training generator
- Inherits from tf.keras.utils.Sequence for full Keras compatibility & multiprocessing
- Fully reproducible randomness with seeded RNG
"""

import os  # Standard library for operating system interface (path operations)
import numpy as np  # Numerical Python for array manipulation and math
import pandas as pd  # Pandas for DataFrame handling
from tensorflow.keras.utils import Sequence  # Base class for the data generator
from tensorflow.keras.preprocessing.image import load_img, img_to_array  # Keras image utilities
from scipy.ndimage import rotate, zoom  # SciPy for image augmentation functions

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================
# Define the root directory of the project
PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
# Define the main dataset directory
DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# Define subdirectories for train, validation, and test splits
TRAIN_DIR = os.path.join(DATASET_DIR, "train")
VALID_DIR = os.path.join(DATASET_DIR, "valid")
TEST_DIR = os.path.join(DATASET_DIR, "test")

# Image dimensions required by MobileNetV3 (224x224 pixels)
IMG_SIZE = (224, 224)
# Batch size for training
BATCH_SIZE = 32
# Tea varieties included in the dataset
VARIETIES = ["Assamica", "DT1"]
# Target classes for maturity detection
LEAF_CLASSES = ["matured", "tender"]

# ============================================================================
# PREPROCESSING FUNCTION
# ============================================================================
def mobilenetv3_preprocess(img):
    """
    Converts pixel values from [0, 255] → [-1, 1].
    Required when include_preprocessing=False in MobileNetV3.
    """
    # Convert image to float32, divide by 127.5, and subtract 1.0 to shift range
    # Formula: (x / 127.5) - 1.0 maps 0->-1 and 255->1
    return (img.astype(np.float32) / 127.5) - 1.0

# ============================================================================
# DATA GENERATOR WITH SAFE AUGMENTATION
# ============================================================================
class MobileNetV3DataGenerator(Sequence):
    """
    Custom Keras Data Generator with optional augmentation.
    """
    def __init__(self, dataframe, batch_size=32, img_size=(224, 224),
                 shuffle=True, augment=False, seed=42):
        # Store a copy of the dataframe to avoid external side effects
        self.df = dataframe.copy()
        # Set batch size
        self.batch_size = batch_size
        # Set target image size
        self.img_size = img_size
        # Whether to shuffle data at the end of each epoch
        self.shuffle = shuffle
        # Whether to apply data augmentation (True for training, False for val/test)
        self.augment = augment
        # Seed for reproducibility
        self.seed = seed
        # Initialize a numpy random number generator with the seed
        self.rng = np.random.default_rng(seed)  # Reproducible RNG
        
        # Determine unique classes and sort them for consistency
        self.classes = sorted(self.df['class'].unique())
        # Create a mapping from class name to integer index
        self.class_to_idx = {c: i for i, c in enumerate(self.classes)}
        # Map the 'class' column to integer labels in the dataframe
        self.df['label_idx'] = self.df['class'].map(self.class_to_idx)
        # Total number of samples in the dataframe
        self.n = len(self.df)
        # Total number of classes
        self.n_classes = len(self.classes)
        
        # Initialize epoch counter for incremental shuffling seeds
        self._epoch = 0
        
        # Initial shuffle if enabled
        self.on_epoch_end()
    
    def __len__(self):
        """Returns the number of batches per epoch."""
        # Divide total samples by batch size and take the ceiling
        return int(np.ceil(self.n / self.batch_size))
    
    def __getitem__(self, index):
        """Generates one batch of data given a batch index."""
        # Calculate start index for the batch
        start = index * self.batch_size
        # Calculate end index, ensuring it doesn't exceed total samples
        end = min(start + self.batch_size, self.n)
        # Slice the dataframe to get rows for this batch
        batch_df = self.df.iloc[start:end]
        
        # Initialize batch array for images (BatchSize, Height, Width, Channels)
        batch_x = np.zeros((len(batch_df), *self.img_size, 3), dtype=np.float32)
        # Initialize batch array for labels (BatchSize, NumClasses) - One-hot encoding
        batch_y = np.zeros((len(batch_df), self.n_classes), dtype=np.float32)
        
        # Iterate over the batch rows
        for i, (_, row) in enumerate(batch_df.iterrows()):
            # Load image from disk, resizing to target size
            img = load_img(row['filename'], target_size=self.img_size)
            # Convert PIL image to numpy array
            x = img_to_array(img)
            # Apply MobileNetV3 preprocessing (scale to [-1, 1])
            x = mobilenetv3_preprocess(x)  # Scale to [-1, 1]
            
            # Apply augmentations if enabled
            if self.augment:
                # 1. Horizontal Flip
                if self.rng.random() > 0.5:  # 50% chance
                    x = np.flip(x, axis=1)  # Flip horizontally
                
                # 2. Small Rotation
                if self.rng.random() > 0.5:  # 50% chance
                    # Random angle between -15 and 15 degrees
                    angle = self.rng.uniform(-15, 15)
                    # Rotate image; 'reflect' handles border pixels nicely
                    x = rotate(x, angle, axes=(0, 1), reshape=False, mode='reflect', order=1)
                    # Clip values back to valid range [-1, 1] after interpolation
                    x = np.clip(x, -1.0, 1.0)
                
                # 3. Brightness Adjustment
                if self.rng.random() > 0.5:  # 50% chance
                    # Random factor between 0.8 (darker) and 1.2 (brighter)
                    factor = self.rng.uniform(0.8, 1.2)
                    # Multiply pixel values and clip
                    x = np.clip(x * factor, -1.0, 1.0)
                
                # 4. Safe Zoom/Crop
                if self.rng.random() > 0.5:  # 50% chance
                    # Zoom factor between 1.0 (no zoom) and ~1.11 (0.9 crop)
                    crop_ratio = self.rng.uniform(0.9, 1.0)
                    # Calculate size of the crop
                    crop_size = int(self.img_size[0] * crop_ratio)
                    # Random top-left corner coordinates for the crop
                    top = self.rng.integers(0, self.img_size[0] - crop_size)
                    left = self.rng.integers(0, self.img_size[1] - crop_size)
                    # Extract the crop
                    x_crop = x[top:top + crop_size, left:left + crop_size]
                    # Calculate scale factors to resize crop back to original size
                    zoom_factor = (self.img_size[0] / crop_size, self.img_size[1] / crop_size, 1)
                    # Zoom/resize using SciPy
                    x = zoom(x_crop, zoom_factor, order=1, mode='reflect')
                    # Clip values again
                    x = np.clip(x, -1.0, 1.0)
            
            # Add processed image to batch array
            batch_x[i] = x
            # One-hot encode the label
            batch_y[i, row['label_idx']] = 1
        
        # Return tuple of (inputs, targets)
        return batch_x, batch_y
    
    def on_epoch_end(self):
        """Called at the end of every epoch. Shuffles data if enabled."""
        if self.shuffle:
            # Create a new seed based on epoch number for reproducible but changing shuffle
            current_seed = self.seed + self._epoch
            # Shuffle dataframe rows
            self.df = self.df.sample(frac=1, random_state=current_seed).reset_index(drop=True)
            # Increment epoch counter
            self._epoch += 1

# ============================================================================
# DATASET CREATION
# ============================================================================
def create_dataframe(base_dir):
    """
    Walks through the directory structure to create a DataFrame of file paths and labels.
    """
    paths, labels = [], []  # Lists to store file paths and labels
    
    # Iterate through defined varieties (e.g., Assamica)
    for var in VARIETIES:
        var_path = os.path.join(base_dir, var)
        # Skip if variety directory doesn't exist
        if not os.path.isdir(var_path):
            continue
            
        # Iterate through leaf classes (matured, tender)
        for cls in LEAF_CLASSES:
            cls_path = os.path.join(var_path, cls)
            # Skip if class directory doesn't exist
            if not os.path.exists(cls_path):
                continue
            
            # Create a composite label string, e.g., "Assamica/tender"
            label = f"{var}/{cls}"
            
            # Iterate through files in the directory
            for img_file in os.listdir(cls_path):
                # Filter for valid image extensions
                if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
                    # Add full path to list
                    paths.append(os.path.join(cls_path, img_file))
                    # Add corresponding label to list
                    labels.append(label)
                    
    # Return a Pandas DataFrame with all found images
    return pd.DataFrame({"filename": paths, "class": labels})

# ============================================================================
# GENERATOR FUNCTIONS
# ============================================================================
def get_generators(img_size=IMG_SIZE, batch_size=BATCH_SIZE, seed=42):
    """
    Creates training and validation data generators.
    """
    print("Creating generators with MANUAL [-1, 1] scaling + TRAINING AUGMENTATION...")
    
    # Create DataFrames for training and validation sets
    train_df = create_dataframe(TRAIN_DIR)
    val_df = create_dataframe(VALID_DIR)
    
    # Initialize Training Generator (with shuffling and augmentation)
    train_gen = MobileNetV3DataGenerator(train_df, batch_size, img_size, shuffle=True, augment=True, seed=seed)
    
    # Initialize Validation Generator (no shuffling, no augmentation)
    val_gen = MobileNetV3DataGenerator(val_df, batch_size, img_size, shuffle=False, augment=False, seed=seed)
    
    # Print statistics
    print(f"Training samples: {len(train_df)} (with augmentation)")
    print(f"Validation samples: {len(val_df)}")
    
    return train_gen, val_gen

def get_test_generator(img_size=IMG_SIZE, batch_size=BATCH_SIZE, seed=42):
    """
    Creates a test data generator.
    """
    print("Creating test generator (no augmentation)...")
    # Create DataFrame for test set
    test_df = create_dataframe(TEST_DIR)
    # Initialize Generator (no shuffling, no augmentation)
    return MobileNetV3DataGenerator(test_df, batch_size, img_size, shuffle=False, augment=False, seed=seed)

# ============================================================================
# VERIFICATION
# ============================================================================
def verify_mathematically():
    """
    Verifies that the preprocessing logic correctly maps [0, 255] to [-1, 1].
    """
    print("=" * 60)
    print("MATHEMATICAL VERIFICATION OF PREPROCESSING")
    print("=" * 60)
    
    # Define key test points: Min, Mid, Max pixel values
    test_points = np.array([0, 127.5, 255], dtype=np.float32)
    # Define expected mapped values
    expected = np.array([-1.0, 0.0, 1.0])
    
    # run preprocessing
    result = mobilenetv3_preprocess(test_points)
    
    # Display results
    print(f"Input:    {test_points}")
    print(f"Output:   {result}")
    print(f"Expected: {expected}")
    
    # Check if results match expectations within a small tolerance
    if np.allclose(result, expected, atol=1e-5):
        print("✓ MATHEMATICALLY CORRECT: [0, 255] → [-1, 1]")
    else:
        print("✗ MATHEMATICALLY INCORRECT")

if __name__ == "__main__":
    # Main execution block for testing the module independently
    print("=" * 60)
    print("FINAL PREPROCESSING + AUGMENTATION VALIDATION")
    print("=" * 60)
    
    # Run mathematical verification
    verify_mathematically()
    
    # Test generator creation
    train_gen, _ = get_generators(batch_size=4)
    # Fetch the first batch to verify augmentation pipeline
    x_batch, _ = train_gen[0]  # ← FIXED: Used indexing instead of next()
    
    # Verify range of augmented data
    print(f"\nBatch range after augmentation: [{x_batch.min():.4f}, {x_batch.max():.4f}]")
    if x_batch.min() <= -0.99 and x_batch.max() >= 0.99:
        print("✓ RANGE PRESERVED — Safe for MobileNetV3")
    else:
        print("✗ RANGE ISSUE — Check clipping")
    
    print("\nReady for training!")
    print("=" * 60)