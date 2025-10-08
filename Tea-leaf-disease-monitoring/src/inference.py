import numpy as np
from tensorflow.keras.models import load_model
from tensorflow.keras.preprocessing import image

# Load trained model
model = load_model("tea_disease_model.h5")

# Load image
img_path = "dataset/test/disease1/sample_leaf.jpg"  # replace with your image path
img = image.load_img(img_path, target_size=(224, 224))
img_array = image.img_to_array(img) / 255.0  # normalize
img_array = np.expand_dims(img_array, axis=0)  # add batch dimension

# Predict
pred = model.predict(img_array)
class_indices = {
    0: "healthy",
    1: "disease1",
    2: "disease2",
}  # match your train_generator.class_indices
pred_class = class_indices[np.argmax(pred)]
confidence = np.max(pred)

print(f"Predicted Class: {pred_class}, Confidence: {confidence*100:.2f}%")
