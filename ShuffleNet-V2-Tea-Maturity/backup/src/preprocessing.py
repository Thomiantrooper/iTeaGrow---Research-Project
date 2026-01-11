# # # import os
# # # from PIL import Image
# # # import matplotlib.pyplot as plt
# # # from tqdm import tqdm

# # # import torch
# # # from torch.utils.data import Dataset, DataLoader
# # # from torchvision import transforms

# # # # ------------------ Project Paths ------------------
# # # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
# # # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# # # TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# # # VALID_DIR = os.path.join(DATASET_DIR, "valid")
# # # TEST_DIR  = os.path.join(DATASET_DIR, "test")

# # # IMG_SIZE = 224
# # # BATCH_SIZE = 32

# # # # ------------------ Step 1: Define classes ------------------
# # # CLASS_MAP = {
# # #     "Assamica/tender": 0,
# # #     "Assamica/matured": 1,
# # #     "DT1/tender": 2,
# # #     "DT1/matured": 3
# # # }
# # # IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}

# # # # ------------------ Step 2: Verify folder structure ------------------
# # # def verify_folder_structure():
# # #     print("\n🔹 Verifying dataset folder structure...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         if not os.path.exists(folder):
# # #             print(f"⚠ Folder missing: {folder}")
# # #             continue
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         for var in varieties:
# # #             for maturity in ["tender", "matured"]:
# # #                 cls_path = os.path.join(folder, var, maturity)
# # #                 if not os.path.exists(cls_path):
# # #                     print(f"⚠ Missing class folder: {cls_path}")
# # #                 else:
# # #                     print(f"✔ Found class folder: {cls_path}")
# # #     print("✔ Folder verification complete.\n")

# # # # ------------------ Step 3: Detect corrupted images ------------------
# # # def detect_corrupted_images(dataset_dir):
# # #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# # #     extensions = (".jpg", ".jpeg", ".png", ".webp")
# # #     corrupted_images = []

# # #     for root, _, files in os.walk(dataset_dir):
# # #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# # #             if f.lower().endswith(extensions):
# # #                 path = os.path.join(root, f)
# # #                 try:
# # #                     img = Image.open(path)
# # #                     img.verify()
# # #                 except Exception:
# # #                     corrupted_images.append(path)

# # #     if corrupted_images:
# # #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# # #         for img_path in corrupted_images:
# # #             print("   ", img_path)
# # #     else:
# # #         print("✔ No corrupted images detected.\n")
# # #     return corrupted_images

# # # # ------------------ Step 4: Check class balance ------------------
# # # def check_class_balance():
# # #     print("\n🔹 Checking class balance...")
# # #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# # #         print(f"\nFolder: {folder}")
# # #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]
# # #         for var in varieties:
# # #             counts = {}
# # #             for maturity in ["tender", "matured"]:
# # #                 path = os.path.join(folder, var, maturity)
# # #                 if os.path.exists(path):
# # #                     counts[maturity] = len(os.listdir(path))
# # #             print(f" Variety: {var}")
# # #             for cls, count in counts.items():
# # #                 print(f"   {cls}: {count} images")
# # #     print("✔ Class balance checked.\n")

# # # # ------------------ Step 5: Custom Dataset ------------------
# # # class TeaDataset(Dataset):
# # #     def __init__(self, root_dir, transform=None):
# # #         self.root_dir = root_dir
# # #         self.transform = transform
# # #         self.images = []
# # #         self.labels = []

# # #         for variety in os.listdir(root_dir):
# # #             variety_path = os.path.join(root_dir, variety)
# # #             if not os.path.isdir(variety_path):
# # #                 continue
# # #             for maturity in ["tender", "matured"]:
# # #                 class_path = os.path.join(variety_path, maturity)
# # #                 if not os.path.exists(class_path):
# # #                     continue
# # #                 for img_file in os.listdir(class_path):
# # #                     if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# # #                         self.images.append(os.path.join(class_path, img_file))
# # #                         self.labels.append(CLASS_MAP[f"{variety}/{maturity}"])

# # #     def __len__(self):
# # #         return len(self.images)

# # #     def __getitem__(self, idx):
# # #         img_path = self.images[idx]
# # #         label = self.labels[idx]
# # #         img = Image.open(img_path).convert("RGB")
# # #         if self.transform:
# # #             img = self.transform(img)
# # #         return img, label

# # # # ------------------ Step 6: Transforms ------------------
# # # imagenet_mean = [0.485, 0.456, 0.406]
# # # imagenet_std  = [0.229, 0.224, 0.225]

# # # train_transform = transforms.Compose([
# # #     transforms.Resize((IMG_SIZE, IMG_SIZE)),
# # #     transforms.RandomRotation(20),
# # #     transforms.RandomHorizontalFlip(),
# # #     transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0)),
# # #     transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),
# # #     transforms.ToTensor(),
# # #     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)
# # # ])

# # # val_transform = transforms.Compose([
# # #     transforms.Resize((IMG_SIZE, IMG_SIZE)),
# # #     transforms.ToTensor(),
# # #     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)
# # # ])

# # # # ------------------ Step 7: Create datasets & loaders ------------------
# # # train_dataset = TeaDataset(TRAIN_DIR, transform=train_transform)
# # # val_dataset   = TeaDataset(VALID_DIR, transform=val_transform)
# # # test_dataset  = TeaDataset(TEST_DIR, transform=val_transform)

# # # train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4, pin_memory=True)
# # # val_loader   = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)
# # # test_loader  = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)

# # # # ------------------ Step 8: Visualization & checks ------------------
# # # def visualize_batch(loader, n_images=5):
# # #     data_iter = iter(loader)
# # #     images, labels = next(data_iter)

# # #     inv_normalize = transforms.Normalize(
# # #         mean=[-m/s for m, s in zip(imagenet_mean, imagenet_std)],
# # #         std=[1/s for s in imagenet_std]
# # #     )

# # #     plt.figure(figsize=(12, 4))
# # #     for i in range(min(n_images, images.size(0))):
# # #         img = inv_normalize(images[i]).permute(1, 2, 0).clamp(0, 1).numpy()
# # #         label = IDX_TO_CLASS[labels[i].item()]
# # #         plt.subplot(1, n_images, i+1)
# # #         plt.imshow(img)
# # #         plt.title(label)
# # #         plt.axis("off")
# # #     plt.show()

# # # def verify_class_mapping():
# # #     print("\n🔹 Class index mapping:")
# # #     for idx, cls_name in IDX_TO_CLASS.items():
# # #         print(f"  {cls_name}: {idx}")
# # #     print("✔ Class mapping verified.\n")

# # # # ------------------ Step 9: Main ------------------
# # # if __name__ == "__main__":
# # #     verify_folder_structure()
# # #     check_class_balance()
# # #     detect_corrupted_images(TRAIN_DIR)
# # #     detect_corrupted_images(VALID_DIR)
# # #     detect_corrupted_images(TEST_DIR)

# # #     print(f"\nTraining samples: {len(train_dataset)}, Validation samples: {len(val_dataset)}, Test samples: {len(test_dataset)}")
# # #     verify_class_mapping()
# # #     visualize_batch(train_loader, n_images=5)

# # #     print("✅ ShuffleNetV2 preprocessing complete! Ready for training.\n")



# # import os  # Provides functions for interacting with the operating system (paths, directories)
# # from PIL import Image  # For opening and processing images
# # import matplotlib.pyplot as plt  # For visualizing images and plots
# # from tqdm import tqdm  # For showing progress bars in loops

# # import torch  # PyTorch core library for tensor computations
# # from torch.utils.data import Dataset, DataLoader  # PyTorch dataset and dataloader utilities
# # from torchvision import transforms  # Image transformation utilities for preprocessing

# # # ------------------ Project Paths ------------------
# # PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"  # Base project folder
# # DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Path to dataset folder
# # TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Path to training images
# # VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Path to validation images
# # TEST_DIR  = os.path.join(DATASET_DIR, "test")  # Path to test images

# # IMG_SIZE = 224  # Target image size (width x height) for model input
# # BATCH_SIZE = 32  # Number of images per batch during training/validation/testing

# # # ------------------ Step 1: Define classes ------------------
# # CLASS_MAP = {  # Mapping of class folder names to numeric labels
# #     "Assamica/tender": 0,
# #     "Assamica/matured": 1,
# #     "DT1/tender": 2,
# #     "DT1/matured": 3
# # }
# # IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}  # Reverse mapping for label-to-class visualization

# # # ------------------ Step 2: Verify folder structure ------------------
# # def verify_folder_structure():
# #     """
# #     Verify that all expected folders for varieties and maturity levels exist in train, valid, test.
# #     Prints status for missing or found folders.
# #     """
# #     print("\n🔹 Verifying dataset folder structure...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         if not os.path.exists(folder):  # Check if main folder exists
# #             print(f"⚠ Folder missing: {folder}")
# #             continue
# #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # List all subfolders (varieties)
# #         for var in varieties:
# #             for maturity in ["tender", "matured"]:  # Check both maturity levels
# #                 cls_path = os.path.join(folder, var, maturity)  # Full path for class folder
# #                 if not os.path.exists(cls_path):  # Missing class folder
# #                     print(f"⚠ Missing class folder: {cls_path}")
# #                 else:  # Class folder exists
# #                     print(f"✔ Found class folder: {cls_path}")
# #     print("✔ Folder verification complete.\n")

# # # ------------------ Step 3: Detect corrupted images ------------------
# # def detect_corrupted_images(dataset_dir):
# #     """
# #     Scan all images in a directory and detect corrupted files that cannot be opened.
# #     Returns a list of corrupted image paths.
# #     """
# #     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
# #     extensions = (".jpg", ".jpeg", ".png", ".webp")  # Supported image file types
# #     corrupted_images = []  # List to store paths of corrupted images

# #     for root, _, files in os.walk(dataset_dir):  # Walk through all subfolders
# #         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
# #             if f.lower().endswith(extensions):  # Process only supported image files
# #                 path = os.path.join(root, f)
# #                 try:
# #                     img = Image.open(path)  # Attempt to open image
# #                     img.verify()  # Verify image integrity
# #                 except Exception:  # Image is corrupted or unreadable
# #                     corrupted_images.append(path)

# #     if corrupted_images:  # Print all corrupted images if any
# #         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
# #         for img_path in corrupted_images:
# #             print("   ", img_path)
# #     else:  # No corrupted images found
# #         print("✔ No corrupted images detected.\n")
# #     return corrupted_images  # Return list for further processing if needed

# # # ------------------ Step 4: Check class balance ------------------
# # def check_class_balance():
# #     """
# #     Count number of images per class for train, valid, and test folders.
# #     Useful to detect imbalances in dataset.
# #     """
# #     print("\n🔹 Checking class balance...")
# #     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
# #         print(f"\nFolder: {folder}")
# #         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # List all varieties
# #         for var in varieties:
# #             counts = {}  # Dictionary to hold counts per maturity
# #             for maturity in ["tender", "matured"]:
# #                 path = os.path.join(folder, var, maturity)
# #                 if os.path.exists(path):
# #                     counts[maturity] = len(os.listdir(path))  # Count images in folder
# #             print(f" Variety: {var}")
# #             for cls, count in counts.items():
# #                 print(f"   {cls}: {count} images")
# #     print("✔ Class balance checked.\n")

# # # ------------------ Step 5: Custom Dataset ------------------
# # class TeaDataset(Dataset):
# #     """
# #     PyTorch Dataset class for loading tea leaf images and labels.
# #     Returns processed image tensors and their corresponding numeric labels.
# #     """
# #     def __init__(self, root_dir, transform=None):
# #         self.root_dir = root_dir  # Root folder for dataset split (train/valid/test)
# #         self.transform = transform  # Image transformations/augmentations
# #         self.images = []  # List to store full image paths
# #         self.labels = []  # Corresponding label list

