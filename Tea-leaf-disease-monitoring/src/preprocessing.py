from tensorflow.keras.preprocessing.image import ImageDataGenerator


def get_train_val_generators(
    train_dir="dataset/train", val_dir="dataset/val", img_size=(224, 224), batch_size=32
):
    """
    Returns training and validation generators with data augmentation.
    """
    # Data augmentation for training
    train_datagen = ImageDataGenerator(
        rescale=1.0 / 255,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode="nearest",
    )

    # Only rescale validation data
    val_datagen = ImageDataGenerator(rescale=1.0 / 255)

    # Load training images
    train_generator = train_datagen.flow_from_directory(
        train_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode="categorical",
        color_mode="rgb",
    )

    # Load validation images
    val_generator = val_datagen.flow_from_directory(
        val_dir,
        target_size=img_size,
        batch_size=batch_size,
        class_mode="categorical",
        color_mode="rgb",
    )

    return train_generator, val_generator


if __name__ == "__main__":
    # Example usage
    train_gen, val_gen = get_train_val_generators()
