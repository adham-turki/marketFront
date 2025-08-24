# Admin Notification System

This document explains how to implement and use the comprehensive notification system for admin pages in the Flutter application.

## Overview

The notification system provides real-time alerts for administrators about important events such as:

- **Low stock alerts** - When products are running low on inventory
- **New customer registrations** - When new users sign up
- **Order status changes** - Important order updates
- **System alerts** - General admin notifications
- **Real-time updates** - Live notifications with polling

## Features

### 1. **Real-time Notifications**

- Automatic polling every 2 minutes for new notifications
- Local storage for offline access
- Priority-based notification sorting
- Expiration handling for old notifications

### 2. **Notification Types**

- `lowStock` - Product inventory alerts
- `newCustomer` - User registration notifications
- `orderStatus` - Order update alerts
- `systemAlert` - System-wide notifications
- `promotion` - Promotion and coupon alerts
- `payment` - Payment-related notifications

### 3. **Priority Levels**

- `urgent` - Critical alerts (red)
- `high` - Important alerts (orange)
- `medium` - Standard notifications (default)
- `low` - Informational notifications

### 4. **UI Components**

- **Notification Bell** - Shows unread count with badge
- **Notification Panel** - Full notification management interface
- **Notification Dashboard** - Summary of important alerts
- **Alert Cards** - Visual representation of different alert types

## Implementation

### 1. **Setup Provider**

Add the `NotificationProvider` to your main app:

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

### 2. **Initialize Service**

Initialize the notification service in your admin main screen:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<NotificationService>().initialize();
  });
}
```

### 3. **Add Notification Bell**

Include the notification bell in your app bar:

```dart
AppBar(
  actions: [
    const NotificationBell(),
    // ... other actions
  ],
)
```

### 4. **Create Notifications**

#### **Low Stock Alerts**

```dart
// Check for low stock products
await notificationService.checkLowStockProducts();

// Create custom low stock notification
notificationService.createLocalNotification(
  title: 'Low Stock Alert',
  message: 'Product X is running low on stock',
  type: NotificationType.lowStock,
  priority: NotificationPriority.high,
  metadata: {
    'product_id': '123',
    'current_stock': 5,
    'min_stock': 10,
  },
  actionUrl: '/admin/products/123',
  actionLabel: 'View Product',
);
```

#### **New Customer Notifications**

```dart
// Check for new customers
await notificationService.checkNewCustomers();

// Create custom customer notification
notificationService.createLocalNotification(
  title: 'New Customer Registration',
  message: 'John Doe has just registered',
  type: NotificationType.newCustomer,
  priority: NotificationPriority.medium,
  metadata: {
    'user_id': '456',
    'user_name': 'John Doe',
    'registration_time': DateTime.now().toIso8601String(),
  },
  actionUrl: '/admin/users/456',
  actionLabel: 'View Customer',
);
```

#### **Order Status Notifications**

```dart
// Create order status notification
notificationService.createLocalNotification(
  title: 'Order Status Updated',
  message: 'Order #123 has been shipped',
  type: NotificationType.orderStatus,
  priority: NotificationPriority.medium,
  metadata: {
    'order_id': '123',
    'old_status': 'processing',
    'new_status': 'shipped',
  },
  actionUrl: '/admin/orders/123',
  actionLabel: 'View Order',
);
```

### 5. **Integration Examples**

#### **Products Screen Integration**

```dart
class AdminProductsScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _loadProducts();

    // Check for low stock products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLowStockProducts();
    });
  }

  Future<void> _checkLowStockProducts() async {
    try {
      final notificationService = context.read<NotificationService>();
      await notificationService.checkLowStockProducts();
    } catch (e) {
      print('Error checking low stock products: $e');
    }
  }

  // Create notification when stock is updated
  void _createStockUpdateNotification(Map<String, dynamic> product, int oldStock, int newStock) {
    final notificationService = context.read<NotificationService>();

    if (newStock <= (product['min_stock_level'] ?? 5)) {
      notificationService.createLocalNotification(
        title: 'Low Stock Alert',
        message: '${product['name']} stock is now low (Current: $newStock)',
        type: NotificationType.lowStock,
        priority: newStock == 0 ? NotificationPriority.urgent : NotificationPriority.high,
        metadata: {
          'product_id': product['id'],
          'product_name': product['name'],
          'current_stock': newStock,
          'min_stock': product['min_stock_level'] ?? 5,
        },
        actionUrl: '/admin/products/${product['id']}',
        actionLabel: 'View Product',
      );
    }
  }
}
```

#### **Users Screen Integration**

```dart
class AdminUsersScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Check for new customers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewCustomers();
    });
  }

  Future<void> _checkNewCustomers() async {
    try {
      final notificationService = context.read<NotificationService>();
      await notificationService.checkNewCustomers();
    } catch (e) {
      print('Error checking new customers: $e');
    }
  }

  // Create notification when new user is added
  void _createNewUserNotification(Map<String, dynamic> user) {
    final notificationService = context.read<NotificationService>();

    notificationService.createLocalNotification(
      title: 'New User Added',
      message: '${user['full_name']} has been added to the system',
      type: NotificationType.newCustomer,
      priority: NotificationPriority.medium,
      metadata: {
        'user_id': user['id'],
        'user_name': user['full_name'],
        'added_by': 'admin',
      },
      actionUrl: '/admin/users/${user['id']}',
      actionLabel: 'View User',
    );
  }
}
```

#### **Orders Screen Integration**

```dart
class AdminOrdersScreen extends StatefulWidget {
  // Create notification when order status changes
  void _createOrderStatusNotification(Map<String, dynamic> order, String oldStatus, String newStatus) {
    final notificationService = context.read<NotificationService>();

    // Only notify for important status changes
    if (['shipped', 'delivered', 'cancelled'].contains(newStatus)) {
      notificationService.createLocalNotification(
        title: 'Order Status Updated',
        message: 'Order #${order['id']} status changed from $oldStatus to $newStatus',
        type: NotificationType.orderStatus,
        priority: newStatus == 'cancelled' ? NotificationPriority.high : NotificationPriority.medium,
        metadata: {
          'order_id': order['id'],
          'old_status': oldStatus,
          'new_status': newStatus,
          'customer_name': order['customer_name'],
        },
        actionUrl: '/admin/orders/${order['id']}',
        actionLabel: 'View Order',
      );
    }
  }

