import numpy as np
import tensorflow as tf
from tensorflow.keras.models import load_model

# Paths
BASE_DIR = r"C:/Users/HP/Desktop/Tea/iTeaGrow---Research-Project/MobileNetV3-Tea-Maturity/"
MODEL_PATH = BASE_DIR + "keras_file/tea_maturity_mobilenetv3_v5_1.keras"
TEST_DIR  = BASE_DIR + "dataset/test"
SAVE_DIR  = r"C:/Users/HP/Desktop/Tea/iTeaGrow---Research-Project/Graph-Confusion-Metrix-Combined/"

# Load model
model = load_model(MODEL_PATH)

# Load test dataset
IMG_SIZE = 224
test_ds = tf.keras.preprocessing.image_dataset_from_directory(
    TEST_DIR,
    image_size=(IMG_SIZE, IMG_SIZE),
    batch_size=1,
    shuffle=False,
    label_mode="binary"
)

# Convert dataset to arrays to avoid multiple iteration issues
y_true = []
y_pred = []

for images, labels in test_ds.take(len(test_ds)):
    preds = model.predict(images, verbose=0)
    y_pred.append(int(preds.item() > 0.5))
    y_true.append(int(labels.numpy().item()))

# Save results
np.save(SAVE_DIR + "y_true_mobilenet.npy", y_true)
np.save(SAVE_DIR + "y_pred_mobilenet.npy", y_pred)

print(f"[INFO] Saved predictions to {SAVE_DIR}")
