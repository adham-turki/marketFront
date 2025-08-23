import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>)? onOrderUpdated;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.onOrderUpdated,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/orders/${widget.order['id']}');
      if (response.statusCode == 200 && response.data['success']) {
        final updatedOrder = response.data['data'];
        setState(() {
          _orderDetails = updatedOrder;
        });

        // Update the widget.order with the latest data from API
        widget.order.addAll(updatedOrder);

        // Notify parent screen about the update
        if (widget.onOrderUpdated != null) {
          widget.onOrderUpdated!(widget.order);
        }
      }
    } catch (e) {
      _showSnackBar('Error loading order details: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final response =
          await _apiService.put('/orders/${widget.order['id']}/status', data: {
        'status': newStatus,
      });

      if (response.statusCode == 200 && response.data['success']) {
        // Update the local state immediately
        setState(() {
          if (_orderDetails != null) {
            _orderDetails!['status'] = newStatus;
          }
          widget.order['status'] = newStatus;
        });

        // Notify parent screen about the update
        if (widget.onOrderUpdated != null) {
          widget.onOrderUpdated!(widget.order);
        }

        _showSnackBar(response.data['message']);
      }
    } catch (e) {
      _showSnackBar('Error updating order status: $e', isError: true);
    }
  }

  Future<void> _updatePaymentStatus(String newPaymentStatus) async {
    try {
      final response = await _apiService
          .put('/orders/${widget.order['id']}/payment-status', data: {
        'payment_status': newPaymentStatus,
      });

      if (response.statusCode == 200 && response.data['success']) {
        // Update the local state immediately
        setState(() {
          if (_orderDetails != null) {
            _orderDetails!['payment_status'] = newPaymentStatus;
          }
          widget.order['payment_status'] = newPaymentStatus;
        });

        // Notify parent screen about the update
        if (widget.onOrderUpdated != null) {
          widget.onOrderUpdated!(widget.order);
        }

        _showSnackBar(ArabicText.paymentStatusUpdatedSuccessfully);
      }
    } catch (e) {
      _showSnackBar('Error updating payment status: $e', isError: true);
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

  Widget _buildHeader() {
    final order = _orderDetails ?? widget.order;
    final orderId = order['id']?.toString() ?? 'N/A';
    final status = order['status']?.toString() ?? ArabicText.unknownStatus;
    final totalAmount = order['total_amount']?.toString() ?? '0.00';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryText,
            AppColors.primaryText.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Back button and title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ArabicText.orderDetails,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Order ID and Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${double.tryParse(totalAmount)?.toStringAsFixed(2) ?? '0.00'}₪',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    final order = _orderDetails ?? widget.order;
    final customerName =
        order['customer_name']?.toString() ?? ArabicText.unknownCustomer;
    final customerPhone =
        order['customer_phone']?.toString() ?? ArabicText.noPhone;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                ArabicText.customerInformation,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(ArabicText.name, customerName, Icons.person_outline),
          _buildInfoRow(
              ArabicText.phoneNumber, customerPhone, Icons.phone_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryText, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    final order = _orderDetails ?? widget.order;
    final items = order['items'] as List? ?? [];
    final totalAmount = order['total_amount']?.toString() ?? '0.00';
    final subtotal = order['subtotal']?.toString() ?? '0.00';
    final tax = order['tax_amount']?.toString() ?? '0.00';
    final shipping = order['shipping_cost']?.toString() ?? '0.00';
    final discount = order['discount_amount']?.toString() ?? '0.00';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.shopping_bag,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Order Items (${items.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Order Items List
          if (items.isNotEmpty) ...[
            ...items.map((item) => _buildOrderItemCard(item)).toList(),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),
          ],

          // Order Summary
          _buildSummaryRow(ArabicText.subtotal, subtotal),
          _buildSummaryRow(ArabicText.tax, tax),
          _buildSummaryRow(ArabicText.shipping, shipping),
          if (double.tryParse(discount) != null && double.parse(discount) > 0)
            _buildSummaryRow(ArabicText.discount, '-$discount',
                isDiscount: true),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildSummaryRow(ArabicText.total, totalAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(Map<String, dynamic> item) {
    final name = item['product_name']?.toString() ?? ArabicText.unknownProduct;
    final quantity = item['quantity']?.toString() ?? '0';
    final price = item['unit_price']?.toString() ?? '0.00';
    final total = item['total_price']?.toString() ?? '0.00';
    final imageUrl = item['product_image_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image,
                          color: AppColors.textSecondaryColor,
                          size: 24,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.image,
                    color: AppColors.textSecondaryColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${double.tryParse(price)?.toStringAsFixed(2) ?? '0.00'}₪ each',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            '${double.tryParse(total)?.toStringAsFixed(2) ?? '0.00'}₪',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal
                  ? AppColors.primaryText
                  : AppColors.textSecondaryColor,
            ),
          ),
          Text(
            isDiscount
                ? value
                : '${double.tryParse(value)?.toStringAsFixed(2) ?? '0.00'}₪',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal
                  ? AppColors.primaryText
                  : AppColors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    final order = _orderDetails ?? widget.order;
    final shippingAddress = order['shipping_address'];
    final billingAddress = order['billing_address'];
    final paymentMethod =
        order['payment_method']?.toString() ?? ArabicText.unknownPaymentMethod;
    final notes = order['notes']?.toString() ?? ArabicText.noSpecialNotes;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Shipping & Billing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shipping Address
          if (shippingAddress != null) ...[
            _buildAddressSection(ArabicText.shippingAddress, shippingAddress),
            const SizedBox(height: 20),
          ],

          // Billing Address
          if (billingAddress != null) ...[
            _buildAddressSection(ArabicText.billingAddress, billingAddress),
            const SizedBox(height: 20),
          ],

          // Payment Method
          _buildInfoRow(ArabicText.paymentMethod, paymentMethod.toUpperCase(),
              Icons.payment),

          // Notes
          if (notes.isNotEmpty && notes != ArabicText.noSpecialNotes) ...[
            const SizedBox(height: 16),
            _buildInfoRow(ArabicText.notes, notes, Icons.note),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(String title, Map<String, dynamic> address) {
    final street = address['street']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final state = address['state']?.toString() ?? '';
    final zipCode = address['zip_code']?.toString() ?? '';
    final country = address['country']?.toString() ?? '';

    final fullAddress = [street, city, state, zipCode, country]
        .where((part) => part.isNotEmpty)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            fullAddress.isEmpty ? ArabicText.noAddressProvided : fullAddress,
            style: TextStyle(
              fontSize: 14,
              color: fullAddress.isEmpty
                  ? AppColors.textSecondaryColor
                  : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final order = _orderDetails ?? widget.order;
    final currentStatus = order['status']?.toString() ?? 'pending';
    final currentPaymentStatus =
        order['payment_status']?.toString() ?? 'pending';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.settings,
                  color: AppColors.primaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                ArabicText.orderActions,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Update
          _buildActionButton(
            ArabicText.updateOrderStatus,
            Icons.update,
            () => _showStatusUpdateDialog(),
            AppColors.primaryText,
          ),
          const SizedBox(height: 12),

          // Payment Status Update
          _buildActionButton(
            ArabicText.updatePaymentStatus,
            Icons.payment,
            () => _showPaymentStatusUpdateDialog(),
            AppColors.secondaryBackground,
          ),
          const SizedBox(height: 12),

          // Cancel Order (if not already cancelled)
          if (currentStatus != 'cancelled' && currentStatus != 'delivered')
            _buildActionButton(
              ArabicText.cancelOrder,
              Icons.cancel,
              () => _showCancelOrderDialog(),
              Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog() {
    final order = _orderDetails ?? widget.order;
    String selectedStatus = order['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ArabicText.updateOrderStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ArabicText.selectNewStatus),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ['pending', 'shipped', 'delivered', 'cancelled']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedStatus = value;
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
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(selectedStatus);
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

  void _showPaymentStatusUpdateDialog() {
    final order = _orderDetails ?? widget.order;
    String selectedPaymentStatus = order['payment_status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select new payment status:'),
            const SizedBox(height: 16),
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
            onPressed: () {
              Navigator.pop(context);
              _updatePaymentStatus(selectedPaymentStatus);
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

  void _showCancelOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus('cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: AppColors.primaryText,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCustomerInfo(),
                      _buildOrderItems(),
                      _buildShippingInfo(),
                      _buildActions(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
