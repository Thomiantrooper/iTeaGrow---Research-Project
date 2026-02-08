import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/services/esp32_bluetooth_service.dart';
import '../../data/services/websocket_sensor_service.dart';
import '../../domain/models/esp32_sensor_data.dart';

/// Connection mode for ESP32
enum ConnectionMode {
  bluetooth,  // BLE - only works with BLE devices
  websocket,  // WebSocket bridge - works with USB/Bluetooth Classic
}

/// State for ESP32 sensor data
class ESP32SensorState {
  final ESP32SensorData? currentData;
  final List<ESP32SensorData> dataHistory;
  final ESP32ConnectionState connectionState;
  final String? errorMessage;
  final BluetoothDevice? connectedDevice;
  final List<ScanResult> availableDevices;
  final bool isScanning;
  final ConnectionMode connectionMode;
  final String serverUrl;

  const ESP32SensorState({
    this.currentData,
    this.dataHistory = const [],
    this.connectionState = ESP32ConnectionState.disconnected,
    this.errorMessage,
    this.connectedDevice,
    this.availableDevices = const [],
    this.isScanning = false,
    this.connectionMode = ConnectionMode.websocket,
    this.serverUrl = 'ws://localhost:8765',
  });

  ESP32SensorState copyWith({
    ESP32SensorData? currentData,
    List<ESP32SensorData>? dataHistory,
    ESP32ConnectionState? connectionState,
    String? errorMessage,
    BluetoothDevice? connectedDevice,
    List<ScanResult>? availableDevices,
    bool? isScanning,
    ConnectionMode? connectionMode,
    String? serverUrl,
  }) {
    return ESP32SensorState(
      currentData: currentData ?? this.currentData,
      dataHistory: dataHistory ?? this.dataHistory,
      connectionState: connectionState ?? this.connectionState,
      errorMessage: errorMessage,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      availableDevices: availableDevices ?? this.availableDevices,
      isScanning: isScanning ?? this.isScanning,
      connectionMode: connectionMode ?? this.connectionMode,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  bool get isConnected => connectionState == ESP32ConnectionState.connected;

  String get connectionStatusText {
    switch (connectionState) {
      case ESP32ConnectionState.disconnected:
        return 'Disconnected';
      case ESP32ConnectionState.scanning:
        return 'Scanning...';
      case ESP32ConnectionState.connecting:
        return 'Connecting...';
      case ESP32ConnectionState.connected:
        return connectionMode == ConnectionMode.websocket ? 'Connected (Bridge)' : 'Connected (BLE)';
      case ESP32ConnectionState.error:
        return 'Error';
    }
  }
}

/// Provider for managing ESP32 sensor state
class ESP32SensorNotifier extends StateNotifier<ESP32SensorState> {
  final ESP32BluetoothService _bluetoothService;
  final WebSocketSensorService _websocketService;

  StreamSubscription<ESP32SensorData>? _bleDataSubscription;
  StreamSubscription<ESP32ConnectionState>? _bleConnectionSubscription;
  StreamSubscription<ESP32SensorData>? _wsDataSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsConnectionSubscription;

  static const int maxHistorySize = 100;

  ESP32SensorNotifier(this._bluetoothService, this._websocketService)
      : super(const ESP32SensorState()) {
    _initWebSocketSubscriptions();
  }

  void _initBleSubscriptions() {
    _bleDataSubscription?.cancel();
    _bleConnectionSubscription?.cancel();

    _bleDataSubscription = _bluetoothService.sensorDataStream.listen(_handleSensorData);
    _bleConnectionSubscription = _bluetoothService.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });
  }

  void _initWebSocketSubscriptions() {
    _wsDataSubscription?.cancel();
    _wsConnectionSubscription?.cancel();

    _wsDataSubscription = _websocketService.sensorDataStream.listen(_handleSensorData);
    _wsConnectionSubscription = _websocketService.connectionStateStream.listen((wsState) {
      ESP32ConnectionState connState;
      switch (wsState) {
        case WebSocketConnectionState.disconnected:
          connState = ESP32ConnectionState.disconnected;
          break;
        case WebSocketConnectionState.connecting:
          connState = ESP32ConnectionState.connecting;
          break;
        case WebSocketConnectionState.connected:
          connState = ESP32ConnectionState.connected;
          break;
        case WebSocketConnectionState.error:
        case WebSocketConnectionState.bridgeDisconnected:
          connState = ESP32ConnectionState.error;
          break;
      }
      state = state.copyWith(connectionState: connState);
    });
  }

