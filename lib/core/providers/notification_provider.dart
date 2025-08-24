import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  NotificationService get notificationService => _notificationService;

  // Expose the service methods directly
  int get unreadCount => _notificationService.unreadCount;
  int get urgentCount => _notificationService.urgentCount;
  int get lowStockCount => _notificationService.lowStockCount;
  List<AdminNotification> get notifications =>
      _notificationService.notifications;

  Future<void> initialize() async {
    await _notificationService.initialize();
    notifyListeners();
  }

  void startPolling() {
    // The service starts polling automatically in initialize()
    notifyListeners();
  }

  void stopPolling() {
    _notificationService.stopPolling();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
    notifyListeners();
  }

  void createLocalNotification({
    required String title,
    required String message,
    String notificationType = 'general',
    String priority = 'medium',
    int? relatedId,
    String? relatedType,
    String? actionUrl,
    String? imageUrl,
  }) {
    _notificationService.createLocalNotification(
      title: title,
      message: message,
      notificationType: notificationType,
      priority: priority,
      relatedId: relatedId,
      relatedType: relatedType,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );
    notifyListeners();
  }

  Future<void> checkLowStockProducts() async {
    await _notificationService.checkLowStockProducts();
    notifyListeners();
  }

  Future<void> checkNewCustomers() async {
    await _notificationService.checkNewCustomers();
    notifyListeners();
  }
}
