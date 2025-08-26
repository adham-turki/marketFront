import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design Patterns for TradeSuper App
/// This file shows how to implement the correct color usage:
/// - White as primary background
/// - Secondary background color for creative design elements
/// - Primary text color for important text

class DesignPatterns {
  /// Example 1: App Header with Creative Design
  /// This matches the design in your image
  static Widget appHeader() {
    return Container(
      color: AppColors.white, // Main background
      child: Column(
        children: [
          // Creative header section using secondary background color
          Container(
            color: AppColors.secondaryBackground,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Hamburger menu icon
                const Icon(
                  Icons.menu,
                  color: AppColors.white,
                  size: 24,
                ),
                const SizedBox(width: 16),
                // Search bar
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Search products...',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Shopping cart icon
                const Icon(
                  Icons.shopping_cart,
                  color: AppColors.white,
                  size: 24,
                ),
              ],
            ),
          ),
          // Curved design element (like in your image)
          Container(
            color: AppColors.white,
            child: CustomPaint(
              painter: CurvedPainter(),
              child: Container(height: 40),
            ),
          ),
        ],
      ),
    );
  }

  /// Example 2: Main Content Section
  static Widget mainContent() {
    return Container(
      color: AppColors.white, // Main background
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main title in primary text color
          const Text(
            'Grocery Shop',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Category grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildCategoryItem('Fruit', Icons.apple),
              _buildCategoryItem('Vegetables', Icons.eco),
              _buildCategoryItem('Cookies', Icons.cake),
              _buildCategoryItem('Fish', Icons.set_meal),
            ],
          ),
        ],
      ),
    );
  }

  /// Example 3: Category Item (like in your image)
  static Widget _buildCategoryItem(String title, IconData icon) {
    return Column(
      children: [
        // White circular background with icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.primaryText,
            size: 40,
          ),
        ),
        const SizedBox(height: 8),
        // Category title in primary text color
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Example 4: Card with Creative Header
  static Widget cardWithCreativeHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Creative header using secondary background color
          Container(
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Featured Products',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Card content on white background
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This card demonstrates the correct color usage: white background with creative header in primary background color.',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for curved design elements
class CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryBackground
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      0,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
