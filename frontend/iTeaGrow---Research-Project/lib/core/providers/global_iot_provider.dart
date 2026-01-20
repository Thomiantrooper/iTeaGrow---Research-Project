import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/iot_connectivity/data/services/websocket_sensor_service.dart';
import '../../features/iot_connectivity/data/services/iot_storage_service.dart';
import '../../features/iot_connectivity/domain/models/esp32_sensor_data.dart';

/// Global IoT State that persists across the entire app
class GlobalIoTState {
  final bool isConnected;
  final WebSocketConnectionState connectionState;
  final ESP32SensorData? latestData;
  final String serverUrl;
  final DateTime? lastUpdated;
  final bool isAutoStorageEnabled;
  final DateTime? lastStoredAt;
  final int bufferCount;

  const GlobalIoTState({
    this.isConnected = false,
    this.connectionState = WebSocketConnectionState.disconnected,
    this.latestData,
    this.serverUrl = 'ws://localhost:8765',
    this.lastUpdated,
    this.isAutoStorageEnabled = false,
    this.lastStoredAt,
    this.bufferCount = 0,
  });

  GlobalIoTState copyWith({
    bool? isConnected,
    WebSocketConnectionState? connectionState,
    ESP32SensorData? latestData,
    String? serverUrl,
    DateTime? lastUpdated,
    bool? isAutoStorageEnabled,
    DateTime? lastStoredAt,
    int? bufferCount,
  }) {
    return GlobalIoTState(
      isConnected: isConnected ?? this.isConnected,
      connectionState: connectionState ?? this.connectionState,
      latestData: latestData ?? this.latestData,
      serverUrl: serverUrl ?? this.serverUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isAutoStorageEnabled: isAutoStorageEnabled ?? this.isAutoStorageEnabled,
      lastStoredAt: lastStoredAt ?? this.lastStoredAt,
      bufferCount: bufferCount ?? this.bufferCount,
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
  final IoTStorageService _storageService = IoTStorageService();
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

      // Start auto-storage when connected (if auth is configured)
      if (connectionState == WebSocketConnectionState.connected && state.isAutoStorageEnabled) {
        _storageService.startAutoStorage();
      }
    });

    // Listen to sensor data and add to storage buffer
    _dataSubscription = _wsService.sensorDataStream.listen((data) {
      state = state.copyWith(
        latestData: data,
        lastUpdated: DateTime.now(),
        bufferCount: _storageService.getBufferStats()['readings_count'] as int? ?? 0,
      );

      // Add reading to storage buffer
      _storageService.addReading(data);
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
    _storageService.stopAutoStorage();
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

  /// Enable auto-storage to database every 30 minutes
  /// Requires auth token and device ID
  void enableAutoStorage({
    required String authToken,
    required String deviceId,
    Function(String, bool)? onStatusUpdate,
  }) {
    debugPrint('Enabling IoT auto-storage for device: $deviceId');

    _storageService.initialize(
      authToken: authToken,
      deviceId: deviceId,
      statusCallback: onStatusUpdate,
    );

    _storageService.startAutoStorage();

    state = state.copyWith(isAutoStorageEnabled: true);
  }

  /// Disable auto-storage
  void disableAutoStorage() {
    _storageService.stopAutoStorage();
    state = state.copyWith(isAutoStorageEnabled: false);
  }

  /// Update auth token for storage service
  void updateAuthToken(String token) {
    _storageService.updateAuthToken(token);
  }

  /// Force store current buffered readings immediately
  Future<void> storeReadingsNow() async {
    await _storageService.storeNow();
    final stats = _storageService.getBufferStats();
    state = state.copyWith(
      bufferCount: stats['readings_count'] as int? ?? 0,
      lastStoredAt: DateTime.tryParse(stats['last_stored_at'] ?? ''),
    );
  }

  /// Get storage buffer statistics
  Map<String, dynamic> getStorageStats() {
    return _storageService.getBufferStats();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _storageService.dispose();
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

/// Convenience provider for auto-storage status
final iotAutoStorageEnabledProvider = Provider<bool>((ref) {
  return ref.watch(globalIoTProvider).isAutoStorageEnabled;
});

/// Convenience provider for buffer count
final iotBufferCountProvider = Provider<int>((ref) {
  return ref.watch(globalIoTProvider).bufferCount;
});
