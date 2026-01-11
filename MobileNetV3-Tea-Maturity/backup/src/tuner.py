# # """
# # ===============================================================================
# # MOBILENETV3 - HYPERPARAMETER TUNING SUITE
# # ===============================================================================

# # PURPOSE:
# # This script performs an automated search (using Hyperband) to find the 
# # optimal hyperparameters (Dropout, Learning Rate, Dense Units).

# # INSTRUCTIONS:
# # 1. Run this script: python tune_tea_model.py
# # 2. Wait for the search to finish.
# # 3. Copy the "Best Hyperparameters" output into your main training script's 
# #    'Tune' class.
# # """

# # import os
# # import sys
# # import tensorflow as tf
# # from tensorflow.keras import layers, models, regularizers
# # from tensorflow.keras.applications import MobileNetV3Small
# # from tensorflow.keras.losses import CategoricalCrossentropy
# # import keras_tuner as kt

# # # Import preprocessing module (Must be in the same directory)
# # current_dir = os.path.dirname(os.path.abspath(__file__))
# # sys.path.append(current_dir)
# # from preprocessing import get_generators

# # # ==================== CONFIGURATION ====================
# # class TuneConfig:
# #     PROJECT_NAME = "tea_maturity_tuning"
# #     # Defines where the tuning logs/checkpoints are saved
# #     SEARCH_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\tuning_results"
    
# #     # Fixed architecture constraints
# #     IMAGE_SIZE = (224, 224)
# #     INPUT_SHAPE = (224, 224, 3)
# #     BACKBONE_ALPHA = 0.75  # Keep this fixed to match your main script
    
# #     # Search constraints
# #     MAX_TRIALS = 20        # Total number of different configs to try
# #     EXECUTION_PER_TRIAL = 1 # How many times to run each config to reduce variance
# #     EPOCHS_PER_TRIAL = 10   # Keep low for speed (we just want relative performance)

# # # Ensure directory exists
# # os.makedirs(TuneConfig.SEARCH_DIR, exist_ok=True)


# # def build_hypermodel(hp):
# #     """
# #     Builds the model dynamically using Hyperparameters (hp)
# #     """
# #     # 1. Hyperparameter Definitions
# #     # -----------------------------------------------------
# #     # Tuning the Head Architecture
# #     dense_units_1 = hp.Int('dense_units_1', min_value=256, max_value=1024, step=256)
# #     dense_units_2 = hp.Int('dense_units_2', min_value=128, max_value=512, step=128)
    
# #     # Tuning Regularization
# #     dropout_main = hp.Float('dropout_main', min_value=0.2, max_value=0.5, step=0.1)
# #     dropout_head = hp.Float('dropout_head', min_value=0.1, max_value=0.4, step=0.1)
# #     l2_rate = hp.Choice('l2_rate', values=[1e-3, 1e-4, 1e-5])
    
# #     # Tuning Optimization
# #     learning_rate = hp.Choice('learning_rate', values=[1e-2, 1e-3, 5e-4])
# #     label_smoothing = hp.Float('label_smoothing', min_value=0.0, max_value=0.1, step=0.05)

# #     # 2. Model Architecture (Matches your main script)
# #     # -----------------------------------------------------
# #     base_model = MobileNetV3Small(
# #         input_shape=TuneConfig.INPUT_SHAPE,
# #         include_top=False,
# #         weights='imagenet',
# #         pooling='max',
# #         include_preprocessing=False, # Assuming manual preprocessing
# #         alpha=TuneConfig.BACKBONE_ALPHA
# #     )
# #     base_model.trainable = False

# #     inputs = layers.Input(shape=TuneConfig.INPUT_SHAPE)
# #     x = base_model(inputs, training=False)

# #     # Apply tuned noise/dropout
# #     x = layers.GaussianNoise(0.02)(x) # Keeping fixed for stability
# #     x = layers.Dropout(dropout_main)(x)

# #     # Dense Block 1
# #     x = layers.Dense(
# #         dense_units_1, 
# #         activation='relu',
# #         kernel_regularizer=regularizers.l2(l2_rate)
# #     )(x)
# #     x = layers.BatchNormalization()(x)
# #     x = layers.Dropout(dropout_head)(x)

