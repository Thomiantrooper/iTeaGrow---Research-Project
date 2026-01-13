import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iteagrow/core/theme/app_theme.dart';

/// IoT Device Model
class IoTDevice {
  final String id;
  final String name;
  final String type; // 'bluetooth' or 'wifi'
  final String? macAddress;
  final String? ipAddress;
  final bool isConnected;
  final DateTime? lastConnected;
  final int? signalStrength; // RSSI for Bluetooth, WiFi signal strength

  IoTDevice({
    required this.id,
    required this.name,
    required this.type,
    this.macAddress,
    this.ipAddress,
    this.isConnected = false,
    this.lastConnected,
    this.signalStrength,
  });

  IoTDevice copyWith({
    String? id,
    String? name,
    String? type,
    String? macAddress,
    String? ipAddress,
    bool? isConnected,
    DateTime? lastConnected,
    int? signalStrength,
  }) {
    return IoTDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'mac_address': macAddress,
      'ip_address': ipAddress,
      'is_connected': isConnected ? 1 : 0,
      'last_connected': lastConnected?.millisecondsSinceEpoch,
      'signal_strength': signalStrength,
    };
  }

  factory IoTDevice.fromMap(Map<String, dynamic> map) {
    return IoTDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      macAddress: map['mac_address'] as String?,
      ipAddress: map['ip_address'] as String?,
      isConnected: (map['is_connected'] as int) == 1,
      lastConnected: map['last_connected'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_connected'] as int)
          : null,
      signalStrength: map['signal_strength'] as int?,
    );
  }
}

/// Sensor Reading Model
class SensorReading {
  final int? id;
  final String deviceId;
  final SensorType sensorType;
  final double value;
  final String unit;
  final DateTime timestamp;
  final SensorStatus status;

  SensorReading({
    this.id,
    required this.deviceId,
    required this.sensorType,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.status = SensorStatus.normal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'sensor_type': sensorType.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      deviceId: map['device_id'] as String,
      sensorType: SensorType.values.firstWhere(
        (e) => e.name == map['sensor_type'],
        orElse: () => SensorType.temperature,
      ),
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: SensorStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SensorStatus.normal,
      ),
    );
  }
}

/// Sensor Types
enum SensorType {
  soilMoisture,
  soilPH,
  nitrogen,
  phosphorus,
  potassium,
  temperature,
  humidity,
}

extension SensorTypeExtension on SensorType {
  String get displayName {
    switch (this) {
      case SensorType.soilMoisture:
        return 'Soil Moisture';
      case SensorType.soilPH:
        return 'Soil pH';
      case SensorType.nitrogen:
        return 'Nitrogen (N)';
      case SensorType.phosphorus:
        return 'Phosphorus (P)';
      case SensorType.potassium:
        return 'Potassium (K)';
      case SensorType.temperature:
        return 'Temperature';
      case SensorType.humidity:
        return 'Humidity';
    }
  }

  String get unit {
    switch (this) {
      case SensorType.soilMoisture:
        return '%';
      case SensorType.soilPH:
        return 'pH';
      case SensorType.nitrogen:
      case SensorType.phosphorus:
      case SensorType.potassium:
        return 'mg/kg';
      case SensorType.temperature:
        return '°C';
      case SensorType.humidity:
        return '%';
    }
  }

  IconData get icon {
    switch (this) {
      case SensorType.soilMoisture:
        return Icons.water_drop;
      case SensorType.soilPH:
        return Icons.science;
      case SensorType.nitrogen:
        return Icons.eco;
      case SensorType.phosphorus:
        return Icons.grain;
      case SensorType.potassium:
        return Icons.spa;
      case SensorType.temperature:
        return Icons.thermostat;
      case SensorType.humidity:
        return Icons.cloud;
    }
  }
}

/// Sensor Status
enum SensorStatus {
  critical,
  warning,
  normal,
  optimal,
}

extension SensorStatusExtension on SensorStatus {
  String get displayName {
    switch (this) {
      case SensorStatus.critical:
        return 'Critical';
      case SensorStatus.warning:
        return 'Warning';
      case SensorStatus.normal:
        return 'Normal';
      case SensorStatus.optimal:
        return 'Optimal';
    }
  }
}
