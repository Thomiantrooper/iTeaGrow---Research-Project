import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../domain/models/iot_models.dart';
import '../../domain/models/esp32_sensor_data.dart';
import '../providers/esp32_sensor_provider.dart';
import '../../data/services/esp32_bluetooth_service.dart';
import '../widgets/esp32_sensor_card.dart';

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
    final esp32State = ref.watch(esp32SensorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
        backgroundColor: JarvisTheme.teaGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            onPressed: _isScanning ? null : _startScanning,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESP32 iTeaGrow Monitor Section
            const Text(
              'iTeaGrow Environmental Monitor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: JarvisTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Real-time environmental data from your ESP32 device',
              style: TextStyle(
                fontSize: 13,
                color: JarvisTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),

            // ESP32 Sensor Card with live data
            const ESP32SensorCard(
              showConnectionStatus: true,
              showAirQuality: true,
              showDiseaseRisk: true,
            ),

            const SizedBox(height: 24),

            // Connection Actions
            if (!esp32State.isConnected) ...[
              _ESP32ConnectionCard(
                state: esp32State,
                onScan: () {
                  ref.read(esp32SensorProvider.notifier).scanForDevices();
                },
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Connected device info
              _ConnectedDeviceCard(
                state: esp32State,
                onDisconnect: () {
                  ref.read(esp32SensorProvider.notifier).disconnect();
                },
                onRefresh: () {
                  ref.read(esp32SensorProvider.notifier).requestData();
                },
              ),
              const SizedBox(height: 24),
            ],

            // Divider
            const Divider(),
            const SizedBox(height: 16),

            // Other devices section
            const Text(
              'Other Sensor Devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: JarvisTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Tab selector
            Row(
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
            const SizedBox(height: 16),

            // Scanning indicator
            if (_isScanning)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: JarvisTheme.teaGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
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
            if (devices.isEmpty && !_isScanning)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedTab == 'bluetooth' ? Icons.bluetooth_disabled : Icons.wifi_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('No devices found'),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap scan to search for devices',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...devices.map((device) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DeviceCard(
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
                    ),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startScanning,
        backgroundColor: JarvisTheme.teaGreen,
        icon: const Icon(Icons.search),
        label: Text('Scan ${_selectedTab == 'bluetooth' ? 'Bluetooth' : 'Wi-Fi'}'),
      ),
    );
  }
}

/// ESP32 Connection Card with Bridge Server option
class _ESP32ConnectionCard extends ConsumerStatefulWidget {
  final ESP32SensorState state;
  final VoidCallback onScan;

  const _ESP32ConnectionCard({
    required this.state,
    required this.onScan,
  });

  @override
  ConsumerState<_ESP32ConnectionCard> createState() => _ESP32ConnectionCardState();
}

class _ESP32ConnectionCardState extends ConsumerState<_ESP32ConnectionCard> {
  final _serverUrlController = TextEditingController(text: 'ws://localhost:8765');
  bool _isConnecting = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _connectViaBridge() async {
    setState(() => _isConnecting = true);

    final success = await ref
        .read(esp32SensorProvider.notifier)
        .connectViaBridge(url: _serverUrlController.text);

    setState(() => _isConnecting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to bridge server!'),
          backgroundColor: JarvisTheme.healthy,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to connect. Is the bridge server running?'),
          backgroundColor: JarvisTheme.critical,
          action: SnackBarAction(
            label: 'Help',
            textColor: Colors.white,
            onPressed: () => _showBridgeHelp(context),
          ),
        ),
      );
    }
  }

  void _showBridgeHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bridge Server Setup'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To connect your ESP32 to the app, you need to run the bridge server:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Open a terminal/command prompt'),
              SizedBox(height: 4),
              Text('2. Navigate to the project folder'),
              SizedBox(height: 4),
              Text('3. Run: python iot_bridge_server.py'),
              SizedBox(height: 4),
              Text('4. Select your COM port when prompted'),
              SizedBox(height: 4),
              Text('5. Click "Connect via Bridge" in the app'),
              SizedBox(height: 16),
              Text(
                'Required Python packages:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('pip install pyserial websockets'),
              SizedBox(height: 16),
              Text(
                'For mobile devices:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('Replace "localhost" with your PC\'s IP address'),
              Text('Example: ws://192.168.1.100:8765'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: JarvisTheme.teaGreen.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: JarvisTheme.teaGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.router,
                    color: JarvisTheme.teaGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connect to iTeaGrow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Via USB/Bluetooth using bridge server',
                        style: TextStyle(
                          fontSize: 13,
                          color: JarvisTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: JarvisTheme.teaGreen),
                  onPressed: () => _showBridgeHelp(context),
                  tooltip: 'Setup help',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Server URL input
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: 'Bridge Server URL',
                hintText: 'ws://localhost:8765',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Connect via Bridge button (Primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _connectViaBridge,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cable),
                label: Text(_isConnecting ? 'Connecting...' : 'Connect via Bridge (Recommended)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JarvisTheme.teaGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Divider with "OR"
            Row(
              children: [
                Expanded(child: Divider(color: JarvisTheme.textMuted.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: JarvisTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: JarvisTheme.textMuted.withOpacity(0.3))),
              ],
            ),
            const SizedBox(height: 12),

            // Scan BLE button (Secondary)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.state.isScanning ? null : widget.onScan,
                icon: widget.state.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(widget.state.isScanning ? 'Scanning...' : 'Scan for BLE Devices'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JarvisTheme.teaGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: JarvisTheme.teaGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: BLE scanning only works with BLE devices.\nYour ESP32 uses Bluetooth Classic - use Bridge instead.',
              style: TextStyle(
                fontSize: 11,
                color: JarvisTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.state.availableDevices.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Found Devices:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: JarvisTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.state.availableDevices.map((device) {
                final name = device.device.platformName.isNotEmpty
                    ? device.device.platformName
                    : device.advertisementData.advName.isNotEmpty
                        ? device.advertisementData.advName
                        : 'Unknown Device';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bluetooth, color: JarvisTheme.teaGreen),
                  title: Text(name),
                  subtitle: Text('Signal: ${device.rssi} dBm'),
                  trailing: Consumer(
                    builder: (context, ref, _) {
                      final connecting = ref.watch(esp32SensorProvider).connectionState ==
                          ESP32ConnectionState.connecting;
                      return ElevatedButton(
                        onPressed: connecting
                            ? null
                            : () async {
                                await ref
                                    .read(esp32SensorProvider.notifier)
                                    .connectToDevice(device.device);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JarvisTheme.teaGreen,
                          foregroundColor: Colors.white,
                        ),
                        child: connecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Connect'),
                      );
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Connected Device Card
class _ConnectedDeviceCard extends StatelessWidget {
  final ESP32SensorState state;
  final VoidCallback onDisconnect;
  final VoidCallback onRefresh;

  const _ConnectedDeviceCard({
    required this.state,
    required this.onDisconnect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: JarvisTheme.healthy.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: JarvisTheme.healthy.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: JarvisTheme.healthy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bluetooth_connected,
                color: JarvisTheme.healthy,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.connectedDevice?.platformName ?? 'iTeaGrow',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Connected - Receiving data',
                    style: TextStyle(
                      fontSize: 12,
                      color: JarvisTheme.healthy,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: JarvisTheme.teaGreen),
              tooltip: 'Refresh data',
            ),
            IconButton(
              onPressed: onDisconnect,
              icon: const Icon(Icons.bluetooth_disabled, color: JarvisTheme.critical),
              tooltip: 'Disconnect',
            ),
          ],
        ),
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
