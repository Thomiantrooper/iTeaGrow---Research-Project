"""
===============================================================================
MOBILENETV3 SMALL - TEA MATURITY CLASSIFICATION
===============================================================================
IMPLEMENTATION:
- Centralized configuration via Tune class
- Two-stage training with fine-tuning
- Test-time augmentation (TTA)
- Statistical validation with bootstrap CIs
- Comprehensive visualization and reporting
"""

import os  # Standard library for operating system interface and file paths
import sys  # Standard library for system-specific parameters and functions
import json  # Standard library for JSON encoding and decoding
import numpy as np  # Numerical Python for array manipulation
import tensorflow as tf  # TensorFlow deep learning framework
from datetime import datetime  # Date and time manipulation
from typing import Dict, List, Tuple, Optional, Any  # Type hinting for better code readability

import matplotlib.pyplot as plt  # Plotting library
import seaborn as sns  # Statistical data visualization library
from sklearn.metrics import confusion_matrix, classification_report, roc_curve, auc  # Scikit-learn metrics
from tensorflow.keras import layers, models, regularizers  # Keras layers, models, and regularizers
from tensorflow.keras.applications import MobileNetV3Small  # Pre-trained MobileNetV3Small model
from tensorflow.keras.losses import CategoricalCrossentropy  # Loss function for multi-class classification
from tensorflow.keras.callbacks import (
    ModelCheckpoint, EarlyStopping, ReduceLROnPlateau, CSVLogger
)  # Keras callbacks for training control

# Import preprocessing module
# Get the absolute path of the current file's directory
current_dir = os.path.dirname(os.path.abspath(__file__))
# Add the current directory to the system path to allow imports
sys.path.append(current_dir)
# Import custom generator functions from preprocessing.py
from preprocessing import get_generators, get_test_generator


# ============================================================================
# TUNING DECK (CENTRALIZED CONFIGURATION)
# ============================================================================
class Tune:
    """
    CENTRALIZED CONFIGURATION CLASS
    Change ONLY these values to tune the entire experiment.
    All hyperparameters and paths are defined here for easy access.
    """
    
    # ==================== EXPERIMENT IDENTITY ====================
    # Name of the experiment for logging and saving
    EXPERIMENT_NAME = "MobileNetV3_4Class_Tea"
    # Seed for reproducibility across numpy and tensorflow
    RANDOM_SEED = 42
    # Timestamp for creating unique directories/files for each run
    TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # ==================== PATHS & DIRECTORIES ====================
    # Base directory of the project
    BASE_DIR = r"C:\Users\HP\Desktop\Tea\iTeaGrow---Research-Project\MobileNetV3-Tea-Maturity"
    # Directory for saving results
    RESULTS_DIR = os.path.join(BASE_DIR, "results_research1")
    # Directory for saving trained models
    MODELS_DIR = os.path.join(BASE_DIR, "models_research1")
    # Directory for saving training logs
    LOGS_DIR = os.path.join(BASE_DIR, "logs_research1")
    # Directory for saving plots
    PLOTS_DIR = os.path.join(BASE_DIR, "plots_research1")
    
    # ==================== DATA CONFIGURATION ====================
    # Target image size for the model
    IMAGE_SIZE = (224, 224)
    # Input shape including color channels (RGB)
    INPUT_SHAPE = (224, 224, 3)
    # Batch size for training and validation
    BATCH_SIZE = 32
    
    # ==================== PREPROCESSING ====================
    # Description of input range for documentation
    INPUT_RANGE = "[-1, 1]"
    # Formula used for preprocessing for documentation
    PREPROCESS_FORMULA = "(x / 127.5) - 1.0"
    # Whether to include Keras's internal preprocessing (False because we do it manually)
    INCLUDE_PREPROCESSING = False  # MUST be False for manual [-1,1] scaling
    
    # ==================== MODEL ARCHITECTURE ====================
    # Backbone
    # Name of the backbone model architecture
    BACKBONE = "MobileNetV3Small"
    # Alpha parameter controls the width of the network (0.75 is smaller/faster)
    ALPHA = 0.75
    # Minimalistic mode for MobileNetV3 (False means use full version)
    MINIMALISTIC = False
    # Global pooling type at the end of the backbone ('max' or 'avg')
    POOLING = "max"
    
    # Custom Head
    # Number of units in the first custom dense layer
    DENSE_UNITS_1 = 320
    # Number of units in the second custom dense layer
    DENSE_UNITS_2 = 128
    # Activation function for dense layers
    ACTIVATION = "relu"
    
    # Stability & Regularization
    # Dropout rate after the backbone
    DROPOUT_MAIN = 0.4
    # Dropout rate after the first custom dense layer
    DROPOUT_HEAD_1 = 0.4
    # Dropout rate after the second custom dense layer
    DROPOUT_HEAD_2 = 0.4
    # Standard deviation for Gaussian noise injection (data augmentation/regularization)
    GAUSSIAN_NOISE = 0.02
    # L2 regularization factor for weights
    L2_REGULARIZATION = 0.0001
    
    # ==================== TRAINING SCHEDULE ====================
    # Stage 1: Feature Extraction (Training only the custom head)
    EPOCHS_STAGE1 = 20
    # Learning rate for stage 1
    LEARNING_RATE_STAGE1 = 0.0001 #previously: 1e-2 = 0.01
    # Patience for early stopping in stage 1
    PATIENCE_STAGE1 = 15
    
    # Stage 2: Fine-tuning (Training head + part of backbone)
    EPOCHS_STAGE2 = 50
    # Lower learning rate for fine-tuning to preserve learned features
    LEARNING_RATE_STAGE2 = 1e-5
    # Patience for early stopping in stage 2
    PATIENCE_STAGE2 = 15
    
    # Common
    # Minimum change in monitored quantity to qualify as an improvement
    MIN_DELTA = 0.001
    
    # ==================== FINE-TUNING STRATEGY ====================
    # Percentage of layers from the end of the backbone to unfreeze
    UNFREEZE_PERCENT = 0.2
    
    # ==================== OPTIMIZATION ====================
    # Label smoothing factor to prevent overconfidence
    LABEL_SMOOTHING = 0.1
    # Gradient clipping norm to prevent exploding gradients
    GRADIENT_CLIP_NORM = 1.0
    # Whether to use class weights to handle imbalance
    USE_CLASS_WEIGHTS = True
    
    # ==================== TEST-TIME AUGMENTATION ====================
    # Whether to enable Test-Time Augmentation (TTA)
    TTA_ENABLED = True
    # Number of different augmented versions to predict for each image
    TTA_SAMPLES = 25
    # Whether to use only geometric augmentations for TTA
    TTA_GEOMETRIC_ONLY = True
    
    # ==================== EVALUATION & STATISTICS ====================
    # Number of bootstrap iterations for confidence interval calculation
    BOOTSTRAP_ITERATIONS = 1000
    # Confidence level for statistical intervals (e.g., 0.95 for 95%)
    CONFIDENCE_LEVEL = 0.95
    
    # ==================== VISUALIZATION ====================
    # DPI (dots per inch) for saving plots
    PLOT_DPI = 150
    # Style for matplotlib plots
    PLOT_STYLE = "seaborn-v0_8"


