#!/usr/bin/env python3
"""
Tea Leaf Disease Multi-Leaf Analysis Script

Analyzes multiple leaves in an image or folder of images and provides:
- Cumulative disease statistics
- Health assessment report
- Treatment recommendations

Usage:
    python analyze_leaves.py --image field_photo.jpg
    python analyze_leaves.py --folder path/to/images/
    python analyze_leaves.py --image photo.jpg --save-report
"""

import argparse
from pathlib import Path
from datetime import datetime
from collections import defaultdict
import json
import cv2
from ultralytics import YOLO


DISEASE_INFO = {
    'blister_blight': {
        'name': 'Blister Blight',
        'severity': 'HIGH',
        'caused_by': 'Fungus Exobasidium vexans',
        'symptoms': [
            'Small, pinhole-sized spots on young leaves',
            'Circular blister-like lesions',
            'White/cream colored fungal growth on underside',
            'Leaves become distorted and curled'
        ],
        'treatment': [
            'Apply copper-based fungicides (Bordeaux mixture 1%)',
            'Spray Hexaconazole 5% EC @ 2ml/litre of water',
            'Apply Propiconazole 25% EC @ 1ml/litre of water',
            'Remove and destroy severely infected leaves',
            'Ensure proper spacing for air circulation'
        ],
        'prevention': [
            'Avoid overhead irrigation',
            'Maintain proper drainage in tea gardens',
            'Regular pruning to improve air circulation',
            'Apply preventive fungicide sprays during monsoon',
            'Monitor weather conditions (high humidity favors disease)'
        ],
        'spray_interval': '7-10 days during active infection'
    },
    'red_rust': {
        'name': 'Red Rust (Algal Leaf Spot)',
        'severity': 'MEDIUM',
        'caused_by': 'Algae Cephaleuros virescens',
        'symptoms': [
            'Reddish-brown to orange circular spots',
            'Velvety texture on leaf surface',
            'Spots may merge forming large patches',
            'Affected leaves may fall prematurely'
        ],
        'treatment': [
            'Apply copper oxychloride 50% WP @ 3g/litre of water',
            'Spray Bordeaux mixture 0.5-1%',
            'Use copper hydroxide-based fungicides',
            'Remove heavily infected branches',
            'Improve light penetration by pruning'
        ],
        'prevention': [
            'Avoid dense planting',
            'Ensure good drainage',
            'Prune shade trees to reduce humidity',
            'Apply preventive copper sprays before monsoon',
            'Maintain balanced nutrition (avoid excess nitrogen)'
        ],
        'spray_interval': '14-21 days'
    },
    'healthy': {
        'name': 'Healthy Leaf',
        'severity': 'NONE',
        'symptoms': ['No disease symptoms detected'],
        'treatment': ['No treatment required'],
        'prevention': [
            'Continue regular monitoring',
            'Maintain good agricultural practices',
            'Ensure balanced fertilization',
            'Regular pruning and maintenance'
        ]
    }
}


def get_model():
    """Load the best available model."""
    project_root = Path(__file__).parent.parent
    model_paths = [
        # Colab GPU trained model (best accuracy)
        project_root / "runs/detect/tea_leaf_gpu/weights/best.pt",
        # Local trained models
        project_root / "runs/detect/runs/detect/max_accuracy/tealeaf_95/weights/best.pt",
        project_root / "runs/detect/runs/detect/augmented/tealeaf_aug/weights/best.pt",
        project_root / "runs/detect/runs/train/tealeaf2/weights/best.pt",
    ]

    for path in model_paths:
        if path.exists():
            print(f"Loading model: {path.name}")
            return YOLO(str(path))

    raise FileNotFoundError("No trained model found! Please train a model first.")


