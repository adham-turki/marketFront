import '../components/advanced_filter_section.dart';
import '../components/statistics_cards.dart';
import 'package:flutter/material.dart';

class FilterConfigs {
  // Users page filter options
  static List<FilterOption> getUsersFilters() {
    return [
      const FilterOption(
        key: 'role',
        label: 'Role',
        type: FilterType.dropdown,
        options: ['customer', 'admin', 'owner'],
        defaultValue: 'customer',
      ),
      const FilterOption(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options: ['active', 'suspended', 'pending'],
        defaultValue: 'active',
      ),
      const FilterOption(
        key: 'created_date',
        label: 'Created Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'last_login',
        label: 'Last Login Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'company_name',
        label: 'Company Name',
        type: FilterType.dropdown,
        options: ['Has Company', 'No Company'],
        defaultValue: 'Has Company',
      ),
      const FilterOption(
        key: 'email_verified',
        label: 'Email Verification',
        type: FilterType.dropdown,
        options: ['Verified', 'Not Verified'],
        defaultValue: 'Verified',
      ),
      const FilterOption(
        key: 'has_orders',
        label: 'Order History',
        type: FilterType.dropdown,
        options: ['Has Orders', 'No Orders'],
        defaultValue: 'Has Orders',
      ),
      const FilterOption(
        key: 'orders_count',
        label: 'Orders Count Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'total_spent',
        label: 'Total Spent Range',
        type: FilterType.range,
      ),
    ];
  }

  // Products page filter options
  static List<FilterOption> getProductsFilters() {
    return [
      const FilterOption(
        key: 'category',
        label: 'Category',
        type: FilterType.dropdown,
        options: ['Fruits', 'Vegetables', 'Dairy', 'Meat', 'Grains'],
        defaultValue: 'Fruits',
      ),
      const FilterOption(
        key: 'brand',
        label: 'Brand',
        type: FilterType.dropdown,
        options: [
          'Organic Valley',
          'Fresh Farm',
          'Premium Quality',
          'Local Farm'
        ],
        defaultValue: 'Organic Valley',
      ),
      const FilterOption(
        key: 'price_range',
        label: 'Price Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'stock_range',
        label: 'Stock Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'weight_range',
        label: 'Weight Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'is_featured',
        label: 'Featured Status',
        type: FilterType.dropdown,
        options: ['Featured', 'Not Featured'],
        defaultValue: 'Featured',
      ),
      const FilterOption(
        key: 'is_active',
        label: 'Active Status',
        type: FilterType.dropdown,
        options: ['Active', 'Inactive'],
        defaultValue: 'Active',
      ),
      const FilterOption(
        key: 'created_date',
        label: 'Created Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'updated_date',
        label: 'Updated Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'has_discount',
        label: 'Discount Status',
        type: FilterType.dropdown,
        options: ['Has Discount', 'No Discount'],
        defaultValue: 'Has Discount',
      ),
      const FilterOption(
        key: 'discount_range',
        label: 'Discount Range (%)',
        type: FilterType.range,
      ),
    ];
  }

  // Orders page filter options
  static List<FilterOption> getOrdersFilters() {
    return [
      const FilterOption(
        key: 'status',
        label: 'Order Status',
        type: FilterType.dropdown,
        options: ['pending', 'shipped', 'delivered', 'cancelled'],
        defaultValue: 'pending',
      ),
      const FilterOption(
        key: 'payment_status',
        label: 'Payment Status',
        type: FilterType.dropdown,
        options: [
          'pending',
          'paid',
          'failed',
          'refunded',
          'partially_refunded'
        ],
        defaultValue: 'pending',
      ),
      const FilterOption(
        key: 'payment_method',
        label: 'Payment Method',
        type: FilterType.dropdown,
        options: ['credit_card', 'paypal', 'bank_transfer', 'cash_on_delivery'],
        defaultValue: 'credit_card',
      ),
      const FilterOption(
        key: 'created_date',
        label: 'Order Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'amount_range',
        label: 'Order Amount Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'customer_search',
        label: 'Customer Search',
        type: FilterType.dropdown,
        options: ['By Email', 'By Phone', 'By Name'],
        defaultValue: 'By Email',
      ),
      const FilterOption(
        key: 'has_coupon',
        label: 'Coupon Usage',
        type: FilterType.dropdown,
        options: ['Used Coupon', 'No Coupon'],
        defaultValue: 'Used Coupon',
      ),
      const FilterOption(
        key: 'coupon_code',
        label: 'Specific Coupon',
        type: FilterType.dropdown,
        options: ['SUMMER20', 'WELCOME10', 'SAVE15', 'FREESHIP'],
        defaultValue: 'SUMMER20',
      ),
    ];
  }

  // Promotions page filter options
  static List<FilterOption> getPromotionsFilters() {
    return [
      const FilterOption(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options: ['active', 'inactive', 'expired'],
        defaultValue: 'active',
      ),
      const FilterOption(
        key: 'promotion_type',
        label: 'Promotion Type',
        type: FilterType.dropdown,
        options: [
          'percentage',
          'fixed_amount',
          'buy_x_get_y',
          'free_shipping',
          'bundle'
        ],
        defaultValue: 'percentage',
      ),
      const FilterOption(
        key: 'scope_type',
        label: 'Scope Type',
        type: FilterType.dropdown,
        options: ['all_products', 'specific_products', 'category', 'brand'],
        defaultValue: 'all_products',
      ),
      const FilterOption(
        key: 'discount_range',
        label: 'Discount Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'order_amount_range',
        label: 'Order Amount Range',
        type: FilterType.range,
      ),
      const FilterOption(
        key: 'start_date',
        label: 'Start Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'end_date',
        label: 'End Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'created_date',
        label: 'Created Date Range',
        type: FilterType.dateRange,
      ),
      const FilterOption(
        key: 'is_featured',
        label: 'Featured Status',
        type: FilterType.dropdown,
        options: ['Featured', 'Not Featured'],
        defaultValue: 'Featured',
      ),
      const FilterOption(
        key: 'is_stackable',
        label: 'Stackable Status',
        type: FilterType.dropdown,
        options: ['Stackable', 'Not Stackable'],
        defaultValue: 'Stackable',
      ),
      const FilterOption(
        key: 'requires_coupon',
        label: 'Coupon Requirement',
        type: FilterType.dropdown,
        options: ['Requires Coupon', 'No Coupon Required'],
        defaultValue: 'Requires Coupon',
      ),
      const FilterOption(
        key: 'priority',
        label: 'Priority Level',
        type: FilterType.dropdown,
        options: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
        defaultValue: '5',
      ),
    ];
  }