# #         # Iterate over all varieties and maturity levels to collect image paths
# #         for variety in os.listdir(root_dir):
# #             variety_path = os.path.join(root_dir, variety)
# #             if not os.path.isdir(variety_path):
# #                 continue
# #             for maturity in ["tender", "matured"]:
# #                 class_path = os.path.join(variety_path, maturity)
# #                 if not os.path.exists(class_path):
# #                     continue
# #                 for img_file in os.listdir(class_path):
# #                     if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
# #                         self.images.append(os.path.join(class_path, img_file))  # Store image path
# #                         self.labels.append(CLASS_MAP[f"{variety}/{maturity}"])  # Store numeric label

# #     def __len__(self):
# #         return len(self.images)  # Return total number of samples

# #     def __getitem__(self, idx):
# #         img_path = self.images[idx]
# #         label = self.labels[idx]
# #         img = Image.open(img_path).convert("RGB")  # Ensure image is RGB
# #         if self.transform:
# #             img = self.transform(img)  # Apply transformations
# #         return img, label  # Return image tensor and label

# # # ------------------ Step 6: Transforms ------------------
# # imagenet_mean = [0.485, 0.456, 0.406]  # Mean for ImageNet normalization
# # imagenet_std  = [0.229, 0.224, 0.225]  # Std for ImageNet normalization

# # train_transform = transforms.Compose([
# #     transforms.Resize((IMG_SIZE, IMG_SIZE)),  # Resize image to 224x224
# #     transforms.RandomRotation(20),  # Random rotation ±20 degrees for augmentation
# #     transforms.RandomHorizontalFlip(),  # Random horizontal flip
# #     transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0)),  # Random crop & resize for augmentation
# #     transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),  # Random color changes
# #     transforms.ToTensor(),  # Convert image to PyTorch tensor
# #     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)  # Normalize to ImageNet stats
# # ])

# # val_transform = transforms.Compose([
# #     transforms.Resize((IMG_SIZE, IMG_SIZE)),  # Resize validation/test images
# #     transforms.ToTensor(),  # Convert to tensor
# #     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)  # Normalize
# # ])

# # # ------------------ Step 7: Create datasets & loaders ------------------
# # train_dataset = TeaDataset(TRAIN_DIR, transform=train_transform)  # Training dataset
# # val_dataset   = TeaDataset(VALID_DIR, transform=val_transform)  # Validation dataset
# # test_dataset  = TeaDataset(TEST_DIR, transform=val_transform)  # Test dataset

# # # DataLoaders: efficiently load batches of data during training/testing
# # train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4, pin_memory=True)
# # val_loader   = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)
# # test_loader  = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)

# # # ------------------ Step 8: Visualization & checks ------------------
# # def visualize_batch(loader, n_images=5):
# #     """
# #     Display a batch of images with labels to check preprocessing and augmentations.
# #     """
# #     data_iter = iter(loader)  # Get iterator for DataLoader
# #     images, labels = next(data_iter)  # Get first batch

# #     # Inverse normalization for visualization
# #     inv_normalize = transforms.Normalize(
# #         mean=[-m/s for m, s in zip(imagenet_mean, imagenet_std)],
# #         std=[1/s for s in imagenet_std]
# #     )

# #     plt.figure(figsize=(12, 4))
# #     for i in range(min(n_images, images.size(0))):  # Display up to n_images
# #         img = inv_normalize(images[i]).permute(1, 2, 0).clamp(0, 1).numpy()  # Convert to HWC and clip
# #         label = IDX_TO_CLASS[labels[i].item()]  # Map numeric label to class name
# #         plt.subplot(1, n_images, i+1)
# #         plt.imshow(img)
# #         plt.title(label)
# #         plt.axis("off")
# #     plt.show()

# # def verify_class_mapping():
# #     """
# #     Print class index mapping to verify correct labeling.
# #     """
# #     print("\n🔹 Class index mapping:")
# #     for idx, cls_name in IDX_TO_CLASS.items():
# #         print(f"  {cls_name}: {idx}")
# #     print("✔ Class mapping verified.\n")

# # # ------------------ Step 9: Main ------------------
# # if __name__ == "__main__":
# #     # Verify that folder structure is correct
# #     verify_folder_structure()
# #     # Check if dataset is balanced
# #     check_class_balance()
# #     # Detect corrupted images in each dataset split
# #     detect_corrupted_images(TRAIN_DIR)
# #     detect_corrupted_images(VALID_DIR)
# #     detect_corrupted_images(TEST_DIR)

# #     # Print dataset sizes
# #     print(f"\nTraining samples: {len(train_dataset)}, Validation samples: {len(val_dataset)}, Test samples: {len(test_dataset)}")
    
# #     # Verify class mapping
# #     verify_class_mapping()
# #     # Visualize some training images
# #     visualize_batch(train_loader, n_images=5)

# #     print("✅ ShuffleNetV2 preprocessing complete! Ready for training.\n")






# import os  
# from PIL import Image  
# import matplotlib.pyplot as plt 
# from tqdm import tqdm  

# import torch  # PyTorch core library for tensor computations
# from torch.utils.data import Dataset, DataLoader  # PyTorch dataset and dataloader utilities
# from torchvision import transforms  # Image transformation utilities for preprocessing

# # ------------------ Project Paths ------------------
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"  # Base project folder
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Path to dataset folder
# TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Path to training images
# VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Path to validation images
# TEST_DIR  = os.path.join(DATASET_DIR, "test")  # Path to test images

# IMG_SIZE = 224  # Target image size (width x height) for model input
# BATCH_SIZE = 32  # Number of images per batch during training/validation/testing

# # ------------------ Step 1: Define classes ------------------
# CLASS_MAP = {  # Mapping of class folder names to numeric labels
#     "Assamica/tender": 0,
#     "Assamica/matured": 1,
#     "DT1/tender": 2,
#     "DT1/matured": 3
# }
# IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}  # Reverse mapping for label-to-class visualization

# # ------------------ Step 2: Verify folder structure ------------------
# def verify_folder_structure():
#     """
#     Verify that all expected folders for varieties and maturity levels exist in train, valid, test.
#     Prints status for missing or found folders.
#     """
#     print("\n🔹 Verifying dataset folder structure...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         if not os.path.exists(folder):  # Check if main folder exists
#             print(f"⚠ Folder missing: {folder}")
#             continue
#         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # List all subfolders (varieties)
#         for var in varieties:
#             for maturity in ["tender", "matured"]:  # Check both maturity levels
#                 cls_path = os.path.join(folder, var, maturity)  # Full path for class folder
#                 if not os.path.exists(cls_path):  # Missing class folder
#                     print(f"⚠ Missing class folder: {cls_path}")
#                 else:  # Class folder exists
#                     print(f"✔ Found class folder: {cls_path}")
#     print("✔ Folder verification complete.\n")

# # ------------------ Step 3: Detect corrupted images ------------------
# def detect_corrupted_images(dataset_dir):
#     """
#     Scan all images in a directory and detect corrupted files that cannot be opened.
#     Returns a list of corrupted image paths.
#     """
#     print(f"\n🔹 Detecting corrupted images in {dataset_dir} ...")
#     extensions = (".jpg", ".jpeg", ".png", ".webp")  # Supported image file types
#     corrupted_images = []  # List to store paths of corrupted images

#     for root, _, files in os.walk(dataset_dir):  # Walk through all subfolders
#         for f in tqdm(files, desc=f"Scanning {os.path.basename(root)}", colour="cyan"):
#             if f.lower().endswith(extensions):  # Process only supported image files
#                 path = os.path.join(root, f)
#                 try:
#                     img = Image.open(path)  # Attempt to open image
#                     img.verify()  # Verify image integrity
#                 except Exception:  # Image is corrupted or unreadable
#                     corrupted_images.append(path)

#     if corrupted_images:  # Print all corrupted images if any
#         print(f"\n⚠ Found {len(corrupted_images)} corrupted images:")
#         for img_path in corrupted_images:
#             print("   ", img_path)
#     else:  # No corrupted images found
#         print("✔ No corrupted images detected.\n")
#     return corrupted_images  # Return list for further processing if needed

# # ------------------ Step 4: Check class balance ------------------
# def check_class_balance():
#     """
#     Count number of images per class for train, valid, and test folders.
#     Useful to detect imbalances in dataset.
#     """
#     print("\n🔹 Checking class balance...")
#     for folder in [TRAIN_DIR, VALID_DIR, TEST_DIR]:
#         print(f"\nFolder: {folder}")
#         varieties = [d for d in os.listdir(folder) if os.path.isdir(os.path.join(folder, d))]  # List all varieties
#         for var in varieties:
#             counts = {}  # Dictionary to hold counts per maturity
#             for maturity in ["tender", "matured"]:
#                 path = os.path.join(folder, var, maturity)
#                 if os.path.exists(path):
#                     counts[maturity] = len(os.listdir(path))  # Count images in folder
#             print(f" Variety: {var}")
#             for cls, count in counts.items():
#                 print(f"   {cls}: {count} images")
#     print("✔ Class balance checked.\n")

# # ------------------ Step 5: Custom Dataset ------------------
# class TeaDataset(Dataset):
#     """
#     PyTorch Dataset class for loading tea leaf images and labels.
#     Returns processed image tensors and their corresponding numeric labels.
#     """
#     def __init__(self, root_dir, transform=None):
#         self.root_dir = root_dir  # Root folder for dataset split (train/valid/test)
#         self.transform = transform  # Image transformations/augmentations
#         self.images = []  # List to store full image paths
#         self.labels = []  # Corresponding label list

#         # Iterate over all varieties and maturity levels to collect image paths
#         for variety in os.listdir(root_dir):
#             variety_path = os.path.join(root_dir, variety)
#             if not os.path.isdir(variety_path):
#                 continue
#             for maturity in ["tender", "matured"]:
#                 class_path = os.path.join(variety_path, maturity)
#                 if not os.path.exists(class_path):
#                     continue
#                 for img_file in os.listdir(class_path):
#                     if img_file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
#                         self.images.append(os.path.join(class_path, img_file))  # Store image path
#                         self.labels.append(CLASS_MAP[f"{variety}/{maturity}"])  # Store numeric label

#     def __len__(self):
#         return len(self.images)  # Return total number of samples

#     def __getitem__(self, idx):
#         img_path = self.images[idx]
#         label = self.labels[idx]
#         img = Image.open(img_path).convert("RGB")  # Ensure image is RGB
#         if self.transform:
#             img = self.transform(img)  # Apply transformations
#         return img, label  # Return image tensor and label

# # ------------------ Step 6: Transforms ------------------
# imagenet_mean = [0.485, 0.456, 0.406]  # Mean for ImageNet normalization
# imagenet_std  = [0.229, 0.224, 0.225]  # Std for ImageNet normalization

# train_transform = transforms.Compose([
#     transforms.Resize((IMG_SIZE, IMG_SIZE)),  # Resize image to 224x224
#     transforms.RandomRotation(20),  # Random rotation ±20 degrees for augmentation
#     transforms.RandomHorizontalFlip(),  # Random horizontal flip
#     transforms.RandomResizedCrop(IMG_SIZE, scale=(0.8, 1.0)),  # Random crop & resize for augmentation
#     transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1),  # Random color changes
#     transforms.ToTensor(),  # Convert image to PyTorch tensor
#     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)  # Normalize to ImageNet stats
# ])

