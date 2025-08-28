import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _userOrders = [];
  Map<String, dynamic> _userStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user orders using admin endpoint with customer_id filter
      final ordersResponse = await _apiService.get(
        '/orders/admin?customer_id=${widget.user['id']}&limit=100',
      );

      if (ordersResponse.statusCode == 200 && ordersResponse.data['success']) {
        setState(() {
          _userOrders = List<Map<String, dynamic>>.from(
            ordersResponse.data['orders'] ?? [],
          );
        });

        // Calculate user statistics from orders
        _calculateUserStats();
      } else {
        print('Failed to load orders: ${ordersResponse.data}');
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Handle errors silently for now
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateUserStats() {
    if (_userOrders.isEmpty) {
      _userStats = {
        'total_orders': 0,
        'total_spent': 0.0,
        'average_order_value': 0.0,
        'last_order_date': null,
        'favorite_category': ArabicText.none,
        'account_age': _calculateAccountAge(),
      };
      return;
    }

    // Calculate total spent
    double totalSpent = 0.0;
    DateTime? lastOrderDate;
    Map<String, int> categoryCount = {};

    for (final order in _userOrders) {
      // Add total amount
      final amount =
          double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
      totalSpent += amount;

      // Track last order date
      if (order['created_at'] != null) {
        try {
          final orderDate = DateTime.parse(order['created_at'].toString());
          if (lastOrderDate == null || orderDate.isAfter(lastOrderDate)) {
            lastOrderDate = orderDate;
          }
        } catch (e) {
          print('Error parsing order date: ${order['created_at']}');
        }
      }

      // Count categories (if order has items with categories)
      if (order['items'] != null && order['items'] is List) {
        for (final item in order['items']) {
          if (item['product'] != null && item['product']['category'] != null) {
            final categoryName = item['product']['category']['name'] ??
                ArabicText.unknownCategory;
            categoryCount[categoryName] =
                (categoryCount[categoryName] ?? 0) + 1;
          }
        }
      }
    }

    // Find favorite category
    String favoriteCategory = ArabicText.none;
    int maxCount = 0;
    for (final entry in categoryCount.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        favoriteCategory = entry.key;
      }
    }

    _userStats = {
      'total_orders': _userOrders.length,
      'total_spent': totalSpent,
      'average_order_value':
          _userOrders.isNotEmpty ? totalSpent / _userOrders.length : 0.0,
      'last_order_date': lastOrderDate,
      'favorite_category': favoriteCategory,
      'account_age': _calculateAccountAge(),
    };

    print('Calculated user stats: $_userStats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 238, 238),
      appBar: AppBar(
        title: Text(
          '${widget.user['full_name'] ?? widget.user['username'] ?? ArabicText.user} ${ArabicText.details}',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  _buildUserProfileSection(),
                  const SizedBox(height: 24),

                  // User Statistics
                  _buildUserStatsSection(),
                  const SizedBox(height: 24),

                  // User Orders
                  _buildUserOrdersSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserProfileSection() {
    return _buildInfoCard(
      title: ArabicText.profileInformation,
      icon: Icons.person,
      children: [
        _buildInfoRow(
            ArabicText.fullName, widget.user['full_name'] ?? ArabicText.none),
       _buildInfoRow(
            ArabicText.email, widget.user['email'] ?? ArabicText.none),
        _buildInfoRow(
            ArabicText.phoneNumber, widget.user['phone'] ?? ArabicText.none),
        _buildInfoRow(ArabicText.role, _getUserRole()),
        _buildInfoRow(ArabicText.status, _getUserStatus()),
        _buildInfoRow(
            ArabicText.joined, _formatDate(widget.user['created_at'])),
        _buildInfoRow(
            ArabicText.lastUpdated, _formatDate(widget.user['updated_at'])),
      ],
    );
  }

  Widget _buildUserStatsSection() {
    return _buildInfoCard(
      title: ArabicText.userStatistics,
      icon: Icons.analytics,
      children: [
        _buildStatRow(ArabicText.totalOrders,
            _userStats['total_orders']?.toString() ?? '0'),
        _buildStatRow(ArabicText.totalSpent,
            '${_formatCurrency(_userStats['total_spent'] ?? 0)}₪'),
        _buildStatRow(ArabicText.averageOrderValue,
            '${_formatCurrency(_userStats['average_order_value'] ?? 0)}₪'),
        _buildStatRow(
            ArabicText.lastOrder, _formatDate(_userStats['last_order_date'])),
        _buildStatRow(ArabicText.favoriteCategory,
            _userStats['favorite_category'] ?? ArabicText.none),
        _buildStatRow(ArabicText.accountAge,
            _userStats['account_age'] ?? ArabicText.none),
      ],
    );
  }

  Widget _buildUserOrdersSection() {
    return _buildInfoCard(
      title:
          '${ArabicText.orderHistory} (${_userOrders.length} ${ArabicText.orders})',
      icon: Icons.shopping_bag,
      children: [
        if (_userOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  ArabicText.noOrdersFound,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ArabicText.userId}: ${widget.user['id']}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${ArabicText.userEmail}: ${widget.user['email']}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  ArabicText.noOrdersMessage,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._userOrders.map((order) => _buildOrderItem(order)),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    final orderId = order['id'];
    final orderDate = _formatDate(order['created_at']);
    final orderTotal = _formatCurrency(order['total_amount'] ?? 0);
    final orderStatus = _getOrderStatus(order['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ArabicText.orderNumber} #$orderId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(order['status']),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  orderStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${ArabicText.date}: $orderDate',
            style: const TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ArabicText.total}: $orderTotal₪',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryText, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getUserRole() {
    final role = widget.user['role'];
    if (role == 'admin') return ArabicText.admin;
    if (role == 'owner') return ArabicText.owner;
    return ArabicText.customer;
  }

  String _getUserStatus() {
    final isActive = widget.user['is_active'];
    return isActive == true ? ArabicText.active : ArabicText.inactive;
  }

  String _getOrderStatus(String? status) {
    switch (status) {
      case 'pending':
        return ArabicText.pending;
      case 'processing':
        return ArabicText.processing;
      case 'shipped':
        return ArabicText.shipped;
      case 'delivered':
        return ArabicText.delivered;
      case 'cancelled':
        return ArabicText.cancelled;
      default:
        return ArabicText.unknownStatus;
    }
  }

  Color _getOrderStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return ArabicText.none;
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0.00';
    try {
      final value = double.parse(amount.toString());
      return value.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  String _calculateAccountAge() {
    final createdAt = widget.user['created_at'];
    if (createdAt == null) return ArabicText.none;

    try {
      final createdDate = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final difference = now.difference(createdDate);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years ${ArabicText.year}${years > 1 ? ArabicText.years : ''}';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${ArabicText.month}${months > 1 ? ArabicText.months : ''}';
      } else {
        return '${difference.inDays} ${ArabicText.day}${difference.inDays > 1 ? ArabicText.days : ''}';
      }
    } catch (e) {
      return ArabicText.none;
    }
  }
}
