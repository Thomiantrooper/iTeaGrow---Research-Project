import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Path to saved model inside src/
MODEL_PATH = "best_model.keras"

# Your classes (same order used in training!)
CLASS_NAMES = ["BOP", "BOPF", "Dust", "Dust1", "Fanning1", "Pekoe"]

IMG_SIZE = (224, 224)

# Load model
model = tf.keras.models.load_model(MODEL_PATH)


def predict_image(img_path):
    # Load image
    img = image.load_img(img_path, target_size=IMG_SIZE)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)

    # Preprocess for MobileNetV2
    img_array = tf.keras.applications.mobilenet_v2.preprocess_input(img_array)

    # Predict
    predictions = model.predict(img_array)
    class_index = np.argmax(predictions)
    confidence = float(np.max(predictions))

    print("=====================================")
    print(f"Image: {img_path}")
    print(f"Predicted Class: {CLASS_NAMES[class_index]}")
    print(f"Confidence: {confidence:.2f}")
    print("=====================================")


# Your test image path
test_image = "../data/test/test1.jpg"

predict_image(test_image)