# val_transform = transforms.Compose([
#     transforms.Resize((IMG_SIZE, IMG_SIZE)),  # Resize validation/test images
#     transforms.ToTensor(),  # Convert to tensor
#     transforms.Normalize(mean=imagenet_mean, std=imagenet_std)  # Normalize
# ])

# # ------------------ Step 7: Create datasets & loaders ------------------
# train_dataset = TeaDataset(TRAIN_DIR, transform=train_transform)  # Training dataset
# val_dataset   = TeaDataset(VALID_DIR, transform=val_transform)  # Validation dataset
# test_dataset  = TeaDataset(TEST_DIR, transform=val_transform)  # Test dataset

# # DataLoaders: efficiently load batches of data during training/testing
# train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=4, pin_memory=True)
# val_loader   = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)
# test_loader  = DataLoader(test_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=4, pin_memory=True)

# # ------------------ Step 8: Visualization & checks ------------------
# def visualize_batch(loader, n_images=5):
#     """
#     Display a batch of images with labels to check preprocessing and augmentations.
#     """
#     data_iter = iter(loader)  # Get iterator for DataLoader
#     images, labels = next(data_iter)  # Get first batch

#     # Inverse normalization for visualization
#     inv_normalize = transforms.Normalize(
#         mean=[-m/s for m, s in zip(imagenet_mean, imagenet_std)],
#         std=[1/s for s in imagenet_std]
#     )

#     plt.figure(figsize=(12, 4))
#     for i in range(min(n_images, images.size(0))):  # Display up to n_images
#         img = inv_normalize(images[i]).permute(1, 2, 0).clamp(0, 1).numpy()  # Convert to HWC and clip
#         label = IDX_TO_CLASS[labels[i].item()]  # Map numeric label to class name
#         plt.subplot(1, n_images, i+1)
#         plt.imshow(img)
#         plt.title(label)
#         plt.axis("off")
#     plt.show()

# def verify_class_mapping():
#     """
#     Print class index mapping to verify correct labeling.
#     """
#     print("\n🔹 Class index mapping:")
#     for idx, cls_name in IDX_TO_CLASS.items():
#         print(f"  {cls_name}: {idx}")
#     print("✔ Class mapping verified.\n")

# # ------------------ Step 9: Main ------------------
# if __name__ == "__main__":
#     # Verify that folder structure is correct
#     verify_folder_structure()
#     # Check if dataset is balanced
#     check_class_balance()
#     # Detect corrupted images in each dataset split
#     detect_corrupted_images(TRAIN_DIR)
#     detect_corrupted_images(VALID_DIR)
#     detect_corrupted_images(TEST_DIR)

#     # Print dataset sizes
#     print(f"\nTraining samples: {len(train_dataset)}, Validation samples: {len(val_dataset)}, Test samples: {len(test_dataset)}")
    
#     # Verify class mapping
#     verify_class_mapping()
#     # Visualize some training images
#     visualize_batch(train_loader, n_images=5)

#     print("✅ ShuffleNetV2 preprocessing complete! Ready for training.\n")





# """
# PROFESSIONAL TEA LEAF PREPROCESSING PIPELINE FOR SHUFFLENETV2
# =============================================================

# This module implements a comprehensive preprocessing pipeline optimized for
# ShuffleNetV2-based tea leaf maturity classification. It includes:
# 1. Dataset validation and quality checks
# 2. Domain-specific augmentations for tea leaves
# 3. Professional transforms aligned with ImageNet standards
# 4. Visualization and analysis tools
# 5. Windows-compatible multiprocessing
# """

# # ======================================================================
# # SECTION 1: IMPORT ESSENTIAL LIBRARIES
# # ======================================================================
# """
# Purpose: Import all necessary Python libraries for the preprocessing pipeline.
# Key libraries:
# - os, numpy: File operations and numerical computations
# - PIL: Image processing
# - torch: Deep learning framework
# - torchvision: Image transforms and models
# - cv2: Computer vision operations for custom augmentations
# - matplotlib: Visualization
# """

# import os  # Operating system interface for file/directory operations
# import numpy as np  # Numerical computing library for array operations
# from PIL import Image  # Python Imaging Library for image processing
# import matplotlib.pyplot as plt  # Plotting library for visualizations
# from tqdm import tqdm  # Progress bar for loops
# import random  # Random number generation for reproducibility
# from collections import Counter  # Count hashable objects (for class distribution)

# import torch  # PyTorch core library for tensor operations and neural networks
# import torch.nn as nn  # Neural network modules
# from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler  # Data handling utilities
# from torchvision import transforms, models  # Image transforms and pre-trained models
# import torchvision.transforms.functional as F  # Functional transforms for custom operations
# import cv2  # OpenCV for advanced image processing operations

# # ======================================================================
# # SECTION 2: SETUP REPRODUCIBILITY
# # ======================================================================
# """
# Purpose: Ensure reproducible results by setting random seeds across all libraries.
# Importance: Critical for research to get same results on different runs.
# """

# def set_seed(seed=42):
#     """
#     Set random seeds for all random number generators to ensure reproducibility.
    
#     Args:
#         seed (int): Random seed value (default: 42)
#     """
#     random.seed(seed)  # Python built-in random module
#     np.random.seed(seed)  # NumPy random number generator
#     torch.manual_seed(seed)  # PyTorch CPU random seed
#     torch.cuda.manual_seed(seed)  # PyTorch GPU random seed
#     torch.cuda.manual_seed_all(seed)  # For multi-GPU setups
#     torch.backends.cudnn.deterministic = True  # Use deterministic algorithms for CuDNN
#     torch.backends.cudnn.benchmark = False  # Disable CuDNN auto-tuner for reproducibility
#     os.environ['PYTHONHASHSEED'] = str(seed)  # Set Python hash seed

# set_seed(42)  # Initialize with seed 42 (common in research)

# # ======================================================================
# # SECTION 3: PROJECT PATHS CONFIGURATION
# # ======================================================================
# """
# Purpose: Define absolute paths to dataset directories for platform independence.
# Structure: Follows standard train/valid/test split organization.
# """

# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"  # Root project directory
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")  # Path to main dataset folder
# TRAIN_DIR = os.path.join(DATASET_DIR, "train")  # Training images directory
# VALID_DIR = os.path.join(DATASET_DIR, "valid")  # Validation images directory
# TEST_DIR = os.path.join(DATASET_DIR, "test")  # Testing images directory

# # ======================================================================
# # SECTION 4: TRAINING CONFIGURATION PARAMETERS
# # ======================================================================
# """
# Purpose: Centralized configuration for model training parameters.
# Key parameters:
# - IMG_SIZE: Input size for ShuffleNetV2 (224x224 as per ImageNet)
# - BATCH_SIZE: Number of samples per gradient update
# - NUM_WORKERS: Data loading threads (0 for Windows compatibility)
# - PIN_MEMORY: Speed up data transfer to GPU
# """

# IMG_SIZE = 224  # Target image size (ShuffleNetV2 expects 224x224 RGB images)
# BATCH_SIZE = 32  # Number of images processed in one batch (optimizes memory/performance)
# NUM_WORKERS = 0  # Number of subprocesses for data loading (0=main process only, Windows-safe)
# PIN_MEMORY = True if torch.cuda.is_available() else False  # Pin memory for faster GPU transfer

# # ======================================================================
# # SECTION 5: CLASS MAPPING DEFINITION
# # ======================================================================
# """
# Purpose: Define mapping between class names and numerical labels.
# Structure: Two-way mapping for easy conversion between labels and class names.
# """

# CLASS_MAP = {
#     "Assamica/tender": 0,    # Class 0: Assamica variety, tender leaves
#     "Assamica/matured": 1,   # Class 1: Assamica variety, matured leaves
#     "DT1/tender": 2,         # Class 2: DT1 variety, tender leaves
#     "DT1/matured": 3         # Class 3: DT1 variety, matured leaves
# }

# # Reverse mapping: Convert numerical labels back to class names
# IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}  # Creates {0: "Assamica/tender", ...}

# # List of class names in order (useful for plotting and reporting)
# CLASS_NAMES = [IDX_TO_CLASS[i] for i in range(len(CLASS_MAP))]

# # ======================================================================
# # SECTION 6: DOMAIN-SPECIFIC AUGMENTATIONS FOR TEA LEAVES
# # ======================================================================
# """
# Purpose: Custom augmentation techniques specifically designed for tea leaf images.
# Key techniques:
# 1. Perspective transformation: Simulates leaf curvature
# 2. Occlusion simulation: Mimics shadows/overlaps
# 3. Color temperature adjustment: Simulates lighting variations
# """

# class AdvancedLeafAugmentation:
#     """
#     Custom augmentation techniques optimized for tea leaf characteristics.
#     These augmentations help the model learn robust features by simulating
#     real-world variations in leaf appearance.
#     """
    
#     @staticmethod
#     def random_leaf_perspective(img, distortion_scale=0.2):
#         """
#         Apply perspective transformation to simulate natural leaf curvature.
        
#         Args:
#             img (PIL.Image): Input image
#             distortion_scale (float): Maximum distortion as fraction of image dimensions
        
#         Returns:
#             PIL.Image: Transformed image with perspective distortion
#         """
#         if random.random() > 0.5:  # Apply with 50% probability
#             return img  # Return original image if random check fails
        
#         width, height = img.size  # Get image dimensions
        
#         # Define original corners (starting points for perspective transform)
#         startpoints = [
#             [0, 0],  # Top-left corner
#             [width - 1, 0],  # Top-right corner
#             [width - 1, height - 1],  # Bottom-right corner
#             [0, height - 1]  # Bottom-left corner
#         ]
        
#         # Create distorted corners (ending points for perspective transform)
#         endpoints = [
#             # Top-left corner with random distortion
#             [int(random.uniform(0, distortion_scale * width)), 
#              int(random.uniform(0, distortion_scale * height))],
#             # Top-right corner with random distortion
#             [int(random.uniform((1 - distortion_scale) * width, width)), 
#              int(random.uniform(0, distortion_scale * height))],
#             # Bottom-right corner with random distortion
#             [int(random.uniform((1 - distortion_scale) * width, width)), 
#              int(random.uniform((1 - distortion_scale) * height, height))],
#             # Bottom-left corner with random distortion
#             [int(random.uniform(0, distortion_scale * width)), 
#              int(random.uniform((1 - distortion_scale) * height, height))]
#         ]
        
#         # Apply perspective transformation
#         return F.perspective(img, startpoints, endpoints)
    
#     @staticmethod
#     def random_leaf_occlusion(img, max_occlusion_size=0.3):
#         """
#         Simulate partial leaf occlusion (e.g., from shadows or overlapping leaves).
        
#         Args:
#             img (PIL.Image): Input image
#             max_occlusion_size (float): Maximum occlusion size as fraction of image
        
#         Returns:
#             PIL.Image: Image with simulated occlusion
#         """
#         if random.random() > 0.7:  # Apply with 30% probability
#             return img  # Return original image 70% of the time
        
#         # Convert PIL Image to NumPy array for OpenCV processing
#         img_array = np.array(img)
#         h, w, _ = img_array.shape  # Get image height and width
        
#         # Generate random elliptical occlusion parameters
#         occl_h = int(h * random.uniform(0.05, max_occlusion_size))  # Occlusion height
#         occl_w = int(w * random.uniform(0.05, max_occlusion_size))  # Occlusion width
#         center_x = random.randint(0, w)  # Random x-coordinate for occlusion center
#         center_y = random.randint(0, h)  # Random y-coordinate for occlusion center
        
#         # Create binary mask (white=keep, black=occlude)
#         mask = np.ones((h, w), dtype=np.uint8) * 255  # Initialize as all white (255)
        