# Create directories
# Iterate through all configured output directories
for dir_path in [Tune.RESULTS_DIR, Tune.MODELS_DIR, Tune.LOGS_DIR, Tune.PLOTS_DIR]:
    # Create directory if it doesn't exist
    os.makedirs(dir_path, exist_ok=True)


# ============================================================================
# HELPER CLASSES
# ============================================================================
class KerasSequenceWrapper(tf.keras.utils.Sequence):
    """Wraps custom generator for Keras compatibility"""
    
    def __init__(self, generator):
        # Initialize parent class
        super().__init__()
        # Store the custom generator instance
        self.generator = generator
        
    def __len__(self):
        # Delegate length call to the custom generator
        return len(self.generator)
    
    def __getitem__(self, idx):
        # Delegate item retrieval to the custom generator
        return self.generator[idx]
    
    def on_epoch_end(self):
        # Call on_epoch_end of custom generator if it exists (e.g., for shuffling)
        if hasattr(self.generator, 'on_epoch_end'):
            self.generator.on_epoch_end()


class StatisticalValidator:
    """Research-grade statistical validation methods"""
    
    @staticmethod
    def bootstrap_confidence_interval(y_true: np.ndarray, 
                                    y_pred: np.ndarray) -> Dict[str, float]:
        """Calculate bootstrap confidence interval for accuracy"""
        # Number of samples in the dataset
        n_samples = len(y_true)
        # List to store accuracy from each bootstrap iteration
        accuracies = []
        
        # Perform bootstrap resampling
        for _ in range(Tune.BOOTSTRAP_ITERATIONS):
            # Sample indices with replacement
            indices = np.random.choice(n_samples, n_samples, replace=True)
            # Create bootstrap sample of true labels
            boot_true = y_true[indices]
            # Create bootstrap sample of predicted labels
            boot_pred = y_pred[indices]
            # Calculate accuracy for this bootstrap sample
            accuracy = np.mean(boot_true == boot_pred)
            # Store accuracy
            accuracies.append(accuracy)
        
        # Calculate alpha for the confidence interval (e.g., 0.025 for 95% CI)
        alpha = (1 - Tune.CONFIDENCE_LEVEL) / 2
        # Calculate lower percentile boundary
        lower = np.percentile(accuracies, alpha * 100)
        # Calculate upper percentile boundary
        upper = np.percentile(accuracies, (1 - alpha) * 100)
        
        # Return dictionary with results
        return {
            'bootstrap_ci_lower': float(lower),
            'bootstrap_ci_upper': float(upper),
            'bootstrap_mean': float(np.mean(accuracies)),
            'bootstrap_std': float(np.std(accuracies))
        }
    
    @staticmethod
    def calculate_research_metrics(y_true: np.ndarray, 
                                 y_pred: np.ndarray, 
                                 accuracy: float) -> Dict[str, Any]:
        """Calculate comprehensive research metrics"""
        # Total number of samples
        n = len(y_true)
        # Calculate classical standard error of the mean
        se_classical = np.sqrt(accuracy * (1 - accuracy) / n)
        # Calculate margin of error for 95% CI (1.96 z-score)
        ci_95_classical = 1.96 * se_classical
        
        # Identify unique classes in the data
        unique_classes = np.unique(y_true)
        # Dictionary to store metrics per class
        class_metrics = {}
        
        # Iterate over each class
        for cls in unique_classes:
            # Create boolean mask for this class
            mask = (y_true == cls)
            # Proceed if there are samples for this class
            if np.sum(mask) > 0:
                # Calculate class-specific accuracy
                class_acc = np.mean(y_pred[mask] == y_true[mask])
                
                # Calculate precision
                true_positives = np.sum((y_pred == cls) & (y_true == cls))
                predicted_positives = np.sum(y_pred == cls)
                class_precision = true_positives / max(1, predicted_positives)
                
                # Calculate recall
                actual_positives = np.sum(y_true == cls)
                class_recall = true_positives / max(1, actual_positives)
                
                # Calculate F1-score
                if class_precision + class_recall > 0:
                    class_f1 = 2 * (class_precision * class_recall) / (class_precision + class_recall)
                else:
                    class_f1 = 0.0
                
                # Store metrics for this class
                class_metrics[int(cls)] = {
                    'accuracy': float(class_acc),
                    'precision': float(class_precision),
                    'recall': float(class_recall),
                    'f1_score': float(class_f1),
                    'support': int(np.sum(mask))
                }
        
        # Return all calculated metrics
        return {
            'accuracy': float(accuracy),
            'standard_error': float(se_classical),
            'ci_95_classical_lower': max(0.0, float(accuracy - ci_95_classical)),
            'ci_95_classical_upper': min(1.0, float(accuracy + ci_95_classical)),
            'class_metrics': class_metrics,
            'min_class_accuracy': float(min([m['accuracy'] for m in class_metrics.values()] 
                                          if class_metrics else [0]))
        }


