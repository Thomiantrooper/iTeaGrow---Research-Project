import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/widgets/hologram_card.dart';
import '../../domain/models/esp32_sensor_data.dart';
import '../providers/esp32_sensor_provider.dart';
import '../../data/services/esp32_bluetooth_service.dart';

/// ESP32 Sensor Card Widget
/// Displays live environmental data from the iTeaGrow ESP32 device
class ESP32SensorCard extends ConsumerWidget {
  final bool showConnectionStatus;
  final bool showAirQuality;
  final bool showDiseaseRisk;
  final VoidCallback? onTap;

  const ESP32SensorCard({
    super.key,
    this.showConnectionStatus = true,
    this.showAirQuality = true,
    this.showDiseaseRisk = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorState = ref.watch(esp32SensorProvider);
    final data = sensorState.currentData;

    return HologramCard(
      enableGlow: sensorState.isConnected,
      glowColor: sensorState.isConnected ? JarvisTheme.teaGreen : Colors.grey,
      onTap: onTap,
      padding: const EdgeInsets.all(JarvisTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, sensorState),
          const SizedBox(height: JarvisTheme.spacingMd),

          if (data != null) ...[
            // Temperature & Humidity Row
            Row(
              children: [
                Expanded(
                  child: _SensorMetric(
                    icon: Icons.thermostat_outlined,
                    label: 'Temperature',
                    value: '${data.temperature.toStringAsFixed(1)}°C',
                    status: data.temperatureStatus,
                  ),
                ),
                const SizedBox(width: JarvisTheme.spacingMd),
                Expanded(
                  child: _SensorMetric(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: '${data.humidity.toStringAsFixed(1)}%',
                    status: data.humidityStatus,
                  ),
                ),
              ],
            ),

            if (showAirQuality) ...[
              const SizedBox(height: JarvisTheme.spacingMd),
              // Air Quality
              _AirQualityIndicator(
                airQuality: data.airQuality,
                rating: data.airQualityRating,
              ),
            ],

            if (showDiseaseRisk && data.diseaseRisk.riskLevel != RiskLevel.low) ...[
              const SizedBox(height: JarvisTheme.spacingMd),
              // Disease Risk Alert
              _DiseaseRiskAlert(risk: data.diseaseRisk),
            ],

            // Motion indicator
            if (data.motionDetected) ...[
              const SizedBox(height: JarvisTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: JarvisTheme.spacingSm,
                  vertical: JarvisTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: JarvisTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(JarvisTheme.radiusSm),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk, size: 14, color: JarvisTheme.info),
                    SizedBox(width: 4),
                    Text(
                      'Motion Detected',
                      style: TextStyle(
                        fontSize: 12,
                        color: JarvisTheme.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Last Updated
            const SizedBox(height: JarvisTheme.spacingSm),
            Text(
              'Updated ${_formatTimestamp(data.timestamp)}',
              style: const TextStyle(
                fontSize: 11,
                color: JarvisTheme.textMuted,
              ),
            ),
          ] else ...[
            // No data placeholder
            _NoDataPlaceholder(
              isConnected: sensorState.isConnected,
              onConnect: () => _showDeviceScanner(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ESP32SensorState state) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: state.isConnected
                ? JarvisTheme.primaryGradient
                : LinearGradient(
                    colors: [Colors.grey.shade400, Colors.grey.shade500],
                  ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.sensors, color: Colors.white, size: 20),
        ),
        const SizedBox(width: JarvisTheme.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'iTeaGrow Monitor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isConnected ? JarvisTheme.healthy : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.connectionStatusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: state.isConnected ? JarvisTheme.healthy : JarvisTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showConnectionStatus)
          _ConnectionButton(
            state: state.connectionState,
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  void _showDeviceScanner(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _DeviceScannerSheet(),
    );
  }
}

class _SensorMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final SensorHealthStatus status;

  const _SensorMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(JarvisTheme.spacingSm),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
        border: Border.all(color: status.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: status.color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: JarvisTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirQualityIndicator extends StatelessWidget {
  final int airQuality;
  final AirQualityRating rating;

  const _AirQualityIndicator({
    required this.airQuality,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(JarvisTheme.spacingSm),
      decoration: BoxDecoration(
        color: rating.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
        border: Border.all(color: rating.color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rating.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(rating.icon, color: rating.color, size: 24),
          ),
          const SizedBox(width: JarvisTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Air Quality',
                  style: TextStyle(
                    fontSize: 12,
                    color: JarvisTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      rating.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rating.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($airQuality)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: JarvisTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress indicator
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (airQuality / 1000).clamp(0.0, 1.0),
                  backgroundColor: rating.color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(rating.color),
                  strokeWidth: 4,
                ),
                Text(
                  '${((1 - airQuality / 1000) * 100).clamp(0, 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rating.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiseaseRiskAlert extends StatelessWidget {
  final DiseaseRisk risk;

  const _DiseaseRiskAlert({required this.risk});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(JarvisTheme.spacingSm),
      decoration: BoxDecoration(
        color: risk.riskLevel.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
        border: Border.all(color: risk.riskLevel.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: risk.riskLevel.color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${risk.disease} Risk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: risk.riskLevel.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: risk.riskLevel.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        risk.riskLevel.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: risk.riskLevel.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  risk.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: risk.riskLevel.color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  final ESP32ConnectionState state;

  const _ConnectionButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading = state == ESP32ConnectionState.connecting ||
        state == ESP32ConnectionState.scanning;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: JarvisTheme.mistGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              state == ESP32ConnectionState.connected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_searching,
              color: state == ESP32ConnectionState.connected
                  ? JarvisTheme.teaGreen
                  : JarvisTheme.textMuted,
              size: 20,
            ),
    );
  }
}

class _NoDataPlaceholder extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onConnect;

  const _NoDataPlaceholder({
    required this.isConnected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(JarvisTheme.spacingLg),
      child: Column(
        children: [
          Icon(
            isConnected ? Icons.hourglass_empty : Icons.bluetooth_disabled,
            size: 48,
            color: JarvisTheme.textMuted,
          ),
          const SizedBox(height: JarvisTheme.spacingSm),
          Text(
            isConnected ? 'Waiting for sensor data...' : 'No device connected',
            style: const TextStyle(
              fontSize: 14,
              color: JarvisTheme.textMuted,
            ),
          ),
          if (!isConnected) ...[
            const SizedBox(height: JarvisTheme.spacingMd),
            ElevatedButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.bluetooth_searching, size: 18),
              label: const Text('Connect Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: JarvisTheme.teaGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Device Scanner Bottom Sheet
class _DeviceScannerSheet extends ConsumerStatefulWidget {
  const _DeviceScannerSheet();

  @override
  ConsumerState<_DeviceScannerSheet> createState() => _DeviceScannerSheetState();
}

class _DeviceScannerSheetState extends ConsumerState<_DeviceScannerSheet> {
  @override
  void initState() {
    super.initState();
    // Start scanning when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(esp32SensorProvider.notifier).scanForDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorState = ref.watch(esp32SensorProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: JarvisTheme.mistWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(JarvisTheme.radiusXl)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: JarvisTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(JarvisTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: JarvisTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bluetooth_searching, color: Colors.white),
                ),
                const SizedBox(width: JarvisTheme.spacingSm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find iTeaGrow Device',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Scanning for nearby devices',
                        style: TextStyle(
                          fontSize: 12,
                          color: JarvisTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sensorState.isScanning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      ref.read(esp32SensorProvider.notifier).scanForDevices();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Device list
          Expanded(
            child: sensorState.availableDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sensorState.isScanning
                              ? Icons.bluetooth_searching
                              : Icons.bluetooth_disabled,
                          size: 64,
                          color: JarvisTheme.textMuted,
                        ),
                        const SizedBox(height: JarvisTheme.spacingMd),
                        Text(
                          sensorState.isScanning
                              ? 'Searching for devices...'
                              : 'No devices found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: JarvisTheme.textMuted,
                          ),
                        ),
                        if (!sensorState.isScanning) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Make sure your iTeaGrow device\nis powered on and nearby',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: JarvisTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(JarvisTheme.spacingMd),
                    itemCount: sensorState.availableDevices.length,
                    itemBuilder: (context, index) {
                      final device = sensorState.availableDevices[index];
                      return _DeviceListTile(
                        device: device,
                        isConnecting:
                            sensorState.connectionState == ESP32ConnectionState.connecting,
                        onConnect: () async {
                          final success = await ref
                              .read(esp32SensorProvider.notifier)
                              .connectToDevice(device.device);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connected to iTeaGrow device'),
                                backgroundColor: JarvisTheme.healthy,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceListTile extends StatelessWidget {
  final ScanResult device;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _DeviceListTile({
    required this.device,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final name = device.device.platformName.isNotEmpty
        ? device.device.platformName
        : device.advertisementData.advName.isNotEmpty
            ? device.advertisementData.advName
            : 'Unknown Device';

    return Card(
      margin: const EdgeInsets.only(bottom: JarvisTheme.spacingSm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: JarvisTheme.teaGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bluetooth, color: JarvisTheme.teaGreen),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Signal: ${device.rssi} dBm',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JarvisTheme.teaGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }
}
