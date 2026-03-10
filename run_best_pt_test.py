import os

from ultralytics import YOLO
from PIL import Image

# Path to the model and image folder
MODEL_PATH = 'models/best.pt'
IMAGE_FOLDER = r'C:\Users\HP\Desktop\Tea Leaf Disease'

# Class labels (update if different)
CLASS_LABELS = ['blister_blight', 'healthy', 'red_rust']


import os
from ultralytics import YOLO
from PIL import Image

# Path to the model and image folder
MODEL_PATH = 'models/best.pt'
IMAGE_FOLDER = r'C:\Users\HP\Desktop\Tea Leaf Disease'

# Class labels (update if different)
CLASS_LABELS = ['blister_blight', 'healthy', 'red_rust']

def get_all_image_files(folder):
    image_files = []
    for root, _, files in os.walk(folder):
        for fname in files:
            if fname.lower().endswith(('.jpg', '.jpeg', '.png')):
                image_files.append(os.path.join(root, fname))
    return image_files

def main():
    yolo = YOLO(MODEL_PATH)
    results = []
    image_files = get_all_image_files(IMAGE_FOLDER)
    for fpath in image_files:
        fname = os.path.relpath(fpath, IMAGE_FOLDER)
        pred = yolo(fpath, verbose=False)[0]
        if pred.probs is None:
            print(f'WARNING: No classification for {fname} (pred.probs is None)')
            continue
        probs = pred.probs.data.cpu().numpy().tolist()
        pred_idx = int(pred.probs.top1)
        conf = float(pred.probs.top1conf)
        results.append((fname, CLASS_LABELS[pred_idx], conf, probs))
        print(f'{fname}: {CLASS_LABELS[pred_idx]} ({conf:.2f}) {probs}')
    # Summary
    for label in CLASS_LABELS:
        label_results = [r for r in results if r[1] == label]
        if label_results:
            confs = [r[2] for r in label_results]
            print(f'\n{label}: {len(label_results)} images')
            print(f'  Highest: {max(confs):.2f}, Lowest: {min(confs):.2f}, Average: {sum(confs)/len(confs):.2f}')
            print('  Example:', label_results[0][0])
        else:
            print(f'\n{label}: 0 images')

if __name__ == '__main__':
    main()
