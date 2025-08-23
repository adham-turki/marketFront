import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import 'products/admin_products_screen.dart';
import 'users/admin_users_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'promotions/admin_promotions_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminProductsScreenWithAuth(),
    const AdminUsersScreenWithAuth(),
    const AdminOrdersScreenWithAuth(),
    const AdminPromotionsScreenWithAuth(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.inventory),
      label: ArabicText.products,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: ArabicText.users,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart),
      label: ArabicText.orders,
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.local_offer),
      label: '${ArabicText.promotions} و ${ArabicText.coupons}',
    ),
  ];

  String get _currentPageTitle {
    switch (_currentIndex) {
      case 0:
        return ArabicText.products;
      case 1:
        return ArabicText.users;
      case 2:
        return ArabicText.orders;
      case 3:
        return ArabicText.promotions;
      default:
        return 'لوحة الإدارة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          _currentPageTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout and navigate back to login
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryText,
          unselectedItemColor: AppColors.textSecondaryColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: _bottomNavItems,
        ),
      ),
    );
  }
}