class TestTimeAugmentation:
    """Test-Time Augmentation implementation"""
    
    @staticmethod
    def augment_batch(x_batch: np.ndarray) -> np.ndarray:
        """Apply geometric augmentations to batch"""
        # Create a copy of the batch to avoid modifying original data
        x_aug = x_batch.copy()
        
        # Random horizontal flip
        if np.random.random() > 0.5:
            # Flip along width axis (axis 2)
            x_aug = np.flip(x_aug, axis=2)
        
        # Random rotation (90, 180, 270 degrees)
        rotation = np.random.choice([0, 1, 2, 3])
        if rotation > 0:
            # Rotate k times covering 90, 180, 270 degrees
            x_aug = np.rot90(x_aug, k=rotation, axes=(1, 2))
        
        # Return augmented batch
        return x_aug
    
    @staticmethod
    def predict_with_tta(model: tf.keras.Model, 
                        generator: Any) -> Tuple[np.ndarray, np.ndarray]:
        """Predict with test-time augmentation"""
        print(f"\nPerforming Test-Time Augmentation (n={Tune.TTA_SAMPLES})...")
        
        # Lists to store aggregated predictions and true labels
        all_predictions = []
        all_true_labels = []
        
        # Reset generator to start if possible
        if hasattr(generator, 'on_epoch_end'):
            generator.on_epoch_end()
        
        # Iterate over all batches in the generator
        for batch_idx in range(len(generator)):
            # Get data for current batch
            x_batch, y_batch = generator[batch_idx]
            # List to store predictions for this batch (original + TTA versions)
            batch_predictions = []
            
            # Original prediction (no augmentation)
            pred = model.predict(x_batch, verbose=0)
            batch_predictions.append(pred)
            
            # Augmented predictions
            for _ in range(Tune.TTA_SAMPLES - 1):
                if Tune.TTA_GEOMETRIC_ONLY:
                    # Apply geometric augmentations
                    x_aug = TestTimeAugmentation.augment_batch(x_batch)
                else:
                    # Placeholder for other augmentations if needed
                    x_aug = x_batch.copy()
                
                # Predict on augmented batch
                pred_aug = model.predict(x_aug, verbose=0)
                # Store prediction
                batch_predictions.append(pred_aug)
            
            # Average predictions across TTA samples (Geometric Mean is often better for probabilities)
            batch_predictions = np.array(batch_predictions)
            # Calculate geometric mean: exp(mean(log(p)))
            # Clip predictions to avoid log(0)
            avg_pred = np.exp(np.mean(np.log(np.clip(batch_predictions, 1e-10, 1.0)), axis=0))
            # Normalize probabilities to sum to 1
            avg_pred = avg_pred / np.sum(avg_pred, axis=1, keepdims=True)
            
            # Extend lists with results for this batch
            all_predictions.extend(avg_pred)
            all_true_labels.extend(np.argmax(y_batch, axis=1))
        
        # Return numpy arrays of predictions and true labels
        return np.array(all_predictions), np.array(all_true_labels)


class ModelBuilder:
    """Handles model building and architecture"""
    
    @staticmethod
    def build_model(num_classes: int) -> Tuple[tf.keras.Model, tf.keras.Model]:
        """Build MobileNetV3-Small model with custom head"""
        # Print header
        print("\n" + "=" * 80)
        print(f"BUILDING MODEL: {Tune.EXPERIMENT_NAME}")
        print("=" * 80)
        
        # Log basic model configuration
        print(f"Classes: {num_classes}")
        print(f"Backbone: {Tune.BACKBONE} (alpha={Tune.ALPHA})")
        print(f"Input range: {Tune.INPUT_RANGE}")
        print(f"Label Smoothing: {Tune.LABEL_SMOOTHING}")
        print(f"Fine-tune Percent: {Tune.UNFREEZE_PERCENT*100:.0f}%")
        
        # Load pre-trained MobileNetV3-Small backbone
        base_model = MobileNetV3Small(
            input_shape=Tune.INPUT_SHAPE,  # Defined input shape
            include_top=False,  # Exclude the final classification layer
            weights='imagenet',  # Initialize with ImageNet weights
            pooling=Tune.POOLING,  # Global pooling strategy
            include_preprocessing=Tune.INCLUDE_PREPROCESSING,  # Whether to include builtin preprocessing
            alpha=Tune.ALPHA,  # Width multiplier
            minimalistic=Tune.MINIMALISTIC  # Use minimalistic version
        )
        # Freeze the backbone initially (for Feature Extraction stage)
        base_model.trainable = False
        
        # Build model with custom head using Functional API
        inputs = layers.Input(shape=Tune.INPUT_SHAPE)
        # Pass input through base model
        # internal training=False ensures BatchNormalization layers stay in inference mode
        x = base_model(inputs, training=False)
        
        # Stability features
        # Add Gaussian noise for robustness
        x = layers.GaussianNoise(Tune.GAUSSIAN_NOISE)(x)
        # Add dropout regularization
        x = layers.Dropout(Tune.DROPOUT_MAIN)(x)
        
        # Custom classification head - Layer 1
        x = layers.Dense(
            Tune.DENSE_UNITS_1,
            activation='relu',
            kernel_regularizer=regularizers.l2(Tune.L2_REGULARIZATION),
            kernel_initializer='he_normal'
        )(x)
        # Batch normalization for faster convergence
        x = layers.BatchNormalization()(x)
        # Dropout for regularization
        x = layers.Dropout(Tune.DROPOUT_HEAD_1)(x)
        
        # Custom classification head - Layer 2
        x = layers.Dense(
            Tune.DENSE_UNITS_2,
            activation='relu',
            kernel_regularizer=regularizers.l2(Tune.L2_REGULARIZATION)
        )(x)
        # Batch normalization
        x = layers.BatchNormalization()(x)
        # Dropout
        x = layers.Dropout(Tune.DROPOUT_HEAD_2)(x)
        
        # Final output layer with Softmax activation for multiclass classification
        outputs = layers.Dense(num_classes, activation='softmax',
                             kernel_initializer='glorot_uniform')(x)
        
        # Compile model
        model = models.Model(inputs=inputs, outputs=outputs)
        
        # Return compiled model and base model reference
        return model, base_model


