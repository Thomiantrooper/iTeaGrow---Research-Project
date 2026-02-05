import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../domain/models/esp32_sensor_data.dart';

/// WebSocket Service for iTeaGrow Bridge Server (Cross-Platform)
///
/// Connects to the Python bridge server that reads ESP32 data via serial port.
/// Works on both Android and Web.
class WebSocketSensorService {
  WebSocketChannel? _channel;
  final _sensorDataController = StreamController<ESP32SensorData>.broadcast();
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String _serverUrl =
      'ws://10.0.2.2:8765'; // Default to Android emulator localhost
  bool _isConnected = false;
  bool _shouldReconnect = true;

  Stream<ESP32SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  /// Connect to the WebSocket bridge server
  Future<bool> connect({String? url}) async {
    if (url != null) {
      _serverUrl = url;
    }

    _shouldReconnect = true;
    _connectionStateController.add(WebSocketConnectionState.connecting);

    try {
      // Close existing connection if any
      _closeSocket();

      // Create WebSocket using web_socket_channel
      final uri = Uri.parse(_serverUrl);
      _channel = WebSocketChannel.connect(uri);

      print('Connecting to $_serverUrl...');

      // Listen to the stream
      _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            print('WebSocket connected to $_serverUrl');
            _isConnected = true;
            _connectionStateController.add(WebSocketConnectionState.connected);
            _startHeartbeat();

            // Request initial data
            Future.delayed(const Duration(milliseconds: 300), () {
              requestData();
            });
          }
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
          _connectionStateController.add(WebSocketConnectionState.error);
        },
        onDone: () {
          print('WebSocket closed');
          _handleDisconnection();
        },
      );

      // Assume connected for now if no immediate error
      // A better approach depends on waiting for the first ping/pong or open event
      // but generic WebSocketChannel doesn't strictly have "onOpen" like html.WebSocket

      return true;
    } catch (e) {
      print('WebSocket connection failed: $e');
      _connectionStateController.add(WebSocketConnectionState.error);
      _isConnected = false;
      _scheduleReconnect();
      return false;
    }
  }

  /// Close WebSocket
  void _closeSocket() {
    if (_channel != null) {
      try {
        _channel!.sink.close(status.goingAway);
      } catch (e) {
        // Ignore close errors
      }
      _channel = null;
    }
    _isConnected = false;
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;

      if (type == 'sensor_data') {
        final sensorJson = data['data'] as Map<String, dynamic>;
        final connected = data['connected'] as bool? ?? false;

        if (connected && sensorJson['temperature'] != null) {
          final sensorData = ESP32SensorData(
            temperature: (sensorJson['temperature'] as num).toDouble(),
            humidity: (sensorJson['humidity'] as num).toDouble(),
            airQuality: sensorJson['airQuality'] as int? ?? 0,
            motionDetected: sensorJson['motionDetected'] as bool? ?? false,
            timestamp:
                DateTime.tryParse(sensorJson['timestamp'] as String? ?? '') ??
                    DateTime.now(),
          );

          _sensorDataController.add(sensorData);
          //  print('Received sensor data: T=${sensorData.temperature}, H=${sensorData.humidity}');
        }
      } else if (type == 'status') {
        final connected = data['connected'] as bool? ?? false;
        if (!connected) {
          _connectionStateController
              .add(WebSocketConnectionState.bridgeDisconnected);
        }
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _connectionStateController.add(WebSocketConnectionState.disconnected);

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldReconnect && !_isConnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        requestStatus();
      }
    });
  }

  /// Request current sensor data
  void requestData() {
    _sendCommand('get_data');
  }

  /// Request connection status
  void requestStatus() {
    _sendCommand('get_status');
  }

  /// Send command to bridge server
  void _sendCommand(String command) {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add(jsonEncode({'command': command}));
      } catch (e) {
        print('Error sending command: $e');
      }
    }
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _closeSocket();
    _connectionStateController.add(WebSocketConnectionState.disconnected);
  }

  /// Update server URL
  void setServerUrl(String url) {
    _serverUrl = url;
  }

  /// Dispose resources
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _closeSocket();
    _sensorDataController.close();
    _connectionStateController.close();
  }
}

/// WebSocket connection states
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  bridgeDisconnected,
}

/// Provider for WebSocket sensor service
final webSocketSensorServiceProvider = Provider<WebSocketSensorService>((ref) {
  final service = WebSocketSensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
