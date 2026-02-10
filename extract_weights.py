import torch
import json
import os

MODEL_PATH = r"C:\Users\HP\Desktop\Tea\Tea-Maturity-Analyzing_API\app\ml\artifacts\pytorch\tea_shufflenet_mobile.pt"
OUTPUT_PATH = r"C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\frontend\iTeaGrow---Research-Project\assets\models\fc_weights.json"

def main():
    print("Extracting model weights...")
    
    if not os.path.exists(MODEL_PATH):
        print("Model not found")
        return

    model = torch.jit.load(MODEL_PATH)
    
    # Extract weights from fc.1
    # Note: named_parameters() might have different names depending on how it was scripted
    # But from our previous inspection: 'fc.1.weight'
    params = dict(model.named_parameters())
    
    if 'fc.1.weight' not in params:
        print("Error: Could not find 'fc.1.weight'. Available params:")
        for p in params:
            print(f"  {p}")
        return

    weights = params['fc.1.weight'].detach().cpu().tolist()
    
    data = {
        "fc_weights": weights,
        "classes": ["Assamica/tender", "Assamica/matured", "DT1/tender", "DT1/matured"]
    }
    
    with open(OUTPUT_PATH, 'w') as f:
        json.dump(data, f)
        
    print(f"Weights saved to: {OUTPUT_PATH}")
    print(f"Shape: {len(weights)}x{len(weights[0])}")

if __name__ == "__main__":
    main()
