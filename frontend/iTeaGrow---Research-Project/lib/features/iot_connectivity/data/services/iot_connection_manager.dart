import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/models/esp32_sensor_data.dart';
import 'esp32_bluetooth_service.dart';
import 'wifi_sensor_service.dart';
import 'websocket_sensor_service.dart';

/// Unified IoT Connection Manager.
///
/// Manages BLE, WiFi, and WebSocket connections with priority:
/// 1. BLE (direct, lowest latency)
/// 2. WiFi (local network, reliable)
/// 3. WebSocket (cloud fallback, always available)
///
/// Provides a single unified stream of sensor data to the UI.
class IoTConnectionManager {
  final ESP32BluetoothService _bleService;
  final WiFiSensorService _wifiService;

  IoTConnectionType _activeConnection = IoTConnectionType.none;
  bool _autoReconnect = true;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  final _sensorDataController =
      StreamController<UnifiedSensorData>.broadcast();
  final _connectionStateController =
      StreamController<IoTConnectionInfo>.broadcast();

  StreamSubscription? _bleSubscription;
  StreamSubscription? _wifiSubscription;

  Stream<UnifiedSensorData> get sensorDataStream =>
      _sensorDataController.stream;
  Stream<IoTConnectionInfo> get connectionInfoStream =>
      _connectionStateController.stream;

  IoTConnectionType get activeConnectionType => _activeConnection;
  bool get isConnected => _activeConnection != IoTConnectionType.none;

  IoTConnectionManager({
    required ESP32BluetoothService bleService,
    required WiFiSensorService wifiService,
  })  : _bleService = bleService,
        _wifiService = wifiService;

  /// Try to connect via BLE first, then WiFi, then WebSocket.
  Future<bool> autoConnect({
    String? wifiIp,
    String? wsUrl,
  }) async {
    // Try BLE first
    final bleConnected = await _tryBleConnect();
    if (bleConnected) return true;

    // Try WiFi if IP provided
    if (wifiIp != null) {
      final wifiConnected = await _tryWifiConnect(wifiIp);
      if (wifiConnected) return true;
    }

    return false;
  }

  /// Connect specifically via BLE.
  Future<bool> connectViaBle(BluetoothDevice device) async {
    _emitState(IoTConnectionType.ble, IoTConnectionStatus.connecting);

    final success = await _bleService.connectToDevice(device);
    if (success) {
      _activeConnection = IoTConnectionType.ble;
      _reconnectAttempts = 0;
      _emitState(IoTConnectionType.ble, IoTConnectionStatus.connected);

      // Listen for BLE data
      _bleSubscription?.cancel();
      _bleSubscription = _bleService.sensorDataStream.listen((data) {
        _sensorDataController.add(UnifiedSensorData(
          temperature: data.temperature,
          humidity: data.humidity,
          airQuality: data.airQuality.toDouble(),
          timestamp: data.timestamp,
          connectionType: IoTConnectionType.ble,
        ));
      });

      // Listen for disconnection
      _bleService.connectionStateStream.listen((state) {
        if (state == ESP32ConnectionState.disconnected) {
          _handleDisconnection(IoTConnectionType.ble);
        }
      });

      return true;
    }

    _emitState(IoTConnectionType.ble, IoTConnectionStatus.failed);
    return false;
  }

  /// Connect specifically via WiFi.
  Future<bool> connectViaWifi(String ipAddress, {int port = 80}) async {
    _emitState(IoTConnectionType.wifi, IoTConnectionStatus.connecting);

    final success =
        await _wifiService.connectToDevice(ipAddress, port: port);
    if (success) {
      _activeConnection = IoTConnectionType.wifi;
      _reconnectAttempts = 0;
      _emitState(IoTConnectionType.wifi, IoTConnectionStatus.connected);

      // Start polling
      _wifiService.startPolling();

      // Listen for WiFi data
      _wifiSubscription?.cancel();
      _wifiSubscription = _wifiService.sensorDataStream.listen((data) {
        _sensorDataController.add(UnifiedSensorData(
          temperature: data.temperature,
          humidity: data.humidity,
          soilMoisture: data.soilMoisture,
          rainfall: data.rainfall,
          lightLevel: data.lightLevel,
          timestamp: data.timestamp,
          connectionType: IoTConnectionType.wifi,
        ));
      });

      // Listen for WiFi disconnection
      _wifiService.connectionStateStream.listen((state) {
        if (state == WiFiConnectionState.disconnected) {
          _handleDisconnection(IoTConnectionType.wifi);
        }
      });

      return true;
    }

    _emitState(IoTConnectionType.wifi, IoTConnectionStatus.failed);
    return false;
  }

