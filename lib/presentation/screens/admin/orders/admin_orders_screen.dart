import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import 'order_details_screen.dart';
import '../../../widgets/admin/auth_wrapper.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class AdminOrdersScreenWithAuth extends StatelessWidget {
  const AdminOrdersScreenWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAuthWrapper(
      child: AdminOrdersScreen(),
    );
  }
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedUserFilter = 'All Users';
  List<String> _availableUsers = [];
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<String> _statusOptions = [
    'All',
    'pending',
    'shipped',
    'delivered',
    'cancelled',
  ];

  // Statistics
  Map<String, dynamic> _statistics = {};
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _apiService.init();
    _loadOrders();
    _loadStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/orders/admin');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _orders =
              List<Map<String, dynamic>>.from(response.data['orders'] ?? []);
          _filteredOrders = List.from(_orders);

          // Extract unique user names from orders
          final Set<String> uniqueUsers = {};
          for (final order in _orders) {
            final customerName = order['customer_name']?.toString() ?? '';
            if (customerName.isNotEmpty) {
              uniqueUsers.add(customerName);
            }
          }
          _availableUsers = uniqueUsers.toList()..sort();
          print('Available users: $_availableUsers');
        });
      }
    } catch (e) {
      _showSnackBar('Error loading orders: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final response = await _apiService.get('/orders/statistics');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _statistics = response.data['statistics'] ?? {};
        });
      }
    } catch (e) {
      // Don't show error for stats, just log it
      print('Error loading statistics: $e');
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  void _filterOrders(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _resetUserFilter() {
    setState(() {
      _selectedUserFilter = 'All Users';
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedStatus = 'All';
      _selectedUserFilter = 'All Users';
      _searchController.clear();
      _applyFilters();
    });
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status ?? 'All';
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredOrders = _orders.where((order) {
      // Search filter
      final searchLower = _searchQuery.toLowerCase();
      final orderId = order['id']?.toString() ?? '';
      final customerName =
          order['customer_name']?.toString().toLowerCase() ?? '';
      final customerPhone =
          order['customer_phone']?.toString().toLowerCase() ?? '';
      final customerEmail =
          order['customer_email']?.toString().toLowerCase() ?? '';

      final matchesSearch = _searchQuery.isEmpty ||
          orderId.contains(searchLower) ||
          customerName.contains(searchLower) ||
          customerPhone.contains(searchLower) ||
          customerEmail.contains(searchLower);

      // Status filter
      final matchesStatus = _selectedStatus == 'All' ||
          order['status']?.toString().toLowerCase() ==
              _selectedStatus.toLowerCase();

      // User filter
      bool matchesUser = true;
      if (_selectedUserFilter != 'All Users') {
        matchesUser =
            customerName.toLowerCase() == _selectedUserFilter.toLowerCase();
        print(
            'User filter: "$_selectedUserFilter" vs "$customerName" = $matchesUser');
      }

      return matchesSearch && matchesStatus && matchesUser;
    }).toList();
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await _apiService.put('/orders/$orderId/status', data: {
        'status': newStatus,
      });

      if (response.statusCode == 200 && response.data['success']) {
        // Update the local state immediately
        setState(() {
          final orderIndex =
              _orders.indexWhere((order) => order['id'] == orderId);
          if (orderIndex != -1) {
            _orders[orderIndex]['status'] = newStatus;
            // Also update filtered orders if they exist
            final filteredIndex =
                _filteredOrders.indexWhere((order) => order['id'] == orderId);
            if (filteredIndex != -1) {
              _filteredOrders[filteredIndex]['status'] = newStatus;
            }
          }
        });

        _showSnackBar(response.data['message']);
        // Refresh statistics to reflect the change
        _loadStatistics();
      }
    } catch (e) {
      _showSnackBar('Error updating order status: $e', isError: true);
    }
  }

  Future<void> _updatePaymentStatus(
      int orderId, String newPaymentStatus) async {
    try {
      final response =
          await _apiService.put('/orders/$orderId/payment-status', data: {
        'payment_status': newPaymentStatus,
      });

      if (response.statusCode == 200 && response.data['success']) {
        // Update the local state immediately
        setState(() {
          final orderIndex =
              _orders.indexWhere((order) => order['id'] == orderId);
          if (orderIndex != -1) {
            _orders[orderIndex]['payment_status'] = newPaymentStatus;
            // Also update filtered orders if they exist
            final filteredIndex =
                _filteredOrders.indexWhere((order) => order['id'] == orderId);
            if (filteredIndex != -1) {
              _filteredOrders[filteredIndex]['payment_status'] =
                  newPaymentStatus;
            }
          }
        });

        _showSnackBar('Payment status updated successfully');
      }
    } catch (e) {
      _showSnackBar('Error updating payment status: $e', isError: true);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response =
            await _apiService.post('/orders/$orderId/cancel', data: {
          'reason': 'Cancelled by admin',
        });

        if (response.statusCode == 200 && response.data['success']) {
          // Update the local state immediately
          setState(() {
            final orderIndex =
                _orders.indexWhere((order) => order['id'] == orderId);
            if (orderIndex != -1) {
              _orders[orderIndex]['status'] = 'cancelled';
              // Also update filtered orders if they exist
              final filteredIndex =
                  _filteredOrders.indexWhere((order) => order['id'] == orderId);
              if (filteredIndex != -1) {
                _filteredOrders[filteredIndex]['status'] = 'cancelled';
              }
            }
          });

          _showSnackBar('Order cancelled successfully');
          // Refresh statistics to reflect the change
          _loadStatistics();
        }
      } catch (e) {
        _showSnackBar('Error cancelling order: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return AppColors.successColor;
      case 'cancelled':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warningColor;
      case 'paid':
        return AppColors.successColor;
      case 'failed':
        return AppColors.errorColor;
      case 'refunded':
        return Colors.purple;
      case 'partially_refunded':
        return Colors.orange;
      default:
        return AppColors.textSecondaryColor;
    }
  }

  Widget _buildStatisticsCard() {
    if (_isLoadingStats) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryText,
                  AppColors.primaryText.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryText.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Statistics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Real-time order insights',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              final childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.5;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard(
                    'Total Orders',
                    '${_statistics['total_orders'] ?? 0}',
                    Icons.shopping_cart,
                    AppColors.primaryText,
                  ),
                  _buildStatCard(
                    'Pending',
                    '${_statistics['pending_orders'] ?? 0}',
                    Icons.schedule,
                    AppColors.warningColor,
                  ),
                  _buildStatCard(
                    'Shipped',
                    '${_statistics['shipped_orders'] ?? 0}',
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Delivered',
                    '${_statistics['delivered_orders'] ?? 0}',
                    Icons.check_circle,
                    AppColors.successColor,
                  ),
                  _buildStatCard(
                    'Cancelled',
                    '${_statistics['cancelled_orders'] ?? 0}',
                    Icons.cancel,
                    AppColors.errorColor,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? 'N/A';
    final status = order['status']?.toString() ?? 'unknown';
    final paymentStatus = order['payment_status']?.toString() ?? 'unknown';
    final totalAmount = order['total_amount']?.toString() ?? '0.00';
    final customerName =
        order['customer_name']?.toString() ?? 'Unknown Customer';
    final customerPhone = order['customer_phone']?.toString() ?? 'No phone';
    final itemsCount = order['items_count']?.toString() ?? '0';
    final createdAt = order['created_at'] != null
        ? DateTime.parse(order['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetails(order),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order ID and Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryText.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Order #$orderId',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(paymentStatus),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          paymentStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Order Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      Icons.attach_money,
                      'Total',
                      '\$${double.tryParse(totalAmount)?.toStringAsFixed(2) ?? '0.00'}',
                      AppColors.primaryText,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.shopping_bag,
                      'Items',
                      '$itemsCount items',
                      AppColors.textSecondaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      Icons.phone,
                      'Phone',
                      customerPhone.length > 15
                          ? '${customerPhone.substring(0, 15)}...'
                          : customerPhone,
                      AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date and Actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      createdAt != null
                          ? 'Date: ${createdAt.toString().split(' ')[0]}'
                          : 'Date: Unknown',
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showStatusUpdateDialog(order),
                        icon: Icon(
                          Icons.edit,
                          color: AppColors.primaryText,
                          size: 20,
                        ),
                        tooltip: 'Update Status',
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryText.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _cancelOrder(order['id']),
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Cancel Order',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> order) {
    String selectedStatus = order['status'] ?? 'pending';
    String selectedPaymentStatus = order['payment_status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order #${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Order Status
            const Text('Order Status:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _statusOptions
                  .where((status) => status != 'All')
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedStatus = value;
              },
            ),
            const SizedBox(height: 16),

            // Payment Status
            const Text('Payment Status:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPaymentStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                'pending',
                'paid',
                'failed',
                'refunded',
                'partially_refunded'
              ]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedPaymentStatus = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(order['id'], selectedStatus);
              await _updatePaymentStatus(order['id'], selectedPaymentStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          order: order,
          onOrderUpdated: (updatedOrder) {
            // Update the order in the main list
            setState(() {
              final orderIndex =
                  _orders.indexWhere((o) => o['id'] == updatedOrder['id']);
              if (orderIndex != -1) {
                _orders[orderIndex] = updatedOrder;
              }

              // Also update filtered orders if they exist
              final filteredIndex = _filteredOrders
                  .indexWhere((o) => o['id'] == updatedOrder['id']);
              if (filteredIndex != -1) {
                _filteredOrders[filteredIndex] = updatedOrder;
              }
            });

            // Refresh statistics to reflect the change
            _loadStatistics();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          // Enhanced Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryText,
                  AppColors.primaryText.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryText.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Order Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryText,
              unselectedLabelColor: AppColors.textSecondaryColor,
              indicatorColor: AppColors.primaryText,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics, size: 20),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(Icons.shopping_cart, size: 20),
                  text: 'Orders',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStatisticsCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Orders Tab
                Column(
                  children: [
                    // Enhanced Search and Filters
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryText.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: AppColors.primaryText,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _filterOrders,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Search orders by ID, customer name, or phone...',
                                    hintStyle: TextStyle(
                                      color: AppColors.textSecondaryColor
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterOrders('');
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Status and User Filters
                          Row(
                            children: [
                              // Status Filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  decoration: InputDecoration(
                                    hintText: 'Filter by Status',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.primaryText,
                                          width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: _statusOptions.map((String status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(
                                        status == 'All'
                                            ? 'All Statuses'
                                            : status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'All'
                                              ? AppColors.textSecondaryColor
                                              : _getStatusColor(status),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onStatusChanged,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // User Filter
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUserFilter,
                                  decoration: InputDecoration(
                                    hintText: 'Filter by User',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: AppColors.primaryText,
                                          width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  items: [
                                    'All Users',
                                    ..._availableUsers,
                                  ].map((String filter) {
                                    return DropdownMenuItem<String>(
                                      value: filter,
                                      child: Text(filter),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedUserFilter = newValue;
                                      });
                                      _applyFilters();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Orders List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_cart_outlined,
                                        size: 64,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty &&
                                                _selectedStatus == 'All'
                                            ? 'No orders yet'
                                            : 'No orders found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                      if (_searchQuery.isEmpty &&
                                          _selectedStatus == 'All') ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Orders will appear here when customers place them',
                                          style: TextStyle(
                                            color: AppColors.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _filteredOrders.length,
                                  itemBuilder: (context, index) {
                                    final order = _filteredOrders[index];
                                    return _buildOrderCard(order);
                                  },
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
