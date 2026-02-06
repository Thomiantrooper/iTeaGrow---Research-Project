import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_iot_service.dart';

/// Bluetooth IoT Sensor Widget
///
/// Shows:
/// - Connection status
/// - Real-time sensor readings
/// - Offline data sync status
/// - Device selection
class BluetoothSensorWidget extends StatefulWidget {
  final String? backendUrl;

  const BluetoothSensorWidget({
    super.key,
    this.backendUrl,
  });

  @override
  State<BluetoothSensorWidget> createState() => _BluetoothSensorWidgetState();
}

class _BluetoothSensorWidgetState extends State<BluetoothSensorWidget> {
  final BluetoothIoTService _bleService = BluetoothIoTService();

  bool _isScanning = false;
  bool _isSyncing = false;
  List<ScanResult> _availableDevices = [];
  SensorData? _latestData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _bleService.initialize(backendUrl: widget.backendUrl);

    _bleService.onDataReceived = (data) {
      setState(() {
        _latestData = data;
        _errorMessage = null;
      });
    };

    _bleService.onDeviceConnected = (device) {
      setState(() {
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.platformName}'),
          backgroundColor: Colors.green,
        ),
      );
    };

    _bleService.onDeviceDisconnected = () {
      setState(() {
        _latestData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sensor disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    };

    _bleService.onError = (error) {
      setState(() {
        _errorMessage = error;
      });
    };
  }

  Future<void> _scanForDevices() async {
    if (!(await _bleService.isBluetoothAvailable())) {
      setState(() {
        _errorMessage = 'Please turn on Bluetooth';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    final devices = await _bleService.scanForDevices();

    setState(() {
      _availableDevices = devices;
      _isScanning = false;
    });

    if (devices.isEmpty) {
      setState(() {
        _errorMessage = 'No sensors found. Make sure your ESP32 is powered on.';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final success = await _bleService.connectToDevice(device);
    if (!success) {
      setState(() {
        _errorMessage = 'Failed to connect';
      });
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    final result = await _bleService.syncOfflineData();

    if (!mounted) return;

    setState(() {
      _isSyncing = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced ${result.synced} readings'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _bleService.isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth,
                  color: _bleService.isConnected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'IoT Sensors',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Offline indicator
                if (_bleService.pendingDataCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_bleService.pendingDataCount} pending',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // Connected device info
            if (_bleService.isConnected) ...[
              Text(
                'Connected: ${_bleService.connectedDeviceName}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),

              // Sensor readings
              if (_latestData != null) _buildSensorReadings(),
            ],

            // Available devices list
            if (_availableDevices.isNotEmpty && !_bleService.isConnected) ...[
              const Text('Available Sensors:'),
              const SizedBox(height: 8),
              ..._availableDevices.map(
              (result) => ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(
                  result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : 'Unknown Device',
                ),
                subtitle: Text('Signal: ${result.rssi} dBm'),
                trailing: ElevatedButton(
                  onPressed: () => _connectToDevice(result.device),
                  child: const Text('Connect'),
                ),
              ),
            ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Scan button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanForDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isScanning ? 'Scanning...' : 'Scan'),
                  ),
                ),
                const SizedBox(width: 8),

                // Sync button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _bleService.pendingDataCount > 0 && !_isSyncing
                        ? _syncData
                        : null,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                // Disconnect button
                if (_bleService.isConnected) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _bleService.disconnect(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Disconnect',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorReadings() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildReadingTile(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: _latestData?.temperature != null
                    ? '${_latestData!.temperature!.toStringAsFixed(1)}°C'
                    : '--',
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              _buildReadingTile(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: _latestData?.humidity != null
                    ? '${_latestData!.humidity!.toStringAsFixed(1)}%'
                    : '--',
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildReadingTile(
                icon: Icons.grass,
                label: 'Soil Moisture',
                value: _latestData?.soilMoisture != null
                    ? '${_latestData!.soilMoisture!.toStringAsFixed(1)}%'
                    : '--',
                color: Colors.brown,
              ),
              const SizedBox(width: 16),
              _buildReadingTile(
                icon: Icons.light_mode,
                label: 'Light',
                value: _latestData?.lightLevel != null
                    ? '${_latestData!.lightLevel!.toStringAsFixed(0)} lux'
                    : '--',
                color: Colors.orange,
              ),
            ],
          ),
          if (_latestData?.batteryLevel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _latestData!.batteryLevel! > 20
                      ? Icons.battery_full
                      : Icons.battery_alert,
                  color: _latestData!.batteryLevel! > 20
                      ? Colors.green
                      : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Battery: ${_latestData!.batteryLevel}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _latestData!.batteryLevel! > 20
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadingTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