#         # Draw filled black ellipse on mask (occlusion area)
#         cv2.ellipse(mask, (center_x, center_y), (occl_w//2, occl_h//2), 
#                    0, 0, 360, 0, -1)  # -1 = filled ellipse
        
#         # Apply Gaussian blur to create soft occlusion edges
#         mask = cv2.GaussianBlur(mask, (21, 21), 10)  # Kernel size 21, sigma=10
#         mask = mask / 255.0  # Normalize mask to [0, 1] range
        
#         # Blend original image with mean color using the mask
#         for c in range(3):  # Iterate through RGB channels
#             img_array[:, :, c] = img_array[:, :, c] * mask + \
#                                 img_array[:, :, c].mean() * (1 - mask)
        
#         # Convert back to PIL Image
#         return Image.fromarray(np.uint8(img_array))
    
#     @staticmethod
#     def random_leaf_color_temperature(img, temperature_range=(-50, 50)):
#         """
#         Adjust color temperature to simulate different lighting conditions.
        
#         Args:
#             img (PIL.Image): Input image
#             temperature_range (tuple): Min and max temperature adjustment values
        
#         Returns:
#             PIL.Image: Color temperature adjusted image
#         """
#         if random.random() > 0.5:  # Apply with 50% probability
#             return img  # Return original image half the time
        
#         # Random temperature value within specified range
#         temperature = random.uniform(*temperature_range)
        
#         # Convert to NumPy array with float32 for precise calculations
#         img_array = np.array(img, dtype=np.float32)
        
#         # Apply temperature adjustment (warm/cool effect)
#         if temperature > 0:  # Warm temperature (increase red, decrease blue)
#             img_array[:, :, 0] *= 1 + (temperature / 100)  # Increase red channel
#             img_array[:, :, 2] *= 1 - (temperature / 200)  # Decrease blue channel
#         else:  # Cool temperature (slight increase red, decrease blue)
#             img_array[:, :, 0] *= 1 + (temperature / 200)  # Slight red adjustment
#             img_array[:, :, 2] *= 1 - (temperature / 100)  # Decrease blue channel
        
#         # Clip values to valid RGB range [0, 255]
#         img_array = np.clip(img_array, 0, 255)
        
#         # Convert back to PIL Image
#         return Image.fromarray(np.uint8(img_array))

# # ======================================================================
# # SECTION 7: PICKLE-SAFE TRANSFORM WRAPPERS
# # ======================================================================
# """
# Purpose: Create wrapper functions that can be pickled (serialized) for
# Windows multiprocessing compatibility.
# Problem: Lambda functions in transforms can't be pickled on Windows.
# Solution: Define named functions that wrap the augmentation methods.
# """

# def create_leaf_perspective_transform(distortion_scale=0.15):
#     """
#     Create a pickle-safe wrapper for perspective transform.
    
#     Args:
#         distortion_scale (float): Maximum distortion scale
    
#     Returns:
#         function: Pickle-safe transform function
#     """
#     def transform(img):
#         """Apply perspective transformation to image."""
#         return AdvancedLeafAugmentation.random_leaf_perspective(img, distortion_scale)
#     return transform

# def create_leaf_occlusion_transform(max_occlusion_size=0.25):
#     """
#     Create a pickle-safe wrapper for occlusion transform.
    
#     Args:
#         max_occlusion_size (float): Maximum occlusion size
    
#     Returns:
#         function: Pickle-safe transform function
#     """
#     def transform(img):
#         """Apply occlusion simulation to image."""
#         return AdvancedLeafAugmentation.random_leaf_occlusion(img, max_occlusion_size)
#     return transform

# def create_leaf_color_temperature_transform(temperature_range=(-50, 50)):
#     """
#     Create a pickle-safe wrapper for color temperature transform.
    
#     Args:
#         temperature_range (tuple): Temperature adjustment range
    
#     Returns:
#         function: Pickle-safe transform function
#     """
#     def transform(img):
#         """Apply color temperature adjustment to image."""
#         return AdvancedLeafAugmentation.random_leaf_color_temperature(img, temperature_range)
#     return transform

# # ======================================================================
# # SECTION 8: PROFESSIONAL TRANSFORMATION PIPELINES
# # ======================================================================
# """
# Purpose: Define comprehensive transformation pipelines for training,
# validation, and testing phases.
# Key features:
# - Training: Heavy augmentation for generalization
# - Validation: Minimal augmentation for accurate evaluation
# - Testing: No augmentation for final evaluation
# All transforms use ImageNet normalization for compatibility with pretrained models.
# """

# class ProfessionalTeaLeafTransforms:
#     """
#     Complete preprocessing pipeline optimized for ShuffleNetV2 tea leaf classification.
#     Follows ImageNet standards while adding domain-specific augmentations.
#     """
    
#     @staticmethod
#     def get_train_transform():
#         """
#         Create training transform with extensive augmentations.
        
#         Strategy: Apply strong augmentations to prevent overfitting and
#         improve model generalization on small dataset.
        
#         Returns:
#             transforms.Compose: Training transformation pipeline
#         """
#         return transforms.Compose([
#             # Stage 1: Resize for aspect ratio preservation
#             # Resize shorter side to 256 pixels while maintaining aspect ratio
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
            
#             # Stage 2: Geometric augmentations (applied 70% of time)
#             # Random affine transformations for spatial robustness
#             transforms.RandomApply([
#                 transforms.RandomAffine(
#                     degrees=15,  # Random rotation up to ±15 degrees
#                     translate=(0.1, 0.1),  # Random translation up to 10% of image size
#                     scale=(0.85, 1.15),  # Random scaling between 85% and 115%
#                     shear=8,  # Random shear up to ±8 degrees
#                     interpolation=transforms.InterpolationMode.BILINEAR  # Smooth interpolation
#                 )
#             ], p=0.7),  # Apply with 70% probability
            
#             # Stage 3: Random cropping with leaf-specific aspect ratios
#             # Crop to target size with random scale and leaf-appropriate aspect ratio
#             transforms.RandomResizedCrop(
#                 IMG_SIZE,  # Target size: 224x224
#                 scale=(0.7, 1.0),  # Crop between 70% and 100% of original area
#                 ratio=(0.8, 1.2),  # Aspect ratio range (slightly wider for leaf shapes)
#                 interpolation=transforms.InterpolationMode.BILINEAR  # Smooth interpolation
#             ),
            
#             # Stage 4: Basic flipping and rotation augmentations
#             transforms.RandomHorizontalFlip(p=0.5),  # Mirror image horizontally (50% chance)
#             transforms.RandomVerticalFlip(p=0.1),  # Mirror vertically (10% chance, rare for leaves)
#             transforms.RandomRotation(25, interpolation=transforms.InterpolationMode.BILINEAR),  # Rotate ±25 degrees
            
#             # Stage 5: Color augmentations (applied 80% of time)
#             # Random color adjustments to simulate lighting and camera variations
#             transforms.RandomApply([
#                 transforms.ColorJitter(
#                     brightness=0.15,  # Random brightness adjustment (±15%)
#                     contrast=0.15,    # Random contrast adjustment (±15%)
#                     saturation=0.15,  # Random saturation adjustment (±15%)
#                     hue=0.05          # Random hue adjustment (±5%)
#                 )
#             ], p=0.8),  # Apply with 80% probability
            
#             # Stage 6: Domain-specific custom augmentations (pickle-safe wrappers)
#             transforms.Lambda(create_leaf_perspective_transform(0.15)),  # Leaf curvature simulation
#             transforms.Lambda(create_leaf_occlusion_transform(0.25)),  # Partial occlusion simulation
#             transforms.Lambda(create_leaf_color_temperature_transform()),  # Lighting variation simulation
            
#             # Stage 7: Quality enhancements (applied 30% of time)
#             # Simulate camera focus variations
#             transforms.RandomApply([
#                 transforms.GaussianBlur(kernel_size=3, sigma=(0.1, 1.0))  # Mild blurring
#             ], p=0.3),  # Apply with 30% probability
            
#             # Stage 8: Convert to PyTorch tensor and normalize to [0, 1]
#             transforms.ToTensor(),  # Converts PIL Image to tensor, scales to [0, 1]
            
#             # Stage 9: Normalization (CRITICAL for pretrained ShuffleNetV2)
#             # Normalize using ImageNet statistics for compatibility with pretrained weights
#             transforms.Normalize(
#                 mean=[0.485, 0.456, 0.406],  # ImageNet mean for RGB channels
#                 std=[0.229, 0.224, 0.225]    # ImageNet standard deviation for RGB channels
#             ),
            
#             # Stage 10: Regularization with Random Erasing (applied 30% of time)
#             # Randomly mask parts of image to prevent over-reliance on specific regions
#             transforms.RandomErasing(
#                 p=0.3,  # Apply with 30% probability
#                 scale=(0.02, 0.12),  # Erasing area between 2% and 12% of image
#                 ratio=(0.3, 3.3),  # Aspect ratio of erased region
#                 value='random'  # Fill with random values (simulates noise)
#             )
#         ])
    
#     @staticmethod
#     def get_val_transform():
#         """
#         Create validation transform (deterministic, no randomness).
        
#         Strategy: Use minimal, deterministic transforms for consistent
#         evaluation across epochs.
        
#         Returns:
#             transforms.Compose: Validation transformation pipeline
#         """
#         return transforms.Compose([
#             # Resize to standard size (same as training)
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
#             # Center crop to target size (no randomness)
#             transforms.CenterCrop(IMG_SIZE),
#             # Convert to tensor
#             transforms.ToTensor(),
#             # Normalize using ImageNet statistics
#             transforms.Normalize(
#                 mean=[0.485, 0.456, 0.406],
#                 std=[0.229, 0.224, 0.225]
#             )
#         ])
    
#     @staticmethod
#     def get_test_transform():
#         """
#         Create test transform (identical to validation).
        
#         Strategy: Consistent preprocessing for fair model evaluation.
        
#         Returns:
#             transforms.Compose: Test transformation pipeline
#         """
#         return transforms.Compose([
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.CenterCrop(IMG_SIZE),
#             transforms.ToTensor(),
#             transforms.Normalize(
#                 mean=[0.485, 0.456, 0.406],
#                 std=[0.229, 0.224, 0.225]
#             )
#         ])

# # ======================================================================
# # SECTION 9: ENHANCED DATASET CLASS
# # ======================================================================
# """
# Purpose: Custom PyTorch Dataset class with comprehensive features:
# 1. Automatic dataset loading and validation
# 2. Error handling for corrupted images
# 3. Metadata tracking for analysis
# 4. Class imbalance detection and handling
# 5. Statistical reporting
# """

# class ProfessionalTeaDataset(Dataset):
#     """
#     Enhanced PyTorch Dataset class for tea leaf images with comprehensive
#     error handling, metadata tracking, and statistical analysis.
#     """
    
#     def __init__(self, root_dir, transform=None, phase="train"):
#         """
#         Initialize dataset.
        
#         Args:
#             root_dir (str): Path to dataset directory
#             transform (callable): Transformations to apply to images
#             phase (str): Dataset phase ("train", "validation", "test")
#         """
#         self.root_dir = root_dir  # Root directory for this dataset split
#         self.transform = transform  # Image transformation pipeline
#         self.phase = phase  # Dataset phase (for reporting)
#         self.images = []  # List to store image file paths
#         self.labels = []  # List to store corresponding labels
#         self.image_paths = []  # List of all image paths (for visualization)
#         self.metadata = []  # List of metadata dictionaries for each image
        
#         self._load_dataset()  # Load images and labels
#         self._print_statistics()  # Print dataset statistics
    