  /// Disconnect from current connection.
  Future<void> disconnect() async {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _bleSubscription?.cancel();
    _wifiSubscription?.cancel();

    switch (_activeConnection) {
      case IoTConnectionType.ble:
        await _bleService.disconnect();
        break;
      case IoTConnectionType.wifi:
        _wifiService.disconnect();
        break;
      case IoTConnectionType.websocket:
      case IoTConnectionType.none:
        break;
    }

    _activeConnection = IoTConnectionType.none;
    _emitState(IoTConnectionType.none, IoTConnectionStatus.disconnected);
    _autoReconnect = true;
  }

  /// Handle disconnection with auto-reconnect.
  void _handleDisconnection(IoTConnectionType type) {
    if (_activeConnection == type) {
      _activeConnection = IoTConnectionType.none;
      _emitState(type, IoTConnectionStatus.disconnected);

      if (_autoReconnect &&
          _reconnectAttempts < _maxReconnectAttempts) {
        _scheduleReconnect(type);
      }
    }
  }

  /// Schedule auto-reconnect with exponential backoff.
  void _scheduleReconnect(IoTConnectionType type) {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    final delay = Duration(seconds: _reconnectAttempts * 2);
    _emitState(type, IoTConnectionStatus.reconnecting);

    _reconnectTimer = Timer(delay, () async {
      bool success = false;
      switch (type) {
        case IoTConnectionType.ble:
          success = await _tryBleConnect();
          break;
        case IoTConnectionType.wifi:
          if (_wifiService.deviceIp != null) {
            success = await _tryWifiConnect(_wifiService.deviceIp!);
          }
          break;
        default:
          break;
      }

      if (!success && _reconnectAttempts < _maxReconnectAttempts) {
        _scheduleReconnect(type);
      }
    });
  }

  Future<bool> _tryBleConnect() async {
    try {
      final results =
          await _bleService.scanForDevices(timeout: const Duration(seconds: 5));
      if (results.isNotEmpty) {
        return await connectViaBle(results.first.device);
      }
    } catch (_) {}
    return false;
  }

  Future<bool> _tryWifiConnect(String ip) async {
    return await connectViaWifi(ip);
  }

  void _emitState(IoTConnectionType type, IoTConnectionStatus status) {
    _connectionStateController.add(IoTConnectionInfo(
      type: type,
      status: status,
      reconnectAttempts: _reconnectAttempts,
    ));
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _bleSubscription?.cancel();
    _wifiSubscription?.cancel();
    _sensorDataController.close();
    _connectionStateController.close();
  }
}

/// Connection types.
enum IoTConnectionType { none, ble, wifi, websocket }

/// Connection status.
enum IoTConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Connection info for UI.
class IoTConnectionInfo {
  final IoTConnectionType type;
  final IoTConnectionStatus status;
  final int reconnectAttempts;

  IoTConnectionInfo({
    required this.type,
    required this.status,
    this.reconnectAttempts = 0,
  });
}

/// Unified sensor data from any connection type.
class UnifiedSensorData {
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? rainfall;
  final double? lightLevel;
  final double? airQuality;
  final int? batteryLevel;
  final DateTime timestamp;
  final IoTConnectionType connectionType;

  UnifiedSensorData({
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.rainfall,
    this.lightLevel,
    this.airQuality,
    this.batteryLevel,
    DateTime? timestamp,
    required this.connectionType,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Provider for IoT Connection Manager.
final iotConnectionManagerProvider = Provider<IoTConnectionManager>((ref) {
  final bleService = ref.watch(esp32BluetoothServiceProvider);
  final wifiService = ref.watch(wifiSensorServiceProvider);
  final manager = IoTConnectionManager(
    bleService: bleService,
    wifiService: wifiService,
  );
  ref.onDispose(() => manager.dispose());
  return manager;
});
