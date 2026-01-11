"""
===============================================================================
ADVANCED FULL-PIPELINE TUNER (STAGE 1 + STAGE 2)
===============================================================================
PURPOSE: 
Finds the absolute best hyperparameters by simulating the FULL training cycle 
(Feature Extraction -> Unfreezing -> Fine-Tuning) for every trial.

This guarantees the chosen settings work for the ENTIRE training process, 
avoiding the "crash" you saw earlier.
"""

import os
import sys
import tensorflow as tf
from tensorflow.keras import layers, models, regularizers
from tensorflow.keras.applications import MobileNetV3Small
from tensorflow.keras.losses import CategoricalCrossentropy
import keras_tuner as kt

# Import preprocessing
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)
from preprocessing import get_generators

# ==================== CONFIGURATION ====================
class TuneConfig:
    PROJECT_NAME = "advanced_tea_tuning"
    SEARCH_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\tuning_results"
    
    INPUT_SHAPE = (224, 224, 3)
    
    # Tuner Settings
    MAX_TRIALS = 15          # 15 Trials is enough to find the "Goldilocks" zone
    EXECUTION_PER_TRIAL = 1 
    
    # Trial Speed Settings 
    # We use 8+8 epochs. This is long enough to detect stability issues
    # but short enough to finish in ~5-6 hours.
    EPOCHS_S1 = 8   
    EPOCHS_S2 = 8   

# Ensure directory exists
os.makedirs(TuneConfig.SEARCH_DIR, exist_ok=True)

# ==================== THE ADVANCED HYPERMODEL ====================
class TeaFullPipeline(kt.HyperModel):
    
    def build(self, hp):
        """Step 1: Define the Architecture Search Space"""
        
        # --- TUNABLE ARCHITECTURE ---
        # We test different sizes for the "Brain" to solve the Tender confusion
        dense_1 = hp.Int('dense_1', min_value=512, max_value=1024, step=256)
        dense_2 = hp.Int('dense_2', min_value=256, max_value=512, step=256)
        
        # We test different dropout rates for stability
        dropout_main = hp.Float('dropout_main', 0.2, 0.4, step=0.1)
        dropout_head = hp.Float('dropout_head', 0.2, 0.4, step=0.1)
        
        # We test regularization strength
        l2_rate = hp.Choice('l2_rate', [1e-4, 1e-5])
        
        # --- FIXED BASE ---
        base_model = MobileNetV3Small(
            input_shape=TuneConfig.INPUT_SHAPE,
            include_top=False,
            weights='imagenet',
            pooling='max',
            include_preprocessing=False,
            alpha=0.75
        )
        base_model.trainable = False # Start Frozen

        # --- BUILD HEAD ---
        inputs = layers.Input(shape=TuneConfig.INPUT_SHAPE)
        x = base_model(inputs, training=False)
        x = layers.GaussianNoise(0.02)(x)
        x = layers.Dropout(dropout_main)(x)
        
        x = layers.Dense(dense_1, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_head)(x)
        
        x = layers.Dense(dense_2, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_head)(x)
        
        # 4 classes (Assamica M/T, DT1 M/T)
        outputs = layers.Dense(4, activation='softmax')(x)
        model = models.Model(inputs=inputs, outputs=outputs)

        # --- STAGE 1 LEARNING RATE ---
        # CRITICAL: We REMOVED 0.01. We only test safe values now.
        lr_s1 = hp.Choice('lr_stage1', [1e-3, 5e-4]) 
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s1),
            loss=CategoricalCrossentropy(label_smoothing=0.0), 
            metrics=['accuracy']
        )
        return model

    def fit(self, hp, model, *args, **kwargs):
        """Step 2: The Full Training Cycle (Stage 1 -> Unfreeze -> Stage 2)"""
        
        # --- PHASE 1: HEAD TRAINING ---
        # Train the head first so it doesn't break the base model
        print(f"\n[Trial] Stage 1: Head Training ({TuneConfig.EPOCHS_S1} epochs)...")
        model.fit(
            *args, 
            epochs=TuneConfig.EPOCHS_S1, 
            verbose=2, # concise output
            **kwargs
        )
        
        # --- PHASE 2: UNFREEZING ---
        # We test if unfreezing 30%, 50%, or 70% is best
        # Unfreezing MORE layers is often the key to distinguishing varieties (Assamica vs DT1)
        unfreeze_pct = hp.Choice('unfreeze_percent', [0.3, 0.5, 0.7])
        
        base_model = model.layers[1] # Access the MobileNet inside
        base_model.trainable = True
        total_layers = len(base_model.layers)
        unfreeze_count = int(total_layers * unfreeze_pct)
        
        # Re-freeze the bottom layers, unfreeze the top
        for layer in base_model.layers[:-unfreeze_count]:
            layer.trainable = False
            
        # --- PHASE 3: FINE TUNING ---
        # We test tiny learning rates for the delicate fine-tuning
        lr_s2 = hp.Choice('lr_stage2', [1e-5, 8e-6, 5e-6])
        
        print(f"[Trial] Stage 2: Unfreeze {int(unfreeze_pct*100)}% layers | LR={lr_s2}...")
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s2),
            loss=CategoricalCrossentropy(label_smoothing=0.0),
            metrics=['accuracy']
        )
        
        # Train Stage 2 and return the history
        # Keras Tuner will use the FINAL validation accuracy from this stage to decide the winner
        return model.fit(
            *args, 
            epochs=TuneConfig.EPOCHS_S2, 
            verbose=2,
            **kwargs
        )

# ==================== RUNNER ====================
def run_advanced_search():
    print("="*60)
    print("STARTING ADVANCED FULL-PIPELINE SEARCH")
    print("This finds the settings that survive the FULL process.")
    print("="*60)
    
    train_gen, val_gen = get_generators()
    
    # BayesianOptimization is smarter/faster than Hyperband for complex pipelines
    tuner = kt.BayesianOptimization(
        TeaFullPipeline(),
        objective='val_accuracy',
        max_trials=TuneConfig.MAX_TRIALS,
        directory=TuneConfig.SEARCH_DIR,
        project_name=TuneConfig.PROJECT_NAME,
        overwrite=False # Safe to stop and resume
    )
    
    tuner.search(train_gen, validation_data=val_gen)
    
    # === DISPLAY RESULTS ===
    best_hps = tuner.get_best_hyperparameters()[0]
    
    print("\n" + "="*60)
    print("FINAL CONFIGURATION (COPY THESE!) ")
    print("="*60)
    print(f"DENSE_UNITS_1        = {best_hps.get('dense_1')}")
    print(f"DENSE_UNITS_2        = {best_hps.get('dense_2')}")
    print(f"DROPOUT_MAIN         = {best_hps.get('dropout_main')}")
    print(f"DROPOUT_HEAD_1       = {best_hps.get('dropout_head')}")
    print(f"DROPOUT_HEAD_2       = {best_hps.get('dropout_head')}")
    print(f"L2_REGULARIZATION    = {best_hps.get('l2_rate')}")
    print("-" * 30)
    print(f"LEARNING_RATE_STAGE1 = {best_hps.get('lr_stage1')}")
    print(f"LEARNING_RATE_STAGE2 = {best_hps.get('lr_stage2')}")
    print(f"UNFREEZE_PERCENT     = {best_hps.get('unfreeze_percent')}")
    print("="*60)

if __name__ == "__main__":
    run_advanced_search()