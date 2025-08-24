class AdminNotification {
  final String id;
  final int userId;
  final String title;
  final String message;
  final String notificationType;
  final String priority;
  final int? relatedId;
  final String? relatedType;
  final String? actionUrl;
  final String? imageUrl;
  final bool isRead;
  final bool isSent;
  final bool sendPush;
  final bool sendEmail;
  final bool sendSms;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  AdminNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    this.relatedId,
    this.relatedType,
    this.actionUrl,
    this.imageUrl,
    required this.isRead,
    required this.isSent,
    required this.sendPush,
    required this.sendEmail,
    required this.sendSms,
    this.scheduledFor,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      notificationType: json['notification_type'] ?? '',
      priority: json['priority'] ?? 'medium',
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      actionUrl: json['action_url'],
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      isSent: json['is_sent'] ?? false,
      sendPush: json['send_push'] ?? false,
      sendEmail: json['send_email'] ?? false,
      sendSms: json['send_sms'] ?? false,
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType,
      'priority': priority,
      'related_id': relatedId,
      'related_type': relatedType,
      'action_url': actionUrl,
      'image_url': imageUrl,
      'is_read': isRead,
      'is_sent': isSent,
      'send_push': sendPush,
      'send_email': sendEmail,
      'send_sms': sendSms,
      'scheduled_for': scheduledFor?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum NotificationType {
  orderUpdate('order_update'),
  promotion('promotion'),
  loyaltyPoints('loyalty_points'),
  stockAlert('stock_alert'),
  customerRegistration('customer_registration'),
  systemAlert('system_alert'),
  payment('payment'),
  general('general');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

enum NotificationPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.medium,
    );
  }
}
