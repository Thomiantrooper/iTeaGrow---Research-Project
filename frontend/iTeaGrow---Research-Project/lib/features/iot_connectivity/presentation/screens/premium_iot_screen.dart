import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/providers/global_iot_provider.dart';
import '../../data/services/websocket_sensor_service.dart';
import '../../domain/models/esp32_sensor_data.dart';
import '../widgets/voice_assistant_panel.dart';

/// Premium IoT Devices Screen with Bluetooth, WiFi, and WebSocket support
class PremiumIoTScreen extends ConsumerStatefulWidget {
  const PremiumIoTScreen({super.key});

  @override
  ConsumerState<PremiumIoTScreen> createState() => _PremiumIoTScreenState();
}

class _PremiumIoTScreenState extends ConsumerState<PremiumIoTScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  String _connectionType = 'all';
  bool _showVoiceAssistant = false;

  // WebSocket URL controller - initialized from global state
  late TextEditingController _wsUrlController;

  final List<IoTDeviceModel> _devices = [
    IoTDeviceModel(
      id: 'esp32_001',
      name: 'iTeaGrow Monitor - Block A',
      type: IoTConnectionType.bluetooth,
      status: DeviceStatus.connected,
      signalStrength: -45,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
      sensorData: SensorData(
        temperature: 24.5,
        humidity: 78,
        soilMoisture: 65,
        lightIntensity: 850,
        ph: 6.2,
      ),
    ),
    IoTDeviceModel(
      id: 'esp32_002',
      name: 'Soil Sensor - Block B',
      type: IoTConnectionType.bluetooth,
      status: DeviceStatus.connected,
      signalStrength: -62,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      sensorData: SensorData(
        temperature: 23.8,
        humidity: 72,
        soilMoisture: 58,
        lightIntensity: 780,
        ph: 6.5,
      ),
    ),
    IoTDeviceModel(
      id: 'weather_001',
      name: 'Weather Station',
      type: IoTConnectionType.wifi,
      status: DeviceStatus.connected,
      signalStrength: -50,
      lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
      sensorData: SensorData(
        temperature: 25.2,
        humidity: 82,
        soilMoisture: null,
        lightIntensity: 920,
        ph: null,
      ),
    ),
  ];

  // WebSocket device (added dynamically)
  IoTDeviceModel? _wsDevice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize URL controller from global state
    final globalState = ref.read(globalIoTProvider);
    _wsUrlController = TextEditingController(text: globalState.serverUrl);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wsUrlController.dispose();
    super.dispose();
  }

  IoTDeviceModel? _buildWebSocketDevice(GlobalIoTState state) {
    if (state.connectionState == WebSocketConnectionState.connected) {
      return IoTDeviceModel(
        id: 'ws_bridge',
        name: 'WebSocket Bridge Server',
        type: IoTConnectionType.websocket,
        status: DeviceStatus.connected,
        signalStrength: -30,
        lastSeen: state.lastUpdated ?? DateTime.now(),
        sensorData: state.hasData
            ? SensorData(
                temperature: state.temperature,
                humidity: state.humidity,
                soilMoisture: null,
                lightIntensity: null,
                ph: null,
              )
            : null,
      );
    } else if (state.connectionState == WebSocketConnectionState.connecting) {
      return IoTDeviceModel(
        id: 'ws_bridge',
        name: 'WebSocket Bridge Server',
        type: IoTConnectionType.websocket,
        status: DeviceStatus.connecting,
        signalStrength: 0,
        lastSeen: DateTime.now(),
        sensorData: null,
      );
    }
    return null;
  }

  List<IoTDeviceModel> _getAllDevices(GlobalIoTState state) {
    final devices = List<IoTDeviceModel>.from(_devices);
    final wsDevice = _buildWebSocketDevice(state);
    if (wsDevice != null) {
      devices.add(wsDevice);
    }
    return devices;
  }

  @override
  Widget build(BuildContext context) {
    // Watch global IoT state - this persists across navigation
    final globalIoTState = ref.watch(globalIoTProvider);
    final allDevices = _getAllDevices(globalIoTState);
    final filteredDevices = _getFilteredDevices(allDevices);
    final connectedCount = allDevices.where((d) => d.status == DeviceStatus.connected).length;

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: TeaColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TeaColors.nearBlack),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'IoT Devices',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
        actions: [
          // Voice Assistant toggle (web only)
          if (kIsWeb)
            IconButton(
              icon: Icon(
                _showVoiceAssistant ? Icons.mic_off : Icons.mic,
                color: _showVoiceAssistant ? TeaColors.alertRust : TeaColors.freshLeaf,
              ),
              tooltip: 'Voice Assistant',
              onPressed: () => setState(() => _showVoiceAssistant = !_showVoiceAssistant),
            ),
          IconButton(
            icon: Icon(
              _isScanning ? Icons.stop : Icons.refresh,
              color: _isScanning ? TeaColors.alertRust : TeaColors.freshLeaf,
            ),
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: TeaColors.freshLeaf),
            onPressed: _showAddDeviceDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TeaColors.freshLeaf,
          labelColor: TeaColors.freshLeaf,
          unselectedLabelColor: TeaColors.darkGray,
          onTap: (index) {
            setState(() {
              _connectionType = ['all', 'bluetooth', 'wifi', 'websocket'][index];
            });
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.devices, size: 16),
                  const SizedBox(width: 4),
                  Text('All ($connectedCount)'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bluetooth, size: 16),
                  SizedBox(width: 4),
                  Text('BT'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi, size: 16),
                  SizedBox(width: 4),
                  Text('WiFi'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud, size: 16),
                  SizedBox(width: 4),
                  Text('WS'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Main content
          Expanded(
            child: Column(
              children: [
                // WebSocket Connection Status Banner (persistent)
                _buildWebSocketStatusBanner(),

                // Scanning Banner
                if (_isScanning)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TeaSpacing.md,
                      vertical: TeaSpacing.sm,
                    ),
                    color: TeaColors.infoSky.withOpacity(0.1),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TeaColors.infoSky,
                          ),
                        ),
                        const SizedBox(width: TeaSpacing.sm),
                        Text(
                          'Scanning for devices...',
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.infoSky,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                // Device List
                Expanded(
                  child: filteredDevices.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: TeaSpacing.screenPadding,
                          itemCount: filteredDevices.length,
                          itemBuilder: (context, index) {
                            final device = filteredDevices[index];
                            return _buildDeviceCard(device)
                                .animate()
                                .fadeIn(delay: (index * 100).ms)
                                .slideX(begin: 0.1, end: 0);
                          },
                        ),
                ),
              ],
            ),
          ),

          // Voice Assistant Panel (side panel)
          if (_showVoiceAssistant && kIsWeb)
            VoiceAssistantPanel(
              iotState: globalIoTState,
              onClose: () => setState(() => _showVoiceAssistant = false),
            ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1, end: 0),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickConnectDialog,
        backgroundColor: TeaColors.freshLeaf,
        icon: const Icon(Icons.link, color: TeaColors.white),
        label: const Text('Quick Connect', style: TextStyle(color: TeaColors.white)),
      ),
    );
  }

  Widget _buildWebSocketStatusBanner() {
    // Use global IoT state for connection status
    final globalState = ref.watch(globalIoTProvider);
    final connectionState = globalState.connectionState;
    final latestData = globalState.latestData;

    Color bgColor;
    Color textColor;
    IconData icon;
    String message;
    Widget? trailing;

    switch (connectionState) {
      case WebSocketConnectionState.connected:
        bgColor = TeaColors.healthyGreen.withOpacity(0.1);
        textColor = TeaColors.healthyGreen;
        icon = Icons.cloud_done;
        message = 'WebSocket Connected';
        trailing = IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: TeaColors.healthyGreen,
          onPressed: _disconnectWebSocket,
        );
        break;
      case WebSocketConnectionState.connecting:
        bgColor = TeaColors.goldenSunlight.withOpacity(0.1);
        textColor = TeaColors.goldenSunlight;
        icon = Icons.cloud_sync;
        message = 'Connecting to WebSocket...';
        trailing = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: TeaColors.goldenSunlight,
          ),
        );
        break;
      case WebSocketConnectionState.error:
        bgColor = TeaColors.alertRust.withOpacity(0.1);
        textColor = TeaColors.alertRust;
        icon = Icons.cloud_off;
        message = 'Connection Error';
        trailing = TextButton(
          onPressed: _connectWebSocket,
          child: Text('Retry', style: TextStyle(color: textColor)),
        );
        break;
      case WebSocketConnectionState.bridgeDisconnected:
        bgColor = TeaColors.warningAmber.withOpacity(0.1);
        textColor = TeaColors.warningAmber;
        icon = Icons.warning_amber;
        message = 'Bridge: ESP32 Disconnected';
        trailing = null;
        break;
      case WebSocketConnectionState.disconnected:
      default:
        // Don't show banner when disconnected
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.md,
        vertical: TeaSpacing.sm,
      ),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: TeaSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TeaTypography.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (connectionState == WebSocketConnectionState.connected &&
                    latestData != null)
                  Text(
                    'T: ${latestData.temperature.toStringAsFixed(1)}°C | H: ${latestData.humidity.toStringAsFixed(1)}%',
                    style: TeaTypography.labelSmall.copyWith(
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    ).animate().fadeIn();
  }

  List<IoTDeviceModel> _getFilteredDevices(List<IoTDeviceModel> allDevices) {
    if (_connectionType == 'all') return allDevices;
    return allDevices.where((d) {
      switch (_connectionType) {
        case 'bluetooth':
          return d.type == IoTConnectionType.bluetooth;
        case 'wifi':
          return d.type == IoTConnectionType.wifi;
        case 'websocket':
          return d.type == IoTConnectionType.websocket;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState() {
    final isWebSocketTab = _connectionType == 'websocket';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWebSocketTab ? Icons.cloud_off : Icons.sensors_off,
            size: 64,
            color: TeaColors.mediumGray,
          ),
          const SizedBox(height: TeaSpacing.md),
          Text(
            isWebSocketTab ? 'No WebSocket Connection' : 'No devices found',
            style: TeaTypography.titleMedium.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
          const SizedBox(height: TeaSpacing.sm),
          Text(
            isWebSocketTab
                ? 'Connect to your iTeaGrow bridge server'
                : 'Tap scan to search for nearby devices',
            style: TeaTypography.bodySmall.copyWith(
              color: TeaColors.mediumGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: TeaSpacing.lg),
          if (isWebSocketTab)
            TeaButton.primary(
              label: 'Connect WebSocket',
              icon: Icons.cloud,
              onPressed: _showWebSocketConfigDialog,
            )
          else
            TeaButton.primary(
              label: 'Start Scanning',
              icon: Icons.search,
              onPressed: _startScanning,
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(IoTDeviceModel device) {
    final isConnected = device.status == DeviceStatus.connected;
    final isConnecting = device.status == DeviceStatus.connecting;

    return Padding(
      padding: const EdgeInsets.only(bottom: TeaSpacing.md),
      child: TeaCard.elevated(
        onTap: () => _showDeviceDetails(device),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: _getConnectionColor(device.type).withOpacity(0.1),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: isConnecting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _getConnectionColor(device.type),
                          ),
                        )
                      : Icon(
                          _getConnectionIcon(device.type),
                          color: _getConnectionColor(device.type),
                          size: 24,
                        ),
                ),
                const SizedBox(width: TeaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: TeaTypography.titleSmall),
                      Row(
                        children: [
                          if (isConnecting)
                            Text(
                              'Connecting...',
                              style: TeaTypography.labelSmall.copyWith(
                                color: TeaColors.goldenSunlight,
                              ),
                            )
                          else ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? TeaColors.healthyGreen
                                    : TeaColors.mediumGray,
                              ),
                            ),
                            const SizedBox(width: TeaSpacing.xs),
                            Text(
                              isConnected ? 'Connected' : 'Disconnected',
                              style: TeaTypography.labelSmall.copyWith(
                                color: isConnected
                                    ? TeaColors.healthyGreen
                                    : TeaColors.mediumGray,
                              ),
                            ),
                          ],
                          if (isConnected) ...[
                            const SizedBox(width: TeaSpacing.md),
                            Icon(
                              _getSignalIcon(device.signalStrength),
                              size: 14,
                              color: TeaColors.darkGray,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: TeaColors.darkGray),
                  onSelected: (value) => _handleDeviceAction(device, value),
                  itemBuilder: (context) => [
                    if (isConnected)
                      const PopupMenuItem(
                        value: 'disconnect',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 18),
                            SizedBox(width: 8),
                            Text('Disconnect'),
                          ],
                        ),
                      )
                    else if (!isConnecting)
                      const PopupMenuItem(
                        value: 'connect',
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 18),
                            SizedBox(width: 8),
                            Text('Connect'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'configure',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 18),
                          SizedBox(width: 8),
                          Text('Configure'),
                        ],
                      ),
                    ),
                    if (device.type != IoTConnectionType.websocket)
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Remove', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Sensor Data (if connected and has data)
            if (isConnected && device.sensorData != null) ...[
              const SizedBox(height: TeaSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: TeaSpacing.md),
              _buildSensorDataRow(device.sensorData!),
            ],

            // Last seen
            const SizedBox(height: TeaSpacing.sm),
            Text(
              'Last seen: ${_formatLastSeen(device.lastSeen)}',
              style: TeaTypography.labelSmall.copyWith(
                color: TeaColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataRow(SensorData data) {
    return Wrap(
      spacing: TeaSpacing.md,
      runSpacing: TeaSpacing.sm,
      children: [
        if (data.temperature != null)
          _buildSensorChip(Icons.thermostat, '${data.temperature?.toStringAsFixed(1)}°C', TeaColors.warningAmber),
        if (data.humidity != null)
          _buildSensorChip(Icons.water_drop, '${data.humidity?.toInt()}%', TeaColors.infoSky),
        if (data.soilMoisture != null)
          _buildSensorChip(Icons.grass, '${data.soilMoisture?.toInt()}%', TeaColors.richSoil),
        if (data.lightIntensity != null)
          _buildSensorChip(Icons.wb_sunny, '${data.lightIntensity?.toInt()} lux', TeaColors.goldenSunlight),
        if (data.ph != null)
          _buildSensorChip(Icons.science, 'pH ${data.ph?.toStringAsFixed(1)}', TeaColors.freshLeaf),
      ],
    );
  }

  Widget _buildSensorChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TeaSpacing.sm,
        vertical: TeaSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TeaRadius.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TeaTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConnectionIcon(IoTConnectionType type) {
    switch (type) {
      case IoTConnectionType.bluetooth:
        return Icons.bluetooth;
      case IoTConnectionType.wifi:
        return Icons.wifi;
      case IoTConnectionType.websocket:
        return Icons.cloud;
    }
  }

  Color _getConnectionColor(IoTConnectionType type) {
    switch (type) {
      case IoTConnectionType.bluetooth:
        return TeaColors.infoSky;
      case IoTConnectionType.wifi:
        return TeaColors.freshLeaf;
      case IoTConnectionType.websocket:
        return TeaColors.goldenSunlight;
    }
  }

  IconData _getSignalIcon(int strength) {
    if (strength > -50) return Icons.signal_cellular_4_bar;
    if (strength > -60) return Icons.signal_cellular_alt;
    if (strength > -70) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  String _formatLastSeen(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _startScanning() {
    final globalState = ref.read(globalIoTProvider);
    final allDevices = _getAllDevices(globalState);

    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isScanning = false);
        TeaSnackbar.success(context, 'Scan complete - ${allDevices.length} devices found');
      }
    });
  }

  void _stopScanning() {
    setState(() => _isScanning = false);
    TeaSnackbar.info(context, 'Scan stopped');
  }

  void _connectWebSocket() async {
    // Use global IoT provider for persistent connection
    final globalIoT = ref.read(globalIoTProvider.notifier);
    final url = _wsUrlController.text.trim();

    if (url.isEmpty) {
      TeaSnackbar.error(context, 'Please enter a WebSocket URL');
      return;
    }

    final success = await globalIoT.connect(url: url);
    if (mounted) {
      if (success) {
        TeaSnackbar.success(context, 'Connected to WebSocket server');
      } else {
        TeaSnackbar.error(context, 'Failed to connect. Check server is running.');
      }
    }
  }

  void _disconnectWebSocket() async {
    // Use global IoT provider
    final globalIoT = ref.read(globalIoTProvider.notifier);
    await globalIoT.disconnect();
    if (mounted) {
      TeaSnackbar.info(context, 'Disconnected from WebSocket');
    }
  }

  void _handleDeviceAction(IoTDeviceModel device, String action) {
    switch (action) {
      case 'connect':
        if (device.type == IoTConnectionType.websocket) {
          _showWebSocketConfigDialog();
        } else {
          TeaSnackbar.info(context, 'Connecting to ${device.name}...');
        }
        break;
      case 'disconnect':
        if (device.type == IoTConnectionType.websocket) {
          _disconnectWebSocket();
        } else {
          TeaSnackbar.info(context, 'Disconnected from ${device.name}');
        }
        break;
      case 'configure':
        _showConfigureDialog(device);
        break;
      case 'remove':
        _showRemoveDialog(device);
        break;
    }
  }

  void _showDeviceDetails(IoTDeviceModel device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: TeaColors.white,
          borderRadius: TeaRadius.topXxl,
        ),
        padding: TeaSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TeaColors.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: TeaSpacing.lg),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.md),
                  decoration: BoxDecoration(
                    color: _getConnectionColor(device.type).withOpacity(0.1),
                    borderRadius: TeaRadius.radiusMd,
                  ),
                  child: Icon(
                    _getConnectionIcon(device.type),
                    color: _getConnectionColor(device.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: TeaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: TeaTypography.titleLarge),
                      Text(
                        'ID: ${device.id}',
                        style: TeaTypography.bodySmall.copyWith(
                          color: TeaColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.lg),
            if (device.sensorData != null) ...[
              Text('Live Sensor Data', style: TeaTypography.titleMedium),
              const SizedBox(height: TeaSpacing.md),
              _buildDetailedSensorData(device.sensorData!),
              const SizedBox(height: TeaSpacing.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: TeaButton.outlined(
                    label: 'Configure',
                    icon: Icons.settings,
                    onPressed: () {
                      Navigator.pop(context);
                      _showConfigureDialog(device);
                    },
                  ),
                ),
                const SizedBox(width: TeaSpacing.md),
                Expanded(
                  child: TeaButton.primary(
                    label: device.status == DeviceStatus.connected
                        ? 'Disconnect'
                        : 'Connect',
                    icon: device.status == DeviceStatus.connected
                        ? Icons.link_off
                        : Icons.link,
                    onPressed: () {
                      Navigator.pop(context);
                      if (device.type == IoTConnectionType.websocket) {
                        if (device.status == DeviceStatus.connected) {
                          _disconnectWebSocket();
                        } else {
                          _showWebSocketConfigDialog();
                        }
                      } else {
                        TeaSnackbar.info(context, 'Action performed');
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: TeaSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedSensorData(SensorData data) {
    return Column(
      children: [
        Row(
          children: [
            if (data.temperature != null)
              Expanded(
                child: _buildSensorDetailCard(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${data.temperature?.toStringAsFixed(1)}°C',
                  color: TeaColors.warningAmber,
                ),
              ),
            if (data.temperature != null && data.humidity != null)
              const SizedBox(width: TeaSpacing.smd),
            if (data.humidity != null)
              Expanded(
                child: _buildSensorDetailCard(
                  icon: Icons.water_drop,
                  label: 'Humidity',
                  value: '${data.humidity?.toInt()}%',
                  color: TeaColors.infoSky,
                ),
              ),
          ],
        ),
        if (data.soilMoisture != null || data.ph != null) ...[
          const SizedBox(height: TeaSpacing.smd),
          Row(
            children: [
              if (data.soilMoisture != null)
                Expanded(
                  child: _buildSensorDetailCard(
                    icon: Icons.grass,
                    label: 'Soil Moisture',
                    value: '${data.soilMoisture?.toInt()}%',
                    color: TeaColors.richSoil,
                  ),
                ),
              if (data.soilMoisture != null && data.ph != null)
                const SizedBox(width: TeaSpacing.smd),
              if (data.ph != null)
                Expanded(
                  child: _buildSensorDetailCard(
                    icon: Icons.science,
                    label: 'pH Level',
                    value: '${data.ph?.toStringAsFixed(1)}',
                    color: TeaColors.freshLeaf,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSensorDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: TeaSpacing.cardPaddingMd,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: TeaRadius.radiusMd,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: TeaSpacing.xs),
          Text(
            value,
            style: TeaTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TeaTypography.labelSmall.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bluetooth, color: TeaColors.infoSky),
              title: const Text('Bluetooth Device'),
              subtitle: const Text('ESP32, Arduino BLE'),
              onTap: () {
                Navigator.pop(context);
                _startScanning();
              },
            ),
            ListTile(
              leading: Icon(Icons.wifi, color: TeaColors.freshLeaf),
              title: const Text('WiFi Device'),
              subtitle: const Text('ESP32 WiFi, Raspberry Pi'),
              onTap: () {
                Navigator.pop(context);
                _showWifiConfigDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: TeaColors.goldenSunlight),
              title: const Text('WebSocket Connection'),
              subtitle: const Text('iTeaGrow Bridge Server'),
              onTap: () {
                Navigator.pop(context);
                _showWebSocketConfigDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConfigureDialog(IoTDeviceModel device) {
    if (device.type == IoTConnectionType.websocket) {
      _showWebSocketConfigDialog();
    } else {
      TeaSnackbar.info(context, 'Configuration for ${device.name} - Coming soon!');
    }
  }

  void _showRemoveDialog(IoTDeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Are you sure you want to remove "${device.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _devices.removeWhere((d) => d.id == device.id));
              TeaSnackbar.success(context, 'Device removed');
            },
            style: ElevatedButton.styleFrom(backgroundColor: TeaColors.alertRust),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickConnectDialog() {
    _showAddDeviceDialog();
  }

  void _showWifiConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WiFi Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '80',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TeaSnackbar.info(context, 'Connecting...');
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showWebSocketConfigDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud, color: TeaColors.goldenSunlight),
            const SizedBox(width: 12),
            const Text('WebSocket Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect to your iTeaGrow Bridge Server to receive live sensor data from ESP32 devices.',
              style: TeaTypography.bodySmall.copyWith(color: TeaColors.darkGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wsUrlController,
              decoration: InputDecoration(
                labelText: 'WebSocket URL',
                hintText: 'ws://localhost:8765',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: TeaColors.leafPale,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TeaColors.infoSky.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: TeaColors.infoSky, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure the bridge server (bridge_server.py) is running',
                      style: TeaTypography.labelSmall.copyWith(
                        color: TeaColors.infoSky,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _connectWebSocket();
            },
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeaColors.freshLeaf,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

enum IoTConnectionType { bluetooth, wifi, websocket }
enum DeviceStatus { connected, disconnected, connecting }

class IoTDeviceModel {
  final String id;
  final String name;
  final IoTConnectionType type;
  final DeviceStatus status;
  final int signalStrength;
  final DateTime lastSeen;
  final SensorData? sensorData;

  IoTDeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.signalStrength,
    required this.lastSeen,
    this.sensorData,
  });
}

class SensorData {
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? lightIntensity;
  final double? ph;

  SensorData({
    this.temperature,
    this.humidity,
    this.soilMoisture,
    this.lightIntensity,
    this.ph,
  });
}