  void _handleSensorData(ESP32SensorData data) {
    final history = [...state.dataHistory, data];
    if (history.length > maxHistorySize) {
      history.removeAt(0);
    }
    state = state.copyWith(
      currentData: data,
      dataHistory: history,
    );
  }

  /// Set connection mode
  void setConnectionMode(ConnectionMode mode) {
    if (state.connectionMode != mode) {
      disconnect();
      state = state.copyWith(connectionMode: mode);

      if (mode == ConnectionMode.bluetooth) {
        _initBleSubscriptions();
      } else {
        _initWebSocketSubscriptions();
      }
    }
  }

  /// Set WebSocket server URL
  void setServerUrl(String url) {
    state = state.copyWith(serverUrl: url);
    _websocketService.setServerUrl(url);
  }

  /// Connect via WebSocket bridge (recommended for USB/Bluetooth Classic)
  Future<bool> connectViaBridge({String? url}) async {
    setConnectionMode(ConnectionMode.websocket);

    state = state.copyWith(
      connectionState: ESP32ConnectionState.connecting,
      errorMessage: null,
    );

    final serverUrl = url ?? state.serverUrl;
    final success = await _websocketService.connect(url: serverUrl);

    if (success) {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.connected,
        serverUrl: serverUrl,
      );
    } else {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.error,
        errorMessage: 'Failed to connect to bridge server',
      );
    }

    return success;
  }

  /// Scan for available BLE devices
  Future<void> scanForDevices() async {
    setConnectionMode(ConnectionMode.bluetooth);

    state = state.copyWith(
      isScanning: true,
      connectionState: ESP32ConnectionState.scanning,
      errorMessage: null,
    );

    try {
      final devices = await _bluetoothService.scanForDevices();
      state = state.copyWith(
        availableDevices: devices,
        isScanning: false,
        connectionState: ESP32ConnectionState.disconnected,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        connectionState: ESP32ConnectionState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Connect to a specific BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    state = state.copyWith(
      connectionState: ESP32ConnectionState.connecting,
      errorMessage: null,
    );

    final success = await _bluetoothService.connectToDevice(device);

    if (success) {
      state = state.copyWith(
        connectedDevice: device,
        connectionState: ESP32ConnectionState.connected,
      );
    } else {
      state = state.copyWith(
        connectionState: ESP32ConnectionState.error,
        errorMessage: 'Failed to connect to device',
      );
    }

    return success;
  }

  /// Disconnect from current connection
  Future<void> disconnect() async {
    if (state.connectionMode == ConnectionMode.bluetooth) {
      await _bluetoothService.disconnect();
    } else {
      await _websocketService.disconnect();
    }

    state = state.copyWith(
      connectedDevice: null,
      connectionState: ESP32ConnectionState.disconnected,
      currentData: null,
    );
  }

  /// Request immediate data update
  Future<void> requestData() async {
    if (state.connectionMode == ConnectionMode.bluetooth) {
      await _bluetoothService.requestData();
    } else {
      _websocketService.requestData();
    }
  }

  /// Clear data history
  void clearHistory() {
    state = state.copyWith(dataHistory: []);
  }

  @override
  void dispose() {
    _bleDataSubscription?.cancel();
    _bleConnectionSubscription?.cancel();
    _wsDataSubscription?.cancel();
    _wsConnectionSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for ESP32 sensor state
final esp32SensorProvider =
    StateNotifierProvider<ESP32SensorNotifier, ESP32SensorState>((ref) {
  final bluetoothService = ref.watch(esp32BluetoothServiceProvider);
  final websocketService = ref.watch(webSocketSensorServiceProvider);
  return ESP32SensorNotifier(bluetoothService, websocketService);
});

/// Provider for current sensor data (convenience)
final currentSensorDataProvider = Provider<ESP32SensorData?>((ref) {
  return ref.watch(esp32SensorProvider).currentData;
});

/// Provider for connection state (convenience)
final esp32ConnectionStateProvider = Provider<ESP32ConnectionState>((ref) {
  return ref.watch(esp32SensorProvider).connectionState;
});

/// Provider for checking if ESP32 is connected
final isESP32ConnectedProvider = Provider<bool>((ref) {
  return ref.watch(esp32SensorProvider).isConnected;
});
