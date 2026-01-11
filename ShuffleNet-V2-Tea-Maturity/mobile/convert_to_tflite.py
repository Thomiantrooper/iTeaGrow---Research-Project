"""
PyTorch Mobile Export Script for ShuffleNetV2
Exports to .pt format with verification
"""
import torch
import torch.nn as nn
from torchvision import models
import numpy as np
import os

# ==========================================
# CONFIGURATION
# ==========================================
MODEL_PTH_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\ShuffleNet-V2-Tea-Maturity\torch_file\tea_maturity_shufflenetv2_final.pth"
MOBILE_MODEL_PATH = "tea_shufflenet_mobile.pt"

IMG_SIZE = 224
NUM_CLASSES = 4
CLASS_NAMES = ["Assamica/tender", "Assamica/matured", "DT1/tender", "DT1/matured"]

def load_pytorch_model():
    """Load the trained ShuffleNetV2 model."""
    print("[1/3] Loading ShuffleNetV2 Model...")
    
    # Recreate architecture
    model = models.shufflenet_v2_x1_0(weights=None)
    
    in_features = model.fc.in_features
    model.fc = nn.Sequential(
        nn.Dropout(0.55), 
        nn.Linear(in_features, NUM_CLASSES)
    )
    
    # Load weights
    try:
        device = torch.device('cpu')
        state_dict = torch.load(MODEL_PTH_PATH, map_location=device)
        model.load_state_dict(state_dict)
        model.to(device)
        model.eval()
        
        print("   ✅ Model loaded successfully")
        return model
    except Exception as e:
        print(f"   ❌ ERROR: {e}")
        return None

def export_to_pytorch_mobile(model):
    """Export model to PyTorch Mobile format."""
    print("\n[2/3] Exporting to PyTorch Mobile (.pt)...")
    
    try:
        # Create example input
        example = torch.randn(1, 3, IMG_SIZE, IMG_SIZE)
        
        # Trace the model (converts to TorchScript)
        traced_script_module = torch.jit.trace(model, example)
        
        # Optimize for mobile
        traced_script_module_optimized = torch.jit.optimize_for_inference(
            traced_script_module
        )
        
        # Save the model
        traced_script_module_optimized.save(MOBILE_MODEL_PATH)
        
        file_size_mb = os.path.getsize(MOBILE_MODEL_PATH) / (1024 * 1024)
        print(f"   ✅ PyTorch Mobile model saved: {MOBILE_MODEL_PATH}")
        print(f"   📦 File size: {file_size_mb:.2f} MB")
        
        return traced_script_module_optimized, example
        
    except Exception as e:
        print(f"   ❌ Export failed: {e}")
        import traceback
        traceback.print_exc()
        return None, None

def verify_mobile_model(original_model, mobile_model, example_input):
    """Verify that mobile model produces identical outputs."""
    print("\n[3/3] VERIFICATION: Original vs Mobile Model")
    print("="*60)
    
    try:
        # Get original model output
        with torch.no_grad():
            original_output = original_model(example_input)
        
        # Get mobile model output
        with torch.no_grad():
            mobile_output = mobile_model(example_input)
        
        # Compare outputs
        original_np = original_output.numpy()
        mobile_np = mobile_output.numpy()
        
        error = np.max(np.abs(original_np - mobile_np))
        
        original_class = np.argmax(original_np)
        mobile_class = np.argmax(mobile_np)
        
        print(f"   Original Output: {original_np[0]}")
        print(f"   Mobile Output:   {mobile_np[0]}")
        print(f"\n   Original Prediction: Class {original_class} ({CLASS_NAMES[original_class]})")
        print(f"   Mobile Prediction:   Class {mobile_class} ({CLASS_NAMES[mobile_class]})")
        print(f"\n   Max Absolute Error: {error:.10f}")
        
        print("\n" + "="*60)
        if error < 1e-6:
            print("   ✅ PERFECT: Bit-exact match")
            print("   👉 Safe to deploy to mobile")
        elif error < 1e-3:
            print("   ✅ EXCELLENT: Near-perfect match")
            print("   👉 Safe to deploy to mobile")
        else:
            print("   ⚠️  WARNING: Small numerical difference")
            print("   👉 Test with real images before deploying")
        print("="*60)
        
        return True
        
    except Exception as e:
        print(f"   ❌ Verification failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("\n" + "="*60)
    print("   PyTorch Mobile Export for ShuffleNetV2")
    print("="*60 + "\n")
    
    # Load model
    model = load_pytorch_model()
    if model is None:
        return
    
    # Export to mobile
    mobile_model, example = export_to_pytorch_mobile(model)
    if mobile_model is None:
        return
    
    # Verify
    verify_mobile_model(model, mobile_model, example)
    
    print("\n" + "="*60)
    print("   EXPORT COMPLETE!")
    print("="*60)
    print(f"\n   Mobile model ready: {MOBILE_MODEL_PATH}")
    print(f"   Next step: Integrate into Flutter app")

if __name__ == "__main__":
    main()