  // Dashboard statistics cards
  static List<StatCard> getDashboardStats() {
    return [
      const StatCard(
        title: 'Total Users',
        subtitle: 'Registered customers',
        value: '1,234',
        icon: Icons.people,
        primaryColor: StatColors.primary,
        change: 12.5,
      ),
      const StatCard(
        title: 'Total Products',
        subtitle: 'Available items',
        value: '567',
        icon: Icons.inventory,
        primaryColor: StatColors.success,
        change: 8.3,
      ),
      const StatCard(
        title: 'Total Orders',
        subtitle: 'Completed transactions',
        value: '890',
        icon: Icons.shopping_cart,
        primaryColor: StatColors.info,
        change: 15.7,
      ),
      const StatCard(
        title: 'Total Revenue',
        subtitle: 'This month',
        value: '\$45,678',
        icon: Icons.attach_money,
        primaryColor: StatColors.warning,
        change: 22.1,
      ),
    ];
  }

  // Users statistics cards
  static List<StatCard> getUsersStats() {
    return [
      const StatCard(
        title: 'Total Users',
        subtitle: 'All registered users',
        value: '1,234',
        icon: Icons.people,
        primaryColor: StatColors.primary,
        change: 12.5,
      ),
      const StatCard(
        title: 'Active Users',
        subtitle: 'Users with orders',
        value: '987',
        icon: Icons.person,
        primaryColor: StatColors.success,
        change: 8.3,
      ),
      const StatCard(
        title: 'New Users',
        subtitle: 'This month',
        value: '156',
        icon: Icons.person_add,
        primaryColor: StatColors.info,
        change: 15.7,
      ),
      const StatCard(
        title: 'Premium Users',
        subtitle: 'High-value customers',
        value: '89',
        icon: Icons.star,
        primaryColor: StatColors.warning,
        change: 22.1,
      ),
    ];
  }

  // Products statistics cards
  static List<StatCard> getProductsStats() {
    return [
      const StatCard(
        title: 'Total Products',
        subtitle: 'All available items',
        value: '567',
        icon: Icons.inventory,
        primaryColor: StatColors.primary,
        change: 8.3,
      ),
      const StatCard(
        title: 'Active Products',
        subtitle: 'In stock items',
        value: '432',
        icon: Icons.check_circle,
        primaryColor: StatColors.success,
        change: 5.2,
      ),
      const StatCard(
        title: 'Low Stock',
        subtitle: 'Items below threshold',
        value: '23',
        icon: Icons.warning,
        primaryColor: StatColors.warning,
        change: -12.5,
      ),
      const StatCard(
        title: 'Featured Products',
        subtitle: 'Promoted items',
        value: '45',
        icon: Icons.star,
        primaryColor: StatColors.purple,
        change: 18.9,
      ),
    ];
  }

  // Orders statistics cards
  static List<StatCard> getOrdersStats() {
    return [
      const StatCard(
        title: 'Total Orders',
        subtitle: 'All transactions',
        value: '890',
        icon: Icons.shopping_cart,
        primaryColor: StatColors.primary,
        change: 15.7,
      ),
      const StatCard(
        title: 'Pending Orders',
        subtitle: 'Awaiting processing',
        value: '45',
        icon: Icons.schedule,
        primaryColor: StatColors.warning,
        change: 8.3,
      ),
      const StatCard(
        title: 'Completed Orders',
        subtitle: 'Delivered successfully',
        value: '789',
        icon: Icons.check_circle,
        primaryColor: StatColors.success,
        change: 22.1,
      ),
      const StatCard(
        title: 'Total Revenue',
        subtitle: 'This month',
        value: '\$45,678',
        icon: Icons.attach_money,
        primaryColor: StatColors.info,
        change: 18.9,
      ),
    ];
  }

  // Promotions statistics cards
  static List<StatCard> getPromotionsStats() {
    return [
      const StatCard(
        title: 'Total Promotions',
        subtitle: 'All active offers',
        value: '67',
        icon: Icons.local_offer,
        primaryColor: StatColors.primary,
        change: 12.5,
      ),
      const StatCard(
        title: 'Active Promotions',
        subtitle: 'Currently running',
        value: '34',
        icon: Icons.play_circle,
        primaryColor: StatColors.success,
        change: 8.3,
      ),
      const StatCard(
        title: 'Featured Promotions',
        subtitle: 'Highlighted offers',
        value: '12',
        icon: Icons.star,
        primaryColor: StatColors.warning,
        change: 15.7,
      ),
      const StatCard(
        title: 'Total Usage',
        subtitle: 'Times applied',
        value: '1,234',
        icon: Icons.trending_up,
        primaryColor: StatColors.info,
        change: 22.1,
      ),
    ];
  }
}
