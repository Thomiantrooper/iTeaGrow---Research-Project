import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_config.dart';

/// WiFi Sensor Service for connecting to ESP32 on local network.
///
/// Supports:
/// - Direct HTTP polling to ESP32 on same WiFi network
/// - ESP32 hotspot mode (connect to iTeaGrow-XXXX SSID)
/// - Manual IP entry or auto-discovery
/// - Data submission to backend for storage
class WiFiSensorService {
  String? _deviceIp;
  int _devicePort = 80;
  Timer? _pollingTimer;
  bool _isConnected = false;
  bool _isPolling = false;

  final _sensorDataController = StreamController<WiFiSensorData>.broadcast();
  final _connectionStateController =
      StreamController<WiFiConnectionState>.broadcast();

  Stream<WiFiSensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<WiFiConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _isConnected;
  String? get deviceIp => _deviceIp;

  /// Connect to an ESP32 device via WiFi by IP address.
  Future<bool> connectToDevice(String ipAddress, {int port = 80}) async {
    _connectionStateController.add(WiFiConnectionState.connecting);

    try {
      // Verify device is reachable
      final statusUrl = 'http://$ipAddress:$port/sensor/status';
      final response = await http
          .get(Uri.parse(statusUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _deviceIp = ipAddress;
        _devicePort = port;
        _isConnected = true;
        _connectionStateController.add(WiFiConnectionState.connected);

        // Register device with backend
        _registerDevice(ipAddress);

        return true;
      }
    } catch (e) {
      // Try alternate data endpoint
      try {
        final dataUrl = 'http://$ipAddress:$port/sensor/data';
        final response = await http
            .get(Uri.parse(dataUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          _deviceIp = ipAddress;
          _devicePort = port;
          _isConnected = true;
          _connectionStateController.add(WiFiConnectionState.connected);
          _registerDevice(ipAddress);
          return true;
        }
      } catch (_) {}
    }

    _connectionStateController.add(WiFiConnectionState.error);
    return false;
  }

  /// Start polling the ESP32 for sensor data.
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    if (!_isConnected || _deviceIp == null) return;

    _isPolling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => _fetchSensorData());

    // Fetch immediately
    _fetchSensorData();
  }

  /// Stop polling.
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch sensor data from ESP32 via HTTP.
  Future<WiFiSensorData?> _fetchSensorData() async {
    if (_deviceIp == null) return null;

    try {
      final url = 'http://$_deviceIp:$_devicePort/sensor/data';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = WiFiSensorData.fromJson(json);
        _sensorDataController.add(data);
        return data;
      }
    } catch (e) {
      // Device may have disconnected
      if (_isConnected) {
        _isConnected = false;
        _connectionStateController.add(WiFiConnectionState.disconnected);
        stopPolling();
      }
    }
    return null;
  }

  /// Fetch sensor data once (manual refresh).
  Future<WiFiSensorData?> fetchOnce() async {
    return _fetchSensorData();
  }

  /// Register the WiFi device with the backend.
  Future<void> _registerDevice(String ipAddress) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.effectiveBaseUrl}/api/v1/wifi/devices/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': 'wifi_$ipAddress',
          'device_name': 'iTeaGrow WiFi Sensor',
          'ip_address': ipAddress,
          'device_type': 'esp32_wifi',
        }),
      );
    } catch (_) {
      // Backend registration is best-effort
    }
  }

  /// Submit data to backend for cloud storage.
  Future<bool> syncToBackend(WiFiSensorData data, {String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.effectiveBaseUrl}/api/v1/wifi/data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': data.deviceId ?? 'wifi_${_deviceIp ?? "unknown"}',
          'temperature': data.temperature,
          'humidity': data.humidity,
          'soil_moisture': data.soilMoisture,
          'rainfall': data.rainfall,
          'light_level': data.lightLevel,
          'battery_level': data.batteryLevel,
          'wifi_rssi': data.wifiRssi,
          'timestamp': data.timestamp.toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Disconnect from the current device.
  void disconnect() {
    stopPolling();
    _isConnected = false;
    _deviceIp = null;
    _connectionStateController.add(WiFiConnectionState.disconnected);
  }

  void dispose() {
    stopPolling();
    _sensorDataController.close();
    _connectionStateController.close();
  }
}

/// WiFi connection state.
enum WiFiConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// WiFi sensor data model.
class WiFiSensorData {
  final String? deviceId;
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? rainfall;
  final double? lightLevel;
  final int? batteryLevel;
  final int? wifiRssi;
  final DateTime timestamp;

  WiFiSensorData({
    this.deviceId,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.rainfall,
    this.lightLevel,
    this.batteryLevel,
    this.wifiRssi,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WiFiSensorData.fromJson(Map<String, dynamic> json) {
    return WiFiSensorData(
      deviceId: json['device_id'] as String?,
      temperature: (json['temperature'] ?? json['temp'] as num?)?.toDouble(),
      humidity: (json['humidity'] ?? json['hum'] as num?)?.toDouble(),
      soilMoisture:
          (json['soil_moisture'] ?? json['soil'] as num?)?.toDouble(),
      rainfall: (json['rainfall'] ?? json['rain'] as num?)?.toDouble(),
      lightLevel: (json['light_level'] ?? json['light'] as num?)?.toDouble(),
      batteryLevel: json['battery_level'] ?? json['bat'] as int?,
      wifiRssi: json['wifi_rssi'] ?? json['rssi'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'soil_moisture': soilMoisture,
        'rainfall': rainfall,
        'light_level': lightLevel,
        'battery_level': batteryLevel,
        'wifi_rssi': wifiRssi,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Provider for WiFi Sensor Service.
final wifiSensorServiceProvider = Provider<WiFiSensorService>((ref) {
  final service = WiFiSensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
