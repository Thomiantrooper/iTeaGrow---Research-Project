import 'package:flutter/material.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/enums/app_enums.dart';

class AlertListWidget extends StatelessWidget {
  final int maxItems;

  const AlertListWidget({
    super.key,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Mock data - in real app, this would come from database
    final alerts = [
      _AlertData(
        severity: AlertSeverity.warning,
        message: 'Soil moisture level below optimal range',
        timestamp: '10 min ago',
      ),
      _AlertData(
        severity: AlertSeverity.info,
        message: 'New fertilizer recommendation available',
        timestamp: '1 hour ago',
      ),
      _AlertData(
        severity: AlertSeverity.critical,
        message: 'IoT device disconnected',
        timestamp: '2 hours ago',
      ),
    ];

    if (alerts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppTheme.statusGood,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'No alerts',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: alerts.take(maxItems).map((alert) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: alert.severity.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                _getAlertIcon(alert.severity),
                color: alert.severity.color,
                size: 20,
              ),
            ),
            title: Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: Text(
              alert.timestamp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                // Dismiss alert
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber_outlined;
      case AlertSeverity.critical:
        return Icons.error_outline;
    }
  }
}

class _AlertData {
  final AlertSeverity severity;
  final String message;
  final String timestamp;

  _AlertData({
    required this.severity,
    required this.message,
    required this.timestamp,
  });
}
