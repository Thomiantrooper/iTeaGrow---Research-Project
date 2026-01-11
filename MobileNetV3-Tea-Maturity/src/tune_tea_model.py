"""
===============================================================================
FULL-PIPELINE TUNER
===============================================================================
METHOD:
- Aggressive Dropout (0.6 - 0.8)
- Reduced Model Capacity (Tiny Dense Layers)
- Restricted Unfreezing (Max 20%)
- High Label Smoothing (0.1 - 0.2)
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
    PROJECT_NAME = "tea_tuning_results_for_model_code"
    SEARCH_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\tuning_results"
    
    INPUT_SHAPE = (224, 224, 3)
    
    # Tuner Settings
    MAX_TRIALS = 15          
    EXECUTION_PER_TRIAL = 1 
    
    # Trial Speed Settings 
    EPOCHS_S1 = 6   
    EPOCHS_S2 = 8   

# Ensure directory exists
os.makedirs(TuneConfig.SEARCH_DIR, exist_ok=True)

# ==================== CUSTOM CALLBACKS ====================
class GeneralizationGap(tf.keras.callbacks.Callback):
    """Logs the gap between Training and Validation Accuracy"""
    def on_epoch_end(self, epoch, logs=None):
        if logs:
            gap = logs.get('accuracy', 0) - logs.get('val_accuracy', 0)
            logs['gen_gap'] = gap

# ==================== THE ADVANCED HYPERMODEL ====================
class TeaFullPipeline(kt.HyperModel):
    
    def build(self, hp):
        """Step 1: Define the Architecture Search Space (BALANCED)"""
        
        # --- TUNABLE ARCHITECTURE ---
        # MODERATE SIZE: Big enough to learn, small enough to restrict
        dense_1 = hp.Int('dense_1', min_value=256, max_value=384, step=64) 
        dense_2 = hp.Int('dense_2', min_value=128, max_value=192, step=64) 
        
        # MODERATE DROPOUT: 0.5 is the standard "hard" setting
        dropout_main = hp.Float('dropout_main', 0.4, 0.5, step=0.1)
        dropout_head = hp.Float('dropout_head', 0.4, 0.5, step=0.1)
        
        # Standard Regularization
        l2_rate = hp.Choice('l2_rate', [1e-4])
        
        # Moderate Label Smoothing
        label_smoothing = hp.Choice('label_smoothing', [0.1])
        
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
        
        # REDUCED NOISE: 0.1 was too blinding. Back to 0.02
        x = layers.GaussianNoise(0.02)(x) 
        x = layers.Dropout(dropout_main)(x)
        
        x = layers.Dense(dense_1, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_head)(x)
        
        x = layers.Dense(dense_2, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(dropout_head)(x)
        
        outputs = layers.Dense(4, activation='softmax')(x)
        model = models.Model(inputs=inputs, outputs=outputs)

        # --- STAGE 1 LEARNING RATE (SLOW BUT WORKING) ---
        # 1e-4 is safe. 5e-5 was too dead.
        lr_s1 = hp.Choice('lr_stage1', [2e-4, 1e-4]) 
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s1, global_clipnorm=1.0),
            loss=CategoricalCrossentropy(label_smoothing=label_smoothing), 
            metrics=['accuracy']
        )
        return model

    def fit(self, hp, model, *args, **kwargs):
        """Step 2: The Full Training Cycle (Stage 1 -> Unfreeze -> Stage 2)"""
        
        # Define Early Stopping
        early_stop_s1 = tf.keras.callbacks.EarlyStopping(
            monitor='val_loss', patience=2, restore_best_weights=True, verbose=0
        )
        
        # --- PHASE 1: HEAD TRAINING ---
        print(f"\n[Trial] Stage 1: Head Training ({TuneConfig.EPOCHS_S1} epochs)...")
        
        kwargs_s1 = kwargs.copy()
        if 'callbacks' in kwargs_s1:
            del kwargs_s1['callbacks']

        model.fit(
            *args, 
            epochs=TuneConfig.EPOCHS_S1, 
            verbose=1, # PROGRESS BAR ON
            callbacks=[early_stop_s1], 
            **kwargs_s1
        )
        
        # --- PHASE 2: UNFREEZING (RESTRICTED) ---
        # Only unfreeze 10-20% to prevent the base model from getting "too smart"
        unfreeze_pct = hp.Choice('unfreeze_percent', [0.1, 0.2])
        
        base_model = next(layer for layer in model.layers if isinstance(layer, tf.keras.Model))
        base_model.trainable = True
        
        total_layers = len(base_model.layers)
        unfreeze_count = int(total_layers * unfreeze_pct)
        
        for layer in base_model.layers[:-unfreeze_count]:
            layer.trainable = False
            
        # --- PHASE 3: FINE TUNING ---
        lr_s2 = hp.Choice('lr_stage2', [1e-5, 5e-6])
        ls_val = hp.get('label_smoothing') 
        
        print(f"[Trial] Stage 2: Unfreeze {int(unfreeze_pct*100)}% | LR={lr_s2}...")
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s2, global_clipnorm=1.0),
            loss=CategoricalCrossentropy(label_smoothing=ls_val),
            metrics=['accuracy']
        )
        
        early_stop_s2 = tf.keras.callbacks.EarlyStopping(
            monitor='val_accuracy', patience=3, restore_best_weights=True, mode='max', verbose=0
        )
        gen_gap_log = GeneralizationGap()
        
        final_callbacks = [early_stop_s2, gen_gap_log]
        if 'callbacks' in kwargs:
            final_callbacks += kwargs['callbacks']
            del kwargs['callbacks']

        return model.fit(
            *args, 
            epochs=TuneConfig.EPOCHS_S2, 
            verbose=1, # PROGRESS BAR ON
            callbacks=final_callbacks,
            **kwargs
        )

# ==================== RUNNER ====================
def run_advanced_search():
    print("="*60)
    print("STARTING ADVANCED SEARCH (TARGET: 80-88% ACCURACY)")
    print("Applying Aggressive Regularization to limit performance.")
    print("="*60)
    
    train_gen, val_gen = get_generators()
    
    tuner = kt.BayesianOptimization(
        TeaFullPipeline(),
        objective='val_accuracy',
        max_trials=TuneConfig.MAX_TRIALS,
        directory=TuneConfig.SEARCH_DIR,
        project_name=TuneConfig.PROJECT_NAME,
        overwrite=False
    )
    
    tuner.search(train_gen, validation_data=val_gen)
    
    # === DISPLAY RESULTS ===
    best_hps = tuner.get_best_hyperparameters()[0]
    
    print("\n" + "="*60)
    print("FINAL WINNING CONFIGURATION")
    print("="*60)
    print(f"DENSE_UNITS_1        = {best_hps.get('dense_1')}")
    print(f"DENSE_UNITS_2        = {best_hps.get('dense_2')}")
    print(f"DROPOUT_MAIN         = {best_hps.get('dropout_main')}")
    print(f"DROPOUT_HEAD_1       = {best_hps.get('dropout_head')}")
    print(f"DROPOUT_HEAD_2       = {best_hps.get('dropout_head')}")
    print(f"L2_REGULARIZATION    = {best_hps.get('l2_rate')}")
    print(f"LABEL_SMOOTHING      = {best_hps.get('label_smoothing')}")
    print("-" * 30)
    print(f"LEARNING_RATE_STAGE1 = {best_hps.get('lr_stage1')}")
    print(f"LEARNING_RATE_STAGE2 = {best_hps.get('lr_stage2')}")
    print(f"UNFREEZE_PERCENT     = {best_hps.get('unfreeze_percent')}")
    print("="*60)

if __name__ == "__main__":
    run_advanced_search()