#     def _load_dataset(self):
#         """
#         Load dataset from directory structure.
        
#         Directory structure expected:
#         root_dir/
#           variety1/
#             tender/
#               image1.jpg
#               image2.jpg
#             matured/
#               image3.jpg
#               image4.jpg
#           variety2/
#             ...
#         """
#         print(f"\n Loading dataset from: {self.root_dir}")
        
#         # Iterate through all varieties in the directory
#         for variety in os.listdir(self.root_dir):
#             variety_path = os.path.join(self.root_dir, variety)
            
#             # Skip if not a directory
#             if not os.path.isdir(variety_path):
#                 continue
            
#             # Process both maturity levels
#             for maturity in ["tender", "matured"]:
#                 # Construct path to class directory
#                 class_path = os.path.join(variety_path, maturity)
                
#                 # Skip if class directory doesn't exist
#                 if not os.path.exists(class_path):
#                     print(f" Warning: Missing class folder {class_path}")
#                     continue
                
#                 # Create class name string
#                 class_name = f"{variety}/{maturity}"
                
#                 # Verify class is in mapping
#                 if class_name not in CLASS_MAP:
#                     print(f" Warning: Unknown class {class_name}")
#                     continue
                
#                 # Get numerical label for this class
#                 label = CLASS_MAP[class_name]
                
#                 # Get all image files in class directory
#                 image_files = [f for f in os.listdir(class_path) 
#                              if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp'))]
                
#                 # Add each image to dataset
#                 for img_file in image_files:
#                     img_path = os.path.join(class_path, img_file)
#                     self.images.append(img_path)  # Store image path
#                     self.labels.append(label)  # Store corresponding label
#                     self.image_paths.append(img_path)  # Store path for visualization
                    
#                     # Store metadata for analysis
#                     self.metadata.append({
#                         'path': img_path,  # Full image path
#                         'variety': variety,  # Tea variety
#                         'maturity': maturity,  # Maturity level
#                         'class_id': label,  # Numerical label
#                         'class_name': class_name,  # Human-readable class name
#                         'filename': img_file  # Original filename
#                     })
        
#         print(f" Loaded {len(self.images)} images with {len(set(self.labels))} classes")
    
#     def _print_statistics(self):
#         """
#         Print detailed statistics about the dataset.
        
#         Reports:
#         - Number of images per class
#         - Percentage distribution
#         - Class imbalance detection
#         """
#         # Count images per class using Counter
#         class_counts = Counter(self.labels)
        
#         print(f"\n Dataset Statistics for {self.phase}:")
#         print("-" * 40)  # Separator line
        
#         # Print statistics for each class
#         for class_id, count in sorted(class_counts.items()):
#             class_name = IDX_TO_CLASS[class_id]  # Get class name from ID
#             percentage = (count / len(self.images)) * 100  # Calculate percentage
#             print(f"  {class_name:30s}: {count:4d} images ({percentage:.1f}%)")
        
#         print("-" * 40)
#         print(f"  Total images: {len(self.images)}")
        
#         # Check for class imbalance
#         max_count = max(class_counts.values())  # Largest class
#         min_count = min(class_counts.values())  # Smallest class
#         imbalance_ratio = max_count / min_count if min_count > 0 else float('inf')
        
#         # Warn if significant imbalance detected
#         if imbalance_ratio > 3:
#             print(f"⚠ Warning: Class imbalance detected (ratio: {imbalance_ratio:.1f}x)")
    
#     def __len__(self):
#         """
#         Return total number of samples in dataset.
        
#         Returns:
#             int: Number of images in dataset
#         """
#         return len(self.images)
    
#     def __getitem__(self, idx):
#         """
#         Get a single sample from the dataset.
        
#         Args:
#             idx (int): Index of sample to retrieve
        
#         Returns:
#             tuple: (image_tensor, label) or fallback if error occurs
#         """
#         try:
#             # Get image path and label
#             img_path = self.images[idx]
#             label = self.labels[idx]
            
#             # Load image and convert to RGB (handles grayscale images)
#             img = Image.open(img_path).convert('RGB')
            
#             # Apply transformations if specified
#             if self.transform:
#                 img = self.transform(img)
            
#             return img, label  # Return image tensor and label
            
#         except Exception as e:
#             # Handle errors (corrupted images, etc.)
#             print(f" Error loading image {img_path}: {str(e)}")
            
#             # Return dummy image as fallback (prevents training crash)
#             dummy_img = torch.zeros((3, IMG_SIZE, IMG_SIZE))  # Black image
#             return dummy_img, 0  # Return dummy image with label 0
    
#     def get_class_weights(self):
#         """
#         Calculate class weights for handling class imbalance.
        
#         Formula: weight = total_samples / (num_classes * class_count)
#         Higher weight for underrepresented classes.
        
#         Returns:
#             torch.Tensor: Weight for each class
#         """
#         # Count images per class
#         class_counts = Counter(self.labels)
#         total_samples = len(self.labels)
#         num_classes = len(CLASS_MAP)
        
#         weights = []
#         # Calculate weight for each class
#         for i in range(num_classes):
#             if i in class_counts:
#                 # Inverse frequency weighting
#                 weight = total_samples / (num_classes * class_counts[i])
#                 weights.append(weight)
#             else:
#                 weights.append(0)  # Zero weight if class not present
        
#         # Convert to PyTorch tensor
#         weights = torch.FloatTensor(weights)
#         return weights

# # ======================================================================
# # SECTION 10: COMPREHENSIVE DATA QUALITY VERIFICATION
# # ======================================================================
# """
# Purpose: Perform thorough validation of dataset quality before training.
# Checks:
# 1. Folder structure integrity
# 2. Image format compatibility
# 3. Image corruption detection
# 4. Dimension analysis
# """

# def perform_comprehensive_quality_check():
#     """
#     Perform comprehensive quality checks on the entire dataset.
    
#     Returns:
#         list: Paths to corrupted images (if any)
#     """
#     print("\n" + "="*60)
#     print(" COMPREHENSIVE DATASET QUALITY CHECK")
#     print("="*60)
    
#     # 1. Folder structure verification
#     print("\n Folder Structure Verification:")
#     for folder_name, folder_path in [("Train", TRAIN_DIR), 
#                                      ("Valid", VALID_DIR), 
#                                      ("Test", TEST_DIR)]:
#         if os.path.exists(folder_path):
#             print(f"   {folder_name}: {folder_path}")
#             # Check each variety in the folder
#             for variety in os.listdir(folder_path):
#                 var_path = os.path.join(folder_path, variety)
#                 if os.path.isdir(var_path):
#                     # Check both maturity levels
#                     for maturity in ["tender", "matured"]:
#                         class_path = os.path.join(var_path, maturity)
#                         if os.path.exists(class_path):
#                             # Count images in class folder
#                             img_count = len([f for f in os.listdir(class_path) 
#                                            if f.lower().endswith(('.jpg', '.jpeg', '.png'))])
#                             print(f"      {variety}/{maturity}: {img_count} images")
#         else:
#             print(f"   {folder_name}: Missing!")
    
#     # 2. Image format and corruption check
#     print("\n2️⃣ Image Format Analysis:")
#     image_formats = {}  # Dictionary to count formats
#     corrupted_images = []  # List to track corrupted images
    
#     # Walk through all directories in dataset
#     for root, _, files in os.walk(DATASET_DIR):
#         for file in files:
#             # Check if file is an image
#             if file.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp')):
#                 ext = file.split('.')[-1].lower()  # Get file extension
#                 image_formats[ext] = image_formats.get(ext, 0) + 1  # Count format
                
#                 # Check for corruption
#                 try:
#                     img_path = os.path.join(root, file)
#                     with Image.open(img_path) as img:
#                         img.verify()  # Verify image integrity
#                 except Exception as e:
#                     corrupted_images.append((img_path, str(e)))  # Track corrupted image
    
#     # Print format statistics
#     print("   Image formats found:")
#     for fmt, count in image_formats.items():
#         print(f"      .{fmt}: {count} images")
    
#     # Report corrupted images
#     if corrupted_images:
#         print(f"    Found {len(corrupted_images)} corrupted images!")
#         for img_path, error in corrupted_images[:5]:  # Show first 5
#             print(f"      {os.path.basename(img_path)}: {error}")
#         if len(corrupted_images) > 5:
#             print(f"      ... and {len(corrupted_images)-5} more")
#     else:
#         print("   No corrupted images found!")
    
#     # 3. Image dimension analysis
#     print("\n Image Dimension Analysis:")
#     dimensions = []  # List to store image dimensions
    
#     # Analyze dimensions in training set
#     for root, _, files in os.walk(TRAIN_DIR):
#         for file in files:
#             if file.lower().endswith(('.jpg', '.jpeg', '.png')):
#                 try:
#                     img_path = os.path.join(root, file)
#                     with Image.open(img_path) as img:
#                         dimensions.append(img.size)  # Store (width, height)
#                 except:
#                     continue  # Skip if can't open
    
#     # Calculate and report average dimensions
#     if dimensions:
#         avg_width = sum(w for w, h in dimensions) / len(dimensions)
#         avg_height = sum(h for w, h in dimensions) / len(dimensions)
#         print(f"   Average dimensions: {avg_width:.0f}x{avg_height:.0f}")
#         print(f"   Target size for ShuffleNetV2: {IMG_SIZE}x{IMG_SIZE}")
#     else:
#         print("   No valid images found for dimension analysis")
    
#     print("\n" + "="*60)
#     print(" Quality check complete!")
#     print("="*60 + "\n")
    
#     return corrupted_images  # Return list of corrupted images

# # ======================================================================
# # SECTION 11: DATA LOADER CREATION
# # ======================================================================
# """
# Purpose: Create PyTorch DataLoader objects for efficient batch processing.
# Features:
# - Weighted sampling for class imbalance
# - Windows-compatible multiprocessing
# - Proper memory pinning for GPU acceleration
# """

# def create_data_loaders():
#     """
#     Create professional data loaders with optional weighted sampling.
    
#     Returns:
#         tuple: (train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset)
#     """
#     print("\n Creating Data Loaders...")
    
#     # Initialize transforms for each dataset split
#     train_transform = ProfessionalTeaLeafTransforms.get_train_transform()
#     val_transform = ProfessionalTeaLeafTransforms.get_val_transform()
#     test_transform = ProfessionalTeaLeafTransforms.get_test_transform()
    
#     # Create dataset objects
#     print(" Loading datasets...")
#     train_dataset = ProfessionalTeaDataset(TRAIN_DIR, train_transform, "train")
#     val_dataset = ProfessionalTeaDataset(VALID_DIR, val_transform, "validation")
#     test_dataset = ProfessionalTeaDataset(TEST_DIR, test_transform, "test")
    
#     # Calculate class weights for handling imbalance
#     if len(train_dataset) > 0:
#         class_weights = train_dataset.get_class_weights()
#         print(f" Class weights for sampling: {class_weights.tolist()}")
        
#         # Create weighted sampler (samples underrepresented classes more frequently)
#         weights = [class_weights[label] for label in train_dataset.labels]
#         sampler = WeightedRandomSampler(weights, len(weights), replacement=True)
#     else:
#         sampler = None  # No sampler if dataset empty
    
#     # Create data loaders
#     print(" Creating data loaders...")
    
#     # Training data loader
#     train_loader = DataLoader(
#         train_dataset,
#         batch_size=BATCH_SIZE,
#         sampler=sampler if sampler else None,  # Use weighted sampler if available
#         shuffle=True if sampler is None else False,  # Shuffle if not using sampler
#         num_workers=NUM_WORKERS,  # Windows-safe (0 workers)
#         pin_memory=PIN_MEMORY,  # Pin memory for faster GPU transfer
#         drop_last=True  # Drop last incomplete batch for stable batch normalization
#     )
    