# #     # Dense Block 2
# #     x = layers.Dense(
# #         dense_units_2, 
# #         activation='relu',
# #         kernel_regularizer=regularizers.l2(l2_rate)
# #     )(x)
# #     x = layers.BatchNormalization()(x)
# #     x = layers.Dropout(dropout_head)(x)

# #     # Output
# #     # Note: We assume 4 classes based on your previous code. 
# #     # Ideally, pass num_classes dynamically, but 4 is hardcoded for safety here.
# #     outputs = layers.Dense(4, activation='softmax')(x)

# #     model = models.Model(inputs=inputs, outputs=outputs)

# #     # 3. Compile
# #     # -----------------------------------------------------
# #     model.compile(
# #         # optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
# #         optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate, global_clipnorm=1.0),
# #         loss=CategoricalCrossentropy(label_smoothing=label_smoothing),
# #         metrics=['accuracy']
# #     )
    
# #     return model


# # def run_tuning():
# #     print("="*60)
# #     print("STARTING HYPERPARAMETER SEARCH (KERAS TUNER)")
# #     print("="*60)

# #     # 1. Get Data
# #     # Note: We use the same generators, but for tuning we often don't need
# #     # the full validation set overhead, just a consistent split.
# #     train_gen, val_gen = get_generators()
    
# #     # 2. Initialize Tuner (Hyperband is efficient)
# #     tuner = kt.Hyperband(
# #         build_hypermodel,
# #         objective='val_accuracy',
# #         max_epochs=TuneConfig.EPOCHS_PER_TRIAL,
# #         factor=3,
# #         directory=TuneConfig.SEARCH_DIR,
# #         project_name=TuneConfig.PROJECT_NAME,
# #         overwrite=False # Set True if you want to restart fresh every time
# #     )

# #     # 3. Print Search Space Summary
# #     tuner.search_space_summary()

# #     # 4. Run Search
# #     # Use EarlyStopping to kill bad trials fast
# #     stop_early = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=3)

# #     print("\nStarting search...")
# #     tuner.search(
# #         train_gen,
# #         validation_data=val_gen,
# #         epochs=TuneConfig.EPOCHS_PER_TRIAL,
# #         callbacks=[stop_early],
# #         verbose=1
# #     )

# #     # 5. Extract Best Results
# #     print("\n" + "="*60)
# #     print("SEARCH COMPLETE - BEST HYPERPARAMETERS")
# #     print("="*60)
    
# #     best_hps = tuner.get_best_hyperparameters(num_trials=1)[0]

# #     print(f"""
# #     COPY THESE VALUES TO YOUR 'Tune' CLASS IN THE MAIN SCRIPT:
# #     ----------------------------------------------------------
# #     DENSE_UNITS_1     = {best_hps.get('dense_units_1')}
# #     DENSE_UNITS_2     = {best_hps.get('dense_units_2')}
# #     DROPOUT_MAIN      = {best_hps.get('dropout_main')}
# #     DROPOUT_HEAD_1    = {best_hps.get('dropout_head')} (Use for both head dropouts)
# #     L2_REGULARIZATION = {best_hps.get('l2_rate')}
# #     LEARNING_RATE     = {best_hps.get('learning_rate')}
# #     LABEL_SMOOTHING   = {best_hps.get('label_smoothing'):.3f}
# #     ----------------------------------------------------------
# #     """)

# # if __name__ == "__main__":
# #     run_tuning()



# # ===========================================================
# # got an advanced version to use

# """
# ===============================================================================
# ADVANCED FULL-PIPELINE TUNER (FINAL RESEARCH VERSION)
# ===============================================================================
# PURPOSE: 
# Finds the absolute best hyperparameters by simulating the FULL training cycle 
# (Feature Extraction -> Unfreezing -> Fine-Tuning) for every trial.

# FEATURES:
# - Simulates Stage 1 AND Stage 2 in every trial.
# - Explicitly checks for Overfitting via 'gen_gap'.
# - Uses EarlyStopping to save time on bad configs.
# - Uses Gradient Clipping to prevent crashes.
# """

# import os
# import sys
# import tensorflow as tf
# from tensorflow.keras import layers, models, regularizers
# from tensorflow.keras.applications import MobileNetV3Small
# from tensorflow.keras.losses import CategoricalCrossentropy
# import keras_tuner as kt

# # Import preprocessing
# current_dir = os.path.dirname(os.path.abspath(__file__))
# sys.path.append(current_dir)
# from preprocessing import get_generators

