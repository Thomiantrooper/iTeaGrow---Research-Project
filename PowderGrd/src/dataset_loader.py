# import tensorflow as tf
# from tensorflow.keras.preprocessing.image import ImageDataGenerator


# def load_dataset(data_dir, img_size=224, batch_size=16):

#     train_datagen = ImageDataGenerator(
#         rescale=1./255,
#         validation_split=0.2,             # 80% train, 20% val
#         rotation_range=20,
#         zoom_range=0.2,
#         width_shift_range=0.2,
#         height_shift_range=0.2,
#         horizontal_flip=True,
#         vertical_flip=True
#     )

#     train_data = train_datagen.flow_from_directory(
#         data_dir,
#         target_size=(img_size, img_size),
#         batch_size=batch_size,
#         class_mode='categorical',
#         subset='training'
#     )

#     val_data = train_datagen.flow_from_directory(
#         data_dir,
#         target_size=(img_size, img_size),
#         batch_size=batch_size,
#         class_mode='categorical',
#         subset='validation'
#     )

#     return train_data, val_data


import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator


def load_dataset(data_dir, img_size=224, batch_size=16):

    train_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2,

        rotation_range=25,         # slightly more rotation
        zoom_range=0.3,            # zoom in/out
        width_shift_range=0.25,    # horizontal movement
        height_shift_range=0.25,   # vertical movement

        shear_range=10,            # small shearing (texture change)

        brightness_range=[0.6, 1.4],  # darker & brighter
        channel_shift_range=20,       # color variation

        horizontal_flip=True,
        vertical_flip=True,

        fill_mode='nearest'
    )

    val_datagen = ImageDataGenerator(
        rescale=1./255,
        validation_split=0.2
    )

    train_data = train_datagen.flow_from_directory(
        data_dir,
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode='categorical',
        subset='training'
    )

    val_data = val_datagen.flow_from_directory(
        data_dir,
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode='categorical',
        subset='validation'
    )

    return train_data, val_data
