import sys
from ultralytics import YOLO

model_path = r"C:\Users\HP\Desktop\Tea\iTeaGrow-Prod\models\best.pt"
img_path = r"C:\Users\HP\Desktop\Tea Leaf Disease\Red Rust\IMG-20251122-WA0045.jpg"

def inspect_image():
    print("Loading original YOLO model...")
    model = YOLO(model_path)
    print(f"Testing image: {img_path}")
    
    results = model(img_path)
    res = results[0]
    
    if hasattr(res, 'boxes') and res.boxes is not None:
        boxes = res.boxes
        names = res.names
        
        print(f"\nFound {len(boxes.cls)} total bounding boxes:")
        for i in range(len(boxes.cls)):
            cls_id = int(boxes.cls[i])
            conf = float(boxes.conf[i])
            name = names[cls_id]
            print(f"  - {name} ({conf*100:.2f}%)")
    else:
        print("No boxes found.")

if __name__ == "__main__":
    inspect_image()
