import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _filteredPromotions = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Form controllers for add/edit promotion
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  String _discountType = 'percentage';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/promotions');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _promotions = List<Map<String, dynamic>>.from(response.data['data']);
          _filteredPromotions = List.from(_promotions);
        });
      }
    } catch (e) {
      _showSnackBar('Error loading promotions: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPromotions(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPromotions = List.from(_promotions);
      } else {
        _filteredPromotions = _promotions.where((promotion) {
          final title = promotion['title']?.toString().toLowerCase() ?? '';
          final description =
              promotion['description']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return title.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showAddPromotionDialog() {
    _clearForm();
    _showPromotionDialog(isEditing: false);
  }

  void _showEditPromotionDialog(Map<String, dynamic> promotion) {
    _populateForm(promotion);
    _showPromotionDialog(isEditing: true, promotionId: promotion['id']);
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _discountController.clear();
    _minAmountController.clear();
    _maxDiscountController.clear();
    _usageLimitController.clear();
    _startDate = null;
    _endDate = null;
    _isActive = true;
    _discountType = 'percentage';
  }

  void _populateForm(Map<String, dynamic> promotion) {
    _titleController.text = promotion['title'] ?? '';
    _descriptionController.text = promotion['description'] ?? '';
    _discountController.text = promotion['discount_value']?.toString() ?? '';
    _minAmountController.text = promotion['min_order_amount']?.toString() ?? '';
    _maxDiscountController.text = promotion['max_discount']?.toString() ?? '';
    _usageLimitController.text = promotion['usage_limit']?.toString() ?? '';
    _startDate = promotion['start_date'] != null
        ? DateTime.parse(promotion['start_date'])
        : null;
    _endDate = promotion['end_date'] != null
        ? DateTime.parse(promotion['end_date'])
        : null;
    _isActive = promotion['is_active'] ?? true;
    _discountType = promotion['discount_type'] ?? 'percentage';
  }

  void _showPromotionDialog({required bool isEditing, int? promotionId}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Promotion' : 'Add New Promotion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFormSection('Basic Information', [
                        _buildTextField('Title', _titleController, Icons.title),
                        _buildTextField('Description', _descriptionController,
                            Icons.description,
                            maxLines: 3),
                      ]),
                      _buildFormSection('Discount Settings', [
                        DropdownButtonFormField<String>(
                          value: _discountType,
                          decoration: InputDecoration(
                            labelText: 'Discount Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: AppColors.primaryText),
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Percentage (%)')),
                            DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Fixed Amount (\$)')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _discountType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField('Discount Value', _discountController,
                            Icons.discount,
                            keyboardType: TextInputType.number),
                        _buildTextField('Minimum Order Amount',
                            _minAmountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField('Maximum Discount',
                            _maxDiscountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField(
                            'Usage Limit', _usageLimitController, Icons.block,
                            keyboardType: TextInputType.number),
                      ]),
                      _buildFormSection('Date Range', [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField('Start Date', _startDate,
                                  (date) {
                                setState(() {
                                  _startDate = date;
                                });
                              }),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child:
                                  _buildDateField('End Date', _endDate, (date) {
                                setState(() {
                                  _endDate = date;
                                });
                              }),
                            ),
                          ],
                        ),
                      ]),
                      _buildFormSection('Settings', [
                        _buildSwitch('Active Promotion', _isActive,
                            (value) => setState(() => _isActive = value)),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _savePromotion(isEditing, promotionId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                          isEditing ? 'Update Promotion' : 'Add Promotion'),
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

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryText),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryText, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
      String label, DateTime? date, ValueChanged<DateTime?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryText),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryText),
                const SizedBox(width: 10),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'Select Date',
                  style: TextStyle(
                    color: date != null
                        ? Colors.black
                        : AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryText,
          ),
        ],
      ),
    );
  }

  Future<void> _savePromotion(bool isEditing, int? promotionId) async {
    if (_titleController.text.isEmpty || _discountController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select start and end dates', isError: true);
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar('End date cannot be before start date', isError: true);
      return;
    }

    try {
      final promotionData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'discount_type': _discountType,
        'discount_value': double.parse(_discountController.text),
        'min_order_amount': _minAmountController.text.isNotEmpty
            ? double.parse(_minAmountController.text)
            : 0,
        'max_discount': _maxDiscountController.text.isNotEmpty
            ? double.parse(_maxDiscountController.text)
            : null,
        'usage_limit': _usageLimitController.text.isNotEmpty
            ? int.parse(_usageLimitController.text)
            : null,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'is_active': _isActive,
      };

      if (isEditing && promotionId != null) {
        await _apiService.put('/promotions/$promotionId', data: promotionData);
        _showSnackBar('Promotion updated successfully');
      } else {
        await _apiService.post('/promotions', data: promotionData);
        _showSnackBar('Promotion added successfully');
      }

      Navigator.pop(context);
      _loadPromotions();
    } catch (e) {
      _showSnackBar('Error saving promotion: $e', isError: true);
    }
  }

  Future<void> _deletePromotion(int promotionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: const Text(
            'Are you sure you want to delete this promotion? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/promotions/$promotionId');
        _showSnackBar('Promotion deleted successfully');
        _loadPromotions();
      } catch (e) {
        _showSnackBar('Error deleting promotion: $e', isError: true);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  size: 32,
                  color: AppColors.primaryText,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promotions & Events',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        'Manage special offers and events',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddPromotionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Promotion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Search
          Container(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterPromotions,
              decoration: InputDecoration(
                hintText: 'Search promotions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primaryText),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide:
                      BorderSide(color: AppColors.primaryText, width: 2),
                ),
              ),
            ),
          ),

          // Promotions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPromotions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 64,
                              color: AppColors.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No promotions yet'
                                  : 'No promotions found',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Add your first promotion to get started',
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
                        itemCount: _filteredPromotions.length,
                        itemBuilder: (context, index) {
                          final promotion = _filteredPromotions[index];
                          return _buildPromotionCard(promotion);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion) {
    final startDate = promotion['start_date'] != null
        ? DateTime.parse(promotion['start_date'])
        : null;
    final endDate = promotion['end_date'] != null
        ? DateTime.parse(promotion['end_date'])
        : null;
    final isExpired = endDate != null && endDate.isBefore(DateTime.now());
    final isActive = promotion['is_active'] == true && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: AppColors.primaryText,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    promotion['title'] ?? 'Untitled Promotion',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditPromotionDialog(promotion);
                    } else if (value == 'delete') {
                      _deletePromotion(promotion['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.more_vert,
                      color: AppColors.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              promotion['description'] ?? 'No description',
              style: TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${promotion['discount_value']}${promotion['discount_type'] == 'percentage' ? '%' : '\$'} OFF',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16, color: AppColors.textSecondaryColor),
                const SizedBox(width: 5),
                Text(
                  '${startDate != null ? '${startDate.day}/${startDate.month}/${startDate.year}' : 'N/A'} - ${endDate != null ? '${endDate.day}/${endDate.month}/${endDate.year}' : 'N/A'}',
                  style: TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (promotion['min_order_amount'] != null &&
                    promotion['min_order_amount'] > 0)
                  Text(
                    'Min: \$${promotion['min_order_amount']}',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
