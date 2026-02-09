import torch
import torch.nn as nn
import os

# Paths
ORIGINAL_MODEL_PATH = r"C:\Users\HP\Desktop\Tea\Tea-Maturity-Analyzing_API\app\ml\artifacts\pytorch\tea_shufflenet_mobile.pt"
OUTPUT_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\frontend\iTeaGrow---Research-Project\assets\models\tea_maturity_explain.ptl"

class ExplainableShuffleNet(nn.Module):
    def __init__(self, original_model):
        super(ExplainableShuffleNet, self).__init__()
        self.model = original_model
        
    def forward(self, x):
        # We need to reach inside stage4 -> conv5
        # Since it's a ScriptModule, we can't easily use hooks.
        # However, we can re-implement the tail of the model or 
        # use the fact that it's a ScriptModule to call sub-modules if they are accessible.
        
        # Let's try to trace the execution.
        # For ShuffleNetV2 in TorchScript, we can't easily "breakpoint" it.
        # But we can create a wrapper that returns the intermediate features if we can 
        # re-construct the forward pass using the sub-modules of the ScriptModule.
        
        # Method 2: If we can't easily slice the ScriptModule, we can try to 
        # modify the ScriptModule if it was saved with certain properties, 
        # but usually it's easier to just return everything if possible.
        
        # Actually, if I have the original .pth, it's easier.
        # But I only have the verified .pt.
        
        # Let's try to find if we can access the layers as modules.
        # For a ScriptModule, model.conv5(model.stage4(model.stage3(...)))
        
        # Step-by-step forward pass through the ScriptModule's sub-modules:
        x = self.model.conv1(x)
        x = self.model.maxpool(x)
        x = self.model.stage2(x)
        x = self.model.stage3(x)
        x = self.model.stage4(x)
        
        # This is the layer we want for CAM
        features = self.model.conv5(x) 
        
        # Continue to get classification output
        p = features.mean([2, 3]) # Global Average Pooling
        logits = self.model.fc(p)
        
        # Concatenate outputs into a single tensor: [1, 4 + 1024*7*7]
        # This allows using regular getImagePredictionList in Dart
        return torch.cat([logits, features.flatten(1)], dim=1)

def main():
    print("Exporting Explainable PyTorch Mobile Model...")
    
    if not os.path.exists(ORIGINAL_MODEL_PATH):
        print(f"Error: Original model not found at {ORIGINAL_MODEL_PATH}")
        return

    # Load original TorchScript model
    try:
        model = torch.jit.load(ORIGINAL_MODEL_PATH)
        model.eval()
        print("Original model loaded successfully.")
    except Exception as e:
        print(f"Error loading model: {e}")
        return

    # Wrap it
    try:
        explainable_model = ExplainableShuffleNet(model)
        # Test with dummy input
        dummy_input = torch.randn(1, 3, 224, 224)
        combined = explainable_model(dummy_input)
        print(f"Export Test Success:")
        print(f"  Combined shape: {combined.shape}")
        # Logits [1:4], Features [4:]
        print(f"  Implicit Logits: {combined[:, :4].shape}")
        print(f"  Implicit Features: {combined[:, 4:].shape}")
    except Exception as e:
        print(f"Error wrapping model: {e}")
        print("Note: If sub-modules are not accessible by name, we may need a different approach.")
        return

    # Script the wrapper
    try:
        scripted_model = torch.jit.script(explainable_model)
        print("Wrapper scripted successfully.")
    except Exception as e:
        print(f"Error scripting wrapper: {e}")
        # Alternative: Try tracing
        try:
            print("Trying tracing instead of scripting...")
            scripted_model = torch.jit.trace(explainable_model, dummy_input)
            print("Wrapper traced successfully.")
        except Exception as e2:
            print(f"Tracing also failed: {e2}")
            return

    # Save for Mobile
    try:
        os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
        # Using saved_for_lite_interpreter
        scripted_model._save_for_lite_interpreter(OUTPUT_PATH)
        print(f"Explainable model saved to: {OUTPUT_PATH}")
    except Exception as e:
        print(f"Error saving explainable model: {e}")

if __name__ == "__main__":
    main()
