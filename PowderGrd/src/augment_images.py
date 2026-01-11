import os
from tensorflow.keras.preprocessing.image import ImageDataGenerator, img_to_array, load_img, array_to_img

# -------- SETTINGS -------- #
INPUT_DIR = "../data/train"          # Your original dataset
OUTPUT_DIR = "../data/augmented"     # Target directory to save new images
AUGMENT_COUNT = 5                    # Number of variants per image
IMAGE_SIZE = (224, 224)
# --------------------------- #

# Strong augmentation for texture images (tea powder)
datagen = ImageDataGenerator(
    rotation_range=25,
    width_shift_range=0.1,
    height_shift_range=0.1,
    shear_range=0.2,
    zoom_range=0.25,
    horizontal_flip=True,
    vertical_flip=True,
    brightness_range=[0.6, 1.4],
    fill_mode='nearest'
)

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Loop through each class folder
for class_name in os.listdir(INPUT_DIR):
    class_input_path = os.path.join(INPUT_DIR, class_name)
    class_output_path = os.path.join(OUTPUT_DIR, class_name)

    if not os.path.isdir(class_input_path):
        continue

    os.makedirs(class_output_path, exist_ok=True)
    print(f"Processing class: {class_name}")

    # Loop through images in each class
    for img_name in os.listdir(class_input_path):
        img_path = os.path.join(class_input_path, img_name)

        if not img_path.lower().endswith((".jpg", ".jpeg", ".png")):
            continue

        img = load_img(img_path, target_size=IMAGE_SIZE)
        x = img_to_array(img)
        x = x.reshape((1,) + x.shape)  # shape = (1, 224, 224, 3)

        # Generate 5 augmented versions
        i = 0
        for batch in datagen.flow(x, batch_size=1):
            new_filename = f"{os.path.splitext(img_name)[0]}_aug{i+1}.jpg"
            save_path = os.path.join(class_output_path, new_filename)

            array_to_img(batch[0]).save(save_path)

            i += 1
            if i >= AUGMENT_COUNT:
                break

print("Augmentation completed! ✔")