# # ==================== CONFIGURATION ====================
# class TuneConfig:
#     PROJECT_NAME = "advanced_tea_tuning_final"
#     SEARCH_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity\tuning_results"
    
#     INPUT_SHAPE = (224, 224, 3)
    
#     # Tuner Settings
#     MAX_TRIALS = 15          
#     EXECUTION_PER_TRIAL = 1 
    
#     # Trial Speed Settings 
#     EPOCHS_S1 = 8   
#     EPOCHS_S2 = 10   # Increased slightly to allow EarlyStopping to work

# # Ensure directory exists
# os.makedirs(TuneConfig.SEARCH_DIR, exist_ok=True)

# # ==================== CUSTOM CALLBACKS ====================
# class GeneralizationGap(tf.keras.callbacks.Callback):
#     """Logs the gap between Training and Validation Accuracy"""
#     def on_epoch_end(self, epoch, logs=None):
#         if logs:
#             gap = logs.get('accuracy', 0) - logs.get('val_accuracy', 0)
#             logs['gen_gap'] = gap

# # ==================== THE ADVANCED HYPERMODEL ====================
# class TeaFullPipeline(kt.HyperModel):
    
#     def build(self, hp):
#         """Step 1: Define the Architecture Search Space"""
        
#         # --- TUNABLE ARCHITECTURE ---
#         dense_1 = hp.Int('dense_1', min_value=512, max_value=1024, step=256)
#         dense_2 = hp.Int('dense_2', min_value=256, max_value=512, step=256)
        
#         dropout_main = hp.Float('dropout_main', 0.2, 0.4, step=0.1)
#         dropout_head = hp.Float('dropout_head', 0.2, 0.4, step=0.1)
        
#         l2_rate = hp.Choice('l2_rate', [1e-4, 1e-5])
        
#         # Adding Label Smoothing back as a small choice (Robustness)
#         label_smoothing = hp.Choice('label_smoothing', [0.0, 0.05])
        
#         # --- FIXED BASE ---
#         base_model = MobileNetV3Small(
#             input_shape=TuneConfig.INPUT_SHAPE,
#             include_top=False,
#             weights='imagenet',
#             pooling='max',
#             include_preprocessing=False,
#             alpha=0.75
#         )
#         base_model.trainable = False # Start Frozen

#         # --- BUILD HEAD ---
#         inputs = layers.Input(shape=TuneConfig.INPUT_SHAPE)
#         x = base_model(inputs, training=False)
#         x = layers.GaussianNoise(0.02)(x)
#         x = layers.Dropout(dropout_main)(x)
        
#         x = layers.Dense(dense_1, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
#         x = layers.BatchNormalization()(x)
#         x = layers.Dropout(dropout_head)(x)
        
#         x = layers.Dense(dense_2, activation='relu', kernel_regularizer=regularizers.l2(l2_rate))(x)
#         x = layers.BatchNormalization()(x)
#         x = layers.Dropout(dropout_head)(x)
        
#         outputs = layers.Dense(4, activation='softmax')(x)
#         model = models.Model(inputs=inputs, outputs=outputs)

#         # --- STAGE 1 LEARNING RATE (SAFE VALUES ONLY) ---
#         lr_s1 = hp.Choice('lr_stage1', [1e-3, 5e-4]) 
        
#         model.compile(
#             optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s1, global_clipnorm=1.0),
#             loss=CategoricalCrossentropy(label_smoothing=label_smoothing), 
#             metrics=['accuracy']
#         )
#         return model

#     def fit(self, hp, model, *args, **kwargs):
#         """Step 2: The Full Training Cycle (Stage 1 -> Unfreeze -> Stage 2)"""
        
#         # Define Early Stopping to save time on bad trials
#         # We use val_loss for safety, but with restore_best_weights
#         early_stop_s1 = tf.keras.callbacks.EarlyStopping(
#             monitor='val_loss', patience=2, restore_best_weights=True, verbose=0
#         )
        
#         # --- PHASE 1: HEAD TRAINING ---
#         print(f"\n[Trial] Stage 1: Head Training ({TuneConfig.EPOCHS_S1} epochs)...")
        
#         # Remove callbacks from kwargs to avoid duplication
#         kwargs_s1 = kwargs.copy()
#         if 'callbacks' in kwargs_s1:
#             del kwargs_s1['callbacks']

