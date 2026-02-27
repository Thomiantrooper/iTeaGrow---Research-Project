import 'package:intl/intl.dart';

enum SoilHealthStatus {
  good('Good'),
  fair('Fair'),
  poor('Poor'),
  unknown('Unknown');

  final String label;
  const SoilHealthStatus(this.label);

  static SoilHealthStatus fromString(String? value) {
    if (value == null) return SoilHealthStatus.unknown;
    return SoilHealthStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => SoilHealthStatus.unknown,
    );
  }
}

class SoilHealthRecord {
  final int hectareId;
  final SoilHealthStatus healthStatus;
  final List<String> fertilizerAdvice;
  final DateTime timestamp;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double ec;
  final double temperature;
  final double humidity;
  final int? blockId;

  SoilHealthRecord({
    required this.hectareId,
    required this.healthStatus,
    required this.fertilizerAdvice,
    required this.timestamp,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.ec,
    required this.temperature,
    required this.humidity,
    this.blockId,
  });

  factory SoilHealthRecord.fromJson(Map<String, dynamic> json) {
    return SoilHealthRecord(
      hectareId: json['hectare_id'] ?? 0,
      healthStatus: SoilHealthStatus.fromString(json['soil_health']),
      fertilizerAdvice: List<String>.from(json['fertilizer'] ?? []),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '')?.toLocal() ??
          DateTime.now(),
      nitrogen: (json['N'] as num?)?.toDouble() ?? 0.0,
      phosphorus: (json['P'] as num?)?.toDouble() ?? 0.0,
      potassium: (json['K'] as num?)?.toDouble() ?? 0.0,
      ph: (json['pH'] as num?)?.toDouble() ?? 0.0,
      ec: (json['EC'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      blockId: json['block_id'],
    );
  }

  /// Returns advice without emojis for a cleaner, professional UI
  /// Strips all non-standard characters to ensure clean PDF font rendering
  List<String> get sanitizedAdvice {
    // Allows Basic Latin, Latin-1 Supplement (for degree symbols, etc.), and standard symbols.
    // Explicitly avoids emojis and common variation selectors.
    final cleanRegex = RegExp(r'[^\x20-\x7E\u00A0-\u00FF]');
    return fertilizerAdvice
        .map((a) => a.replaceAll(cleanRegex, '').trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  String get formattedTime {
    // Format: "Feb 28, 01:27 AM" (local time with date)
    return DateFormat('MMM d, hh:mm a').format(timestamp);
  }
  
  String get formattedDateTime {
    // Format: "Feb 28, 2026 at 01:27 AM" (full datetime in local time)
    return DateFormat('MMM d, y \'at\' hh:mm a').format(timestamp);
  }
}
