import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/providers/iot_live_provider.dart';

class SensorSummaryCard extends ConsumerWidget {
  const SensorSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final liveState = ref.watch(iotLiveProvider);

    // Pick the first available device from MQTT live feed
    final device = liveState.deviceList.isNotEmpty
        ? liveState.deviceList.first
        : null;

    final hasLive = device != null && device.hasData;

    // Values: prefer MQTT live, fall back to placeholder
    final tempStr = hasLive && device.temperature != null
        ? '${device.temperature!.toStringAsFixed(1)}°C'
        : '—°C';
    final humStr = hasLive && device.humidity != null
        ? '${device.humidity!.toStringAsFixed(0)}%'
        : '—%';
    final soilStr = hasLive && device.soilMoisture != null
        ? '${device.soilMoisture!.toStringAsFixed(0)}%'
        : '—%';
    final airStr = hasLive && device.airQuality != null
        ? '${device.airQuality!.toStringAsFixed(0)} ppm'
        : '— ppm';

    // Status colours based on real ranges
    SensorStatus tempStatus(double? v) {
      if (v == null) return SensorStatus.optimal;
      if (v < 15 || v > 35) return SensorStatus.critical;
      if (v < 18 || v > 30) return SensorStatus.warning;
      return SensorStatus.optimal;
    }
    SensorStatus humStatus(double? v) {
      if (v == null) return SensorStatus.optimal;
      if (v < 40 || v > 95) return SensorStatus.critical;
      if (v < 55 || v > 85) return SensorStatus.warning;
      return SensorStatus.optimal;
    }
    SensorStatus soilStatus(double? v) {
      if (v == null) return SensorStatus.optimal;
      if (v < 20 || v > 90) return SensorStatus.critical;
      if (v < 35 || v > 75) return SensorStatus.warning;
      return SensorStatus.optimal;
    }
    SensorStatus airStatus(double? v) {
      if (v == null) return SensorStatus.optimal;
      if (v > 2000) return SensorStatus.critical;
      if (v > 1000) return SensorStatus.warning;
      return SensorStatus.optimal;
    }

    final sensors = [
      _SensorData(
        label: l10n.sensor_soil_moisture,
        value: soilStr,
        status: soilStatus(device?.soilMoisture),
        icon: Icons.water_drop,
      ),
      _SensorData(
        label: l10n.sensor_temperature,
        value: tempStr,
        status: tempStatus(device?.temperature),
        icon: Icons.thermostat,
      ),
      _SensorData(
        label: l10n.sensor_humidity,
        value: humStr,
        status: humStatus(device?.humidity),
        icon: Icons.cloud,
      ),
      _SensorData(
        label: 'Air Quality',
        value: airStr,
        status: airStatus(device?.airQuality),
        icon: Icons.air,
      ),
    ];

    // Last updated label
    final updatedLabel = hasLive
        ? device.lastSeenLabel
        : liveState.isLoading
            ? 'Loading…'
            : 'No sensor data';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sensors,
                      color: hasLive
                          ? AppTheme.primaryGreen
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      hasLive
                          ? 'Live • ${device.deviceId}'
                          : l10n.sensor_last_updated,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasLive
                                ? AppTheme.primaryGreen
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Text(
                  updatedLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...sensors.map((sensor) => _SensorRow(sensor: sensor)),
          ],
        ),
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final _SensorData sensor;
  const _SensorRow({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: sensor.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(sensor.icon, color: sensor.status.color, size: 18),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              sensor.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: sensor.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: sensor.status.color.withOpacity(0.3)),
            ),
            child: Text(
              sensor.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sensor.status.color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorData {
  final String label;
  final String value;
  final SensorStatus status;
  final IconData icon;

  _SensorData({
    required this.label,
    required this.value,
    required this.status,
    required this.icon,
  });
}