class TrainingManager:
    """Manages the training process"""
    
    @staticmethod
    def calculate_class_weights(train_seq: KerasSequenceWrapper) -> Optional[Dict[int, float]]:
        """Calculate class weights from training data details"""
        print("\nCalculating class weights...")
        
        # Get number of classes
        num_classes = len(train_seq.generator.classes)
        # Initialize counts array
        class_counts = np.zeros(num_classes)
        
        # Iterate over all training batches to count samples per class
        for i in range(len(train_seq)):
            _, y_batch = train_seq[i]
            # Sum one-hot encoded labels to get counts for this batch
            batch_counts = np.sum(y_batch, axis=0)
            # Accumulate counts
            class_counts += batch_counts
        
        # Total number of samples
        total = np.sum(class_counts)
        # Dictionary to store weights
        class_weights = {}
        
        # Calculate weight for each class
        # Formula: w_j = n_total / (n_classes * n_j)
        for i, count in enumerate(class_counts):
            if count > 0:
                class_weights[i] = total / (num_classes * count)
            else:
                class_weights[i] = 1.0  # Default to 1 if no samples (shouldn't happen)
        
        # Print class distribution and weights
        print(f"Class Distribution:")
        for i, class_name in enumerate(train_seq.generator.classes):
            print(f"  {class_name}: {int(class_counts[i])} samples (weight: {class_weights[i]:.2f})")
        
        # Check if dataset is balanced
        if np.allclose(list(class_weights.values()), 1.0, atol=0.1):
            print("\nDataset is balanced. Class weights ≈ 1.0")
        
        # Return weights if enabled in config
        return class_weights if Tune.USE_CLASS_WEIGHTS else None
    
    @staticmethod
    def create_callbacks(stage: int) -> List[tf.keras.callbacks.Callback]:
        """Create callbacks for training stage"""
        # Define paths and settings based on stage
        if stage == 1:
            checkpoint_path = os.path.join(Tune.MODELS_DIR, f"stage1_{Tune.TIMESTAMP}.keras")
            log_path = os.path.join(Tune.LOGS_DIR, f"stage1_{Tune.TIMESTAMP}.csv")
            patience = Tune.PATIENCE_STAGE1
        else:
            checkpoint_path = os.path.join(Tune.MODELS_DIR, f"stage2_{Tune.TIMESTAMP}.keras")
            log_path = os.path.join(Tune.LOGS_DIR, f"stage2_{Tune.TIMESTAMP}.csv")
            patience = Tune.PATIENCE_STAGE2
        
        # Common callbacks
        callbacks = [
            # Save best model based on validation accuracy
            ModelCheckpoint(
                checkpoint_path,
                monitor='val_accuracy',
                save_best_only=True,
                mode='max',
                verbose=1
            ),
            # Stop early if no improvement
            EarlyStopping(
                monitor='val_accuracy',
                patience=patience,
                restore_best_weights=True,
                min_delta=Tune.MIN_DELTA,
                mode='max',
                verbose=1
            ),
            # Log training metrics to CSV
            CSVLogger(log_path)
        ]
        
        # Add Learning Rate reduction for Stage 1
        if stage == 1:
            callbacks.append(
                ReduceLROnPlateau(
                    monitor='val_accuracy',
                    factor=0.5,
                    patience=3,
                    min_lr=1e-7,
                    mode ='max',
                    verbose=1
                )
            )
        
        return callbacks
    
    @staticmethod
    def unfreeze_layers(base_model: tf.keras.Model) -> int:
        """Unfreeze specified percentage of layers for fine-tuning"""
        # Get total number of layers in backbone
        total_layers = len(base_model.layers)
        # Calculate index to unfreeze from
        unfreeze_from = int(total_layers * (1 - Tune.UNFREEZE_PERCENT))
        
        # Iterate and set trainability
        for i, layer in enumerate(base_model.layers):
            layer.trainable = (i >= unfreeze_from)
        
        # Count trainable layers
        trainable_count = sum(1 for layer in base_model.layers if layer.trainable)
        print(f"Unfroze last {trainable_count} layers ({Tune.UNFREEZE_PERCENT*100:.0f}% of network)")
        
        return trainable_count


