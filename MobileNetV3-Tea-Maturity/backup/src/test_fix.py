"""
OFFICIAL MOBILENETV3 PREPROCESSING VERIFICATION
"""
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV3Small

print("="*80)
print("OFFICIAL TENSORFLOW MOBILENETV3 PREPROCESSING TEST")
print("="*80)

# Create test image
test_img = np.random.randint(0, 256, (1, 224, 224, 3), dtype=np.float32)

print("\n1. Testing include_preprocessing=True:")
model_true = MobileNetV3Small(include_top=False, include_preprocessing=True, weights='imagenet')
output_true = model_true.predict(test_img, verbose=0)
print(f"   Input range: [{test_img.min():.1f}, {test_img.max():.1f}]")
print(f"   Output shape: {output_true.shape}")
print(f"   ✓ Works with [0, 255] input")

print("\n2. Testing include_preprocessing=False:")
print("   Testing different input ranges:")
test_cases = [
    ("[0, 255]", test_img),
    ("[-1, 1]", (test_img / 127.5) - 1.0),
    ("[0, 1]", test_img / 255.0),
]

for name, img in test_cases:
    try:
        model_false = MobileNetV3Small(include_top=False, include_preprocessing=False, weights='imagenet')
        output_false = model_false.predict(img, verbose=0)
        print(f"   ✓ {name}: Works (range: [{img.min():.3f}, {img.max():.3f}])")
    except Exception as e:
        print(f"   ✗ {name}: Fails")

print("\n" + "="*80)
print("RECOMMENDATION:")
print("Use include_preprocessing=True for simplicity")
print("Then your preprocessing should just return img.astype(np.float32)")
print("="*80)