  // Create notification for large orders
  void _createLargeOrderNotification(Map<String, dynamic> order) {
    final total = order['total'] ?? 0.0;
    if (total > 1000) { // Notify for orders over 1000
      final notificationService = context.read<NotificationService>();

      notificationService.createLocalNotification(
        title: 'Large Order Received',
        message: 'Order #${order['id']} worth ${total.toStringAsFixed(2)}₪ has been placed',
        type: NotificationType.orderStatus,
        priority: NotificationPriority.high,
        metadata: {
          'order_id': order['id'],
          'order_total': total,
          'customer_name': order['customer_name'],
        },
        actionUrl: '/admin/orders/${order['id']}',
        actionLabel: 'Review Order',
      );
    }
  }
}
```

## API Endpoints

The notification system expects these backend endpoints:

### **GET /admin/notifications**

Fetch all notifications for the admin.

### **PUT /admin/notifications/{id}/read**

Mark a specific notification as read.

### **PUT /admin/notifications/read-all**

Mark all notifications as read.

### **DELETE /admin/notifications/{id}**

Delete a specific notification.

### **DELETE /admin/notifications/clear-all**

Clear all notifications.

### **GET /admin/products/low-stock**

Fetch products with low stock levels.

### **GET /admin/users/recent**

Fetch recently registered users.

## Customization

### **Adding New Notification Types**

1. Add new type to `NotificationType` enum
2. Update the icon mapping in `NotificationPanel`
3. Add corresponding Arabic text constants
4. Implement the notification logic

### **Modifying Priority Logic**

1. Update the priority assignment in your business logic
2. Modify the visual indicators in the UI
3. Adjust the sorting and filtering logic

### **Changing Polling Frequency**

Modify the timer duration in `NotificationService._startPolling()`:

```dart
_pollingTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
  _fetchNotificationsFromServer();
});
```

## Best Practices

### **1. Notification Frequency**

- Don't spam users with too many notifications
- Use appropriate priority levels
- Set expiration dates for time-sensitive notifications

### **2. Action URLs**

- Provide meaningful action URLs for each notification
- Include relevant metadata for context
- Make notifications actionable

### **3. Performance**

- Use local storage for offline access
- Implement proper cleanup for expired notifications
- Avoid creating duplicate notifications

### **4. User Experience**

- Show notification count badges
- Provide clear action buttons
- Use appropriate colors and icons for different types

## Troubleshooting

### **Common Issues**

1. **Notifications not showing**

   - Check if `NotificationProvider` is properly initialized
   - Verify the service is added to the widget tree
   - Check console for error messages

2. **Polling not working**

   - Ensure the service is initialized
   - Check network connectivity
   - Verify API endpoints are accessible

3. **Local storage issues**
   - Check `shared_preferences` package is added
   - Verify storage permissions
   - Clear app data if needed

### **Debug Mode**

Enable debug logging by checking the console output:

```dart
if (kDebugMode) {
  print('Notification created: ${notification.title}');
}
```

## Conclusion

This notification system provides a comprehensive solution for keeping administrators informed about important events in real-time. It's designed to be flexible, performant, and user-friendly while maintaining good separation of concerns and following Flutter best practices.

For additional features or customization, refer to the individual component files and modify them according to your specific requirements.
