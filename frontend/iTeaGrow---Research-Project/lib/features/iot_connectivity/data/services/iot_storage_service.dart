import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_config.dart';
import '../../domain/models/esp32_sensor_data.dart';

/// Service for storing IoT sensor readings to MongoDB backend
/// Stores cumulative readings every 30 minutes
class IoTStorageService {
  static final IoTStorageService _instance = IoTStorageService._internal();
  factory IoTStorageService() => _instance;
  IoTStorageService._internal();

  Timer? _storageTimer;
  String? _authToken;
  String? _deviceId;

  // Store readings for averaging
  final List<ESP32SensorData> _readingsBuffer = [];
  DateTime? _lastStoredAt;

  // Callback for status updates
  Function(String message, bool isError)? onStatusUpdate;

  /// Storage interval in minutes (default 30)
  static const int storageIntervalMinutes = 30;

  /// Initialize the storage service with auth token and device ID
  void initialize({
    required String authToken,
    required String deviceId,
    Function(String, bool)? statusCallback,
  }) {
    _authToken = authToken;
    _deviceId = deviceId;
    onStatusUpdate = statusCallback;
    debugPrint('IoTStorageService initialized for device: $_deviceId');
  }

  /// Start automatic storage every 30 minutes
  void startAutoStorage() {
    stopAutoStorage(); // Stop any existing timer

    debugPrint('Starting IoT auto-storage every $storageIntervalMinutes minutes');
    _notifyStatus('IoT storage started (every $storageIntervalMinutes min)', false);

    // Store immediately if we have buffered data
    if (_readingsBuffer.isNotEmpty) {
      _storeAveragedReadings();
    }

    // Set up periodic storage
    _storageTimer = Timer.periodic(
      const Duration(minutes: storageIntervalMinutes),
      (_) => _storeAveragedReadings(),
    );
  }

  /// Stop automatic storage
  void stopAutoStorage() {
    _storageTimer?.cancel();
    _storageTimer = null;
    debugPrint('IoT auto-storage stopped');
  }

  /// Add a sensor reading to the buffer
  /// Call this whenever new sensor data arrives
  void addReading(ESP32SensorData data) {
    _readingsBuffer.add(data);

    // Keep buffer size reasonable (max 1000 readings)
    if (_readingsBuffer.length > 1000) {
      _readingsBuffer.removeRange(0, _readingsBuffer.length - 1000);
    }

    debugPrint('IoT reading added to buffer. Total: ${_readingsBuffer.length}');
  }

  /// Store averaged readings to the database
  Future<void> _storeAveragedReadings() async {
    if (_readingsBuffer.isEmpty) {
      debugPrint('No readings to store');
      return;
    }

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('No auth token - cannot store IoT data');
      _notifyStatus('Login required to store IoT data', true);
      return;
    }

    if (_deviceId == null || _deviceId!.isEmpty) {
      debugPrint('No device ID - cannot store IoT data');
      return;
    }

    try {
      // Calculate averages from buffer
      final avgData = _calculateAverages();

      debugPrint('Storing IoT data: temp=${avgData['temperature']}, humidity=${avgData['humidity']}');

      final response = await http.post(
        Uri.parse(ApiConfig.iotData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'device_id': _deviceId,
          'temperature': avgData['temperature'],
          'humidity': avgData['humidity'],
          'air_quality': avgData['air_quality'],
          'soil_moisture': avgData['soil_moisture'],
          'light_level': avgData['light_level'],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('IoT data stored successfully!');
        _notifyStatus('IoT data saved to database', false);

        // Clear buffer after successful storage
        _readingsBuffer.clear();
        _lastStoredAt = DateTime.now();
      } else {
        debugPrint('Failed to store IoT data: ${response.statusCode} - ${response.body}');
        _notifyStatus('Failed to save IoT data: ${response.statusCode}', true);
      }
    } catch (e) {
      debugPrint('Error storing IoT data: $e');
      _notifyStatus('Error saving IoT data: $e', true);
    }
  }

  /// Calculate average values from buffered readings
  Map<String, double?> _calculateAverages() {
    if (_readingsBuffer.isEmpty) {
      return {
        'temperature': null,
        'humidity': null,
        'air_quality': null,
        'soil_moisture': null,
        'light_level': null,
      };
    }

    double totalTemp = 0;
    double totalHumidity = 0;
    double totalAirQuality = 0;
    int count = _readingsBuffer.length;

    for (final reading in _readingsBuffer) {
      totalTemp += reading.temperature;
      totalHumidity += reading.humidity;
      totalAirQuality += reading.airQuality.toDouble();
    }

    return {
      'temperature': double.parse((totalTemp / count).toStringAsFixed(2)),
      'humidity': double.parse((totalHumidity / count).toStringAsFixed(2)),
      'air_quality': double.parse((totalAirQuality / count).toStringAsFixed(2)),
      'soil_moisture': null, // ESP32SensorData doesn't have soil moisture
      'light_level': null,   // ESP32SensorData doesn't have light level
    };
  }

  /// Force store current readings immediately
  Future<void> storeNow() async {
    await _storeAveragedReadings();
  }

  /// Get buffer statistics
  Map<String, dynamic> getBufferStats() {
    return {
      'readings_count': _readingsBuffer.length,
      'last_stored_at': _lastStoredAt?.toIso8601String(),
      'storage_interval_minutes': storageIntervalMinutes,
      'is_auto_storage_active': _storageTimer != null && _storageTimer!.isActive,
    };
  }

  void _notifyStatus(String message, bool isError) {
    onStatusUpdate?.call(message, isError);
  }

  /// Update auth token (e.g., after login)
  void updateAuthToken(String token) {
    _authToken = token;
  }

  /// Update device ID
  void updateDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Dispose resources
  void dispose() {
    stopAutoStorage();
    _readingsBuffer.clear();
  }
}
