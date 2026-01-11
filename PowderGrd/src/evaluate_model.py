"""
Model Evaluation Script
Evaluates the trained model and saves accuracy metrics
"""
import tensorflow as tf
import numpy as np
import json
from datetime import datetime

# Configuration
MODEL_PATH = "best_model.keras"
TEST_DATA_DIR = "../data/final"  # Using final data with 80-20 split for testing
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
CLASS_NAMES = ["BOP", "BOPF", "Dust", "Dust1", "Fanning1", "Pekoe"]

def evaluate_model():
    """Evaluate model and save metrics"""
    print("="*60)
    print("🔍 MODEL EVALUATION")
    print("="*60)
    
    # Load model
    print(f"\n📂 Loading model from: {MODEL_PATH}")
    try:
        model = tf.keras.models.load_model(MODEL_PATH)
        print("✓ Model loaded successfully")
    except Exception as e:
        print(f"✗ Error loading model: {e}")
        return
    
    # Load test/validation data (using 20% validation split)
    print(f"\n📊 Loading test dataset from: {TEST_DATA_DIR}")
    test_ds = tf.keras.utils.image_dataset_from_directory(
        TEST_DATA_DIR,
        labels="inferred",
        label_mode="categorical",
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE
    )
    
    test_ds = test_ds.cache().prefetch(buffer_size=tf.data.AUTOTUNE)
    
    # Evaluate
    print("\n🧪 Evaluating model on test set...")
    results = model.evaluate(test_ds, verbose=1)
    
    test_loss = results[0]
    test_accuracy = results[1]
    
    print("\n" + "="*60)
    print("📈 EVALUATION RESULTS")
    print("="*60)
    print(f"Test Loss: {test_loss:.4f}")
    print(f"Test Accuracy: {test_accuracy*100:.2f}%")
    print("="*60)
    
    # Get detailed predictions for confusion matrix analysis
    print("\n🔬 Generating detailed predictions...")
    
    all_predictions = []
    all_labels = []
    
    for images, labels in test_ds:
        predictions = model.predict(images, verbose=0)
        all_predictions.extend(np.argmax(predictions, axis=1))
        all_labels.extend(np.argmax(labels.numpy(), axis=1))
    
    # Calculate per-class accuracy
    per_class_correct = {i: 0 for i in range(len(CLASS_NAMES))}
    per_class_total = {i: 0 for i in range(len(CLASS_NAMES))}
    
    for true_label, pred_label in zip(all_labels, all_predictions):
        per_class_total[true_label] += 1
        if true_label == pred_label:
            per_class_correct[true_label] += 1
    
    per_class_accuracy = {}
    for i in range(len(CLASS_NAMES)):
        if per_class_total[i] > 0:
            acc = (per_class_correct[i] / per_class_total[i]) * 100
            per_class_accuracy[CLASS_NAMES[i]] = round(acc, 2)
        else:
            per_class_accuracy[CLASS_NAMES[i]] = 0.0
    
    print("\n📊 Per-Class Accuracy:")
    print("-" * 40)
    for grade, acc in per_class_accuracy.items():
        print(f"{grade:12s}: {acc:6.2f}% ({per_class_correct[CLASS_NAMES.index(grade)]}/{per_class_total[CLASS_NAMES.index(grade)]} correct)")
    
    # Save metrics to JSON
    metrics = {
        "evaluation_date": datetime.now().isoformat(),
        "model_path": MODEL_PATH,
        "test_dataset": TEST_DATA_DIR,
        "overall_accuracy": round(test_accuracy * 100, 2),
        "test_loss": round(test_loss, 4),
        "per_class_accuracy": per_class_accuracy,
        "total_samples": len(all_labels),
        "class_distribution": {CLASS_NAMES[i]: per_class_total[i] for i in range(len(CLASS_NAMES))}
    }
    
    output_file = "model_metrics.json"
    with open(output_file, 'w') as f:
        json.dump(metrics, f, indent=2)
    
    print(f"\n💾 Metrics saved to: {output_file}")
    print("="*60 + "\n")
    
    return metrics

if __name__ == "__main__":
    evaluate_model()
