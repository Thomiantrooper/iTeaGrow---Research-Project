import os
import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image
from preprocessing import get_train_val_generators

# -----------------------------
# 1️⃣ Define paths
# -----------------------------
PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODEL_EXTENSIONS = (".keras", ".h5", ".hdf5")

# -----------------------------
# 2️⃣ Find the latest model
# -----------------------------
def find_latest_model(project_dir):
    model_files = []
    for root, _, files in os.walk(project_dir):
        for f in files:
            if f.lower().endswith(MODEL_EXTENSIONS):
                full_path = os.path.join(root, f)
                model_files.append((full_path, os.path.getmtime(full_path)))
    if not model_files:
        raise FileNotFoundError("❌ No model files found in the project folder!")
    # Sort by modification time (latest first)
    model_files.sort(key=lambda x: x[1], reverse=True)
    latest_model = model_files[0][0]
    print(f"✔ Using model: {latest_model}")
    return latest_model

model_path = find_latest_model(PROJECT_DIR)

# -----------------------------
# 3️⃣ Load the model
# -----------------------------
model = load_model(model_path)

# -----------------------------
# 4️⃣ Get class mapping
# -----------------------------
_, val_gen = get_train_val_generators()
class_indices = val_gen.class_indices
inv_class_indices = {v: k for k, v in class_indices.items()}

# -----------------------------
# 5️⃣ Load test image
# -----------------------------
# Replace this with your test image path
TEST_IMAGE_PATH = os.path.join(PROJECT_DIR, "dataset", "train", "Blister blight disease", "Image 2.jpeg")

if not os.path.exists(TEST_IMAGE_PATH):
    raise FileNotFoundError(f"❌ Test image not found: {TEST_IMAGE_PATH}")

img = image.load_img(TEST_IMAGE_PATH, target_size=(224, 224))
img_array = image.img_to_array(img) / 255.0
img_array = np.expand_dims(img_array, axis=0)

# Optional: if you used MobileNetV3 preprocessing
#from tensorflow.keras.applications.mobilenet_v3 import preprocess_input
#img_array = preprocess_input(img_array)

# -----------------------------
# 6️⃣ Predict
# -----------------------------
pred = model.predict(img_array)
pred_class = inv_class_indices[np.argmax(pred)]
confidence = np.max(pred)

print(f"\n✅ Predicted Class: {pred_class}")
print(f"🔹 Confidence: {confidence*100:.2f}%\n")