#     # Validation data loader
#     val_loader = DataLoader(
#         val_dataset,
#         batch_size=BATCH_SIZE,
#         shuffle=False,  # No shuffling for validation
#         num_workers=NUM_WORKERS,
#         pin_memory=PIN_MEMORY
#     )
    
#     # Test data loader
#     test_loader = DataLoader(
#         test_dataset,
#         batch_size=BATCH_SIZE,
#         shuffle=False,  # No shuffling for testing
#         num_workers=NUM_WORKERS,
#         pin_memory=PIN_MEMORY
#     )
    
#     print(" Data loaders created successfully!")
#     print(f"   Training batches: {len(train_loader)}")
#     print(f"   Validation batches: {len(val_loader)}")
#     print(f"   Test batches: {len(test_loader)}")
    
#     return train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset

# # ======================================================================
# # SECTION 12: VISUALIZATION TOOLS
# # ======================================================================
# """
# Purpose: Provide comprehensive visualization tools for:
# 1. Data augmentation inspection
# 2. Batch visualization
# 3. Dataset distribution analysis
# These tools help researchers understand data characteristics and preprocessing effects.
# """

# class Visualizer:
#     """
#     Professional visualization tools for data inspection and analysis.
#     """
    
#     @staticmethod
#     def visualize_augmentations(dataset, num_samples=4):
#         """
#         Visualize original vs augmented images side by side.
        
#         Args:
#             dataset (ProfessionalTeaDataset): Dataset to visualize
#             num_samples (int): Number of samples to display
#         """
#         print("\n Visualizing Data Augmentations...")
        
#         # Randomly select samples
#         indices = np.random.choice(len(dataset), min(num_samples, len(dataset)), replace=False)
        
#         # Create figure with 2 rows (original and augmented)
#         fig, axes = plt.subplots(2, num_samples, figsize=(4*num_samples, 8))
#         fig.suptitle('Data Augmentation Examples', fontsize=16, fontweight='bold')
        
#         # Create inverse normalization transform for visualization
#         inv_normalize = transforms.Normalize(
#             mean=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
#             std=[1/0.229, 1/0.224, 1/0.225]
#         )
        
#         # Plot each sample
#         for i, idx in enumerate(indices):
#             # Get original image
#             img_path = dataset.image_paths[idx]
#             orig_img = Image.open(img_path).convert('RGB')
            
#             # Get augmented image from dataset
#             aug_img, label = dataset[idx]
            
#             # Plot original image (top row)
#             axes[0, i].imshow(orig_img)
#             axes[0, i].set_title(f"Original\n{dataset.metadata[idx]['class_name']}")
#             axes[0, i].axis('off')
            
#             # Plot augmented image (bottom row)
#             if aug_img.dim() == 3:  # Check if it's a valid image tensor
#                 # Denormalize and convert to displayable format
#                 aug_img_disp = inv_normalize(aug_img).permute(1, 2, 0).clamp(0, 1).cpu().numpy()
#                 axes[1, i].imshow(aug_img_disp)
#                 axes[1, i].set_title(f"Augmented\nClass: {IDX_TO_CLASS[label]}")
#                 axes[1, i].axis('off')
        
#         plt.tight_layout()  # Adjust layout
#         plt.show()  # Display plot
    
#     @staticmethod
#     def visualize_batch(loader, title="Batch Visualization"):
#         """
#         Visualize a batch of images with labels.
        
#         Args:
#             loader (DataLoader): DataLoader to visualize batch from
#             title (str): Plot title
#         """
#         print(f"\n👁 {title}...")
        
#         # Create temporary loader without multiprocessing for visualization
#         loader_copy = DataLoader(
#             loader.dataset,
#             batch_size=min(8, BATCH_SIZE),  # Smaller batch for visualization
#             shuffle=False,
#             num_workers=0,  # Force single process for visualization
#             pin_memory=False  # No memory pinning for visualization
#         )
        
#         # Get one batch
#         data_iter = iter(loader_copy)
#         images, labels = next(data_iter)
        
#         # Create inverse normalization transform
#         inv_normalize = transforms.Normalize(
#             mean=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
#             std=[1/0.229, 1/0.224, 1/0.225]
#         )
        
#         # Create visualization grid
#         batch_size = min(images.size(0), 8)  # Max 8 images
#         fig, axes = plt.subplots(2, 4, figsize=(16, 8))
#         fig.suptitle(title, fontsize=16, fontweight='bold')
        
#         # Plot each image in batch
#         for i in range(batch_size):
#             row, col = divmod(i, 4)  # Calculate grid position
#             # Denormalize and prepare image for display
#             img = inv_normalize(images[i]).permute(1, 2, 0).clamp(0, 1).cpu().numpy()
#             class_name = IDX_TO_CLASS[labels[i].item()]  # Get class name
            
#             # Display image
#             axes[row, col].imshow(img)
#             axes[row, col].set_title(f"Label: {class_name}\nShape: {images[i].shape}")
#             axes[row, col].axis('off')
        
#         plt.tight_layout()
#         plt.show()
    
#     @staticmethod
#     def plot_dataset_distribution(datasets):
#         """
#         Plot class distribution across train, validation, and test datasets.
        
#         Args:
#             datasets (list): List of three datasets (train, val, test)
#         """
#         print("\n📈 Visualizing Dataset Distribution...")
        
#         # Create figure with 3 subplots
#         fig, axes = plt.subplots(1, 3, figsize=(15, 5))
#         dataset_names = ['Training', 'Validation', 'Test']
#         colors = plt.cm.Set3(np.linspace(0, 1, len(CLASS_MAP)))  # Color palette
        
#         # Plot each dataset
#         for idx, (name, dataset) in enumerate(zip(dataset_names, datasets)):
#             if len(dataset) == 0:  # Skip empty datasets
#                 continue
                
#             # Count images per class
#             class_counts = Counter(dataset.labels)
#             class_names = [IDX_TO_CLASS[i] for i in sorted(class_counts.keys())]
#             counts = [class_counts[i] for i in sorted(class_counts.keys())]
            
#             # Create bar plot
#             axes[idx].bar(range(len(class_names)), counts, color=colors[:len(class_names)])
#             axes[idx].set_title(f'{name} Dataset\n({len(dataset)} images)')
#             axes[idx].set_xlabel('Class')
#             axes[idx].set_ylabel('Count')
#             axes[idx].set_xticks(range(len(class_names)))
#             # Show only maturity level for cleaner labels
#             axes[idx].set_xticklabels([cn.split('/')[1] for cn in class_names], rotation=45, ha='right')
            
#             # Add count labels on top of bars
#             for j, count in enumerate(counts):
#                 axes[idx].text(j, count + 0.5, str(count), ha='center', va='bottom')
        
#         plt.tight_layout()
#         plt.show()

# # ======================================================================
# # SECTION 13: DATASET STATISTICS CALCULATION
# # ======================================================================
# """
# Purpose: Calculate and display comprehensive statistics about the dataset.
# This helps researchers understand data distribution and potential biases.
# """

# def calculate_dataset_statistics(datasets):
#     """
#     Calculate and display comprehensive dataset statistics.
    
#     Args:
#         datasets (list): List of datasets (train, val, test)
    
#     Returns:
#         dict: Comprehensive statistics dictionary
#     """
#     print("\n DATASET STATISTICS SUMMARY")
#     print("="*60)
    
#     # Initialize statistics dictionary
#     total_stats = {
#         'total_images': 0,
#         'total_classes': len(CLASS_MAP),
#         'class_distribution': {name: 0 for name in CLASS_MAP.keys()}
#     }
    
#     # Calculate statistics for each dataset
#     for phase, dataset in zip(['Training', 'Validation', 'Test'], datasets):
#         if len(dataset) == 0:  # Skip empty datasets
#             continue
            
#         # Count images per class
#         class_counts = Counter(dataset.labels)
        
#         # Print dataset summary
#         print(f"\n{phase} Dataset:")
#         print(f"  Total images: {len(dataset):,}")
#         print(f"  Number of classes: {len(class_counts)}")
        
#         # Print per-class statistics
#         for class_id, count in sorted(class_counts.items()):
#             class_name = IDX_TO_CLASS[class_id]
#             percentage = (count / len(dataset)) * 100
#             print(f"  {class_name:25s}: {count:4d} ({percentage:5.1f}%)")
            
#             # Update total statistics
#             total_stats['class_distribution'][class_name] += count
        
#         # Update total image count
#         total_stats['total_images'] += len(dataset)
    
#     # Print grand total
#     print("\n" + "="*60)
#     print(f"GRAND TOTAL: {total_stats['total_images']:,} images across {total_stats['total_classes']} classes")
    
#     # Check for minimum samples per class
#     min_per_class = min(total_stats['class_distribution'].values())
#     if min_per_class < 50:
#         print(f"Warning: Some classes have fewer than 50 samples (minimum: {min_per_class})")
    
#     return total_stats

# # ======================================================================
# # SECTION 14: SHUFFLENETV2 COMPATIBILITY VERIFICATION
# # ======================================================================
# """
# Purpose: Verify that preprocessing meets all requirements for ShuffleNetV2.
# Ensures compatibility with pretrained weights and optimal performance.
# """

# def verify_shufflenetv2_compatibility():
#     """
#     Verify that preprocessing matches ShuffleNetV2 requirements.
    
#     Checks:
#     - Input size and format
#     - Normalization parameters
#     - Tensor shape
#     - Value ranges
#     """
#     print("\n VERIFYING SHUFFLENETV2 COMPATIBILITY")
#     print("="*60)
    
#     # Define requirements checklist
#     requirements = {
#         "Input size": f"{IMG_SIZE}x{IMG_SIZE} RGB",
#         "Normalization mean": [0.485, 0.456, 0.406],
#         "Normalization std": [0.229, 0.224, 0.225],
#         "Input tensor shape": "(batch, 3, 224, 224)",
#         "Value range": "Normalized to N(0,1)",
#         "Augmentations": "Geometric + Photometric + Regularization",
#         "Batch handling": "Supports batch normalization"
#     }
    
#     # Check and print each requirement
#     for req, value in requirements.items():
#         print(f"✅ {req:25s}: {value}")
    
#     # Print recommended configuration
#     print("\n Recommended ShuffleNetV2 Configuration:")
#     print("   Model variant: shufflenet_v2_x1_0 (balanced speed/accuracy)")
#     print("   Pretrained weights: ImageNet")
#     print("   Fine-tuning: Last 2 layers + classifier")
#     print("   Learning rate: 0.001 with cosine annealing")
#     print("   Optimizer: AdamW with weight decay")
    
#     print("\n" + "="*60)
#     print("All requirements satisfied for ShuffleNetV2!")

# # ======================================================================
# # SECTION 15: MAIN EXECUTION PIPELINE
# # ======================================================================
# """
# Purpose: Orchestrate the complete preprocessing pipeline.
# Sequential execution of all preprocessing steps with error handling.
# """

# def main():
#     """
#     Main execution function that runs the complete preprocessing pipeline.
    
#     Returns:
#         tuple: (train_loader, val_loader, test_loader) for model training
#     """
#     print("\n" + "="*60)
#     print(" PROFESSIONAL TEA LEAF PREPROCESSING PIPELINE")
#     print(" Optimized for ShuffleNetV2 Classification")
#     print("="*60)
    
#     # Step 1: Comprehensive quality check
#     corrupted = perform_comprehensive_quality_check()
    
