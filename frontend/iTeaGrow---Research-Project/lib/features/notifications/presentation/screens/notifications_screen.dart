import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';

/// Notifications Screen
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<NotificationItem> _allNotifications = _generateMockNotifications();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: TeaTypography.titleLarge.copyWith(color: TeaColors.nearBlack),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: TeaColors.freshLeaf),
            onPressed: () {
              setState(() {
                for (var n in _allNotifications) {
                  n.isRead = true;
                }
              });
              TeaSnackbar.success(context, 'All notifications marked as read');
            },
            tooltip: 'Mark all as read',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: TeaColors.freshLeaf,
          unselectedLabelColor: TeaColors.darkGray,
          indicatorColor: TeaColors.freshLeaf,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('All'),
                  const SizedBox(width: 4),
                  _buildBadge(_allNotifications.length),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Alerts'),
                  const SizedBox(width: 4),
                  _buildBadge(_allNotifications.where((n) => n.type == NotificationType.alert).length),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Updates'),
                  const SizedBox(width: 4),
                  _buildBadge(_allNotifications.where((n) => n.type == NotificationType.update).length),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_allNotifications),
          _buildNotificationList(_allNotifications.where((n) => n.type == NotificationType.alert).toList()),
          _buildNotificationList(_allNotifications.where((n) => n.type == NotificationType.update).toList()),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TeaColors.freshLeaf.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TeaTypography.labelSmall.copyWith(
          color: TeaColors.freshLeaf,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItem> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: TeaColors.mediumGray,
            ),
            const SizedBox(height: TeaSpacing.md),
            Text(
              'No notifications',
              style: TeaTypography.titleMedium.copyWith(
                color: TeaColors.darkGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: TeaSpacing.screenPadding,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: TeaSpacing.lg),
        decoration: BoxDecoration(
          color: TeaColors.alertRust,
          borderRadius: TeaRadius.radiusMd,
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _allNotifications.remove(notification);
        });
        TeaSnackbar.info(context, 'Notification deleted');
      },
      child: TeaCard.elevated(
        margin: const EdgeInsets.only(bottom: TeaSpacing.sm),
        onTap: () {
          setState(() => notification.isRead = true);
          _handleNotificationTap(notification);
        },
        child: Container(
          decoration: BoxDecoration(
            border: notification.isRead
                ? null
                : Border(
                    left: BorderSide(
                      color: _getNotificationColor(notification.type),
                      width: 3,
                    ),
                  ),
          ),
          child: Padding(
            padding: TeaSpacing.cardPaddingMd,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(TeaSpacing.sm),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: TeaRadius.radiusSm,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: TeaSpacing.smd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TeaTypography.titleSmall.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: TeaColors.freshLeaf,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TeaTypography.bodySmall.copyWith(
                          color: TeaColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.timeAgo,
                        style: TeaTypography.labelSmall.copyWith(
                          color: TeaColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return TeaColors.alertRust;
      case NotificationType.warning:
        return TeaColors.warningAmber;
      case NotificationType.success:
        return TeaColors.healthyGreen;
      case NotificationType.update:
        return TeaColors.infoSky;
      case NotificationType.info:
        return TeaColors.freshLeaf;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.update:
        return Icons.system_update_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (notification.route != null) {
      context.push(notification.route!);
    }
  }
}

enum NotificationType { alert, warning, success, update, info }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String timeAgo;
  final String? route;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timeAgo,
    this.route,
    this.isRead = false,
  });
}

List<NotificationItem> _generateMockNotifications() {
  return [
    NotificationItem(
      id: '1',
      title: 'Disease Alert: Blister Blight',
      message: 'High risk of blister blight detected in Block A3. Immediate action recommended.',
      type: NotificationType.alert,
      timeAgo: '10 minutes ago',
      route: '/disease-detection',
    ),
    NotificationItem(
      id: '2',
      title: 'Harvest Reminder',
      message: 'Block B2 leaves are ready for harvest (P+2 stage). Schedule picking within 2 days.',
      type: NotificationType.warning,
      timeAgo: '1 hour ago',
      route: '/plants',
    ),
    NotificationItem(
      id: '3',
      title: 'IoT Sensor Connected',
      message: 'New soil moisture sensor successfully paired and calibrated.',
      type: NotificationType.success,
      timeAgo: '2 hours ago',
      route: '/iot-devices',
    ),
    NotificationItem(
      id: '4',
      title: 'App Update Available',
      message: 'Version 1.1.0 is now available with new disease detection models.',
      type: NotificationType.update,
      timeAgo: '5 hours ago',
    ),
    NotificationItem(
      id: '5',
      title: 'Weekly Report Ready',
      message: 'Your plantation health report for this week is ready to view.',
      type: NotificationType.info,
      timeAgo: 'Yesterday',
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      title: 'Temperature Alert',
      message: 'Temperature in Block C1 exceeded 32°C. Monitor plant stress levels.',
      type: NotificationType.warning,
      timeAgo: 'Yesterday',
      route: '/iot-devices',
      isRead: true,
    ),
  ];
}
