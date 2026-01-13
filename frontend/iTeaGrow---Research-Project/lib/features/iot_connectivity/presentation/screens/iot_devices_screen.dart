import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/iot_models.dart';

class IoTDevicesScreen extends ConsumerStatefulWidget {
  const IoTDevicesScreen({super.key});

  @override
  ConsumerState<IoTDevicesScreen> createState() => _IoTDevicesScreenState();
}

class _IoTDevicesScreenState extends ConsumerState<IoTDevicesScreen> {
  bool _isScanning = false;
  String _selectedTab = 'bluetooth'; // 'bluetooth' or 'wifi'

  // Mock devices for demonstration
  final List<IoTDevice> _mockBluetoothDevices = [
    IoTDevice(
      id: 'bt_001',
      name: 'NPK Sensor - Field A',
      type: 'bluetooth',
      macAddress: 'AA:BB:CC:DD:EE:01',
      isConnected: true,
      signalStrength: -45,
      lastConnected: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    IoTDevice(
      id: 'bt_002',
      name: 'Soil Moisture Sensor',
      type: 'bluetooth',
      macAddress: 'AA:BB:CC:DD:EE:02',
      isConnected: false,
      signalStrength: -65,
      lastConnected: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final List<IoTDevice> _mockWiFiDevices = [
    IoTDevice(
      id: 'wifi_001',
      name: 'Weather Station',
      type: 'wifi',
      ipAddress: '192.168.1.100',
      isConnected: true,
      signalStrength: -50,
      lastConnected: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  void _startScanning() {
    setState(() => _isScanning = true);
    // Simulate scanning
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan complete - Ready for real device integration')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = _selectedTab == 'bluetooth' ? _mockBluetoothDevices : _mockWiFiDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? null : _startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Bluetooth',
                    icon: Icons.bluetooth,
                    isSelected: _selectedTab == 'bluetooth',
                    onTap: () => setState(() => _selectedTab = 'bluetooth'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TabButton(
                    label: 'Wi-Fi',
                    icon: Icons.wifi,
                    isSelected: _selectedTab == 'wifi',
                    onTap: () => setState(() => _selectedTab = 'wifi'),
                  ),
                ),
              ],
            ),
          ),

          // Scanning indicator
          if (_isScanning)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryGreen.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Text('Scanning for ${_selectedTab == 'bluetooth' ? 'Bluetooth' : 'Wi-Fi'} devices...'),
                ],
              ),
            ),

          // Device list
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 'bluetooth' ? Icons.bluetooth_disabled : Icons.wifi_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No devices found'),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap refresh to scan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return _DeviceCard(
                        device: device,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SensorReadingsScreen(device: device),
                            ),
                          );
                        },
                        onConnect: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                device.isConnected
                                    ? 'Disconnecting from ${device.name}'
                                    : 'Connecting to ${device.name}',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScanning,
        icon: const Icon(Icons.search),
        label: Text('Scan ${_selectedTab == 'bluetooth' ? 'Bluetooth' : 'Wi-Fi'}'),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final IoTDevice device;
  final VoidCallback onTap;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.device,
    required this.onTap,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: device.isConnected
                          ? AppTheme.statusGood.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      device.type == 'bluetooth' ? Icons.bluetooth : Icons.wifi,
                      color: device.isConnected ? AppTheme.statusGood : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.type == 'bluetooth'
                              ? device.macAddress ?? 'Unknown'
                              : device.ipAddress ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: device.isConnected
                          ? AppTheme.statusGood.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      device.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: device.isConnected ? AppTheme.statusGood : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              if (device.signalStrength != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Signal: ${device.signalStrength} dBm',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    if (device.lastConnected != null)
                      Text(
                        'Last: ${_formatTime(device.lastConnected!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

// Sensor Readings Screen
class SensorReadingsScreen extends StatelessWidget {
  final IoTDevice device;

  const SensorReadingsScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    // Mock sensor readings
    final readings = [
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.soilMoisture,
        value: 65.5,
        unit: '%',
        timestamp: DateTime.now(),
        status: SensorStatus.optimal,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.soilPH,
        value: 5.8,
        unit: 'pH',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.nitrogen,
        value: 45.2,
        unit: 'mg/kg',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.phosphorus,
        value: 32.1,
        unit: 'mg/kg',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.potassium,
        value: 28.7,
        unit: 'mg/kg',
        timestamp: DateTime.now(),
        status: SensorStatus.warning,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.temperature,
        value: 24.5,
        unit: '°C',
        timestamp: DateTime.now(),
        status: SensorStatus.optimal,
      ),
      SensorReading(
        deviceId: device.id,
        sensorType: SensorType.humidity,
        value: 72.3,
        unit: '%',
        timestamp: DateTime.now(),
        status: SensorStatus.normal,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing sensor data...')),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final reading = readings[index];
          return _SensorReadingCard(reading: reading);
        },
      ),
    );
  }
}

class _SensorReadingCard extends StatelessWidget {
  final SensorReading reading;

  const _SensorReadingCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reading.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              reading.sensorType.icon,
              size: 32,
              color: statusColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reading.sensorType.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${reading.value.toStringAsFixed(1)} ${reading.unit}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reading.status.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SensorStatus status) {
    switch (status) {
      case SensorStatus.critical:
        return AppTheme.statusCritical;
      case SensorStatus.warning:
        return AppTheme.statusWarning;
      case SensorStatus.normal:
        return Colors.blue;
      case SensorStatus.optimal:
        return AppTheme.statusGood;
    }
  }
}
