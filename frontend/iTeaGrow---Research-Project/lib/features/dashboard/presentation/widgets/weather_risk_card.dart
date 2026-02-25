import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/jarvis_theme.dart';
import '../../../../core/widgets/hologram_card.dart';
import '../../../../core/providers/iot_live_provider.dart';

/// Weather-based disease risk alert card
class WeatherRiskCard extends ConsumerStatefulWidget {
  const WeatherRiskCard({super.key});

  @override
  ConsumerState<WeatherRiskCard> createState() => _WeatherRiskCardState();
}

class _WeatherRiskCardState extends ConsumerState<WeatherRiskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  final WeatherRiskData _riskData = WeatherRiskData(
    riskLevel: RiskLevel.moderate,
    disease: 'Blister Blight',
    forecast: 'Foggy morning expected',
    recommendation: 'Inspect leaves early morning. Consider preventive spray.',
  );

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(iotLiveProvider);
    final device = liveState.deviceList.isNotEmpty ? liveState.deviceList.first : null;
    final liveTemp = device?.temperature;
    final liveHumidity = device?.humidity;

    return HologramCard(
      enableGlow: _riskData.riskLevel != RiskLevel.low,
      glowColor: _riskData.riskColor,
      enable3DEffect: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with risk level
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _riskData.riskLevel == RiskLevel.high
                        ? _pulseAnimation.value
                        : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _riskData.riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _riskData.riskLevel != RiskLevel.low
                            ? [
                                BoxShadow(
                                  color: _riskData.riskColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _riskData.riskIcon,
                        color: _riskData.riskColor,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: JarvisTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _riskData.riskColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _riskData.riskLevel.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _riskData.riskColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Risk',
                          style: TextStyle(
                            fontSize: 12,
                            color: JarvisTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_riskData.disease} Alert',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: JarvisTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Weather icon
              Column(
                children: [
                  const Icon(
                    Icons.cloud,
                    color: JarvisTheme.textMuted,
                    size: 32,
                  ),
                  Text(
                    liveTemp != null ? '${liveTemp.toStringAsFixed(0)}°C' : '--°C',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: JarvisTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: JarvisTheme.spacingMd),

          // Weather conditions
          Container(
            padding: const EdgeInsets.all(JarvisTheme.spacingSm),
            decoration: BoxDecoration(
              color: JarvisTheme.mistGray,
              borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
            ),
            child: Row(
              children: [
                _buildWeatherChip(
                  Icons.thermostat_outlined,
                  liveTemp != null ? '${liveTemp.toStringAsFixed(1)}°C' : '--°C',
                  Colors.deepOrange,
                ),
                const SizedBox(width: JarvisTheme.spacingSm),
                _buildWeatherChip(
                  Icons.water_drop_outlined,
                  liveHumidity != null ? '${liveHumidity.toStringAsFixed(0)}%' : '--%',
                  Colors.blue,
                ),
                const SizedBox(width: JarvisTheme.spacingSm),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wb_cloudy_outlined,
                        size: 16,
                        color: JarvisTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _riskData.forecast,
                          style: const TextStyle(
                            fontSize: 12,
                            color: JarvisTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: JarvisTheme.spacingMd),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(JarvisTheme.spacingMd),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _riskData.riskColor.withOpacity(0.08),
                  _riskData.riskColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(JarvisTheme.radiusMd),
              border: Border.all(
                color: _riskData.riskColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _riskData.riskColor,
                  size: 20,
                ),
                const SizedBox(width: JarvisTheme.spacingSm),
                Expanded(
                  child: Text(
                    _riskData.recommendation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: JarvisTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: JarvisTheme.spacingSm),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Show detailed forecast
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('7-Day Forecast'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JarvisTheme.teaGreen,
                    side: BorderSide(color: JarvisTheme.teaGreen.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: JarvisTheme.spacingSm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show prevention guide
                  },
                  icon: const Icon(Icons.shield_outlined, size: 18),
                  label: const Text('Prevention'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _riskData.riskColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum RiskLevel {
  low('Low Risk'),
  moderate('Moderate'),
  high('High Risk');

  final String label;
  const RiskLevel(this.label);
}

class WeatherRiskData {
  final RiskLevel riskLevel;
  final String disease;
  final String forecast;
  final String recommendation;

  WeatherRiskData({
    required this.riskLevel,
    required this.disease,
    required this.forecast,
    required this.recommendation,
  });

  Color get riskColor {
    switch (riskLevel) {
      case RiskLevel.low:
        return JarvisTheme.healthy;
      case RiskLevel.moderate:
        return JarvisTheme.warning;
      case RiskLevel.high:
        return JarvisTheme.critical;
    }
  }

  IconData get riskIcon {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle_outline;
      case RiskLevel.moderate:
        return Icons.warning_amber_outlined;
      case RiskLevel.high:
        return Icons.error_outline;
    }
  }
}

/// Seasonal planning widget
class SeasonalPlanningCard extends StatelessWidget {
  const SeasonalPlanningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;
    final season = _getSeason(currentMonth);

    return HologramCard(
      enableGlow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: JarvisTheme.teaGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  season.icon,
                  color: JarvisTheme.teaGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: JarvisTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      season.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: JarvisTheme.textPrimary,
                      ),
                    ),
                    Text(
                      season.period,
                      style: const TextStyle(
                        fontSize: 12,
                        color: JarvisTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: JarvisTheme.spacingMd),

          // Tasks for this season
          ...season.tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: task.priority == TaskPriority.high
                            ? JarvisTheme.critical
                            : task.priority == TaskPriority.medium
                                ? JarvisTheme.warning
                                : JarvisTheme.teaGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: JarvisTheme.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      task.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: task.completed
                          ? JarvisTheme.healthy
                          : JarvisTheme.textMuted,
                    ),
                  ],
                ),
              ),),
        ],
      ),
    );
  }

  TeaSeason _getSeason(int month) {
    // Sri Lanka tea seasons
    if (month >= 3 && month <= 5) {
      return TeaSeason(
        name: 'First Flush Season',
        period: 'March - May',
        icon: Icons.eco,
        tasks: [
          SeasonTask('Monitor for Blister Blight', priority: TaskPriority.high),
          SeasonTask('Apply balanced NPK fertilizer', priority: TaskPriority.medium),
          SeasonTask('Regular plucking every 7-10 days', priority: TaskPriority.high),
          SeasonTask('Check shade tree coverage', priority: TaskPriority.low),
        ],
      );
    } else if (month >= 6 && month <= 8) {
      return TeaSeason(
        name: 'Monsoon Season',
        period: 'June - August',
        icon: Icons.water_drop,
        tasks: [
          SeasonTask('Improve drainage', priority: TaskPriority.high),
          SeasonTask('Monitor for fungal diseases', priority: TaskPriority.high),
          SeasonTask('Reduce nitrogen application', priority: TaskPriority.medium),
          SeasonTask('Prune for air circulation', priority: TaskPriority.medium),
        ],
      );
    } else if (month >= 9 && month <= 11) {
      return TeaSeason(
        name: 'Quality Season',
        period: 'September - November',
        icon: Icons.star,
        tasks: [
          SeasonTask('Fine plucking for quality', priority: TaskPriority.high),
          SeasonTask('Reduce plucking interval', priority: TaskPriority.medium),
          SeasonTask('Monitor for mites', priority: TaskPriority.medium),
          SeasonTask('Prepare for dry season', priority: TaskPriority.low),
        ],
      );
    } else {
      return TeaSeason(
        name: 'Dry Season',
        period: 'December - February',
        icon: Icons.wb_sunny,
        tasks: [
          SeasonTask('Irrigation management', priority: TaskPriority.high),
          SeasonTask('Mulching to retain moisture', priority: TaskPriority.high),
          SeasonTask('Watch for Red Spider Mite', priority: TaskPriority.medium),
          SeasonTask('Soil testing for next season', priority: TaskPriority.low),
        ],
      );
    }
  }
}

class TeaSeason {
  final String name;
  final String period;
  final IconData icon;
  final List<SeasonTask> tasks;

  TeaSeason({
    required this.name,
    required this.period,
    required this.icon,
    required this.tasks,
  });
}

enum TaskPriority { low, medium, high }

class SeasonTask {
  final String title;
  final TaskPriority priority;
  final bool completed;

  SeasonTask(
    this.title, {
    this.priority = TaskPriority.medium,
    this.completed = false,
  });
}
