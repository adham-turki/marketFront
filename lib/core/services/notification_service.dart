import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../network/api_service.dart';

class NotificationService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final List<AdminNotification> _notifications = [];
  bool _isInitialized = false;
  bool _isPolling = false;

  List<AdminNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get urgentCount =>
      _notifications.where((n) => n.priority == 'urgent' && !n.isRead).length;
  int get lowStockCount => _notifications
      .where((n) => n.notificationType == 'stock_alert' && !n.isRead)
      .length;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadNotificationsFromStorage();
    await fetchNotificationsFromServer();
    _startPolling();
    _isInitialized = true;
  }

  void _startPolling() {
    if (_isPolling) return;
    _isPolling = true;

    // Poll every 30 seconds for new notifications
    Future.delayed(const Duration(seconds: 30), () {
      if (_isPolling) {
        fetchNotificationsFromServer();
        _startPolling();
      }
    });
  }

  void stopPolling() {
    _isPolling = false;
  }

  Future<void> fetchNotificationsFromServer() async {
    try {
      final response = await _apiService.get('/notifications');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> notificationsData = response.data['data'] ?? [];

        _notifications.clear();
        _notifications.addAll(
            notificationsData.map((json) => AdminNotification.fromJson(json)));

        await _saveNotificationsToStorage();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching notifications: $e');
      }
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await _apiService.put('/notifications/$id/read');

      if (response.statusCode == 200) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          // Create a new notification with updated read status
          final notification = _notifications[index];
          final updatedNotification = AdminNotification(
            id: notification.id,
            userId: notification.userId,
            title: notification.title,
            message: notification.message,
            notificationType: notification.notificationType,
            priority: notification.priority,
            relatedId: notification.relatedId,
            relatedType: notification.relatedType,
            actionUrl: notification.actionUrl,
            imageUrl: notification.imageUrl,
            isRead: true,
            isSent: notification.isSent,
            sendPush: notification.sendPush,
            sendEmail: notification.sendEmail,
            sendSms: notification.sendSms,
            scheduledFor: notification.scheduledFor,
            sentAt: notification.sentAt,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
          );

          _notifications[index] = updatedNotification;
          await _saveNotificationsToStorage();
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.put('/notifications/mark-all-read');

      if (response.statusCode == 200) {
        for (int i = 0; i < _notifications.length; i++) {
          final notification = _notifications[i];
          if (!notification.isRead) {
            final updatedNotification = AdminNotification(
              id: notification.id,
              userId: notification.userId,
              title: notification.title,
              message: notification.message,
              notificationType: notification.notificationType,
              priority: notification.priority,
              relatedId: notification.relatedId,
              relatedType: notification.relatedType,
              actionUrl: notification.actionUrl,
              imageUrl: notification.imageUrl,
              isRead: true,
              isSent: notification.isSent,
              sendPush: notification.sendPush,
              sendEmail: notification.sendEmail,
              sendSms: notification.sendSms,
              scheduledFor: notification.scheduledFor,
              sentAt: notification.sentAt,
              readAt: DateTime.now(),
              createdAt: notification.createdAt,
            );
            _notifications[i] = updatedNotification;
          }
        }

        await _saveNotificationsToStorage();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all notifications as read: $e');
      }
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final response = await _apiService.delete('/notifications/$id');

      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n.id == id);
        await _saveNotificationsToStorage();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final response = await _apiService.delete('/notifications/clear-all');

      if (response.statusCode == 200) {
        _notifications.clear();
        await _saveNotificationsToStorage();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all notifications: $e');
      }
    }
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
    final notification = AdminNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 1, // Default admin user ID
      title: title,
      message: message,
      notificationType: notificationType,
      priority: priority,
      relatedId: relatedId,
      relatedType: relatedType,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
      isRead: false,
      isSent: false,
      sendPush: false,
      sendEmail: false,
      sendSms: false,
      scheduledFor: null,
      sentAt: null,
      readAt: null,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _saveNotificationsToStorage();
    notifyListeners();
  }

  Future<void> checkLowStockProducts() async {
    try {
      final response = await _apiService.get('/products/low-stock');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> lowStockProducts = response.data['data'] ?? [];

        for (final product in lowStockProducts) {
          final existingNotification = _notifications.any((n) =>
              n.notificationType == 'stock_alert' &&
              n.relatedId == product['id']);

          if (!existingNotification) {
            createLocalNotification(
              title: 'تنبيه مخزون منخفض',
              message:
                  '${product['name']} وصل إلى الحد الأدنى للمخزون (المخزون الحالي: ${product['stock_quantity']})',
              notificationType: 'stock_alert',
              priority: product['stock_quantity'] == 0 ? 'urgent' : 'high',
              relatedId: product['id'],
              relatedType: 'product',
              actionUrl: '/admin/products/${product['id']}',
              imageUrl: 'https://example.com/stock-icon.png',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking low stock products: $e');
      }
    }
  }

  Future<void> checkNewCustomers() async {
    try {
      final response = await _apiService.get('/users/recent');

      if (response.statusCode == 200 && response.data['success']) {
        final List<dynamic> recentUsers = response.data['data'] ?? [];

        for (final user in recentUsers) {
          final existingNotification = _notifications.any((n) =>
              n.notificationType == 'customer_registration' &&
              n.relatedId == user['id']);

          if (!existingNotification) {
            createLocalNotification(
              title: 'عميل جديد مسجل',
              message: 'تم تسجيل عميل جديد: ${user['name']} (${user['email']})',
              notificationType: 'customer_registration',
              priority: 'medium',
              relatedId: user['id'],
              relatedType: 'customer',
              actionUrl: '/admin/users/${user['id']}',
              imageUrl: 'https://example.com/customer-icon.png',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking new customers: $e');
      }
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString('notifications', jsonEncode(notificationsJson));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notifications to storage: $e');
      }
    }
  }

  Future<void> _loadNotificationsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsString = prefs.getString('notifications');

      if (notificationsString != null) {
        final List<dynamic> notificationsJson = jsonDecode(notificationsString);
        _notifications.clear();
        _notifications.addAll(
            notificationsJson.map((json) => AdminNotification.fromJson(json)));
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications from storage: $e');
      }
    }
  }
}
