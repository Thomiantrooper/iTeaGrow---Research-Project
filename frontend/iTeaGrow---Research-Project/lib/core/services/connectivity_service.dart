import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Service to monitor internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Check internet connectivity by making a simple HTTP request
  Future<bool> checkConnectivity() async {
    try {
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      _isConnected = response.statusCode == 200;
      _connectivityController.add(_isConnected);
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _connectivityController.add(_isConnected);
      return false;
    }
  }

  /// Start periodic connectivity checks
  Timer? _timer;
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => checkConnectivity());
  }

  /// Stop periodic connectivity checks
  void stopMonitoring() {
    _timer?.cancel();
  }

  void dispose() {
    _timer?.cancel();
    _connectivityController.close();
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider for current connectivity status
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  service.checkConnectivity(); // Initial check
  return service.connectivityStream;
});
