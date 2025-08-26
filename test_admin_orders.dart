import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/presentation/screens/admin/orders/admin_orders_screen.dart';
import 'lib/presentation/screens/admin/orders/order_details_screen.dart';

void main() {
  group('Admin Orders Tests', () {
    testWidgets('AdminOrdersScreen builds without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminOrdersScreen(),
        ),
      );

      expect(find.text('Order Management'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('OrderDetailsScreen builds without errors',
        (WidgetTester tester) async {
      final testOrder = {
        'id': 1,
        'customer_name': 'Test Customer',
        'customer_email': 'test@example.com',
        'status': 'pending',
        'total_amount': 99.99,
        'items_count': 3,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: OrderDetailsScreen(order: testOrder),
        ),
      );

      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('Order #1'), findsOneWidget);
      expect(find.text('Test Customer'), findsOneWidget);
    });
  });
}
