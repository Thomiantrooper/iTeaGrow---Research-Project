import 'package:flutter/material.dart';
import '../../../../core/design_system/tea_colors.dart';

/// Data model for Estate Zone (5 main zones)
class PlantationZone {
  final int id;
  final String name;
  final List<SubZone> subZones;
  final Offset position; // Relative position (0.0-1.0)
  final Size size; // Relative size (0.0-1.0)
  final Color accentColor;

  PlantationZone({
    required this.id,
    required this.name,
    required this.subZones,
    required this.position,
    required this.size,
    required this.accentColor,
  });

  /// Calculate average health of all sub-zones
  double get averageHealth {
    final withData = subZones.where((s) => s.latestData != null).toList();
    if (withData.isEmpty) return 0;

    int goodCount =
        withData.where((s) => s.latestData!.soilHealth == 'Good').length;
    int fairCount =
        withData.where((s) => s.latestData!.soilHealth == 'Fair').length;

    // Good = 100%, Fair = 60%, Poor = 30%
    return (goodCount * 100 +
            fairCount * 60 +
            (withData.length - goodCount - fairCount) * 30) /
        withData.length;
  }

  /// Get health status string
  String get healthStatus {
    final avg = averageHealth;
    if (avg >= 85) return 'Excellent';
    if (avg >= 70) return 'Good';
    if (avg >= 50) return 'Fair';
    return 'Poor';
  }

  /// Get color based on average health
  Color get healthColor {
    // 1. Check if any sub-zones have data
    final hasData = subZones.any((s) => s.latestData != null);
    if (!hasData) return TeaColors.mediumGray.withOpacity(0.6);

    final avg = averageHealth;
    if (avg >= 85) return TeaColors.healthyGreen;
    if (avg >= 70) return TeaColors.leafMedium;
    if (avg >= 50) return TeaColors.warningAmber;
    return TeaColors.alertRust;
  }
}

/// Data model for Sub-Zone (25 hectares per zone)
class SubZone {
  final int hectareId;
  final String name;
  final int zoneId;
  final Offset position; // Relative position within zone
  final Size size; // Relative size
  SoilData? latestData;

  SubZone({
    required this.hectareId,
    required this.name,
    required this.zoneId,
    required this.position,
    required this.size,
    this.latestData,
  });

  /// Get health color based on latest data
  Color get healthColor {
    if (latestData == null) return TeaColors.mediumGray.withOpacity(0.3);

    switch (latestData!.soilHealth) {
      case 'Good':
        return TeaColors.healthyGreen;
      case 'Fair':
        return TeaColors.warningAmber;
      case 'Poor':
        return TeaColors.alertRust;
      default:
        return TeaColors.mediumGray;
    }
  }

  /// Check if data is recent (within last 5 minutes)
  bool get isDataRecent {
    if (latestData == null) return false;
    final diff = DateTime.now().difference(latestData!.timestamp);
    return diff.inMinutes < 5;
  }
}

/// Soil data model from Railway API
class SoilData {
  final int hectareId;
  final String soilHealth; // Good/Fair/Poor
  final double temperature;
  final double humidity;
  final double pH;
  final double ec;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final List<String> fertilizer;
  final DateTime timestamp;
  final String deviceId;
  final int? blockId;
  final int? readingCount;

  SoilData({
    required this.hectareId,
    required this.soilHealth,
    required this.temperature,
    required this.humidity,
    required this.pH,
    required this.ec,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.fertilizer,
    required this.timestamp,
    required this.deviceId,
    this.blockId,
    this.readingCount,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      hectareId: json['hectare_id'] as int,
      soilHealth: json['soil_health'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      pH: (json['pH'] as num).toDouble(),
      ec: (json['EC'] as num).toDouble(),
      nitrogen: (json['N'] as num).toDouble(),
      phosphorus: (json['P'] as num).toDouble(),
      potassium: (json['K'] as num).toDouble(),
      fertilizer:
          (json['fertilizer'] as List).map((e) => e.toString()).toList(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      deviceId: json['device_id'] as String,
      blockId: json['block_id'] as int?,
      readingCount: json['reading_count'] as int?,
    );
  }

  /// Get N-P-K as formatted string
  String get npkString =>
      '${nitrogen.toInt()}-${phosphorus.toInt()}-${potassium.toInt()}';

  /// Get temperature status
  String get tempStatus {
    if (temperature < 18) return 'Low';
    if (temperature > 25) return 'High';
    return 'Optimal';
  }

  /// Get humidity status
  String get humidityStatus {
    if (humidity < 40) return 'Low';
    if (humidity > 70) return 'High';
    return 'Optimal';
  }

  /// Get pH status
  String get phStatus {
    if (pH < 4.5) return 'Too Acidic';
    if (pH > 5.5) return 'Too Alkaline';
    return 'Optimal';
  }
}