def analyze_image(model, image_path, conf_threshold=0.25):
    """Analyze a single image and return detection results."""
    results = model.predict(
        source=str(image_path),
        conf=conf_threshold,
        verbose=False
    )

    detections = []
    class_names = ['blister_blight', 'healthy', 'red_rust']

    for result in results:
        for box in result.boxes:
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            cls_name = class_names[cls_id] if cls_id < len(class_names) else f"class_{cls_id}"

            detections.append({
                'class': cls_name,
                'confidence': conf,
                'bbox': box.xyxy[0].tolist()
            })

    return detections, results[0] if results else None


def generate_cumulative_report(all_detections, image_count):
    """Generate cumulative analysis report from all detections."""
    # Count detections by class
    class_counts = defaultdict(int)
    class_confidences = defaultdict(list)

    for detection in all_detections:
        cls = detection['class']
        class_counts[cls] += 1
        class_confidences[cls].append(detection['confidence'])

    total_leaves = sum(class_counts.values())

    # Calculate percentages and averages
    report = {
        'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'images_analyzed': image_count,
        'total_leaves_detected': total_leaves,
        'summary': {},
        'diseases_found': [],
        'overall_health': 'UNKNOWN'
    }

    for cls, count in class_counts.items():
        avg_conf = sum(class_confidences[cls]) / len(class_confidences[cls]) if class_confidences[cls] else 0
        percentage = (count / total_leaves * 100) if total_leaves > 0 else 0

        report['summary'][cls] = {
            'count': count,
            'percentage': round(percentage, 1),
            'avg_confidence': round(avg_conf * 100, 1)
        }

        if cls != 'healthy':
            report['diseases_found'].append(cls)

    # Determine overall health status
    healthy_count = class_counts.get('healthy', 0)
    diseased_count = total_leaves - healthy_count

    if total_leaves == 0:
        report['overall_health'] = 'NO LEAVES DETECTED'
        report['health_percentage'] = 0
    elif diseased_count == 0:
        report['overall_health'] = 'EXCELLENT - All leaves healthy'
        report['health_percentage'] = 100
    elif healthy_count / total_leaves >= 0.8:
        report['overall_health'] = 'GOOD - Minor disease presence'
        report['health_percentage'] = round(healthy_count / total_leaves * 100, 1)
    elif healthy_count / total_leaves >= 0.5:
        report['overall_health'] = 'MODERATE - Treatment recommended'
        report['health_percentage'] = round(healthy_count / total_leaves * 100, 1)
    else:
        report['overall_health'] = 'CRITICAL - Immediate action required'
        report['health_percentage'] = round(healthy_count / total_leaves * 100, 1)

    return report


def print_report(report):
    """Print formatted analysis report."""
    print()
    print("=" * 70)
    print("  TEA LEAF DISEASE ANALYSIS REPORT")
    print("=" * 70)
    print(f"  Date: {report['timestamp']}")
    print(f"  Images Analyzed: {report['images_analyzed']}")
    print(f"  Total Leaves Detected: {report['total_leaves_detected']}")
    print()

    # Overall Health Status
    print("-" * 70)
    print("  OVERALL HEALTH STATUS")
    print("-" * 70)
    health_color = {
        'EXCELLENT': '\033[92m',  # Green
        'GOOD': '\033[93m',       # Yellow
        'MODERATE': '\033[93m',   # Yellow
        'CRITICAL': '\033[91m',   # Red
    }
    reset = '\033[0m'

    status_key = report['overall_health'].split(' - ')[0]
    color = health_color.get(status_key, '')

    print(f"  Status: {color}{report['overall_health']}{reset}")
    print(f"  Health Percentage: {report.get('health_percentage', 0)}%")
    print()

    # Detection Summary
    print("-" * 70)
    print("  DETECTION SUMMARY")
    print("-" * 70)
    print(f"  {'Category':<20} {'Count':<10} {'Percentage':<15} {'Avg Confidence':<15}")
    print(f"  {'-'*20} {'-'*10} {'-'*15} {'-'*15}")

    for cls, data in report['summary'].items():
        status = "DISEASED" if cls != 'healthy' else "HEALTHY"
        print(f"  {cls:<20} {data['count']:<10} {data['percentage']:<15}% {data['avg_confidence']:<15}%")
    print()

    # Treatment Recommendations
    if report['diseases_found']:
        print("-" * 70)
        print("  TREATMENT RECOMMENDATIONS")
        print("-" * 70)

        for disease in report['diseases_found']:
            info = DISEASE_INFO.get(disease, {})
            print(f"\n  [{info.get('severity', 'UNKNOWN')}] {info.get('name', disease).upper()}")
            print(f"  Caused by: {info.get('caused_by', 'Unknown')}")

            print("\n  Symptoms:")
            for symptom in info.get('symptoms', []):
                print(f"    - {symptom}")

            print("\n  Recommended Treatment:")
            for i, treatment in enumerate(info.get('treatment', []), 1):
                print(f"    {i}. {treatment}")

            print(f"\n  Spray Interval: {info.get('spray_interval', 'Consult expert')}")

            print("\n  Prevention Measures:")
            for prevention in info.get('prevention', []):
                print(f"    - {prevention}")

            print()
    else:
        print("-" * 70)
        print("  MAINTENANCE RECOMMENDATIONS")
        print("-" * 70)
        print("  All leaves appear healthy! Continue with:")
        for tip in DISEASE_INFO['healthy']['prevention']:
            print(f"    - {tip}")
        print()

    print("=" * 70)
    print("  END OF REPORT")
    print("=" * 70)


