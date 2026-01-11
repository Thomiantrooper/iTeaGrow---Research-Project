# from dataset_loader import load_dataset
# from model import build_model
# import tensorflow as tf
# import os

# DATA_DIR = "../data/train"


# def main():
#     train_data, val_data = load_dataset(DATA_DIR, img_size=224, batch_size=16)
#     num_classes = train_data.num_classes

#     model = build_model(num_classes)

#     checkpoint = tf.keras.callbacks.ModelCheckpoint(
#         filepath="../saved_models/best_model.h5",
#         save_best_only=True,
#         monitor='val_accuracy',
#         mode='max'
#     )

#     history = model.fit(
#         train_data,
#         validation_data=val_data,
#         epochs=20,
#         callbacks=[checkpoint]
#     )

#     model.save("../saved_models/final_model.h5")


# if __name__ == "__main__":
#     main()

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
import os

# -------- SETTINGS -------- #
DATASET_DIR = "../data/final"
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 25
# --------------------------- #

print("🔍 Loading dataset...")

train_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    labels="inferred",
    label_mode="categorical",
    validation_split=0.2,
    subset="training",
    seed=123,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE
)

val_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    labels="inferred",
    label_mode="categorical",
    validation_split=0.2,
    subset="validation",
    seed=123,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE
)

# Cache + prefetch = faster training
train_ds = train_ds.cache().prefetch(buffer_size=tf.data.AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=tf.data.AUTOTUNE)

# ---------- AUGMENTATION ---------- #
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal_and_vertical"),
    layers.RandomRotation(0.2),
    layers.RandomZoom(0.2),
    layers.RandomContrast(0.2),
])

# ---------- BASE MODEL (TRANSFER LEARNING) ---------- #
base_model = MobileNetV2(
    input_shape=IMG_SIZE + (3,),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False  # freeze

# ---------- BUILD MODEL ---------- #
inputs = layers.Input(shape=IMG_SIZE + (3,))
x = data_augmentation(inputs)
x = tf.keras.applications.mobilenet_v2.preprocess_input(x)

x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(6, activation="softmax")(x)

model = models.Model(inputs, outputs)

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0005),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()

# ---------- TRAINING ---------- #
callbacks = [
    tf.keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=5,
        restore_best_weights=True
    ),
    tf.keras.callbacks.ModelCheckpoint(
        "best_model.keras",
        monitor="val_accuracy",
        save_best_only=True
    )
]

print("🚀 Training started...")

history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=EPOCHS,
    callbacks=callbacks
)

print("✅ Training completed!")
print("📁 Best model saved as: best_model.keras")
