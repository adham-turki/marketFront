import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class EditOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic>) onOrderUpdated;

  const EditOrderScreen({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  bool _isLoading = false;

  final List<String> _statusOptions = [
    ArabicText.pending,
    ArabicText.shipped,
    ArabicText.delivered,
    ArabicText.cancelled,
  ];

  final List<String> _paymentStatusOptions = [
    ArabicText.pendingPayment,
    ArabicText.paid,
    ArabicText.failed,
    ArabicText.refunded,
    ArabicText.partiallyRefunded,
  ];

  @override
  void initState() {
    super.initState();
    _apiService.init();
    _selectedStatus = _getArabicStatus(widget.order['status'] ?? 'pending');
    _selectedPaymentStatus =
        _getArabicPaymentStatus(widget.order['payment_status'] ?? 'pending');
  }

  String _getArabicStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArabicText.pending;
      case 'shipped':
        return ArabicText.shipped;
      case 'delivered':
        return ArabicText.delivered;
      case 'cancelled':
        return ArabicText.cancelled;
      default:
        return ArabicText.pending;
    }
  }

  String _getArabicPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ArabicText.pendingPayment;
      case 'paid':
        return ArabicText.paid;
      case 'failed':
        return ArabicText.failed;
      case 'refunded':
        return ArabicText.refunded;
      case 'partially_refunded':
        return ArabicText.partiallyRefunded;
      default:
        return ArabicText.pendingPayment;
    }
  }

  String _getDatabaseStatus(String arabicStatus) {
    switch (arabicStatus) {
      case ArabicText.pending:
        return 'pending';
      case ArabicText.shipped:
        return 'shipped';
      case ArabicText.delivered:
        return 'delivered';
      case ArabicText.cancelled:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _getDatabasePaymentStatus(String arabicStatus) {
    switch (arabicStatus) {
      case ArabicText.pendingPayment:
        return 'pending';
      case ArabicText.paid:
        return 'paid';
      case ArabicText.failed:
        return 'failed';
      case ArabicText.refunded:
        return 'refunded';
      case ArabicText.partiallyRefunded:
        return 'partially_refunded';
      default:
        return 'pending';
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _apiService.put('/orders/$orderId/status', data: {
        'status': status,
      });

      if (response.statusCode == 200 && response.data['success']) {
        _showSnackBar(ArabicText.orderStatusUpdatedSuccessfully);
      } else {
        _showSnackBar(ArabicText.errorUpdatingOrderStatus, isError: true);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorUpdatingOrderStatus}: $e',
          isError: true);
    }
  }

  Future<void> _updatePaymentStatus(int orderId, String status) async {
    try {
      final response =
          await _apiService.put('/orders/$orderId/payment-status', data: {
        'payment_status': status,
      });

      if (response.statusCode == 200 && response.data['success']) {
        _showSnackBar(ArabicText.paymentStatusUpdatedSuccessfully);
      } else {
        _showSnackBar(ArabicText.errorUpdatingPaymentStatus, isError: true);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorUpdatingPaymentStatus}: $e',
          isError: true);
    }
  }

  Future<void> _saveChanges() async {
    if (_selectedStatus == null || _selectedPaymentStatus == null) {
      _showSnackBar(ArabicText.pleaseSelectStatus, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderId = widget.order['id'];

      await _updateOrderStatus(orderId, _getDatabaseStatus(_selectedStatus!));
      await _updatePaymentStatus(
          orderId, _getDatabasePaymentStatus(_selectedPaymentStatus!));

      // Update the order object
      final updatedOrder = Map<String, dynamic>.from(widget.order);
      updatedOrder['status'] = _getDatabaseStatus(_selectedStatus!);
      updatedOrder['payment_status'] =
          _getDatabasePaymentStatus(_selectedPaymentStatus!);

      widget.onOrderUpdated(updatedOrder);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorSavingChanges}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${ArabicText.updateOrder}: #${widget.order['id']}'),
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status Section
              Text(
                '${ArabicText.orderStatus}:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: AppColors.primaryText, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _statusOptions
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Payment Status Section
              Text(
                '${ArabicText.paymentStatus}:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: AppColors.primaryText, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _paymentStatusOptions
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentStatus = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryText),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        ArabicText.cancel,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              ArabicText.update,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