class VisualizationManager:
    """Handles all visualization tasks"""
    
    @staticmethod
    def plot_training_history(history1: tf.keras.callbacks.History,
                            history2: tf.keras.callbacks.History,
                            accuracy: float) -> str:
        """Plot training and validation accuracy/loss across both stages"""
        
        def combine_histories(h1, h2):
            """Combines history dictionaries from two training stages"""
            combined = {}
            for key in h1.history.keys():
                if key in h2.history:
                    combined[key] = h1.history[key] + h2.history[key]
            return combined
        
        # Combine histories
        combined_history = combine_histories(history1, history2)
        
        # Plot accuracy
        plt.figure(figsize=(10, 6))
        # Create x-axis range (epochs)
        epochs = range(1, len(combined_history['accuracy']) + 1)
        # Plot training accuracy
        plt.plot(epochs, combined_history['accuracy'], 'b-', label='Training', linewidth=2)
        # Plot validation accuracy
        plt.plot(epochs, combined_history['val_accuracy'], 'r-', label='Validation', linewidth=2)
        # Add horizontal line for final test accuracy
        plt.axhline(y=accuracy, color='g', linestyle='--', alpha=0.7, 
                   label=f'Test (TTA): {accuracy:.3f}')
        
        # Styling
        plt.title('Training and Validation Accuracy', fontsize=14, fontweight='bold')
        plt.xlabel('Epoch', fontsize=12)
        plt.ylabel('Accuracy', fontsize=12)
        plt.legend(loc='lower right')
        plt.grid(True, alpha=0.3)
        plt.ylim(0.4, 1.05)
        plt.tight_layout()
        
        # Save accuracy plot
        accuracy_plot_path = os.path.join(Tune.PLOTS_DIR, f"accuracy_plot_{Tune.TIMESTAMP}.png")
        plt.savefig(accuracy_plot_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        # Plot loss
        plt.figure(figsize=(10, 6))
        plt.plot(epochs, combined_history['loss'], 'b-', label='Training', linewidth=2)
        plt.plot(epochs, combined_history['val_loss'], 'r-', label='Validation', linewidth=2)
        plt.title('Training and Validation Loss', fontsize=14, fontweight='bold')
        plt.xlabel('Epoch', fontsize=12)
        plt.ylabel('Loss', fontsize=12)
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        # Save loss plot
        loss_plot_path = os.path.join(Tune.PLOTS_DIR, f"loss_plot_{Tune.TIMESTAMP}.png")
        plt.savefig(loss_plot_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        # Return paths to saved plots
        return accuracy_plot_path, loss_plot_path
    
    @staticmethod
    def plot_confusion_matrix(cm: np.ndarray, class_names: List[str]) -> str:
        """Plot confusion matrix heatmap"""
        plt.figure(figsize=(10, 8))
        # Create heatmap using Seaborn
        sns.heatmap(cm, annot=True, fmt='d', cmap='YlOrRd',
                   xticklabels=class_names, yticklabels=class_names,
                   cbar_kws={'label': 'Count'})
        
        # Styling
        plt.title('Confusion Matrix Heatmap', fontsize=14, fontweight='bold')
        plt.xlabel('Predicted', fontsize=12)
        plt.ylabel('True', fontsize=12)
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        
        # Save plot
        cm_plot_path = os.path.join(Tune.PLOTS_DIR, f"confusion_matrix_{Tune.TIMESTAMP}.png")
        plt.savefig(cm_plot_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        return cm_plot_path
    
    @staticmethod
    def plot_confidence_intervals(accuracy: float,
                                stats: Dict[str, Any],
                                bootstrap_results: Dict[str, float]) -> str:
        """Plot comparison of Classical vs Bootstrap Confidence Intervals"""
        plt.figure(figsize=(8, 6))
        # Define method names
        methods = [f'Classical {Tune.CONFIDENCE_LEVEL*100:.0f}% CI',
                  f'Bootstrap {Tune.CONFIDENCE_LEVEL*100:.0f}% CI']
        
        # Get values
        classical_lower = stats['ci_95_classical_lower']
        classical_upper = stats['ci_95_classical_upper']
        bootstrap_lower = bootstrap_results['bootstrap_ci_lower']
        bootstrap_upper = bootstrap_results['bootstrap_ci_upper']
        
        # Plot error bars
        plt.errorbar(1, accuracy,
                    yerr=[[accuracy - classical_lower], [classical_upper - accuracy]],
                    fmt='o', capsize=10, markersize=10, color='blue', label='Classical')
        plt.errorbar(2, bootstrap_results['bootstrap_mean'],
                    yerr=[[bootstrap_results['bootstrap_mean'] - bootstrap_lower],
                         [bootstrap_upper - bootstrap_results['bootstrap_mean']]],
                    fmt='s', capsize=10, markersize=10, color='red', label='Bootstrap')
        
        # Styling
        y_min = min(classical_lower, bootstrap_lower) - 0.02
        y_max = max(classical_upper, bootstrap_upper) + 0.02
        plt.xlim(0.5, 2.5)
        plt.ylim(y_min, y_max)
        plt.xticks([1, 2], methods)
        plt.title('Accuracy Confidence Intervals Comparison', fontsize=14, fontweight='bold')
        plt.ylabel('Accuracy', fontsize=12)
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        # Save plot
        ci_plot_path = os.path.join(Tune.PLOTS_DIR, f"confidence_intervals_{Tune.TIMESTAMP}.png")
        plt.savefig(ci_plot_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        return ci_plot_path
    
    @staticmethod
    def plot_class_accuracies(stats: Dict[str, Any], class_names: List[str]) -> str:
        """Plot bar chart of accuracy per class"""
        plt.figure(figsize=(10, 6))
        # Extract accuracies
        class_accuracies = [stats['class_metrics'][i]['accuracy'] for i in range(len(class_names))]
        # Generate colors
        colors = plt.cm.Set3(np.linspace(0, 1, len(class_names)))
        
        # Create bar chart
        bars = plt.bar(range(len(class_names)), class_accuracies, color=colors)
        
        # Styling
        plt.title('Per-Class Accuracy', fontsize=14, fontweight='bold')
        plt.xlabel('Class', fontsize=12)
        plt.ylabel('Accuracy', fontsize=12)
        plt.xticks(range(len(class_names)), class_names, rotation=45, ha='right')
        y_min_acc = max(0.4, min(class_accuracies) * 0.95)
        plt.ylim(y_min_acc, 1.05)
        plt.grid(True, alpha=0.3, axis='y')
        
        # Add value labels on bars
        for bar, acc in zip(bars, class_accuracies):
            height = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2., height + 0.005,
                    f'{acc:.3f}', ha='center', va='bottom', fontsize=10, fontweight='bold')
        
        # Save plot
        plt.tight_layout()
        class_acc_plot_path = os.path.join(Tune.PLOTS_DIR, f"class_accuracy_{Tune.TIMESTAMP}.png")
        plt.savefig(class_acc_plot_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        return class_acc_plot_path
    
    @staticmethod
    def plot_roc_curves(y_true: np.ndarray,
                       y_pred_probs: np.ndarray,
                       class_names: List[str],
                       num_classes: int) -> Dict[str, Any]:
        """Generate ROC curve analysis and plots"""
        print("\nGenerating ROC Curve Analysis...")
        
        # Initialize dictionaries for TPR, FPR, and AUC
        fpr = dict()
        tpr = dict()
        roc_auc = dict()
        
        # Convert true labels to one-hot encoding
        y_true_onehot = np.eye(num_classes)[y_true]
        
        # Calculate ROC coordinates for each class
        for i in range(num_classes):
            fpr[i], tpr[i], _ = roc_curve(y_true_onehot[:, i], y_pred_probs[:, i])
            roc_auc[i] = auc(fpr[i], tpr[i])
        
        # Plot 1: Individual ROC curves for each class
        plt.figure(figsize=(10, 8))
        colors = plt.cm.Set3(np.linspace(0, 1, num_classes))
        
        for i, class_name in enumerate(class_names):
            plt.plot(fpr[i], tpr[i], color=colors[i], lw=2,
                    label=f'{class_name} (AUC = {roc_auc[i]:.3f})')
        
        # Add diagonal reference line (random guess)
        plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Random (AUC = 0.50)')
        
        # Styling
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate', fontsize=12)
        plt.ylabel('True Positive Rate', fontsize=12)
        plt.title('ROC Curves (One-vs-Rest)', fontsize=14, fontweight='bold')
        plt.legend(loc="lower right", fontsize=10)
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        # Save individual ROC plot
        roc_individual_path = os.path.join(Tune.PLOTS_DIR, f"roc_individual_{Tune.TIMESTAMP}.png")
        plt.savefig(roc_individual_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        # Plot 2: Micro and Macro average ROC curves
        plt.figure(figsize=(10, 8))
        
        # Calculate Micro-average (aggregating all predictions)
        fpr_micro, tpr_micro, _ = roc_curve(y_true_onehot.ravel(), y_pred_probs.ravel())
        roc_auc_micro = auc(fpr_micro, tpr_micro)
        
        # Plot Micro-average
        plt.plot(fpr_micro, tpr_micro, color='darkorange', lw=3,
                label=f'Micro-average (AUC = {roc_auc_micro:.3f})')
        
        # Calculate Macro-average (averaging across classes)
        # First, aggregate all false positive rates
        all_fpr = np.unique(np.concatenate([fpr[i] for i in range(num_classes)]))
        # Then interpolate all ROC curves at this points
        mean_tpr = np.zeros_like(all_fpr)
        for i in range(num_classes):
            mean_tpr += np.interp(all_fpr, fpr[i], tpr[i])
        # Average it and compute AUC
        mean_tpr /= num_classes
        fpr_macro = all_fpr
        tpr_macro = mean_tpr
        roc_auc_macro = auc(fpr_macro, tpr_macro)
        
        # Plot Macro-average
        plt.plot(fpr_macro, tpr_macro, color='navy', lw=3, linestyle=':',
                label=f'Macro-average (AUC = {roc_auc_macro:.3f})')
        
        # Add diagonal reference line
        plt.plot([0, 1], [0, 1], 'k--', lw=2, label='Random')
        
        # Styling
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate', fontsize=12)
        plt.ylabel('True Positive Rate', fontsize=12)
        plt.title('Micro and Macro Average ROC Curves', fontsize=14, fontweight='bold')
        plt.legend(loc="lower right", fontsize=10)
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        
        # Save average ROC plot
        roc_average_path = os.path.join(Tune.PLOTS_DIR, f"roc_average_{Tune.TIMESTAMP}.png")
        plt.savefig(roc_average_path, dpi=Tune.PLOT_DPI, bbox_inches='tight')
        plt.close()
        
        # Print summary
        print(f"ROC curve plots saved:")
        print(f"  - Individual classes: {roc_individual_path}")
        print(f"  - Micro/Macro average: {roc_average_path}")
        
        # Create AUC summary dictionary
        auc_summary = {
            'individual_auc': {class_names[i]: float(roc_auc[i]) for i in range(num_classes)},
            'micro_auc': float(roc_auc_micro),
            'macro_auc': float(roc_auc_macro),
            'mean_auc': float(np.mean([roc_auc[i] for i in range(num_classes)]))
        }
        
        # Print detailed AUC stats
        print("\nAUC SUMMARY:")
        for class_name, auc_value in auc_summary['individual_auc'].items():
            print(f"  {class_name}: {auc_value:.4f}")
        print(f"  Micro-average AUC: {auc_summary['micro_auc']:.4f}")
        print(f"  Macro-average AUC: {auc_summary['macro_auc']:.4f}")
        print(f"  Mean AUC: {auc_summary['mean_auc']:.4f}")
        
        # Return paths and results
        return {
            'individual': roc_individual_path,
            'average': roc_average_path,
            'summary': auc_summary
        }


class ReportGenerator:
    """Generates comprehensive research reports"""
    
    @staticmethod
    def generate_json_report(model: tf.keras.Model,
                           accuracy: float,
                           stats: Dict[str, Any],
                           bootstrap_results: Dict[str, float],
                           y_true: np.ndarray,
                           y_pred: np.ndarray,
                           class_names: List[str],
                           plot_paths: Dict[str, str],
                           roc_results: Dict[str, Any]) -> str:
        """Generate structured JSON research report"""
        
        # Construct the report dictionary
        json_report = {
            'experiment_id': Tune.TIMESTAMP,
            'experiment_name': Tune.EXPERIMENT_NAME,
            'model': Tune.BACKBONE,
            'task': f'{len(class_names)}-class tea leaf maturity classification',
            'tuning_configuration': {
                'include_preprocessing': Tune.INCLUDE_PREPROCESSING,
                'input_range': Tune.INPUT_RANGE,
                'preprocessing_formula': Tune.PREPROCESS_FORMULA,
                'alpha': Tune.ALPHA,
                'dense_units_1': Tune.DENSE_UNITS_1,
                'dense_units_2': Tune.DENSE_UNITS_2,
                'label_smoothing': Tune.LABEL_SMOOTHING,
                'fine_tune_percent': Tune.UNFREEZE_PERCENT * 100,
                'learning_rate_stage1': Tune.LEARNING_RATE_STAGE1,
                'learning_rate_stage2': Tune.LEARNING_RATE_STAGE2,
                'batch_size': Tune.BATCH_SIZE,
                'tta_enabled': Tune.TTA_ENABLED,
                'tta_samples': Tune.TTA_SAMPLES
            },
            'results': {
                'tta_accuracy': float(accuracy),
                'standard_accuracy': float(stats['accuracy']),
                'standard_error': float(stats['standard_error']),
                'classical_ci': {
                    'lower': float(stats['ci_95_classical_lower']),
                    'upper': float(stats['ci_95_classical_upper'])
                },
                'bootstrap_ci': {
                    'lower': float(bootstrap_results['bootstrap_ci_lower']),
                    'upper': float(bootstrap_results['bootstrap_ci_upper'])
                },
                'bootstrap_mean': float(bootstrap_results['bootstrap_mean']),
                'min_class_accuracy': float(stats['min_class_accuracy'])
            },
            'auc_results': roc_results['summary'],
            'class_performance': {},
            'stability_config': {
                'label_smoothing': Tune.LABEL_SMOOTHING,
                'gradient_clip_norm': Tune.GRADIENT_CLIP_NORM,
                'dropout_main': Tune.DROPOUT_MAIN,
                'dropout_head_1': Tune.DROPOUT_HEAD_1,
                'dropout_head_2': Tune.DROPOUT_HEAD_2,
                'l2_regularization': Tune.L2_REGULARIZATION,
                'gaussian_noise': Tune.GAUSSIAN_NOISE
            },
            'plot_paths': plot_paths
        }
        
        # Add class-specific metrics
        for i, class_name in enumerate(class_names):
            json_report['class_performance'][class_name] = {
                'accuracy': float(stats['class_metrics'][i]['accuracy']),
                'precision': float(stats['class_metrics'][i]['precision']),
                'recall': float(stats['class_metrics'][i]['recall']),
                'f1_score': float(stats['class_metrics'][i]['f1_score']),
                'support': int(stats['class_metrics'][i]['support']),
                'auc': float(roc_results['summary']['individual_auc'][class_name])
            }
        
        # Save JSON report to file
        json_path = os.path.join(Tune.RESULTS_DIR, f"research_report_{Tune.TIMESTAMP}.json")
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(json_report, f, indent=2, ensure_ascii=False)
        
        return json_path
    
    @staticmethod
    def generate_text_report(accuracy: float,
                           stats: Dict[str, Any],
                           bootstrap_results: Dict[str, float],
                           class_names: List[str],
                           roc_results: Dict[str, Any],
                           plot_paths: Dict[str, str]) -> str:
        """Generate human-readable text research report"""
        
        # Define path
        txt_path = os.path.join(Tune.RESULTS_DIR, f"research_report_{Tune.TIMESTAMP}.txt")
        
        # Write report content
        with open(txt_path, 'w', encoding='utf-8') as f:
            # Header
            f.write("="*80 + "\n")
            f.write(f"FINAL RESEARCH REPORT: {Tune.EXPERIMENT_NAME}\n")
            f.write("="*80 + "\n\n")
            
            # Experiment Details
            f.write(f"EXPERIMENT ID: {Tune.TIMESTAMP}\n")
            f.write(f"MODEL: {Tune.BACKBONE} with research-grade enhancements\n")
            f.write(f"PREPROCESSING: Manual {Tune.INPUT_RANGE} scaling {Tune.PREPROCESS_FORMULA}\n")
            f.write(f"CONFIGURATION: include_preprocessing={Tune.INCLUDE_PREPROCESSING}\n\n")
            
            # Hyperparameters
            f.write("TUNING DECK CONFIGURATION:\n")
            f.write(f"  - Learning Rate Stage 1: {Tune.LEARNING_RATE_STAGE1}\n")
            f.write(f"  - Learning Rate Stage 2: {Tune.LEARNING_RATE_STAGE2}\n")
            f.write(f"  - Fine-tune Percent: {Tune.UNFREEZE_PERCENT*100:.0f}%\n")
            f.write(f"  - Label Smoothing: {Tune.LABEL_SMOOTHING}\n")
            f.write(f"  - Batch Size: {Tune.BATCH_SIZE}\n")
            f.write(f"  - TTA Enabled: {Tune.TTA_ENABLED}\n")
            f.write(f"  - TTA Samples: {Tune.TTA_SAMPLES}\n\n")
            
            # Overall Results
            f.write("RESULTS:\n")
            f.write(f"  Test Accuracy (TTA): {accuracy:.4f}\n")
            f.write(f"  Bootstrap {Tune.CONFIDENCE_LEVEL*100:.0f}% CI: [{bootstrap_results['bootstrap_ci_lower']:.4f}, "
                   f"{bootstrap_results['bootstrap_ci_upper']:.4f}]\n")
            f.write(f"  Micro-average AUC: {roc_results['summary']['micro_auc']:.4f}\n")
            f.write(f"  Macro-average AUC: {roc_results['summary']['macro_auc']:.4f}\n")
            f.write(f"  Mean Class AUC: {roc_results['summary']['mean_auc']:.4f}\n\n")
            
            # Per-Class Results
            f.write("CLASS PERFORMANCE:\n")
            for i, class_name in enumerate(class_names):
                metrics = stats['class_metrics'][i]
                f.write(f"  {class_name}:\n")
                f.write(f"    - Accuracy: {metrics['accuracy']:.4f}\n")
                f.write(f"    - AUC: {roc_results['summary']['individual_auc'][class_name]:.4f}\n")
                f.write(f"    - Precision: {metrics['precision']:.4f}\n")
                f.write(f"    - Recall: {metrics['recall']:.4f}\n")
                f.write(f"    - F1-Score: {metrics['f1_score']:.4f}\n")
                f.write(f"    - Support: {metrics['support']} samples\n\n")
            
            # Visualization Paths
            f.write("\nVISUALIZATIONS:\n")
            for plot_name, plot_path in plot_paths.items():
                f.write(f"  {plot_name.replace('_', ' ').title()}: {plot_path}\n")
        
        return txt_path


# ============================================================================
# MAIN PIPELINE
# ============================================================================
def train_with_validation():
    """Main training pipeline executing both stages"""
    print("\n" + "=" * 80)
    print("DATASET LOADING AND VALIDATION")
    print("=" * 80)
    
    # Load data generators
    train_gen, val_gen = get_generators()
    test_gen = get_test_generator()
    
    # Extract class information
    class_names = train_gen.classes
    num_classes = len(class_names)
    
    # Print dataset statistics
    print(f"DATASET STATISTICS:")
    print(f"  Training samples: {train_gen.n}")
    print(f"  Validation samples: {val_gen.n}")
    print(f"  Test samples: {test_gen.n}")
    print(f"  Classes: {class_names}")
    
    # Build the model
    model, base_model = ModelBuilder.build_model(num_classes)
    
    # Wrap generators for Keras compatibility
    train_seq = KerasSequenceWrapper(train_gen)
    val_seq = KerasSequenceWrapper(val_gen)
    
    # Calculate class weights if enabled
    class_weights = TrainingManager.calculate_class_weights(train_seq) if Tune.USE_CLASS_WEIGHTS else None
    
    # ========================================================================
    # STAGE 1: FEATURE EXTRACTION
    # ========================================================================
    print("\nStage 1: Feature Extraction")
    
    # Compile model for stage 1 (base model is frozen)
    model.compile(
        optimizer=tf.keras.optimizers.Adam(
            learning_rate=Tune.LEARNING_RATE_STAGE1,
            clipnorm=Tune.GRADIENT_CLIP_NORM
        ),
        loss=CategoricalCrossentropy(label_smoothing=Tune.LABEL_SMOOTHING),
        metrics=['accuracy']
    )
    
    # Create callbacks for stage 1
    stage1_callbacks = TrainingManager.create_callbacks(stage=1)
    
    # Train
    history1 = model.fit(
        train_seq,
        validation_data=val_seq,
        epochs=Tune.EPOCHS_STAGE1,
        callbacks=stage1_callbacks,
        class_weight=class_weights,
        verbose=1
    )
    
    # ========================================================================
    # STAGE 2: FINE-TUNING
    # ========================================================================
    print("\n" + "=" * 80)
    print("STAGE 2: FINE-TUNING")
    print("=" * 80)
    
    # Unfreeze part of the backbone
    TrainingManager.unfreeze_layers(base_model)
    
    # Recompile model with lower learning rate for fine-tuning
    model.compile(
        optimizer=tf.keras.optimizers.Adam(
            learning_rate=Tune.LEARNING_RATE_STAGE2,
            clipnorm=Tune.GRADIENT_CLIP_NORM
        ),
        loss=CategoricalCrossentropy(label_smoothing=Tune.LABEL_SMOOTHING),
        metrics=['accuracy']
    )
    
    # Create callbacks for stage 2
    stage2_callbacks = TrainingManager.create_callbacks(stage=2)
    
    # Continue training (fine-tuning)
    print("Fine-tuning with adjusted settings...")
    history2 = model.fit(
        train_seq,
        validation_data=val_seq,
        epochs=Tune.EPOCHS_STAGE2,
        callbacks=stage2_callbacks,
        class_weight=class_weights,
        verbose=1
    )
    
    # Return trained model and artifacts
    return model, test_gen, class_names, history1, history2, num_classes


def evaluate_with_tta(model: tf.keras.Model, 
                     test_gen: Any, 
                     class_names: List[str], 
                     num_classes: int) -> Tuple[Any, ...]:
    """Comprehensive evaluation using Test-Time Augmentation"""
    print("\n" + "=" * 80)
    print("COMPREHENSIVE MODEL EVALUATION")
    print("=" * 80)
    
    # Determine best checkpoint path
    best_model_path = os.path.join(Tune.MODELS_DIR, f"stage2_{Tune.TIMESTAMP}.keras")
    if not os.path.exists(best_model_path):
        best_model_path = os.path.join(Tune.MODELS_DIR, f"stage1_{Tune.TIMESTAMP}.keras")
    
    # Load best model weights
    print(f"Loading best model: {os.path.basename(best_model_path)}")
    model = tf.keras.models.load_model(best_model_path)
    
    # Standard evaluation (without TTA)
    print("\nSTANDARD EVALUATION:")
    test_seq = KerasSequenceWrapper(test_gen)
    test_results = model.evaluate(test_seq, verbose=1)
    test_loss, test_accuracy = test_results[0], test_results[1]
    
    # TTA evaluation
    if Tune.TTA_ENABLED:
        # Perform prediction with TTA
        y_pred_probs_tta, y_true_tta = TestTimeAugmentation.predict_with_tta(model, test_gen)
        # Convert probabilities to class labels
        y_pred_tta = np.argmax(y_pred_probs_tta, axis=1)
        # Calculate accuracy
        tta_accuracy = np.mean(y_pred_tta == y_true_tta)
    else:
        # Predict without TTA if disabled
        y_true_tta, y_pred_tta = [], []
        for x_batch, y_batch in test_seq:
            pred = model.predict(x_batch, verbose=0)
            y_pred_tta.extend(np.argmax(pred, axis=1))
            y_true_tta.extend(np.argmax(y_batch, axis=1))
        y_true_tta, y_pred_tta = np.array(y_true_tta), np.array(y_pred_tta)
        y_pred_probs_tta = None
        tta_accuracy = np.mean(y_pred_tta == y_true_tta)
    
    # Print TTA verification results
    print(f"\nTEST-TIME AUGMENTATION RESULTS:")
    print(f" Standard Accuracy: {test_accuracy:.4f}")
    print(f" TTA Accuracy (n={Tune.TTA_SAMPLES if Tune.TTA_ENABLED else 1}): {tta_accuracy:.4f}")
    print(f" Difference: {abs(test_accuracy - tta_accuracy):.4f}")
    
    # Statistical validation
    validator = StatisticalValidator()
    stats = validator.calculate_research_metrics(y_true_tta, y_pred_tta, tta_accuracy)
    
    # Bootstrap Confidence Interval
    print("\nBOOTSTRAP CONFIDENCE INTERVAL:")
    bootstrap_results = validator.bootstrap_confidence_interval(y_true_tta, y_pred_tta)
    print(f" Bootstrap Mean: {bootstrap_results['bootstrap_mean']:.4f}")
    print(f" Bootstrap {Tune.CONFIDENCE_LEVEL*100:.0f}% CI: [{bootstrap_results['bootstrap_ci_lower']:.4f}, "
          f"{bootstrap_results['bootstrap_ci_upper']:.4f}]")
    
    # Print Classification Report
    print(f"\nCLASSIFICATION REPORT:")
    print(classification_report(y_true_tta, y_pred_tta, target_names=class_names, digits=4))
    
    # Compute Confusion Matrix
    cm = confusion_matrix(y_true_tta, y_pred_tta)
    
    # ROC Curve analysis
    roc_results = VisualizationManager.plot_roc_curves(
        y_true_tta, y_pred_probs_tta, class_names, num_classes
    ) if y_pred_probs_tta is not None else {'summary': {}}
    
    # Return all evaluation artifacts
    return model, tta_accuracy, stats, bootstrap_results, y_true_tta, y_pred_tta, cm, roc_results


def create_visualizations(history1: tf.keras.callbacks.History,
                         history2: tf.keras.callbacks.History,
                         accuracy: float,
                         stats: Dict[str, Any],
                         bootstrap_results: Dict[str, float],
                         cm: np.ndarray,
                         class_names: List[str],
                         roc_results: Dict[str, Any]) -> Tuple[Dict[str, str], Dict[str, Any]]:
    """Generate and save all plots and visualizations"""
    print("\nCreating comprehensive visualizations...")
    
    # Set plotting style
    plt.style.use(Tune.PLOT_STYLE)
    plot_paths = {}
    
    # Plot Training History
    accuracy_path, loss_path = VisualizationManager.plot_training_history(history1, history2, accuracy)
    plot_paths['accuracy'] = accuracy_path
    plot_paths['loss'] = loss_path
    
    # Plot Confusion Matrix
    cm_path = VisualizationManager.plot_confusion_matrix(cm, class_names)
    plot_paths['confusion_matrix'] = cm_path
    
    # Plot Confidence Intervals
    ci_path = VisualizationManager.plot_confidence_intervals(accuracy, stats, bootstrap_results)
    plot_paths['confidence_intervals'] = ci_path
    
    # Plot Class Accuracies
    class_acc_path = VisualizationManager.plot_class_accuracies(stats, class_names)
    plot_paths['class_accuracy'] = class_acc_path
    
    # Add ROC paths to return dictionary
    if 'individual' in roc_results:
        plot_paths['roc_individual'] = roc_results['individual']
        plot_paths['roc_average'] = roc_results['average']
    
    return plot_paths, roc_results


def save_comprehensive_report(model: tf.keras.Model,
                            accuracy: float,
                            stats: Dict[str, Any],
                            bootstrap_results: Dict[str, float],
                            y_true: np.ndarray,
                            y_pred: np.ndarray,
                            class_names: List[str],
                            plot_paths: Dict[str, str],
                            roc_results: Dict[str, Any]) -> Tuple[str, str]:
    """Orchestrate saving of all report files"""
    
    # Generate JSON report
    json_path = ReportGenerator.generate_json_report(
        model, accuracy, stats, bootstrap_results, y_true, y_pred, 
        class_names, plot_paths, roc_results
    )
    
    # Generate Text report
    txt_path = ReportGenerator.generate_text_report(
        accuracy, stats, bootstrap_results, class_names, roc_results, plot_paths
    )
    
    print(f"Research reports saved:")
    print(f"  - JSON: {json_path}")
    print(f"  - Text: {txt_path}")
    
    return txt_path, json_path


# ============================================================================
# MAIN EXECUTION
# ============================================================================
def main():
    """Entry point for the experiment"""
    print("\n" + "=" * 80)
    print(f"{Tune.EXPERIMENT_NAME} - TEA MATURITY CLASSIFICATION")
    print("=" * 80)
    
    # Set random seeds for reproducibility
    np.random.seed(Tune.RANDOM_SEED)
    tf.random.set_seed(Tune.RANDOM_SEED)
    
    try:
        # Step 1: Train model with validation
        model, test_gen, class_names, history1, history2, num_classes = train_with_validation()
        
        # Step 2: Evaluate with Test-Time Augmentation
        model, accuracy, stats, bootstrap_results, y_true, y_pred, cm, roc_results = evaluate_with_tta(
            model, test_gen, class_names, num_classes
        )
        
        # Step 3: Create Visualizations
        plot_paths, roc_results = create_visualizations(
            history1, history2, accuracy, stats, bootstrap_results, cm, class_names, roc_results
        )
        
        # Step 4: Save Final Model
        final_model_path = os.path.join(Tune.MODELS_DIR, f"final_{Tune.TIMESTAMP}.keras")
        model.save(final_model_path)
        
        # Step 5: Save Reports
        save_comprehensive_report(
            model, accuracy, stats, bootstrap_results, y_true, y_pred, 
            class_names, plot_paths, roc_results
        )
        
        # Final Success Summary
        print("\n" + "=" * 80)
        print("EXPERIMENT COMPLETE")
        print("=" * 80)
        print(f"Experiment: {Tune.EXPERIMENT_NAME}")
        print(f"Timestamp: {Tune.TIMESTAMP}")
        print(f"Final TTA Accuracy: {accuracy:.4f}")
        if roc_results.get('summary'):
            print(f"Mean AUC: {roc_results['summary'].get('mean_auc', 0):.4f}")
        print(f"Bootstrap {Tune.CONFIDENCE_LEVEL*100:.0f}% CI: [{bootstrap_results['bootstrap_ci_lower']:.4f}, "
              f"{bootstrap_results['bootstrap_ci_upper']:.4f}]")
        print(f"Final model saved: {final_model_path}")
        print("=" * 80)
        
    except Exception as e:
        # Error handling
        print(f"\nERROR: Training failed!")
        print(f"  Error details: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    # Execute main function if run as script
    main()