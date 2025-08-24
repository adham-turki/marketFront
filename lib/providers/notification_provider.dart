import 'package:flutter/foundation.dart';
import '../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  NotificationService get notificationService => _notificationService;

  // Initialize the notification service
  Future<void> initialize() async {
    await _notificationService.initialize();
    _notificationService.addListener(_onNotificationUpdate);
  }

  // Handle notification updates
  void _onNotificationUpdate() {
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationUpdate);
    _notificationService.dispose();
    super.dispose();
  }
}
