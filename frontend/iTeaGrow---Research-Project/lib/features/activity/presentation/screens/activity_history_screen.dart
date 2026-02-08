import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Activity History Screen
class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Scans', 'Harvests', 'IoT', 'Alerts'];

  final List<ActivityItem> _activities = _generateMockActivities();

  @override
  Widget build(BuildContext context) {
    final filteredActivities = _selectedFilter == 'All'
        ? _activities
        : _activities.where((a) => a.category == _selectedFilter).toList();

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
          'Activity History',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: TeaColors.freshLeaf),
            onPressed: () => _showDateFilter(),
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: TeaColors.white,
            padding: const EdgeInsets.symmetric(vertical: TeaSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: TeaSpacing.screenPaddingHorizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: TeaSpacing.sm),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      selectedColor: TeaColors.freshLeaf.withOpacity(0.2),
                      checkmarkColor: TeaColors.freshLeaf,
                      labelStyle: TeaTypography.labelMedium.copyWith(
                        color: isSelected ? TeaColors.freshLeaf : TeaColors.darkGray,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Activity List
          Expanded(
            child: filteredActivities.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: TeaSpacing.screenPadding,
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      final showDateHeader = index == 0 ||
                          _getDateHeader(activity.timestamp) !=
                              _getDateHeader(filteredActivities[index - 1].timestamp);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) ...[
                            if (index > 0) const SizedBox(height: TeaSpacing.md),
                            Padding(
                              padding: const EdgeInsets.only(bottom: TeaSpacing.sm),
                              child: Text(
                                _getDateHeader(activity.timestamp),
                                style: TeaTypography.labelMedium.copyWith(
                                  color: TeaColors.darkGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          _buildActivityCard(activity, index),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: TeaColors.mediumGray,
          ),
          const SizedBox(height: TeaSpacing.md),
          Text(
            'No activities found',
            style: TeaTypography.titleMedium.copyWith(
              color: TeaColors.darkGray,
            ),
          ),
          Text(
            'Your activities will appear here',
            style: TeaTypography.bodySmall.copyWith(
              color: TeaColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity, int index) {
    return TeaCard.elevated(
      margin: const EdgeInsets.only(bottom: TeaSpacing.sm),
      onTap: activity.route != null ? () => context.push(activity.route!) : null,
      child: Padding(
        padding: TeaSpacing.cardPaddingMd,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TeaSpacing.sm),
              decoration: BoxDecoration(
                color: activity.color.withOpacity(0.1),
                borderRadius: TeaRadius.radiusSm,
              ),
              child: Icon(
                activity.icon,
                color: activity.color,
                size: 24,
              ),
            ),
            const SizedBox(width: TeaSpacing.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TeaTypography.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: TeaTypography.bodySmall.copyWith(
                      color: TeaColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: TeaColors.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(activity.timestamp),
                        style: TeaTypography.labelSmall.copyWith(
                          color: TeaColors.mediumGray,
                        ),
                      ),
                      const SizedBox(width: TeaSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: activity.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          activity.category,
                          style: TeaTypography.labelSmall.copyWith(
                            color: activity.color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (activity.route != null)
              const Icon(
                Icons.chevron_right,
                color: TeaColors.mediumGray,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms).slideX(begin: 0.05, end: 0);
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return _getDayName(date.weekday);
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDateFilter() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: TeaColors.freshLeaf,
            ),
          ),
          child: child!,
        );
      },
    ).then((range) {
      if (range != null) {
        TeaSnackbar.info(
          context,
          'Filtered: ${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}',
        );
      }
    });
  }
}

class ActivityItem {
  final String title;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final String? route;

  ActivityItem({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.route,
  });
}

List<ActivityItem> _generateMockActivities() {
  final now = DateTime.now();
  return [
    ActivityItem(
      title: 'Leaf scan completed',
      description: 'Block A2 - Healthy detected (98% confidence)',
      category: 'Scans',
      icon: Icons.camera_alt_outlined,
      color: TeaColors.healthyGreen,
      timestamp: now.subtract(const Duration(hours: 2)),
      route: '/disease-detection',
    ),
    ActivityItem(
      title: 'Harvest recorded',
      description: '245 kg from Block B1 - Grade A quality',
      category: 'Harvests',
      icon: Icons.inventory_2_outlined,
      color: TeaColors.goldenSunlight,
      timestamp: now.subtract(const Duration(hours: 5)),
    ),
    ActivityItem(
      title: 'IoT sensor alert',
      description: 'Soil moisture low in Block C3 (32%)',
      category: 'IoT',
      icon: Icons.sensors,
      color: TeaColors.warningAmber,
      timestamp: now.subtract(const Duration(hours: 8)),
      route: '/iot-devices',
    ),
    ActivityItem(
      title: 'Disease detected',
      description: 'Blister blight suspected in Block A3',
      category: 'Alerts',
      icon: Icons.warning_amber_outlined,
      color: TeaColors.alertRust,
      timestamp: now.subtract(const Duration(hours: 12)),
      route: '/disease-detection',
    ),
    ActivityItem(
      title: 'Soil analysis',
      description: 'NPK levels optimal - Block D2',
      category: 'Scans',
      icon: Icons.science_outlined,
      color: TeaColors.richSoil,
      timestamp: now.subtract(const Duration(days: 1)),
      route: '/soil-fertilization',
    ),
    ActivityItem(
      title: 'Harvest recorded',
      description: '189 kg from Block A1 - Grade B quality',
      category: 'Harvests',
      icon: Icons.inventory_2_outlined,
      color: TeaColors.goldenSunlight,
      timestamp: now.subtract(const Duration(days: 1, hours: 3)),
    ),
    ActivityItem(
      title: 'New sensor paired',
      description: 'Temperature sensor #TMP-005 connected',
      category: 'IoT',
      icon: Icons.bluetooth_connected,
      color: TeaColors.infoSky,
      timestamp: now.subtract(const Duration(days: 1, hours: 8)),
      route: '/iot-devices',
    ),
    ActivityItem(
      title: 'Leaf maturity check',
      description: 'Block B2 - P+2 stage ready for harvest',
      category: 'Scans',
      icon: Icons.eco_outlined,
      color: TeaColors.freshLeaf,
      timestamp: now.subtract(const Duration(days: 2)),
      route: '/leaf-maturity',
    ),
    ActivityItem(
      title: 'Weather alert',
      description: 'Heavy rain expected - cover sensitive areas',
      category: 'Alerts',
      icon: Icons.cloud_outlined,
      color: TeaColors.infoSky,
      timestamp: now.subtract(const Duration(days: 2, hours: 5)),
    ),
    ActivityItem(
      title: 'Harvest recorded',
      description: '312 kg from Block C1 - Grade A quality',
      category: 'Harvests',
      icon: Icons.inventory_2_outlined,
      color: TeaColors.goldenSunlight,
      timestamp: now.subtract(const Duration(days: 3)),
    ),
  ];
}
