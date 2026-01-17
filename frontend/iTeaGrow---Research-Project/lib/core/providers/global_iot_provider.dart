import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/iot_connectivity/data/services/websocket_sensor_service.dart';
import '../../features/iot_connectivity/domain/models/esp32_sensor_data.dart';

/// Global IoT State that persists across the entire app
class GlobalIoTState {
  final bool isConnected;
  final WebSocketConnectionState connectionState;
  final ESP32SensorData? latestData;
  final String serverUrl;
  final DateTime? lastUpdated;

  const GlobalIoTState({
    this.isConnected = false,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.latestData,
    this.serverUrl = 'ws://localhost:8765',
    this.lastUpdated,
  });

  GlobalIoTState copyWith({
    bool? isConnected,
    WebSocketConnectionState? connectionState,
    ESP32SensorData? latestData,
    String? serverUrl,
    DateTime? lastUpdated,
  }) {
    return GlobalIoTState(
      isConnected: isConnected ?? this.isConnected,
      connectionState: connectionState ?? this.connectionState,
      latestData: latestData ?? this.latestData,
      serverUrl: serverUrl ?? this.serverUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Convenient getters for sensor values
  double get temperature => latestData?.temperature ?? 0.0;
  double get humidity => latestData?.humidity ?? 0.0;
  int get airQuality => latestData?.airQuality ?? 0;
  bool get hasData => latestData != null;
}

/// Global IoT Notifier that manages WebSocket connection across the app
class GlobalIoTNotifier extends StateNotifier<GlobalIoTState> {
  final WebSocketSensorService _wsService;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;
  StreamSubscription<ESP32SensorData>? _dataSubscription;

  GlobalIoTNotifier(this._wsService) : super(const GlobalIoTState()) {
    _initializeListeners();
  }

  void _initializeListeners() {
    // Listen to connection state changes
    _connectionSubscription = _wsService.connectionStateStream.listen((connectionState) {
      state = state.copyWith(
        connectionState: connectionState,
        isConnected: connectionState == WebSocketConnectionState.connected,
      );
    });

    // Listen to sensor data
    _dataSubscription = _wsService.sensorDataStream.listen((data) {
      state = state.copyWith(
        latestData: data,
        lastUpdated: DateTime.now(),
      );
    });

    // Set initial state
    state = state.copyWith(
      isConnected: _wsService.isConnected,
      connectionState: _wsService.isConnected
          ? WebSocketConnectionState.connected
          : WebSocketConnectionState.disconnected,
      serverUrl: _wsService.serverUrl,
    );
  }

  /// Connect to WebSocket server
  Future<bool> connect({String? url}) async {
    if (url != null) {
      state = state.copyWith(serverUrl: url);
    }

    state = state.copyWith(connectionState: WebSocketConnectionState.connecting);

    final success = await _wsService.connect(url: url ?? state.serverUrl);

    return success;
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    await _wsService.disconnect();
    state = state.copyWith(
      isConnected: false,
      connectionState: WebSocketConnectionState.disconnected,
    );
  }

  /// Request latest data from server
  void requestData() {
    _wsService.requestData();
  }

  /// Update server URL
  void setServerUrl(String url) {
    state = state.copyWith(serverUrl: url);
    _wsService.setServerUrl(url);
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }
}

/// Global IoT Provider - Use this throughout the app for persistent IoT connection
final globalIoTProvider = StateNotifierProvider<GlobalIoTNotifier, GlobalIoTState>((ref) {
  final wsService = ref.watch(webSocketSensorServiceProvider);
  return GlobalIoTNotifier(wsService);
});

/// Convenience provider for just the latest sensor data
final latestSensorDataProvider = Provider<ESP32SensorData?>((ref) {
  return ref.watch(globalIoTProvider).latestData;
});

/// Convenience provider for connection state
final iotConnectionStateProvider = Provider<WebSocketConnectionState>((ref) {
  return ref.watch(globalIoTProvider).connectionState;
});

/// Convenience provider for live temperature
final liveTemperatureProvider = Provider<double>((ref) {
  return ref.watch(globalIoTProvider).temperature;
});

/// Convenience provider for live humidity
final liveHumidityProvider = Provider<double>((ref) {
  return ref.watch(globalIoTProvider).humidity;
});

/// Convenience provider for live air quality
final liveAirQualityProvider = Provider<int>((ref) {
  return ref.watch(globalIoTProvider).airQuality;
});
