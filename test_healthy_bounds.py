import sys
import os
import glob
from PIL import Image
from ultralytics import YOLO

model_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\models\best.pt"
base_dir = r"C:\Users\HP\Desktop\Tea Leaf Disease"

def test_all_images():
    print("Loading original YOLO model...")
    try:
        model = YOLO(model_path)
        print("Model loaded successfully.")
    except Exception as e:
        print(f"Failed to load YOLO model: {e}")
        return

    # Gather all images
    img_files = glob.glob(os.path.join(base_dir, "**", "*.jpg"), recursive=True) + \
                glob.glob(os.path.join(base_dir, "**", "*.jpeg"), recursive=True) + \
                glob.glob(os.path.join(base_dir, "**", "*.png"), recursive=True)
                
    if not img_files:
        print("No images found in the directory.")
        return
        
    print(f"Found {len(img_files)} images. Running inference...\n")
    
    healthy_results = []
    
    for count, img_path in enumerate(img_files):
        try:
            # Run inference
            results = model(img_path, verbose=False)
            if not results:
                continue
                
            res = results[0]
            
            # Extract boxes since this is an Object Detection model
            if hasattr(res, 'boxes') and res.boxes is not None:
                boxes = res.boxes
                names = res.names
                
                # Find the healthy class index
                healthy_idx = -1
                for k, v in names.items():
                    if 'health' in v.lower():
                        healthy_idx = k
                        break
                        
                if healthy_idx == -1:
                    healthy_idx = 1
                
                # Find all healthy boxes in this image
                healthy_confs = []
                for i in range(len(boxes.cls)):
                    cls_id = int(boxes.cls[i])
                    if cls_id == healthy_idx:
                        healthy_confs.append(float(boxes.conf[i]))
                        
                best_healthy_conf = max(healthy_confs) if healthy_confs else 0.0
                
                # We record every image so we know its highest 'Healthy' box confidence
                healthy_results.append({
                    'path': img_path,
                    'confidence': best_healthy_conf,
                    'box_count': len(healthy_confs)
                })
        except Exception as e:
            print(f"Error processing {os.path.basename(img_path)}: {e}")
            
    if not healthy_results:
        print("No images were successfully predicted by the model.")
        return
        
    # Sort by confidence
    healthy_results.sort(key=lambda x: x['confidence'])
    
    lower_bound = healthy_results[0]
    upper_bound = healthy_results[-1]
    
    total_conf = sum(x['confidence'] for x in healthy_results)
    avg_conf = total_conf / len(healthy_results)
    
    print("\n" + "="*80)
    print(f"Found {len(healthy_results)} images classified as 'Healthy' out of {len(img_files)} images")
    print("="*80)
    
    print(f"\n[ LOWER BOUND - Lowest Confidence Healthy ]")
    print(f"File: {lower_bound['path']}")
    print(f"Max Healthy Confidence: {lower_bound['confidence']:.4f}")
    print(f"Total Healthy Boxes Found: {lower_bound['box_count']}")
    
    print(f"\n[ UPPER BOUND - Highest Confidence Healthy ]")
    print(f"File: {upper_bound['path']}")
    print(f"Max Healthy Confidence: {upper_bound['confidence']:.4f}")
    print(f"Total Healthy Boxes Found: {upper_bound['box_count']}")
    
    print(f"\n[ AVERAGE STATS ]")
    print(f"Average Healthy Confidence: {avg_conf:.4f}")
    print("="*80)
    
if __name__ == "__main__":
    test_all_images()
