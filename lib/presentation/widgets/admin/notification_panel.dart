import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/models/notification_model.dart';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  ArabicText.notifications,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primaryColor,
              tabs: const [
                Tab(text: ArabicText.all),
                Tab(text: ArabicText.unread),
                Tab(text: ArabicText.urgent),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList('all'),
                _buildNotificationList('unread'),
                _buildNotificationList('urgent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(String type) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        List<AdminNotification> notifications = [];

        switch (type) {
          case 'all':
            notifications = notificationProvider.notifications;
            break;
          case 'unread':
            notifications = notificationProvider.notifications
                .where((n) => !n.isRead)
                .toList();
            break;
          case 'urgent':
            notifications = notificationProvider.notifications
                .where((n) => n.priority == 'urgent')
                .toList();
            break;
        }

        if (notifications.isEmpty) {
          return _buildEmptyState(type);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationTile(notification);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'all':
        message = ArabicText.noNotificationsYet;
        icon = Icons.notifications_none;
        break;
      case 'unread':
        message = ArabicText.noUnreadNotifications;
        icon = Icons.mark_email_read;
        break;
      case 'urgent':
        message = ArabicText.noUrgentNotifications;
        icon = Icons.priority_high;
        break;
      default:
        message = ArabicText.noNotificationsYet;
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(AdminNotification notification) {
    final isUrgent = notification.priority == 'urgent';
    final color = isUrgent ? Colors.red : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              notification.isRead ? Colors.grey[300]! : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getNotificationIcon(notification.notificationType),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color:
                        notification.isRead ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    ArabicText.urgent,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: TextStyle(
              fontSize: 14,
              color: notification.isRead ? Colors.grey[600] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatTimestamp(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              if (!notification.isRead)
                TextButton(
                  onPressed: () => _markAsRead(notification.id),
                  child: const Text(
                    ArabicText.markAsRead,
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (notification.actionUrl != null)
                TextButton(
                  onPressed: () => _handleAction(notification),
                  child: Text(
                    '${ArabicText.navigatingTo} ${notification.relatedType ?? ''}',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'stock_alert':
        return Icons.inventory_2;
      case 'customer_registration':
        return Icons.person_add;
      case 'order_update':
        return Icons.shopping_cart;
      case 'system_alert':
        return Icons.warning;
      case 'promotion':
        return Icons.local_offer;
      case 'payment':
        return Icons.payment;
      case 'loyalty_points':
        return Icons.stars;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return ArabicText.justNow;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${ArabicText.minutesAgo}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${ArabicText.hoursAgo}';
    } else {
      return '${difference.inDays} ${ArabicText.daysAgo}';
    }
  }

  void _markAsRead(String id) {
    context.read<NotificationProvider>().markAsRead(id);
  }

  void _handleAction(AdminNotification notification) {
    if (notification.actionUrl != null) {
      // Navigate to the action URL
      Navigator.pop(context);
      // You can implement navigation logic here
      // For example: Navigator.pushNamed(context, notification.actionUrl!);
    }
  }
}
