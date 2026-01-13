import 'package:flutter/material.dart';

/// ESP32 Sensor Data Model
/// Represents the data received from the iTeaGrow Environmental Monitor
class ESP32SensorData {
  final double temperature; // Celsius
  final double humidity; // Percentage
  final int airQuality; // Raw ADC value (0-4095)
  final bool motionDetected;
  final DateTime timestamp;

  const ESP32SensorData({
    required this.temperature,
    required this.humidity,
    required this.airQuality,
    required this.motionDetected,
    required this.timestamp,
  });

  /// Get air quality rating based on raw ADC value
  AirQualityRating get airQualityRating {
    if (airQuality < 200) return AirQualityRating.excellent;
    if (airQuality < 400) return AirQualityRating.good;
    if (airQuality < 600) return AirQualityRating.moderate;
    if (airQuality < 800) return AirQualityRating.poor;
    return AirQualityRating.critical;
  }

  /// Get temperature status for tea cultivation
  /// Optimal range: 20-28°C
  SensorHealthStatus get temperatureStatus {
    if (temperature < 13) return SensorHealthStatus.critical;
    if (temperature < 18) return SensorHealthStatus.warning;
    if (temperature >= 18 && temperature <= 30) return SensorHealthStatus.optimal;
    if (temperature <= 32) return SensorHealthStatus.warning;
    return SensorHealthStatus.critical;
  }

  /// Get humidity status for tea cultivation
  /// Optimal range: 70-90%
  SensorHealthStatus get humidityStatus {
    if (humidity < 40) return SensorHealthStatus.critical;
    if (humidity < 60) return SensorHealthStatus.warning;
    if (humidity >= 60 && humidity <= 90) return SensorHealthStatus.optimal;
    if (humidity <= 95) return SensorHealthStatus.warning;
    return SensorHealthStatus.critical;
  }

  /// Calculate disease risk based on environmental conditions
  DiseaseRisk get diseaseRisk {
    // Blister Blight risk: High humidity (>80%) + Temperature 15-25°C
    if (humidity > 80 && temperature >= 15 && temperature <= 25) {
      return DiseaseRisk(
        disease: 'Blister Blight',
        riskLevel: RiskLevel.high,
        description: 'High humidity and cool temperatures favor Blister Blight',
      );
    }

    // Red Rust risk: Humidity >70% + Temperature 20-28°C
    if (humidity > 70 && temperature >= 20 && temperature <= 28) {
      return DiseaseRisk(
        disease: 'Red Rust',
        riskLevel: humidity > 80 ? RiskLevel.moderate : RiskLevel.low,
        description: 'Monitor for Red Rust development',
      );
    }

    return DiseaseRisk(
      disease: 'None',
      riskLevel: RiskLevel.low,
      description: 'Environmental conditions are favorable',
    );
  }

  ESP32SensorData copyWith({
    double? temperature,
    double? humidity,
    int? airQuality,
    bool? motionDetected,
    DateTime? timestamp,
  }) {
    return ESP32SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      airQuality: airQuality ?? this.airQuality,
      motionDetected: motionDetected ?? this.motionDetected,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'air_quality': airQuality,
      'motion_detected': motionDetected,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ESP32SensorData.fromJson(Map<String, dynamic> json) {
    return ESP32SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      airQuality: json['air_quality'] as int,
      motionDetected: json['motion_detected'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'ESP32SensorData(T: ${temperature.toStringAsFixed(1)}°C, '
        'H: ${humidity.toStringAsFixed(1)}%, A: $airQuality, M: $motionDetected)';
  }
}

/// Air Quality Rating based on MQ sensor readings
enum AirQualityRating {
  excellent,
  good,
  moderate,
  poor,
  critical;

  String get displayName {
    switch (this) {
      case AirQualityRating.excellent:
        return 'Excellent';
      case AirQualityRating.good:
        return 'Good';
      case AirQualityRating.moderate:
        return 'Moderate';
      case AirQualityRating.poor:
        return 'Poor';
      case AirQualityRating.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AirQualityRating.excellent:
        return const Color(0xFF4CAF50);
      case AirQualityRating.good:
        return const Color(0xFF8BC34A);
      case AirQualityRating.moderate:
        return const Color(0xFFFFC107);
      case AirQualityRating.poor:
        return const Color(0xFFFF9800);
      case AirQualityRating.critical:
        return const Color(0xFFE53935);
    }
  }

  IconData get icon {
    switch (this) {
      case AirQualityRating.excellent:
        return Icons.air;
      case AirQualityRating.good:
        return Icons.check_circle_outline;
      case AirQualityRating.moderate:
        return Icons.info_outline;
      case AirQualityRating.poor:
        return Icons.warning_amber_outlined;
      case AirQualityRating.critical:
        return Icons.dangerous_outlined;
    }
  }
}

/// Sensor Health Status
enum SensorHealthStatus {
  optimal,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case SensorHealthStatus.optimal:
        return 'Optimal';
      case SensorHealthStatus.warning:
        return 'Warning';
      case SensorHealthStatus.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case SensorHealthStatus.optimal:
        return const Color(0xFF4CAF50);
      case SensorHealthStatus.warning:
        return const Color(0xFFFFA726);
      case SensorHealthStatus.critical:
        return const Color(0xFFE53935);
    }
  }
}

/// Risk Level
enum RiskLevel {
  low,
  moderate,
  high;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50);
      case RiskLevel.moderate:
        return const Color(0xFFFFA726);
      case RiskLevel.high:
        return const Color(0xFFE53935);
    }
  }
}

/// Disease Risk
class DiseaseRisk {
  final String disease;
  final RiskLevel riskLevel;
  final String description;

  const DiseaseRisk({
    required this.disease,
    required this.riskLevel,
    required this.description,
  });
}
