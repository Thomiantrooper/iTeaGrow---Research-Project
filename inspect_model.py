import torch
import os

MODEL_PATH = r"C:\Users\HP\Desktop\Tea\Tea-Maturity-Analyzing_API\app\ml\artifacts\pytorch\tea_shufflenet_mobile.pt"

def main():
    if not os.path.exists(MODEL_PATH):
        print("Model not found")
        return

    # Load the TorchScript model
    model = torch.jit.load(MODEL_PATH)
    
    print("--- Model Layers ---")
    # Recursively print modules
    for name, module in model.named_modules():
        print(f"Layer: {name}")
        
    print("\n--- Identifying Target Layer for CAM ---")
    # Usually the last conv layer before the head
    # For ShuffleNetV2, it's often 'conv5'
    
    # Try to see if we can find Linear layer weights
    params = dict(model.named_parameters())
    print(f"Parameters found: {len(params)}")
    for p_name in params:
        print(f"Param: {p_name} - Shape: {params[p_name].shape}")

if __name__ == "__main__":
    main()
