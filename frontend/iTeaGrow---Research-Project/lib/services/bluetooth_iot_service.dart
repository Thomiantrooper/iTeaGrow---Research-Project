import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../core/api/api_config.dart';

/// Bluetooth IoT Service for Tea Plantation Sensors
///
/// Features:
/// - Scan and connect to ESP32/Arduino BLE sensors
/// - Parse sensor data (temperature, humidity, soil moisture, light)
/// - Store data locally when offline
/// - Sync to backend when online
///
/// Works completely offline - syncs when network available
class BluetoothIoTService {
  // Singleton pattern
  static final BluetoothIoTService _instance = BluetoothIoTService._internal();
  factory BluetoothIoTService() => _instance;
  BluetoothIoTService._internal();

  // BLE UUIDs - Custom for tea plantation sensors
  static const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const String characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';

  // State
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _sensorCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;
  bool _isScanning = false;

  // Callbacks
  Function(SensorData)? onDataReceived;
  Function(BluetoothDevice)? onDeviceConnected;
  Function()? onDeviceDisconnected;
  Function(String)? onError;

  // Offline data storage
  final List<SensorData> _offlineQueue = [];
  static const int maxOfflineRecords = 1000;

  // Backend URL - uses API config for proper URL resolution
  String _backendUrl = '';

  /// Initialize the service
  Future<void> initialize({String? backendUrl}) async {
    _backendUrl = backendUrl ?? ApiConfig.effectiveBaseUrl;

    // Load offline queue from storage
    await _loadOfflineQueue();

    // Check Bluetooth status
    if (await FlutterBluePlus.isSupported == false) {
      onError?.call('Bluetooth not supported on this device');
      return;
    }

    // Listen to Bluetooth state changes
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        onError?.call('Bluetooth is turned off');
      }
    });
  }

  /// Check if Bluetooth is available and on
  Future<bool> isBluetoothAvailable() async {
    if (await FlutterBluePlus.isSupported == false) return false;
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  /// Turn on Bluetooth (Android only)
  Future<void> turnOnBluetooth() async {
    await FlutterBluePlus.turnOn();
  }

  /// Scan for tea plantation sensor devices
  Future<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) {
      await stopScan();
    }

    _isScanning = true;
    final List<ScanResult> devices = [];

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(serviceUuid)], // Only show our sensors
      );

      // Listen for results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // Filter by name prefix for tea sensors
          if (r.device.platformName.startsWith('TeaSensor') ||
              r.device.platformName.startsWith('iTeaGrow') ||
              r.advertisementData.serviceUuids.contains(Guid(serviceUuid))) {
            if (!devices.any((d) => d.device.remoteId == r.device.remoteId)) {
              devices.add(r);
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
    } finally {
      _isScanning = false;
      await stopScan();
    }

    return devices;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  /// Connect to a sensor device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // Disconnect from current device if connected
      await disconnect();

      // Connect with auto-reconnect
      await device.connect(
        timeout: const Duration(seconds: 30),
        autoConnect: true,
      );

      _connectedDevice = device;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find our custom service
      for (BluetoothService service in services) {
        if (service.uuid == Guid(serviceUuid)) {
          // Find sensor data characteristic
          for (BluetoothCharacteristic char in service.characteristics) {
            if (char.uuid == Guid(characteristicUuid)) {
              _sensorCharacteristic = char;

              // Enable notifications
              await char.setNotifyValue(true);

              // Listen for data
              _dataSubscription = char.lastValueStream.listen(_handleSensorData);

              onDeviceConnected?.call(device);
              return true;
            }
          }
        }
      }

      onError?.call('Sensor characteristic not found');
      return false;
    } catch (e) {
      onError?.call('Connection failed: $e');
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    _dataSubscription?.cancel();
    _dataSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // Ignore disconnect errors
      }
      _connectedDevice = null;
      _sensorCharacteristic = null;
      onDeviceDisconnected?.call();
    }
  }

  /// Handle incoming sensor data
  void _handleSensorData(List<int> data) {
    try {
      final sensorData = _parseSensorData(Uint8List.fromList(data));
      sensorData.deviceId = _connectedDevice?.remoteId.str ?? 'unknown';
      sensorData.deviceName = _connectedDevice?.platformName ?? 'Unknown Sensor';

      // Store locally
      _addToOfflineQueue(sensorData);

      // Notify listeners
      onDataReceived?.call(sensorData);

      // Try to sync in background
      _trySyncInBackground();
    } catch (e) {
      onError?.call('Error parsing sensor data: $e');
    }
  }

  /// Parse raw BLE data into SensorData
  SensorData _parseSensorData(Uint8List data) {
    if (data.length >= 17) {
      // Binary format from ESP32
      final buffer = ByteData.view(data.buffer);
      return SensorData(
        temperature: buffer.getFloat32(0, Endian.little),
        humidity: buffer.getFloat32(4, Endian.little),
        soilMoisture: buffer.getFloat32(8, Endian.little),
        lightLevel: buffer.getFloat32(12, Endian.little),
        batteryLevel: data[16],
        timestamp: DateTime.now(),
        collectedOffline: true,
      );
    } else {
      // Try JSON format
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr);
      return SensorData(
        temperature: (json['temp'] as num?)?.toDouble(),
        humidity: (json['hum'] as num?)?.toDouble(),
        soilMoisture: (json['soil'] as num?)?.toDouble(),
        lightLevel: (json['light'] as num?)?.toDouble(),
        batteryLevel: json['bat'] as int?,
        timestamp: DateTime.now(),
        collectedOffline: true,
      );
    }
  }

  /// Add data to offline queue
  void _addToOfflineQueue(SensorData data) {
    _offlineQueue.add(data);

    // Limit queue size
    if (_offlineQueue.length > maxOfflineRecords) {
      _offlineQueue.removeAt(0);
    }

    // Save to persistent storage
    _saveOfflineQueue();
  }

  /// Save offline queue to SharedPreferences
  Future<void> _saveOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _offlineQueue.map((d) => d.toJson()).toList();
    await prefs.setString('offline_sensor_data', jsonEncode(jsonList));
  }

  /// Load offline queue from SharedPreferences
  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('offline_sensor_data');
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      _offlineQueue.clear();
      _offlineQueue.addAll(jsonList.map((j) => SensorData.fromJson(j)));
    }
  }

  /// Try to sync data in background
  Future<void> _trySyncInBackground() async {
    if (_offlineQueue.isEmpty) return;

    try {
      final unsyncedData = _offlineQueue.where((d) => !d.synced).toList();
      if (unsyncedData.isEmpty) return;

      final response = await http.post(
        Uri.parse('$_backendUrl/api/v1/bluetooth/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'readings': unsyncedData.map((d) => d.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Mark as synced
        for (var data in unsyncedData) {
          data.synced = true;
        }
        await _saveOfflineQueue();
      }
    } catch (e) {
      // Network unavailable - will try again later
    }
  }

  /// Force sync all offline data
  Future<SyncResult> syncOfflineData() async {
    final unsyncedData = _offlineQueue.where((d) => !d.synced).toList();

    if (unsyncedData.isEmpty) {
      return SyncResult(synced: 0, failed: 0, total: 0);
    }

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/v1/bluetooth/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'readings': unsyncedData.map((d) => d.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Mark as synced
        for (var data in unsyncedData) {
          data.synced = true;
        }
        await _saveOfflineQueue();

        return SyncResult(
          synced: result['synced'] ?? unsyncedData.length,
          failed: result['failed'] ?? 0,
          total: result['total'] ?? unsyncedData.length,
        );
      } else {
        return SyncResult(
          synced: 0,
          failed: unsyncedData.length,
          total: unsyncedData.length,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return SyncResult(
        synced: 0,
        failed: unsyncedData.length,
        total: unsyncedData.length,
        error: e.toString(),
      );
    }
  }

  /// Get pending offline data count
  int get pendingDataCount => _offlineQueue.where((d) => !d.synced).length;

  /// Get all offline data
  List<SensorData> get offlineData => List.unmodifiable(_offlineQueue);

  /// Clear synced data from queue
  Future<void> clearSyncedData() async {
    _offlineQueue.removeWhere((d) => d.synced);
    await _saveOfflineQueue();
  }

  /// Read sensor data manually (one-time read)
  Future<SensorData?> readSensorData() async {
    if (_sensorCharacteristic == null) {
      onError?.call('Not connected to sensor');
      return null;
    }

    try {
      final data = await _sensorCharacteristic!.read();
      final sensorData = _parseSensorData(Uint8List.fromList(data));
      sensorData.deviceId = _connectedDevice?.remoteId.str ?? 'unknown';
      _addToOfflineQueue(sensorData);
      return sensorData;
    } catch (e) {
      onError?.call('Error reading sensor: $e');
      return null;
    }
  }

  /// Check if connected
  bool get isConnected => _connectedDevice != null;

  /// Get connected device name
  String? get connectedDeviceName => _connectedDevice?.platformName;

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    disconnect();
  }
}

