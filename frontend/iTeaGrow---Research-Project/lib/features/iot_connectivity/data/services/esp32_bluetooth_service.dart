import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/esp32_sensor_data.dart';

/// ESP32 Bluetooth Service for iTeaGrow Environmental Monitor
///
/// This service connects to the ESP32 device via Bluetooth Classic (Serial Port Profile)
/// and parses the sensor data format: "T:21.8,H:81.4,A:663,M:1"
class ESP32BluetoothService {
  static const String deviceName = 'iTeaGrow';

  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<int>>? _dataSubscription;
  final _sensorDataController = StreamController<ESP32SensorData>.broadcast();
  final _connectionStateController = StreamController<ESP32ConnectionState>.broadcast();

  Stream<ESP32SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<ESP32ConnectionState> get connectionStateStream => _connectionStateController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _dataBuffer = '';

  /// Scan for iTeaGrow Bluetooth devices
  Future<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    final results = <ScanResult>[];

    // Check if Bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is not enabled. Please enable Bluetooth.');
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: timeout);

    // Listen for scan results
    final subscription = FlutterBluePlus.scanResults.listen((scanResults) {
      for (var result in scanResults) {
        if (result.device.platformName.contains(deviceName) ||
            result.advertisementData.advName.contains(deviceName)) {
          if (!results.any((r) => r.device.remoteId == result.device.remoteId)) {
            results.add(result);
          }
        }
      }
    });

    // Wait for scan to complete
    await Future.delayed(timeout);
    await subscription.cancel();
    await FlutterBluePlus.stopScan();

    return results;
  }

  /// Connect to a specific Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connectionStateController.add(ESP32ConnectionState.connecting);

      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();

      // Look for Serial Port Profile (SPP) or similar UART service
      // Common UUIDs for BLE UART:
      // Nordic UART Service: 6E400001-B5A3-F393-E0A9-E50E24DCCA9E
      // TX Characteristic: 6E400002-B5A3-F393-E0A9-E50E24DCCA9E
      // RX Characteristic: 6E400003-B5A3-F393-E0A9-E50E24DCCA9E

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            // Subscribe to notifications
            await characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.onValueReceived.listen(_handleDataReceived);
          }
        }
      }

      _isConnected = true;
      _connectionStateController.add(ESP32ConnectionState.connected);

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      return true;
    } catch (e) {
      _connectionStateController.add(ESP32ConnectionState.error);
      _isConnected = false;
      return false;
    }
  }

  /// Handle incoming data from ESP32
  void _handleDataReceived(List<int> data) {
    final receivedString = utf8.decode(data, allowMalformed: true);
    _dataBuffer += receivedString;

    // Process complete lines
    while (_dataBuffer.contains('\n')) {
      final newlineIndex = _dataBuffer.indexOf('\n');
      final line = _dataBuffer.substring(0, newlineIndex).trim();
      _dataBuffer = _dataBuffer.substring(newlineIndex + 1);

      if (line.isNotEmpty) {
        final sensorData = _parseDataLine(line);
        if (sensorData != null) {
          _sensorDataController.add(sensorData);
        }
      }
    }
  }

  /// Parse data line from ESP32
  /// Format: "T:21.8,H:81.4,A:663,M:1"
  ESP32SensorData? _parseDataLine(String line) {
    try {
      // Skip non-data lines
      if (!line.contains('T:') || !line.contains('H:')) {
        return null;
      }

      final parts = line.split(',');
      double? temperature;
      double? humidity;
      int? airQuality;
      int? motion;

      for (var part in parts) {
        final keyValue = part.trim().split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim();
          final value = keyValue[1].trim();

          switch (key) {
            case 'T':
              temperature = double.tryParse(value);
              break;
            case 'H':
              humidity = double.tryParse(value);
              break;
            case 'A':
              airQuality = int.tryParse(value);
              break;
            case 'M':
              motion = int.tryParse(value);
              break;
          }
        }
      }

      if (temperature != null && humidity != null) {
        return ESP32SensorData(
          temperature: temperature,
          humidity: humidity,
          airQuality: airQuality ?? 0,
          motionDetected: motion == 1,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      // Parsing error, return null
    }
    return null;
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectedDevice = null;
    _connectionStateController.add(ESP32ConnectionState.disconnected);
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _handleDisconnection();
  }

  /// Send command to ESP32
  Future<void> sendCommand(String command) async {
    if (_connectedDevice == null) return;

    final services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          await characteristic.write(utf8.encode('$command\n'));
          return;
        }
      }
    }
  }

  /// Request immediate data from ESP32
  Future<void> requestData() async {
    await sendCommand('data');
  }

  /// Request status from ESP32
  Future<void> requestStatus() async {
    await sendCommand('status');
  }

  /// Dispose the service
  void dispose() {
    _dataSubscription?.cancel();
    _sensorDataController.close();
    _connectionStateController.close();
    _connectedDevice?.disconnect();
  }
}

/// Connection state enum
enum ESP32ConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Provider for ESP32 Bluetooth Service
final esp32BluetoothServiceProvider = Provider<ESP32BluetoothService>((ref) {
  final service = ESP32BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});