#     # Optional: Remove corrupted images
#     if corrupted:
#         print(f"\n⚠ Found {len(corrupted)} corrupted images.")
#         response = input("Would you like to remove them? (y/n): ")
#         if response.lower() == 'y':
#             for img_path, _ in corrupted:
#                 try:
#                     os.remove(img_path)
#                     print(f"Removed: {img_path}")
#                 except:
#                     pass  # Skip if removal fails
    
#     # Step 2: Create data loaders
#     train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset = create_data_loaders()
    
#     # Step 3: Calculate and display statistics
#     total_stats = calculate_dataset_statistics([train_dataset, val_dataset, test_dataset])
    
#     # Step 4: Verify ShuffleNetV2 compatibility
#     verify_shufflenetv2_compatibility()
    
#     # Step 5: Visualizations (with error handling)
#     try:
#         visualizer = Visualizer()
        
#         # Visualize data augmentations
#         if len(train_dataset) > 0:
#             visualizer.visualize_augmentations(train_dataset, num_samples=4)
        
#         # Visualize training batch
#         if len(train_loader) > 0:
#             visualizer.visualize_batch(train_loader, "Training Batch (Augmented)")
        
#         # Visualize validation batch
#         if len(val_loader) > 0:
#             visualizer.visualize_batch(val_loader, "Validation Batch")
        
#         # Plot dataset distributions
#         visualizer.plot_dataset_distribution([train_dataset, val_dataset, test_dataset])
        
#     except Exception as e:
#         # Continue even if visualization fails
#         print(f"⚠ Visualization error (can continue): {str(e)}")
    
#     # Step 6: Final summary and next steps
#     print("\n" + "="*60)
#     print("🚀 PREPROCESSING PIPELINE READY!")
#     print("="*60)

#     # Print summary statistics
#     print(f"\n Data Loaders Created:")
#     print(f"   Training:   {len(train_dataset):,} images")
#     print(f"   Validation: {len(val_dataset):,} images")
#     print(f"   Test:       {len(test_dataset):,} images")
    
#     print(f"\n Batch Configuration:")
#     print(f"   Batch size: {BATCH_SIZE}")
#     print(f"   Workers:    {NUM_WORKERS} (Windows-safe)")
#     print(f"   Image size: {IMG_SIZE}x{IMG_SIZE}")
    
#     print("\n Pipeline initialization complete!")
#     print("   Ready for ShuffleNetV2 training!")
#     print("="*60 + "\n")
    
#     return train_loader, val_loader, test_loader

# # ======================================================================
# # SECTION 16: PROGRAM ENTRY POINT
# # ======================================================================
# """
# Purpose: Execute the main function when script is run directly.
# Also saves configuration summary for documentation.
# """

# if __name__ == "__main__":
#     """
#     Entry point when script is executed directly.
#     """
#     # Run the complete preprocessing pipeline
#     train_loader, val_loader, test_loader = main()
    
#     # Save configuration for documentation and reproducibility
#     config = {
#         'img_size': IMG_SIZE,
#         'batch_size': BATCH_SIZE,
#         'num_workers': NUM_WORKERS,
#         'class_map': CLASS_MAP,
#         'normalization': {
#             'mean': [0.485, 0.456, 0.406],
#             'std': [0.229, 0.224, 0.225]
#         }
#     }
    
#     # Print configuration summary
#     print("📝 Configuration Summary:")
#     for key, value in config.items():
#         print(f"   {key}: {value}")





# """
#  PREPROCESSING PIPELINE FOR SHUFFLENETV2
# =============================================================

# This module implements a comprehensive preprocessing pipeline optimized for
# ShuffleNetV2-based tea leaf maturity classification. It includes:
# 1. Dataset validation and quality checks
# 2. Domain-specific augmentations for tea leaves
# 3. Professional transforms aligned with ImageNet standards
# 4. Visualization and analysis tools
# 5. Windows-compatible multiprocessing
# """

# # ======================================================================
# # SECTION 1: IMPORT ESSENTIAL LIBRARIES
# # ======================================================================
# import os  # Operating system interface for file/directory operations
# import numpy as np  # Numerical computing library for array operations
# from PIL import Image  # Python Imaging Library for image processing
# import matplotlib.pyplot as plt  # Plotting library for visualizations
# from tqdm import tqdm  # Progress bar for loops
# import random  # Random number generation for reproducibility
# from collections import Counter  # Count hashable objects (for class distribution)

# import torch  # PyTorch core library for tensor operations and neural networks
# import torch.nn as nn  # Neural network modules
# from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler  # Data handling utilities
# from torchvision import transforms, models  # Image transforms and pre-trained models
# import torchvision.transforms.functional as F  # Functional transforms for custom operations
# import cv2  # OpenCV for advanced image processing operations

# # ======================================================================
# # SECTION 2: SETUP REPRODUCIBILITY
# # ======================================================================
# def set_seed(seed=42):
#     """
#     Set random seeds for all random number generators to ensure reproducibility.
#     """
#     random.seed(seed)
#     np.random.seed(seed)
#     torch.manual_seed(seed)
#     torch.cuda.manual_seed(seed)
#     torch.cuda.manual_seed_all(seed)
#     torch.backends.cudnn.deterministic = True
#     torch.backends.cudnn.benchmark = False
#     os.environ['PYTHONHASHSEED'] = str(seed)

# set_seed(42)

# # ======================================================================
# # SECTION 3: PROJECT PATHS CONFIGURATION
# # ======================================================================
# # UPDATE THIS PATH TO MATCH YOUR EXACT FOLDER LOCATION IF DIFFERENT
# PROJECT_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity"
# DATASET_DIR = os.path.join(PROJECT_DIR, "dataset")
# TRAIN_DIR = os.path.join(DATASET_DIR, "train")
# VALID_DIR = os.path.join(DATASET_DIR, "valid")
# TEST_DIR = os.path.join(DATASET_DIR, "test")

# # ======================================================================
# # SECTION 4: TRAINING CONFIGURATION PARAMETERS
# # ======================================================================
# IMG_SIZE = 224  # Target image size (ShuffleNetV2 expects 224x224 RGB images)
# BATCH_SIZE = 32
# NUM_WORKERS = 0  # Windows-safe (set to 0 to avoid pickle errors)
# PIN_MEMORY = True if torch.cuda.is_available() else False

# # ======================================================================
# # SECTION 5: CLASS MAPPING DEFINITION
# # ======================================================================
# CLASS_MAP = {
#     "Assamica/tender": 0,
#     "Assamica/matured": 1,
#     "DT1/tender": 2,
#     "DT1/matured": 3
# }

# IDX_TO_CLASS = {v: k for k, v in CLASS_MAP.items()}
# CLASS_NAMES = [IDX_TO_CLASS[i] for i in range(len(CLASS_MAP))]

# # ======================================================================
# # SECTION 6: DOMAIN-SPECIFIC AUGMENTATIONS
# # ======================================================================
# class AdvancedLeafAugmentation:
#     """
#     Custom augmentation techniques optimized for tea leaf characteristics.
#     """
    
#     @staticmethod
#     def random_leaf_perspective(img, distortion_scale=0.2):
#         if random.random() > 0.5:
#             return img
        
#         width, height = img.size
#         startpoints = [[0, 0], [width - 1, 0], [width - 1, height - 1], [0, height - 1]]
#         endpoints = [
#             [int(random.uniform(0, distortion_scale * width)), int(random.uniform(0, distortion_scale * height))],
#             [int(random.uniform((1 - distortion_scale) * width, width)), int(random.uniform(0, distortion_scale * height))],
#             [int(random.uniform((1 - distortion_scale) * width, width)), int(random.uniform((1 - distortion_scale) * height, height))],
#             [int(random.uniform(0, distortion_scale * width)), int(random.uniform((1 - distortion_scale) * height, height))]
#         ]
        
#         # Added fill=128 (grey) to avoid black corners
#         return F.perspective(img, startpoints, endpoints, fill=128)
    
#     @staticmethod
#     def random_leaf_occlusion(img, max_occlusion_size=0.3):
#         if random.random() > 0.7:
#             return img
        
#         img_array = np.array(img)
#         h, w, _ = img_array.shape
        
#         occl_h = int(h * random.uniform(0.05, max_occlusion_size))
#         occl_w = int(w * random.uniform(0.05, max_occlusion_size))
#         center_x = random.randint(0, w)
#         center_y = random.randint(0, h)
        
#         mask = np.ones((h, w), dtype=np.uint8) * 255
#         cv2.ellipse(mask, (center_x, center_y), (occl_w//2, occl_h//2), 0, 0, 360, 0, -1)
#         mask = cv2.GaussianBlur(mask, (21, 21), 10)
#         mask = mask / 255.0
        
#         for c in range(3):
#             img_array[:, :, c] = img_array[:, :, c] * mask + img_array[:, :, c].mean() * (1 - mask)
        
#         return Image.fromarray(np.uint8(img_array))
    
#     @staticmethod
#     def random_leaf_color_temperature(img, temperature_range=(-50, 50)):
#         if random.random() > 0.5:
#             return img
        
#         temperature = random.uniform(*temperature_range)
#         img_array = np.array(img, dtype=np.float32)
        
#         if temperature > 0:
#             img_array[:, :, 0] *= 1 + (temperature / 100)
#             img_array[:, :, 2] *= 1 - (temperature / 200)
#         else:
#             img_array[:, :, 0] *= 1 + (temperature / 200)
#             img_array[:, :, 2] *= 1 - (temperature / 100)
        
#         img_array = np.clip(img_array, 0, 255)
#         return Image.fromarray(np.uint8(img_array))

# # ======================================================================
# # SECTION 7: PICKLE-SAFE TRANSFORM WRAPPERS
# # ======================================================================
# def create_leaf_perspective_transform(distortion_scale=0.15):
#     def transform(img):
#         return AdvancedLeafAugmentation.random_leaf_perspective(img, distortion_scale)
#     return transform

# def create_leaf_occlusion_transform(max_occlusion_size=0.25):
#     def transform(img):
#         return AdvancedLeafAugmentation.random_leaf_occlusion(img, max_occlusion_size)
#     return transform

# def create_leaf_color_temperature_transform(temperature_range=(-50, 50)):
#     def transform(img):
#         return AdvancedLeafAugmentation.random_leaf_color_temperature(img, temperature_range)
#     return transform