/// Sensor data model
class SensorData {
  String deviceId;
  String? deviceName;
  double? temperature;
  double? humidity;
  double? soilMoisture;
  double? lightLevel;
  int? batteryLevel;
  int? rssi;
  DateTime timestamp;
  bool collectedOffline;
  bool synced;

  SensorData({
    this.deviceId = '',
    this.deviceName,
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.lightLevel,
    this.batteryLevel,
    this.rssi,
    DateTime? timestamp,
    this.collectedOffline = true,
    this.synced = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_name': deviceName,
        'temperature': temperature,
        'humidity': humidity,
        'soil_moisture': soilMoisture,
        'light_level': lightLevel,
        'battery_level': batteryLevel,
        'rssi': rssi,
        'timestamp': timestamp.toIso8601String(),
        'collected_offline': collectedOffline,
        'synced': synced,
      };

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
        deviceId: json['device_id'] ?? '',
        deviceName: json['device_name'],
        temperature: (json['temperature'] as num?)?.toDouble(),
        humidity: (json['humidity'] as num?)?.toDouble(),
        soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
        lightLevel: (json['light_level'] as num?)?.toDouble(),
        batteryLevel: json['battery_level'] as int?,
        rssi: json['rssi'] as int?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        collectedOffline: json['collected_offline'] ?? true,
        synced: json['synced'] ?? false,
      );
}

/// Sync result model
class SyncResult {
  final int synced;
  final int failed;
  final int total;
  final String? error;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.total,
    this.error,
  });

  bool get success => error == null && failed == 0;
}
