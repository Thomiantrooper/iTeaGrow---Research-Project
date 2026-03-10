import sys
import os
from pathlib import Path
import glob
from PIL import Image

model_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\frontend\iTeaGrow---Research-Project\assets\models\disease_explain.ptl"
base_dir = r"C:\Users\HP\Desktop\Tea Leaf Disease"

def test_model():
    try:
        import torch
        import torchvision
    except ImportError:
        print("PyTorch not installed.")
        return

    print("Loading model...")
    try:
        # PTL models can sometimes be loaded via jit
        model = torch.jit.load(model_path)
        model.eval()
        print("Model loaded successfully via torch.jit.load.")
    except Exception as e:
        print(f"Failed to load with torch.jit.load: {e}")
        try:
            # Maybe ultralytics?
            from ultralytics import YOLO
            model = YOLO(model_path)
            print("Model loaded via ultralytics YOLO.")
        except Exception as e2:
            print(f"Failed via YOLO: {e2}")
            # Try to load as exported lite interpreter
            try:
                from torch.utils.mobile_optimizer import optimize_for_mobile
                print("Trying torch.jit._load_for_lite_interpreter...")
                model = torch.jit._load_for_lite_interpreter(model_path)
                print("Loaded via _load_for_lite_interpreter")
            except Exception as e3:
                print(f"Failed via _load_for_lite_interpreter: {e3}")
                return

    import torchvision.transforms as transforms
    
    transform = transforms.Compose([
        transforms.Resize((224, 224)), # Standard size, might be different for YOLO (usually 640)
        transforms.ToTensor(),
    ])

    # Let's just find one image for now
    img_files = glob.glob(os.path.join(base_dir, "**", "*.jpg"), recursive=True) + glob.glob(os.path.join(base_dir, "**", "*.png"), recursive=True)
    if not img_files:
        print("No images found.")
        return
        
    print(f"Found {len(img_files)} images, testing the first one...")
    img_path = img_files[0]
    img = Image.open(img_path).convert("RGB")
    tensor = transform(img).unsqueeze(0)
    
    print(f"Testing on {img_path} with tensor shape {tensor.shape}")
    try:
        if hasattr(model, 'forward'):
            out = model(tensor)
            print("Output shape:", out.shape if hasattr(out, 'shape') else type(out))
            print("Output:", out)
        else:
            # Ultralytics
            out = model(img_path)
            print("Output:", out)
    except Exception as e:
        print("Inference error:", e)

if __name__ == "__main__":
    test_model()
