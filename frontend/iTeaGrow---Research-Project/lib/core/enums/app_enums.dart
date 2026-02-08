import 'package:flutter/material.dart';

enum UserRole {
  farmer,
  manager,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.manager:
        return 'Manager';
      case UserRole.admin:
        return 'System Administrator';
    }
  }

  bool canAccessYieldPrediction() {
    return this == UserRole.manager || this == UserRole.admin;
  }

  bool canAccessAnalytics() {
    return this == UserRole.manager || this == UserRole.admin;
  }

  bool canAccessAdminPanel() {
    return this == UserRole.admin;
  }

  bool canManageUsers() {
    return this == UserRole.admin;
  }

  bool canConfigureSystem() {
    return this == UserRole.admin;
  }
}

enum ConnectionType {
  bluetooth,
  wifi;

  String get displayName {
    switch (this) {
      case ConnectionType.bluetooth:
        return 'Bluetooth';
      case ConnectionType.wifi:
        return 'Wi-Fi';
    }
  }
}

enum LeafMaturityClass {
  tender,
  mature,
  coarser;

  String get displayName {
    switch (this) {
      case LeafMaturityClass.tender:
        return 'Tender';
      case LeafMaturityClass.mature:
        return 'Mature';
      case LeafMaturityClass.coarser:
        return 'Coarser';
    }
  }

  Color get color {
    switch (this) {
      case LeafMaturityClass.tender:
        return const Color(0xFF4CAF50); // Green
      case LeafMaturityClass.mature:
        return const Color(0xFFFFA726); // Amber
      case LeafMaturityClass.coarser:
        return const Color(0xFFEF5350); // Red
    }
  }
}

enum AlertSeverity {
  info,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.info:
        return const Color(0xFF2196F3); // Blue
      case AlertSeverity.warning:
        return const Color(0xFFFFA726); // Amber
      case AlertSeverity.critical:
        return const Color(0xFFEF5350); // Red
    }
  }
}

enum SensorStatus {
  optimal,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case SensorStatus.optimal:
        return 'Optimal';
      case SensorStatus.warning:
        return 'Warning';
      case SensorStatus.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case SensorStatus.optimal:
        return const Color(0xFF4CAF50); // Green
      case SensorStatus.warning:
        return const Color(0xFFFFA726); // Amber
      case SensorStatus.critical:
        return const Color(0xFFEF5350); // Red
    }
  }
}
