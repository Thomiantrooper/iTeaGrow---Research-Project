import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one live sensor reading coming from the MQTT bridge.
class LiveSensorReading {
  final String deviceId;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? airQuality;
  final double? lightLevel;
  final DateTime? timestamp;

  const LiveSensorReading({
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.airQuality,
    this.lightLevel,
    this.timestamp,
  });

  factory LiveSensorReading.fromJson(Map<String, dynamic> json) {
    return LiveSensorReading(
      deviceId:    json['device_id']?.toString() ?? 'unknown',
      temperature: _toDouble(json['temperature']),
      humidity:    _toDouble(json['humidity']),
      soilMoisture: _toDouble(json['soil_moisture']),
      airQuality:  _toDouble(json['air_quality']),
      lightLevel:  _toDouble(json['light_level']),
      timestamp:   json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  /// True if at least one sensor value is present
  bool get hasData =>
      temperature != null ||
      humidity != null ||
      soilMoisture != null ||
      airQuality != null;

  /// Seconds since this reading was recorded
  int get secondsAgo =>
      timestamp != null
          ? DateTime.now().difference(timestamp!).inSeconds
          : -1;

  /// Human-readable "last seen" string
  String get lastSeenLabel {
    if (timestamp == null) return 'Unknown';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Air-quality label (ppm-based rough scale)
  String get airQualityLabel {
    if (airQuality == null) return 'N/A';
    if (airQuality! < 400)  return 'Excellent';
    if (airQuality! < 600)  return 'Good';
    if (airQuality! < 1000) return 'Moderate';
    if (airQuality! < 2000) return 'Poor';
    return 'Critical';
  }

  /// Is this reading stale (older than 5 minutes)?
  bool get isStale =>
      timestamp == null || DateTime.now().difference(timestamp!).inMinutes > 5;
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class IoTLiveState {
  /// Map of device_id → latest reading
  final Map<String, LiveSensorReading> devices;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshed;

  const IoTLiveState({
    this.devices = const {},
    this.isLoading = false,
    this.error,
    this.lastRefreshed,
  });

  IoTLiveState copyWith({
    Map<String, LiveSensorReading>? devices,
    bool? isLoading,
    String? error,
    DateTime? lastRefreshed,
  }) =>
      IoTLiveState(
        devices:       devices       ?? this.devices,
        isLoading:     isLoading     ?? this.isLoading,
        error:         error,                          // null clears error
        lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      );

  bool get hasDevices => devices.isNotEmpty;
  int  get deviceCount => devices.length;
  List<LiveSensorReading> get deviceList =>
      devices.values.toList()
        ..sort((a, b) => a.deviceId.compareTo(b.deviceId));
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class IoTLiveNotifier extends StateNotifier<IoTLiveState> {
  IoTLiveNotifier() : super(const IoTLiveState()) {
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 5);
  Timer? _timer;

  /// Start the 5-second polling loop
  void _startPolling() {
    _timer?.cancel();
    refresh(); // immediate fetch
    _timer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');

      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated. Please log in.',
        );
        return;
      }

      final uri = Uri.parse(ApiConfig.iotLiveLatest);
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept':        'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final Map<String, LiveSensorReading> parsed = {};
        for (final entry in body.entries) {
          if (entry.value is Map<String, dynamic>) {
            parsed[entry.key] = LiveSensorReading.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }
        state = state.copyWith(
          devices:       parsed,
          isLoading:     false,
          lastRefreshed: DateTime.now(),
        );
      } else if (response.statusCode == 401) {
        state = state.copyWith(
          isLoading: false,
          error: 'Session expired. Please log in again.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Server error (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Connection failed: $e',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final iotLiveProvider =
    StateNotifierProvider<IoTLiveNotifier, IoTLiveState>(
  (ref) => IoTLiveNotifier(),
);
