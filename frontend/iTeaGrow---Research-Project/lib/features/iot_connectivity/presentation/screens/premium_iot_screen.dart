import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/providers/iot_live_provider.dart';

/// Premium IoT Devices Screen - Simplified Design
class PremiumIoTScreen extends ConsumerWidget {
  const PremiumIoTScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iotData = ref.watch(iotLiveProvider);
    final device = iotData.deviceList.isNotEmpty ? iotData.deviceList.first : null;
    
    // Check if device is online (data received within last 30 seconds)
    bool isOnline = false;
    if (device != null && device.timestamp != null) {
      final timeDiff = DateTime.now().difference(device.timestamp!);
      isOnline = timeDiff.inSeconds < 30;
    }

    return Scaffold(
      backgroundColor: TeaColors.mistGreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TeaColors.mistGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: TeaColors.nearBlack),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'IoT Devices',
          style: TeaTypography.titleLarge.copyWith(
            color: TeaColors.nearBlack,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TeaColors.freshLeaf.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: TeaColors.freshLeaf),
              onPressed: () {
                ref.invalidate(iotLiveProvider);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(iotLiveProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TeaColors.freshLeaf.withOpacity(0.1),
                      TeaColors.freshLeaf.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Devices',
                      style: TeaTypography.titleLarge.copyWith(
                        color: TeaColors.nearBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor your tea plantation environmental conditions',
                      style: TeaTypography.bodyMedium.copyWith(
                        color: TeaColors.darkGray,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // IoTENV Device Card
              _IoTDeviceCard(
                deviceName: 'IoTENV',
                deviceDescription: 'Environmental Monitoring',
                isOnline: isOnline,
                icon: Icons.thermostat,
                iconColor: Colors.orange,
                metrics: device != null
                    ? [
                        _MetricData(
                          icon: Icons.thermostat,
                          label: 'Temperature',
                          value: '${device.temperature?.toStringAsFixed(1) ?? '--'}°C',
                          color: Colors.deepOrange,
                        ),
                        _MetricData(
                          icon: Icons.water_drop,
                          label: 'Humidity',
                          value: '${device.humidity?.toString() ?? '--'}%',
                          color: Colors.blue,
                        ),
                        _MetricData(
                          icon: Icons.air,
                          label: 'Air Quality',
                          value: device.airQuality != null ? _getAirQualityLabel(device.airQuality!.toInt()) : '--',
                          color: _getAirQualityColor(device.airQuality ?? 0),
                        ),
                      ]
                    : [],
                lastUpdate: device?.timestamp,
              ),

              const SizedBox(height: 20),

              // IoTSOIL Device Card (Coming Soon)
              _IoTDeviceCard(
                deviceName: 'IoTSOIL',
                deviceDescription: 'Soil Monitoring',
                isOnline: false,
                icon: Icons.grass,
                iconColor: Colors.brown,
                metrics: const [],
                comingSoon: true,
              ),

              const SizedBox(height: 28),

              // Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TeaColors.freshLeaf.withOpacity(0.15),
                      TeaColors.freshLeaf.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TeaColors.freshLeaf.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TeaColors.freshLeaf.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TeaColors.freshLeaf.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.info_rounded,
                        color: TeaColors.freshLeaf,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Devices update automatically every 5 seconds when online',
                        style: TeaTypography.bodyMedium.copyWith(
                          color: TeaColors.nearBlack,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
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

  String _getAirQualityLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy';
    if (aqi <= 200) return 'Bad';
    return 'Hazardous';
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
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isOnline
                ? [
                    Colors.white,
                    TeaColors.freshLeaf.withOpacity(0.03),
                  ]
                : [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Device Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor.withOpacity(0.2),
                          iconColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 32,
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
                          style: TeaTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TeaColors.nearBlack,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deviceDescription,
                          style: TeaTypography.bodyMedium.copyWith(
                            color: TeaColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOnline
                              ? [
                                  TeaColors.freshLeaf,
                                  TeaColors.freshLeaf.withOpacity(0.8),
                                ]
                              : [
                                  Colors.grey.shade400,
                                  Colors.grey.shade300,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline ? TeaColors.freshLeaf : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              if (comingSoon) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.construction,
                          color: Colors.amber.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Soil monitoring device will be available soon with NPK, moisture, and pH sensors',
                          style: TeaTypography.bodyMedium.copyWith(
                            color: Colors.amber.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (metrics.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),

                // Metrics Grid
                Row(
                  children: metrics.map((metric) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              metric.color.withOpacity(0.15),
                              metric.color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: metric.color.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: metric.color.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: metric.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                metric.icon,
                                color: metric.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              metric.value,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: metric.color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metric.label,
                              style: TeaTypography.bodySmall.copyWith(
                                color: TeaColors.darkGray,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Last Update
                if (lastUpdate != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: TeaColors.mistGreen.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: TeaColors.darkGray,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last update: ${_getTimeAgo(lastUpdate!)}',
                          style: TeaTypography.bodySmall.copyWith(
                            color: TeaColors.darkGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'No data available. Waiting for device connection...',
                          style: TeaTypography.bodyMedium.copyWith(
                            color: TeaColors.darkGray,
                            height: 1.4,
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