#         model.fit(
#             *args, 
#             epochs=TuneConfig.EPOCHS_S1, 
#             verbose=1, 
#             callbacks=[early_stop_s1], # Local callback
#             **kwargs_s1
#         )
        
#         # --- PHASE 2: UNFREEZING ---
#         unfreeze_pct = hp.Choice('unfreeze_percent', [0.3, 0.5, 0.7])
        
#         # SAFER way to find the base model (Fix 2 from critique)
#         base_model = next(layer for layer in model.layers if isinstance(layer, tf.keras.Model))
#         base_model.trainable = True
        
#         total_layers = len(base_model.layers)
#         unfreeze_count = int(total_layers * unfreeze_pct)
        
#         # Re-freeze bottom layers
#         for layer in base_model.layers[:-unfreeze_count]:
#             layer.trainable = False
            
#         # --- PHASE 3: FINE TUNING ---
#         lr_s2 = hp.Choice('lr_stage2', [1e-5, 8e-6, 5e-6])
#         ls_val = hp.get('label_smoothing') # Reuse the chosen value
        
#         print(f"[Trial] Stage 2: Unfreeze {int(unfreeze_pct*100)}% | LR={lr_s2}...")
        
#         model.compile(
#             optimizer=tf.keras.optimizers.Adam(learning_rate=lr_s2, global_clipnorm=1.0),
#             loss=CategoricalCrossentropy(label_smoothing=ls_val),
#             metrics=['accuracy']
#         )
        
#         # Stage 2 Callbacks (Include the critical GenGap logger)
#         early_stop_s2 = tf.keras.callbacks.EarlyStopping(
#             monitor='val_accuracy', patience=3, restore_best_weights=True, mode='max', verbose=0
#         )
#         gen_gap_log = GeneralizationGap()
        
#         # We need to inject these callbacks into the tuner's standard callbacks
#         final_callbacks = [early_stop_s2, gen_gap_log]
#         if 'callbacks' in kwargs:
#             final_callbacks += kwargs['callbacks']
#             del kwargs['callbacks']

#         return model.fit(
#             *args, 
#             epochs=TuneConfig.EPOCHS_S2, 
#             verbose=1,
#             callbacks=final_callbacks,
#             **kwargs
#         )

# # ==================== RUNNER ====================
# def run_advanced_search():
#     print("="*60)
#     print("STARTING ADVANCED FULL-PIPELINE SEARCH (FINAL VERSION)")
#     print("="*60)
    
#     train_gen, val_gen = get_generators()
    
#     tuner = kt.BayesianOptimization(
#         TeaFullPipeline(),
#         objective='val_accuracy',
#         max_trials=TuneConfig.MAX_TRIALS,
#         directory=TuneConfig.SEARCH_DIR,
#         project_name=TuneConfig.PROJECT_NAME,
#         overwrite=False
#     )
    
#     tuner.search(train_gen, validation_data=val_gen)
    
#     # === DISPLAY RESULTS ===
#     best_hps = tuner.get_best_hyperparameters()[0]
    
#     print("\n" + "="*60)
#     print("🏆 FINAL WINNING CONFIGURATION (COPY THESE!) 🏆")
#     print("="*60)
#     print(f"DENSE_UNITS_1        = {best_hps.get('dense_1')}")
#     print(f"DENSE_UNITS_2        = {best_hps.get('dense_2')}")
#     print(f"DROPOUT_MAIN         = {best_hps.get('dropout_main')}")
#     print(f"DROPOUT_HEAD_1       = {best_hps.get('dropout_head')}")
#     print(f"DROPOUT_HEAD_2       = {best_hps.get('dropout_head')}")
#     print(f"L2_REGULARIZATION    = {best_hps.get('l2_rate')}")
#     print(f"LABEL_SMOOTHING      = {best_hps.get('label_smoothing')}")
#     print("-" * 30)
#     print(f"LEARNING_RATE_STAGE1 = {best_hps.get('lr_stage1')}")
#     print(f"LEARNING_RATE_STAGE2 = {best_hps.get('lr_stage2')}")
#     print(f"UNFREEZE_PERCENT     = {best_hps.get('unfreeze_percent')}")
#     print("="*60)

# if __name__ == "__main__":
#     run_advanced_search()