def save_report(report, output_path):
    """Save report to JSON file."""
    with open(output_path, 'w') as f:
        json.dump(report, f, indent=2)
    print(f"\nReport saved to: {output_path}")


def save_annotated_image(result, output_path):
    """Save image with detection annotations."""
    annotated = result.plot()
    cv2.imwrite(str(output_path), annotated)


def main():
    parser = argparse.ArgumentParser(description="Analyze tea leaves for diseases")
    parser.add_argument("--image", type=str, help="Path to a single image")
    parser.add_argument("--folder", type=str, help="Path to folder of images")
    parser.add_argument("--conf", type=float, default=0.25, help="Confidence threshold (default: 0.25)")
    parser.add_argument("--save-report", action="store_true", help="Save report to JSON file")
    parser.add_argument("--save-images", action="store_true", help="Save annotated images")
    parser.add_argument("--output", type=str, default="analysis_output", help="Output folder for saved files")
    args = parser.parse_args()

    if not args.image and not args.folder:
        print("ERROR: Please specify --image or --folder")
        print("Example: python analyze_leaves.py --image field_photo.jpg")
        return

    # Load model
    try:
        model = get_model()
    except FileNotFoundError as e:
        print(f"ERROR: {e}")
        return

    # Collect images to analyze
    images = []
    if args.image:
        images = [Path(args.image)]
    elif args.folder:
        folder = Path(args.folder)
        images = list(folder.glob("*.jpg")) + list(folder.glob("*.jpeg")) + list(folder.glob("*.png"))

    if not images:
        print("ERROR: No images found!")
        return

    print(f"\nAnalyzing {len(images)} image(s)...")
    print("-" * 50)

    # Create output folder if saving
    if args.save_report or args.save_images:
        output_dir = Path(args.output)
        output_dir.mkdir(exist_ok=True)

    # Analyze all images
    all_detections = []
    for img_path in images:
        print(f"  Processing: {img_path.name}...", end=" ")

        detections, result = analyze_image(model, img_path, args.conf)
        all_detections.extend(detections)

        print(f"Found {len(detections)} leaf(s)")

        # Save annotated image if requested
        if args.save_images and result:
            output_img = Path(args.output) / f"annotated_{img_path.name}"
            save_annotated_image(result, output_img)

    # Generate and print cumulative report
    report = generate_cumulative_report(all_detections, len(images))
    print_report(report)

    # Save report if requested
    if args.save_report:
        report_path = Path(args.output) / f"analysis_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        save_report(report, report_path)


if __name__ == "__main__":
    main()
