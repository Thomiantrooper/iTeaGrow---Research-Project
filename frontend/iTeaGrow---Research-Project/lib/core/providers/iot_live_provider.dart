import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveSensorReading &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId &&
          temperature == other.temperature &&
          humidity == other.humidity &&
          soilMoisture == other.soilMoisture &&
          airQuality == other.airQuality &&
          lightLevel == other.lightLevel &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      deviceId.hashCode ^
      temperature.hashCode ^
      humidity.hashCode ^
      soilMoisture.hashCode ^
      airQuality.hashCode ^
      lightLevel.hashCode ^
      timestamp.hashCode;

  factory LiveSensorReading.fromJson(Map<String, dynamic> json) {
    return LiveSensorReading(
      deviceId: json['device_id']?.toString() ?? 'unknown',
      temperature: _toDouble(json['temperature']),
      humidity: _toDouble(json['humidity']),
      soilMoisture: _toDouble(json['soil_moisture']),
      airQuality: _toDouble(json['air_quality']),
      lightLevel: _toDouble(json['light_level']),
      timestamp: json['timestamp'] != null
          ? _parseTimestamp(json['timestamp'].toString())
          : null,
    );
  }

  static DateTime? _parseTimestamp(String t) {
    if (!t.endsWith('Z')) t += 'Z'; // Force UTC interpretation from Railway
    final parsed = DateTime.tryParse(t);
    return parsed?.toLocal();
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
      timestamp != null ? DateTime.now().difference(timestamp!).inSeconds : -1;

  /// Human-readable "last seen" string
  String get lastSeenLabel {
    if (timestamp == null) return 'Unknown';
    final diff = DateTime.now().difference(timestamp!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Air-quality label (ppm-based rough scale)
  String get airQualityLabel {
    if (airQuality == null) return 'N/A';
    if (airQuality! < 400) return 'Excellent';
    if (airQuality! < 600) return 'Good';
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

  // DO NOT override == or hashCode - Riverpod needs to detect new instances
  // to trigger UI updates even when values haven't changed

  bool get hasDevices => devices.isNotEmpty;
  int get deviceCount => devices.length;
  List<LiveSensorReading> get deviceList {
    final list = devices.values.toList();
    list.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null)
        return a.deviceId.compareTo(b.deviceId);
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!); // Descending (newest first)
    });
    return list;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class IoTLiveNotifier extends StateNotifier<IoTLiveState> {
  IoTLiveNotifier() : super(const IoTLiveState()) {
    debugPrint('[IoTLive] Notifier created, starting polling...');
    _startPolling();
  }

  static const _pollInterval = Duration(seconds: 5);
  Timer? _timer;
  int _fetchCount = 0;

  /// Start the 5-second polling loop
  void _startPolling() {
    _timer?.cancel();
    debugPrint('[IoTLive] Polling started');
    refresh(); // immediate fetch
    _timer = Timer.periodic(_pollInterval, (_) {
      _fetchCount++;
      debugPrint('[IoTLive] Timer tick #$_fetchCount - fetching...');
      refresh();
    });
  }

  Future<void> refresh() async {
    // Create new loading state
    state = IoTLiveState(
      devices: state.devices,
      isLoading: true,
      error: state.error,
      lastRefreshed: state.lastRefreshed,
    );
    try {
      // Fetch all devices (deviceId is not supported in this simple provider refresh)
      final String baseUrl = ApiConfig.environmentalIotLiveLatest;
      final String apiUrl =
          '$baseUrl?_t=${DateTime.now().millisecondsSinceEpoch}';
      final uri = Uri.parse(apiUrl);
      
      debugPrint('[IoTLive] Fetching: $apiUrl');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          // Anti-caching headers for live IoT data
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('[IoTLive] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        debugPrint('[IoTLive] Decoded ${body.length} device(s)');
        
        final Map<String, LiveSensorReading> parsed = {};
        
        for (final entry in body.entries) {
          if (entry.value is Map<String, dynamic>) {
            final reading = LiveSensorReading.fromJson(
              entry.value as Map<String, dynamic>,
            );
            parsed[entry.key] = reading;
            debugPrint('[IoTLive] Device ${entry.key}: T=${reading.temperature}°C H=${reading.humidity}% AQ=${reading.airQuality} TS=${reading.timestamp}');
          }
        }
        
        final now = DateTime.now();
        final oldState = state;
        final oldHash = oldState.hashCode;
        final oldDeviceCount = oldState.devices.length;
        
        // Create new state - always notify even if values are the same
        final newState = IoTLiveState(
          devices: parsed,
          isLoading: false,
          lastRefreshed: now,
          error: null,
        );
        
        debugPrint('[IoTLive] OLD State: hash=$oldHash devices=$oldDeviceCount loading=${oldState.isLoading}');
        debugPrint('[IoTLive] NEW State: hash=${newState.hashCode} devices=${newState.devices.length} loading=${newState.isLoading}');
        
        state = newState;
        
        debugPrint('[IoTLive] ✓ State assigned! Current state hash: ${state.hashCode}');
        
        // Log if state actually changed
        if (oldDeviceCount > 0 && parsed.isNotEmpty) {
          final oldTemp = oldState.devices.values.first.temperature;
          final newTemp = parsed.values.first.temperature;
          final oldHum = oldState.devices.values.first.humidity;
          final newHum = parsed.values.first.humidity;
          debugPrint('[IoTLive] Values: T=$oldTemp→$newTemp H=$oldHum→$newHum');
        }
      } else if (response.statusCode == 401) {
        state = IoTLiveState(
          devices: state.devices,
          isLoading: false,
          error: 'Session expired. Please log in again.',
          lastRefreshed: state.lastRefreshed,
        );
      } else {
        state = IoTLiveState(
          devices: state.devices,
          isLoading: false,
          error: 'Server error (${response.statusCode})',
          lastRefreshed: state.lastRefreshed,
        );
      }
    } catch (e) {
      debugPrint('[IoTLive] Error: $e');
      state = IoTLiveState(
        devices: state.devices,
        isLoading: false,
        error: 'Connection failed: $e',
        lastRefreshed: state.lastRefreshed,
      );
    }
  }

  @override
  void dispose() {
    debugPrint('[IoTLive] Notifier disposed after $_fetchCount fetches, canceling timer');
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final iotLiveProvider = StateNotifierProvider<IoTLiveNotifier, IoTLiveState>(
  (ref) {
    debugPrint('[IoTLive] Provider instance created');
    // Keep provider alive to prevent disposal during navigation
    ref.keepAlive();
    return IoTLiveNotifier();
  },
);
