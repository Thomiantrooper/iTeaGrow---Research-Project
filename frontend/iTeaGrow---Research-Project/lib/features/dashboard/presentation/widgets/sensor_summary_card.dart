import 'package:flutter/material.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';

class SensorSummaryCard extends StatelessWidget {
  const SensorSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Mock data - in real app, this would come from providers
    final sensors = [
      _SensorData(
        label: l10n.sensor_soil_moisture,
        value: '45%',
        status: SensorStatus.optimal,
        icon: Icons.water_drop,
      ),
      _SensorData(
        label: l10n.sensor_soil_ph,
        value: '5.8',
        status: SensorStatus.optimal,
        icon: Icons.science,
      ),
      _SensorData(
        label: l10n.sensor_temperature,
        value: '24°C',
        status: SensorStatus.optimal,
        icon: Icons.thermostat,
      ),
      _SensorData(
        label: l10n.sensor_humidity,
        value: '75%',
        status: SensorStatus.warning,
        icon: Icons.cloud,
      ),
    ];

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
                    const Icon(
                      Icons.sensors,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      l10n.sensor_last_updated,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Text(
                  '2 min ago',
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
            child: Icon(
              sensor.icon,
              color: sensor.status.color,
              size: 18,
            ),
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
              border: Border.all(
                color: sensor.status.color.withOpacity(0.3),
              ),
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
