# Import libraries
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
import matplotlib.pyplot as plt


# Import preprocessing
from preprocessing import get_train_val_generators

# Step 2: Load data
train_generator, val_generator = get_train_val_generators()

# Step 3: Build the model
base_model = EfficientNetB0(
    weights="imagenet", include_top=False, input_shape=(224, 224, 3)
)
base_model.trainable = False

x = GlobalAveragePooling2D()(base_model.output)
x = Dropout(0.3)(x)
x = Dense(128, activation="relu")(x)
output = Dense(3, activation="softmax")(x)  # 3 classes: healthy, disease1, disease2

model = Model(inputs=base_model.input, outputs=output)
model.compile(
    optimizer=Adam(learning_rate=0.0001),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

model.summary()

# Step 4: Train the model
checkpoint = ModelCheckpoint(
    "tea_disease_model.h5", monitor="val_accuracy", save_best_only=True
)
earlystop = EarlyStopping(monitor="val_accuracy", patience=5, restore_best_weights=True)

history = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=20,
    callbacks=[checkpoint, earlystop],
)

# Step 5: Evaluate & visualize training
plt.plot(history.history["accuracy"], label="train_accuracy")
plt.plot(history.history["val_accuracy"], label="val_accuracy")
plt.xlabel("Epochs")
plt.ylabel("Accuracy")
plt.legend()
plt.show()
