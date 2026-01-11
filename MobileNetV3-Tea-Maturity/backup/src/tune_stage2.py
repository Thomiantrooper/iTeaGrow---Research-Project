"""
===============================================================================
STAGE 2 TUNER - FINE-TUNING STRATEGY SEARCH
===============================================================================
"""
import os
import sys
import tensorflow as tf
from tensorflow.keras import layers, models, regularizers
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.losses import CategoricalCrossentropy
import keras_tuner as kt

current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)
from preprocessing import get_generators

# LOCKED BEST VALUES (From your Tuner + Manual Fixes)
class BestStage1:
    DENSE_1 = 768
    DENSE_2 = 512
    DROP_MAIN = 0.2
    DROP_HEAD = 0.3
    L2 = 0.0001
    LR_STAGE1 = 0.001  # LOCKED at the safe 1e-3
    SMOOTHING = 0.0

class TuneConfig:
    PROJECT_NAME = "stage2_search_v2"
    # Update this path
    SEARCH_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\tuning_results"
    INPUT_SHAPE = (224, 224, 3)
    EPOCHS_S1_WARMUP = 10 
    EPOCHS_S2_SEARCH = 12

class TeaHyperModel(kt.HyperModel):
    def build(self, hp):
        base_model = MobileNetV3Small(
            input_shape=TuneConfig.INPUT_SHAPE,
            include_top=False,
            weights='imagenet',
            pooling='max',
            include_preprocessing=False,
            alpha=0.75
        )
        base_model.trainable = False

        inputs = layers.Input(shape=TuneConfig.INPUT_SHAPE)
        x = base_model(inputs, training=False)
        x = layers.GaussianNoise(0.02)(x)
        x = layers.Dropout(BestStage1.DROP_MAIN)(x)
        x = layers.Dense(BestStage1.DENSE_1, activation='relu', kernel_regularizer=regularizers.l2(BestStage1.L2))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(BestStage1.DROP_HEAD)(x)
        x = layers.Dense(BestStage1.DENSE_2, activation='relu', kernel_regularizer=regularizers.l2(BestStage1.L2))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(BestStage1.DROP_HEAD)(x)
        outputs = layers.Dense(4, activation='softmax')(x)
        model = models.Model(inputs=inputs, outputs=outputs)

        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=BestStage1.LR_STAGE1),
            loss=CategoricalCrossentropy(label_smoothing=BestStage1.SMOOTHING),
            metrics=['accuracy']
        )
        return model

    def fit(self, hp, model, *args, **kwargs):
        # Phase 1: Warmup
        print(f"\n[Trial] Warmup Stage 1...")
        model.fit(*args, epochs=TuneConfig.EPOCHS_S1_WARMUP, verbose=0, **kwargs)

        # Phase 2: Search Fine-Tuning
        unfreeze_percent = hp.Choice('unfreeze_percent', [0.3, 0.5, 0.7])
        lr_stage2 = hp.Choice('lr_stage2', [1e-4, 5e-5, 1e-5])
        
        base_model = model.layers[1]
        base_model.trainable = True
        num_layers = len(base_model.layers)
        num_unfreeze = int(num_layers * unfreeze_percent)
        
        for layer in base_model.layers[:-num_unfreeze]:
            layer.trainable = False
            
        print(f"[Trial] Stage 2: Unfreeze {unfreeze_percent*100}%, LR={lr_stage2}")

        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=lr_stage2),
            loss=CategoricalCrossentropy(label_smoothing=BestStage1.SMOOTHING),
            metrics=['accuracy']
        )

        return model.fit(*args, epochs=TuneConfig.EPOCHS_S2_SEARCH, verbose=1, **kwargs)

def run_stage2_search():
    train_gen, val_gen = get_generators()
    tuner = kt.RandomSearch(
        TeaHyperModel(),
        objective='val_accuracy',
        max_trials=9,
        executions_per_trial=1,
        directory=TuneConfig.SEARCH_DIR,
        project_name=TuneConfig.PROJECT_NAME,
        overwrite=False
    )
    tuner.search(train_gen, validation_data=val_gen)
    
    best_hps = tuner.get_best_hyperparameters()[0]
    print("\n" + "="*60)
    print("BEST FINE-TUNING SETTINGS")
    print(f"UNFREEZE_PERCENT     = {best_hps.get('unfreeze_percent')}")
    print(f"LEARNING_RATE_STAGE2 = {best_hps.get('lr_stage2')}")

if __name__ == "__main__":
    run_stage2_search()