# # ======================================================================
# # SECTION 8: PROFESSIONAL TRANSFORMATION PIPELINES
# # ======================================================================
# class ProfessionalTeaLeafTransforms:
#     @staticmethod
#     def get_train_transform():
#         return transforms.Compose([
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.RandomApply([
#                 transforms.RandomAffine(
#                     degrees=15, translate=(0.1, 0.1), scale=(0.85, 1.15), shear=8,
#                     interpolation=transforms.InterpolationMode.BILINEAR
#                 )
#             ], p=0.7),
#             transforms.RandomResizedCrop(IMG_SIZE, scale=(0.7, 1.0), ratio=(0.8, 1.2),
#                                        interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.RandomHorizontalFlip(p=0.5),
#             transforms.RandomVerticalFlip(p=0.1),
#             transforms.RandomRotation(25, interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.RandomApply([
#                 transforms.ColorJitter(brightness=0.15, contrast=0.15, saturation=0.15, hue=0.05)
#             ], p=0.8),
#             transforms.Lambda(create_leaf_perspective_transform(0.15)),
#             transforms.Lambda(create_leaf_occlusion_transform(0.25)),
#             transforms.Lambda(create_leaf_color_temperature_transform()),
#             transforms.RandomApply([transforms.GaussianBlur(kernel_size=3, sigma=(0.1, 1.0))], p=0.3),
#             transforms.ToTensor(),
#             transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
#             transforms.RandomErasing(p=0.3, scale=(0.02, 0.12), ratio=(0.3, 3.3), value='random')
#         ])
    
#     @staticmethod
#     def get_val_transform():
#         return transforms.Compose([
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.CenterCrop(IMG_SIZE),
#             transforms.ToTensor(),
#             transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
#         ])
    
#     @staticmethod
#     def get_test_transform():
#         return transforms.Compose([
#             transforms.Resize(256, interpolation=transforms.InterpolationMode.BILINEAR),
#             transforms.CenterCrop(IMG_SIZE),
#             transforms.ToTensor(),
#             transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
#         ])

# # ======================================================================
# # SECTION 9: ENHANCED DATASET CLASS
# # ======================================================================
# class ProfessionalTeaDataset(Dataset):
#     def __init__(self, root_dir, transform=None, phase="train"):
#         self.root_dir = root_dir
#         self.transform = transform
#         self.phase = phase
#         self.images = []
#         self.labels = []
#         self.image_paths = []
#         self.metadata = []
#         self._load_dataset()
#         self._print_statistics()
    
#     def _load_dataset(self):
#         print(f"\n Loading dataset from: {self.root_dir}")
#         if not os.path.exists(self.root_dir):
#              print(f"Error: Directory not found: {self.root_dir}")
#              return

#         for variety in os.listdir(self.root_dir):
#             variety_path = os.path.join(self.root_dir, variety)
#             if not os.path.isdir(variety_path): continue
            
#             for maturity in ["tender", "matured"]:
#                 class_path = os.path.join(variety_path, maturity)
#                 if not os.path.exists(class_path): continue
                
#                 class_name = f"{variety}/{maturity}"
#                 if class_name not in CLASS_MAP: continue
                
#                 label = CLASS_MAP[class_name]
#                 image_files = [f for f in os.listdir(class_path) if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp'))]
                
#                 for img_file in image_files:
#                     img_path = os.path.join(class_path, img_file)
#                     self.images.append(img_path)
#                     self.labels.append(label)
#                     self.image_paths.append(img_path)
#                     self.metadata.append({
#                         'path': img_path, 'variety': variety, 'maturity': maturity,
#                         'class_id': label, 'class_name': class_name, 'filename': img_file
#                     })
#         print(f" Loaded {len(self.images)} images with {len(set(self.labels))} classes")
    
#     def _print_statistics(self):
#         class_counts = Counter(self.labels)
#         print(f"\n Dataset Statistics for {self.phase}:")
#         print("-" * 40)
#         for class_id, count in sorted(class_counts.items()):
#             class_name = IDX_TO_CLASS[class_id]
#             percentage = (count / len(self.images)) * 100 if len(self.images) > 0 else 0
#             print(f"  {class_name:30s}: {count:4d} images ({percentage:.1f}%)")
#         print("-" * 40)
#         print(f"  Total images: {len(self.images)}")
    
#     def __len__(self):
#         return len(self.images)
    
#     def __getitem__(self, idx):
#         try:
#             img_path = self.images[idx]
#             label = self.labels[idx]
#             img = Image.open(img_path).convert('RGB')
#             if self.transform:
#                 img = self.transform(img)
#             return img, label
#         except Exception as e:
#             print(f" Error loading image {self.images[idx]}: {str(e)}")
#             dummy_img = torch.zeros((3, IMG_SIZE, IMG_SIZE))
#             return dummy_img, 0
    
#     def get_class_weights(self):
#         class_counts = Counter(self.labels)
#         total_samples = len(self.labels)
#         num_classes = len(CLASS_MAP)
#         weights = []
#         for i in range(num_classes):
#             if i in class_counts:
#                 weight = total_samples / (num_classes * class_counts[i])
#                 weights.append(weight)
#             else:
#                 weights.append(0)
#         return torch.FloatTensor(weights)

# # ======================================================================
# # SECTION 10: QUALITY CHECK
# # ======================================================================
# def perform_comprehensive_quality_check():
#     print("\n" + "="*60 + "\n COMPREHENSIVE DATASET QUALITY CHECK\n" + "="*60)
#     image_formats = {}
#     corrupted_images = []
    
#     for root, _, files in os.walk(DATASET_DIR):
#         for file in files:
#             if file.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.bmp')):
#                 ext = file.split('.')[-1].lower()
#                 image_formats[ext] = image_formats.get(ext, 0) + 1
#                 try:
#                     img_path = os.path.join(root, file)
#                     with Image.open(img_path) as img:
#                         img.verify()
#                 except Exception as e:
#                     corrupted_images.append((img_path, str(e)))
    
#     print("   Image formats found:")
#     for fmt, count in image_formats.items():
#         print(f"      .{fmt}: {count} images")
    
#     if corrupted_images:
#         print(f"    Found {len(corrupted_images)} corrupted images!")
#     else:
#         print("   No corrupted images found!")
    
#     return corrupted_images

# # ======================================================================
# # SECTION 11: DATA LOADER CREATION
# # ======================================================================
# def create_data_loaders():
#     print("\n Creating Data Loaders...")
#     train_transform = ProfessionalTeaLeafTransforms.get_train_transform()
#     val_transform = ProfessionalTeaLeafTransforms.get_val_transform()
#     test_transform = ProfessionalTeaLeafTransforms.get_test_transform()
    
#     train_dataset = ProfessionalTeaDataset(TRAIN_DIR, train_transform, "train")
#     val_dataset = ProfessionalTeaDataset(VALID_DIR, val_transform, "validation")
#     test_dataset = ProfessionalTeaDataset(TEST_DIR, test_transform, "test")
    
#     sampler = None
#     if len(train_dataset) > 0:
#         class_weights = train_dataset.get_class_weights()
#         print(f" Class weights for sampling: {class_weights.tolist()}")
#         weights = [class_weights[label] for label in train_dataset.labels]
#         sampler = WeightedRandomSampler(weights, len(weights), replacement=True)
    
#     train_loader = DataLoader(
#         train_dataset, batch_size=BATCH_SIZE, sampler=sampler, 
#         shuffle=(sampler is None), num_workers=NUM_WORKERS, 
#         pin_memory=PIN_MEMORY, drop_last=True
#     )
    
#     val_loader = DataLoader(
#         val_dataset, batch_size=BATCH_SIZE, shuffle=False, 
#         num_workers=NUM_WORKERS, pin_memory=PIN_MEMORY, drop_last=False
#     )
    
#     test_loader = DataLoader(
#         test_dataset, batch_size=BATCH_SIZE, shuffle=False, 
#         num_workers=NUM_WORKERS, pin_memory=PIN_MEMORY, drop_last=False
#     )
    
#     return train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset

# # ======================================================================
# # SECTION 12: VISUALIZATION
# # ======================================================================
# class Visualizer:
#     @staticmethod
#     def visualize_augmentations(dataset, num_samples=4):
#         print("\n Visualizing Data Augmentations...")
#         indices = np.random.choice(len(dataset), min(num_samples, len(dataset)), replace=False)
#         fig, axes = plt.subplots(2, num_samples, figsize=(4*num_samples, 8))
        
#         # Correct inverse normalization using class-based logic
#         inv_normalize = transforms.Normalize(
#             mean=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
#             std=[1/0.229, 1/0.224, 1/0.225]
#         )
        
#         for i, idx in enumerate(indices):
#             img_path = dataset.image_paths[idx]
#             orig_img = Image.open(img_path).convert('RGB')
#             aug_img, label = dataset[idx]
            
#             axes[0, i].imshow(orig_img)
#             axes[0, i].set_title(f"Original\n{dataset.metadata[idx]['class_name']}")
#             axes[0, i].axis('off')
            
#             if aug_img.dim() == 3:
#                 aug_img_disp = inv_normalize(aug_img).permute(1, 2, 0).clamp(0, 1).cpu().numpy()
#                 axes[1, i].imshow(aug_img_disp)
#                 axes[1, i].set_title(f"Augmented\nClass: {IDX_TO_CLASS[label]}")
#                 axes[1, i].axis('off')
#         plt.tight_layout()
#         plt.show()

#     @staticmethod
#     def plot_dataset_distribution(datasets):
#         print("\n Visualizing Dataset Distribution...")
#         fig, axes = plt.subplots(1, 3, figsize=(15, 5))
#         dataset_names = ['Training', 'Validation', 'Test']
#         colors = plt.cm.Set3(np.linspace(0, 1, len(CLASS_MAP)))
        
#         for idx, (name, dataset) in enumerate(zip(dataset_names, datasets)):
#             if len(dataset) == 0: continue
#             class_counts = Counter(dataset.labels)
#             class_names = [IDX_TO_CLASS[i] for i in sorted(class_counts.keys())]
#             counts = [class_counts[i] for i in sorted(class_counts.keys())]
            
#             axes[idx].bar(range(len(class_names)), counts, color=colors[:len(class_names)])
#             axes[idx].set_title(f'{name} Dataset\n({len(dataset)} images)')
#             axes[idx].set_xticks(range(len(class_names)))
#             axes[idx].set_xticklabels([cn.split('/')[1] for cn in class_names], rotation=45, ha='right')
#         plt.tight_layout()
#         plt.show()

# # ======================================================================
# # SECTION 13: STATS & VERIFICATION
# # ======================================================================
# def calculate_dataset_statistics(datasets):
#     print("\n DATASET STATISTICS SUMMARY\n" + "="*60)
#     total_images = 0
#     for phase, dataset in zip(['Training', 'Validation', 'Test'], datasets):
#         if len(dataset) == 0: continue
#         print(f"\n{phase} Dataset: {len(dataset):,} images")
#         total_images += len(dataset)
#     print("\n" + "="*60 + f"\nGRAND TOTAL: {total_images:,} images")
#     return total_images

# def verify_shufflenetv2_compatibility():
#     print("\n VERIFYING SHUFFLENETV2 COMPATIBILITY\n" + "="*60)
#     requirements = {
#         "Input size": f"{IMG_SIZE}x{IMG_SIZE} RGB",
#         "Normalization mean": [0.485, 0.456, 0.406],
#         "Normalization std": [0.229, 0.224, 0.225],
#         "Input tensor shape": f"(batch, 3, {IMG_SIZE}, {IMG_SIZE})"
#     }
#     for req, value in requirements.items():
#         print(f" {req:25s}: {value}")
#     print("\n" + "="*60 + "\nAll requirements satisfied for ShuffleNetV2!")

# # ======================================================================
# # SECTION 14: MAIN
# # ======================================================================
# def main():
#     print("\n" + "="*60 + "\n PROFESSIONAL TEA LEAF PREPROCESSING PIPELINE\n" + "="*60)
    
#     corrupted = perform_comprehensive_quality_check()
#     if corrupted:
#         print(f"\n⚠ Found {len(corrupted)} corrupted images.")
    
#     train_loader, val_loader, test_loader, train_dataset, val_dataset, test_dataset = create_data_loaders()
#     calculate_dataset_statistics([train_dataset, val_dataset, test_dataset])
#     verify_shufflenetv2_compatibility()
    
#     try:
#         visualizer = Visualizer()
#         if len(train_dataset) > 0:
#             visualizer.visualize_augmentations(train_dataset, num_samples=4)
#             visualizer.plot_dataset_distribution([train_dataset, val_dataset, test_dataset])
#     except Exception as e:
#         print(f"⚠ Visualization skipped: {str(e)}")
    
#     print("\n" + "="*60 + "\n PREPROCESSING PIPELINE READY!\n" + "="*60)
#     return train_loader, val_loader, test_loader

# if __name__ == "__main__":
#     train_loader, val_loader, test_loader = main()


