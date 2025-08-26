import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import '../../../core/providers/notification_provider.dart';
import 'notification_panel.dart';

class NotificationDashboard extends StatelessWidget {
  const NotificationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final urgentCount = notificationProvider.urgentCount;
        final lowStockCount = notificationProvider.lowStockCount;
        final unreadCount = notificationProvider.unreadCount;

        if (urgentCount == 0 && lowStockCount == 0 && unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    ArabicText.importantAlerts,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Alert Cards
              if (urgentCount > 0)
                _buildAlertCard(
                  context,
                  'urgent',
                  urgentCount,
                  Colors.red,
                  Icons.priority_high,
                  ArabicText.urgentNotifications,
                ),

              if (lowStockCount > 0)
                _buildAlertCard(
                  context,
                  'low_stock',
                  lowStockCount,
                  Colors.orange,
                  Icons.inventory_2,
                  ArabicText.lowStockProducts,
                ),

              if (unreadCount > 0)
                _buildAlertCard(
                  context,
                  'unread',
                  unreadCount,
                  Colors.blue,
                  Icons.mark_email_unread,
                  ArabicText.unreadNotifications,
                ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showNotificationPanel(context),
                      icon: const Icon(Icons.visibility),
                      label: const Text(ArabicText.viewAll),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notificationProvider.markAllAsRead(),
                      icon: const Icon(Icons.check_circle),
                      label: const Text(ArabicText.markAllAsRead),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: const BorderSide(color: AppColors.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String type,
    int count,
    Color color,
    IconData icon,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  '$count ${ArabicText.items}',
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationPanel(),
    );
  }
}
