import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/providers/iot_live_provider.dart';
import 'package:iteagrow/l10n/app_localizations.dart';

class IoTDevicesScreen extends ConsumerWidget {
  const IoTDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final iotData = ref.watch(iotLiveProvider);
    final device = iotData.deviceList.isNotEmpty ? iotData.deviceList.first : null;
    
    // Check if device is online (data received within last 30 seconds)
    bool isOnline = false;
    if (device != null && device.timestamp != null) {
      final timeDiff = DateTime.now().difference(device.timestamp!);
      isOnline = timeDiff.inSeconds < 30;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.iot_title),
        backgroundColor: JarvisTheme.teaGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force refresh by invalidating provider
              ref.invalidate(iotLiveProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(iotLiveProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.iot_devices_heading,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: JarvisTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.iot_devices_subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: JarvisTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // IoTENV Device Card
              _IoTDeviceCard(
                deviceName: l10n.iot_env_device,
                deviceDescription: l10n.iot_env_device_desc,
                isOnline: isOnline,
                icon: Icons.thermostat,
                iconColor: Colors.orange,
                metrics: device != null
                    ? [
                        _MetricData(
                          icon: Icons.thermostat,
                          label: l10n.sensor_temperature,
                          value: '${device.temperature?.toStringAsFixed(1) ?? '--'}°C',
                          color: Colors.deepOrange,
                        ),
                        _MetricData(
                          icon: Icons.water_drop,
                          label: l10n.sensor_humidity,
                          value: '${device.humidity?.toString() ?? '--'}%',
                          color: Colors.blue,
                        ),
                        _MetricData(
                          icon: Icons.air,
                          label: l10n.iot_air_quality,
                          value: device.airQuality?.toStringAsFixed(0) ?? '--',
                          color: _getAirQualityColor(device.airQuality ?? 0),
                        ),
                      ]
                    : [],
                lastUpdate: device?.timestamp,
              ),

              const SizedBox(height: 16),

              // IoTSOIL Device Card (Coming Soon)
              _IoTDeviceCard(
                deviceName: l10n.iot_soil_device,
                deviceDescription: l10n.iot_soil_device_desc,
                isOnline: false,
                icon: Icons.grass,
                iconColor: Colors.brown,
                metrics: const [],
                comingSoon: true,
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: JarvisTheme.teaGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: JarvisTheme.teaGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: JarvisTheme.teaGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.iot_auto_update,
                        style: const TextStyle(
                          fontSize: 13,
                          color: JarvisTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAirQualityColor(double value) {
    if (value < 50) return Colors.green;
    if (value < 100) return Colors.yellow.shade700;
    if (value < 150) return Colors.orange;
    return Colors.red;
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _IoTDeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceDescription;
  final bool isOnline;
  final IconData icon;
  final Color iconColor;
  final List<_MetricData> metrics;
  final DateTime? lastUpdate;
  final bool comingSoon;

  const _IoTDeviceCard({
    required this.deviceName,
    required this.deviceDescription,
    required this.isOnline,
    required this.icon,
    required this.iconColor,
    required this.metrics,
    this.lastUpdate,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOnline 
              ? JarvisTheme.teaGreen.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOnline
                ? [
                    Colors.white,
                    JarvisTheme.teaGreen.withOpacity(0.05),
                  ]
                : [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Device Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Device Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: JarvisTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deviceDescription,
                          style: const TextStyle(
                            fontSize: 13,
                            color: JarvisTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.common_coming_soon,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppTheme.statusGood.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOnline
                              ? AppTheme.statusGood.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppTheme.statusGood
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? AppLocalizations.of(context)!.common_online : AppLocalizations.of(context)!.common_offline,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOnline
                                  ? AppTheme.statusGood
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (comingSoon) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.construction,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.iot_soil_soon,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (metrics.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Metrics Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics.map((metric) {
                    return Container(
                      width: (MediaQuery.of(context).size.width - 96) / 3,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: metric.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: metric.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            metric.icon,
                            color: metric.color,
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            metric.value,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: metric.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: JarvisTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                // Last Update
                if (lastUpdate != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppLocalizations.of(context)!.iot_last_update}: ${_getTimeAgo(lastUpdate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.iot_no_data,
                          style: const TextStyle(
                            fontSize: 13,
                            color: JarvisTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
