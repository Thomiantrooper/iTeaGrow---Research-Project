/// Bounding box for detected disease regions
class BoundingBox {
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;
  final double confidence;

  BoundingBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    required this.confidence,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      xMin: (json['x_min'] as num).toDouble(),
      yMin: (json['y_min'] as num).toDouble(),
      xMax: (json['x_max'] as num).toDouble(),
      yMax: (json['y_max'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'x_min': xMin,
    'y_min': yMin,
    'x_max': xMax,
    'y_max': yMax,
    'confidence': confidence,
  };
}

/// Individual detection from the model
class Detection {
  final String detectionId;
  final String className;
  final int classId;
  final double confidence;
  final BoundingBox boundingBox;
  final double areaPercentage;

  Detection({
    required this.detectionId,
    required this.className,
    required this.classId,
    required this.confidence,
    required this.boundingBox,
    required this.areaPercentage,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      detectionId: json['detection_id'] ?? '',
      className: json['class_name'] ?? 'unknown',
      classId: json['class_id'] ?? 0,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: BoundingBox.fromJson(json['bounding_box']),
      areaPercentage: (json['area_percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'detection_id': detectionId,
    'class_name': className,
    'class_id': classId,
    'confidence': confidence,
    'bounding_box': boundingBox.toJson(),
    'area_percentage': areaPercentage,
  };

  /// Get display-friendly disease name
  String get displayName {
    switch (className) {
      case 'healthy':
        return 'Healthy';
      case 'red_rust':
        return 'Red Rust';
      case 'blister_blight':
        return 'Blister Blight';
      default:
        return className.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
        ).join(' ');
    }
  }
}

/// Detection summary from API response
class DetectionSummary {
  final int totalLeavesDetected;
  final int healthyCount;
  final int redRustCount;
  final int blisterBlightCount;
  final double overallHealthScore;
  final String? dominantDisease;
  final String severityLevel;
  final bool requiresImmediateAction;

  DetectionSummary({
    required this.totalLeavesDetected,
    required this.healthyCount,
    required this.redRustCount,
    required this.blisterBlightCount,
    required this.overallHealthScore,
    this.dominantDisease,
    required this.severityLevel,
    required this.requiresImmediateAction,
  });

  factory DetectionSummary.fromJson(Map<String, dynamic> json) {
    return DetectionSummary(
      totalLeavesDetected: json['total_leaves_detected'] ?? 0,
      healthyCount: json['healthy_count'] ?? 0,
      redRustCount: json['red_rust_count'] ?? 0,
      blisterBlightCount: json['blister_blight_count'] ?? 0,
      overallHealthScore: (json['overall_health_score'] as num?)?.toDouble() ?? 0.0,
      dominantDisease: json['dominant_disease'],
      severityLevel: json['severity_level'] ?? 'none',
      requiresImmediateAction: json['requires_immediate_action'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_leaves_detected': totalLeavesDetected,
    'healthy_count': healthyCount,
    'red_rust_count': redRustCount,
    'blister_blight_count': blisterBlightCount,
    'overall_health_score': overallHealthScore,
    'dominant_disease': dominantDisease,
    'severity_level': severityLevel,
    'requires_immediate_action': requiresImmediateAction,
  };
}

class DiseaseDetectionResult {
  final String diseaseType; // 'Healthy', 'Leaf Blight', 'Red Rust', 'Not A Leaf', etc.
  final double confidence;
  final String severity; // 'Low', 'Medium', 'High'
  final List<String> recommendations;
  final DateTime timestamp;

  // Live IoT context
  final double? temperature; // °C
  final double? humidity; // %
  final double? airQuality; // AQI

  // API response data
  final String? requestId;
  final String? imageId;
  final String? dbId; // MongoDB _id for report generation
  final double? processingTimeMs;
  final List<Detection>? detections;
  final DetectionSummary? summary;

  /// Check if the result indicates the image is not a valid leaf
  bool get isNotALeaf => diseaseType == 'Not A Leaf';

  DiseaseDetectionResult({
    required this.diseaseType,
    required this.confidence,
    required this.severity,
    required this.recommendations,
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.airQuality,
    this.requestId,
    this.imageId,
    this.dbId,
    this.processingTimeMs,
    this.detections,
    this.summary,
  });

  /// Create from API response
  factory DiseaseDetectionResult.fromApiResponse(Map<String, dynamic> json) {
    final summary = json['summary'] != null
        ? DetectionSummary.fromJson(json['summary'])
        : null;

    final detections = (json['detections'] as List?)
        ?.map((d) => Detection.fromJson(d))
        .toList() ?? [];

    // Determine main disease type - prefer direct API field, then summary, then detections
    String diseaseType = 'Healthy';
    double confidence = 0.0;

    // First check if API directly provides disease_type and confidence
    if (json['disease_type'] != null && json['disease_type'] != 'No Detection') {
      diseaseType = json['disease_type'];
      confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    } else if (summary != null && summary.dominantDisease != null) {
      diseaseType = _formatDiseaseName(summary.dominantDisease!);
      // Use highest confidence from detections of this type
      final relevantDetections = detections.where(
        (d) => d.className == summary.dominantDisease,
      );
      if (relevantDetections.isNotEmpty) {
        confidence = relevantDetections.map((d) => d.confidence).reduce(
          (a, b) => a > b ? a : b,
        );
      }
    } else if (detections.isNotEmpty) {
      // Use first non-healthy detection or healthy if all are healthy
      final nonHealthy = detections.where((d) => d.className != 'healthy').toList();
      if (nonHealthy.isNotEmpty) {
        final topDetection = nonHealthy.reduce(
          (a, b) => a.confidence > b.confidence ? a : b,
        );
        diseaseType = topDetection.displayName;
        confidence = topDetection.confidence;
      } else {
        diseaseType = 'Healthy';
        confidence = detections.first.confidence;
      }
    }

    // Map severity from API - prefer direct severity field
    String severity = json['severity'] ?? 'Low';
    if (severity == 'None') severity = 'Low';
    if (summary != null && severity == 'Low') {
      switch (summary.severityLevel) {
        case 'critical':
        case 'high':
          severity = 'High';
          break;
        case 'moderate':
          severity = 'Medium';
          break;
        default:
          severity = 'Low';
      }
    }

    // Use recommendations from API response if available, otherwise generate based on detection
    List<String> recommendations = [];
    if (json['recommendations'] != null && (json['recommendations'] as List).isNotEmpty) {
      recommendations = List<String>.from(json['recommendations']);
    } else if (diseaseType == 'Not A Leaf') {
      recommendations = [
        'The scanned image does not appear to be a tea leaf. It may be a hand, fabric, surface, soil, or other non-leaf object.',
        'Please position a single tea leaf clearly in the camera frame',
        'Ensure the leaf is well-lit, in focus, and fills most of the image',
        'Avoid backgrounds with clutter or other objects',
        'Try again with a proper tea leaf image',
      ];
    } else if (diseaseType == 'Healthy') {
      recommendations = [
        'Continue regular monitoring',
        'Maintain current practices',
      ];
    } else {
      recommendations = [
        'Apply recommended fungicide',
        'Improve drainage and air circulation',
        'Monitor closely for 2 weeks',
        'Check environmental conditions',
        if (summary?.requiresImmediateAction == true)
          'Immediate action required!',
      ];
    }

    return DiseaseDetectionResult(
      diseaseType: diseaseType,
      confidence: confidence,
      severity: severity,
      recommendations: recommendations,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      requestId: json['request_id'],
      imageId: json['image_id'],
      dbId: json['_id'] ?? json['id'] ?? json['db_id'],
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble(),
      detections: detections,
      summary: summary,
    );
  }

  static String _formatDiseaseName(String name) {
    switch (name) {
      case 'healthy':
        return 'Healthy';
      case 'red_rust':
        return 'Red Rust';
      case 'blister_blight':
        return 'Blister Blight';
      case 'not_a_leaf':
        return 'Not A Leaf';
      default:
        return name.replaceAll('_', ' ').split(' ').map((w) =>
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w,
        ).join(' ');
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'disease_name': diseaseType,
    'confidence': confidence,
    'severity': severity,
    'recommendations': recommendations,
    'timestamp': timestamp.toIso8601String(),
    'temperature': temperature,
    'humidity': humidity,
    'air_quality': airQuality,
    'request_id': requestId,
    'image_id': imageId,
    'db_id': dbId,
    'processing_time_ms': processingTimeMs,
    'detections': detections?.map((d) => d.toJson()).toList(),
    'summary': summary?.toJson(),
  };

  /// Create from stored JSON
  factory DiseaseDetectionResult.fromStoredJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      diseaseType: json['disease_name'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: json['severity'] ?? 'Low',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      airQuality: (json['air_quality'] as num?)?.toDouble(),
      requestId: json['request_id'],
      imageId: json['image_id'],
      dbId: json['_id'] ?? json['id'] ?? json['db_id'],
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble(),
      detections: (json['detections'] as List?)?.map((d) => Detection.fromJson(d)).toList(),
      summary: json['summary'] != null ? DetectionSummary.fromJson(json['summary']) : null,
    );
  }
}
