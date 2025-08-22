import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../widgets/admin/auth_wrapper.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class AdminPromotionsScreenWithAuth extends StatelessWidget {
  const AdminPromotionsScreenWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAuthWrapper(
      child: AdminPromotionsScreen(),
    );
  }
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // Promotions state
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _filteredPromotions = [];
  bool _isLoadingPromotions = false;
  String _searchQuery = '';

  // Promotion form controllers (backend field names)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxDiscountController = TextEditingController();
  final TextEditingController _usageLimitController = TextEditingController();
  final TextEditingController _usagePerUserController = TextEditingController();
  final TextEditingController _maxQuantityPerProductController =
      TextEditingController();
  final TextEditingController _usageLimitPerProductController =
      TextEditingController();
  final TextEditingController _buyXController =
      TextEditingController(text: '1');
  final TextEditingController _getYController =
      TextEditingController(text: '1');

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true; // mapped to status active/inactive
  String _promotionType = 'percentage';
  String _scopeType = 'all_products';
  bool _isFeatured = false;
  bool _isStackable = false;
  bool _requiresCoupon = false;
  int _priority = 0;

  // Product selection for promotions
  List<Map<String, dynamic>> _availableProducts = [];
  List<int> _selectedProductIds = [];
  List<Map<String, dynamic>> _selectedCategories = [];

  // Available categories
  List<Map<String, dynamic>> _availableCategories = [];

  // Search state for dialogs
  String _productSearchQuery = '';
  String _categorySearchQuery = '';

  // Coupons state
  List<Map<String, dynamic>> _coupons = [];
  List<Map<String, dynamic>> _filteredCoupons = [];
  bool _isLoadingCoupons = false;

  // Coupon form controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _couponNameController = TextEditingController();
  final TextEditingController _couponDescriptionController =
      TextEditingController();
  final TextEditingController _couponDiscountController =
      TextEditingController();
  final TextEditingController _couponMinAmountController =
      TextEditingController();
  final TextEditingController _couponMaxDiscountController =
      TextEditingController();
  final TextEditingController _couponUsageLimitController =
      TextEditingController();
  final TextEditingController _couponUsagePerUserController =
      TextEditingController();
  DateTime? _couponValidFrom;
  DateTime? _couponValidUntil;
  bool _couponIsActive = true;
  String _couponDiscountType = 'percentage';
  String _couponTargetAudience = 'both';

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _loadCoupons();
    _loadAvailableProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _usagePerUserController.dispose();
    _maxQuantityPerProductController.dispose();
    _usageLimitPerProductController.dispose();
    _buyXController.dispose();
    _getYController.dispose();
    _codeController.dispose();
    _couponNameController.dispose();
    _couponDescriptionController.dispose();
    _couponDiscountController.dispose();
    _couponMinAmountController.dispose();
    _couponMaxDiscountController.dispose();
    _couponUsageLimitController.dispose();
    _couponUsagePerUserController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableProducts() async {
    try {
      final response = await _apiService.get('/products/admin/list');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _availableProducts =
              List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } catch (e) {
      // Silently fail - products are optional for promotions
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.get('/categories');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _availableCategories =
              List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } catch (e) {
      // Silently fail - categories are optional for promotions
    }
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoadingPromotions = true;
    });

    try {
      final response = await _apiService.get('/promotions/admin/list');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _promotions = List<Map<String, dynamic>>.from(response.data['data']);
          _filteredPromotions = List.from(_promotions);
        });
      }
    } catch (e) {
      _showSnackBar('Error loading promotions: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingPromotions = false;
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
          final name = promotion['name']?.toString().toLowerCase() ?? '';
          final description =
              promotion['description']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
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
    _nameController.clear();
    _descriptionController.clear();
    _discountController.clear();
    _minAmountController.clear();
    _maxDiscountController.clear();
    _usageLimitController.clear();
    _usagePerUserController.clear();
    _maxQuantityPerProductController.clear();
    _usageLimitPerProductController.clear();
    _buyXController.text = '1';
    _getYController.text = '1';
    _startDate = null;
    _endDate = null;
    _isActive = true;
    _promotionType = 'percentage';
    // Target audience removed - all promotions are for customers
    _scopeType = 'all_products';
    _isFeatured = false;
    _isStackable = false;
    _requiresCoupon = false;
    _priority = 0;
    _selectedProductIds.clear();
    _selectedCategories.clear();
  }

  void _populateForm(Map<String, dynamic> promotion) {
    _nameController.text = promotion['name'] ?? '';
    _descriptionController.text = promotion['description'] ?? '';
    _discountController.text = promotion['discount_value']?.toString() ?? '';
    _minAmountController.text =
        promotion['minimum_order_amount']?.toString() ?? '';
    _maxDiscountController.text =
        promotion['max_discount_amount']?.toString() ?? '';
    _usageLimitController.text = promotion['usage_limit']?.toString() ?? '';
    _usagePerUserController.text =
        promotion['usage_limit_per_user']?.toString() ?? '';
    _maxQuantityPerProductController.text =
        promotion['max_quantity_per_product']?.toString() ?? '';
    _usageLimitPerProductController.text =
        promotion['usage_limit_per_product']?.toString() ?? '';
    _startDate = promotion['start_date'] != null
        ? DateTime.parse(promotion['start_date'])
        : null;
    _endDate = promotion['end_date'] != null
        ? DateTime.parse(promotion['end_date'])
        : null;
    _isActive = (promotion['status'] ?? 'active') == 'active';
    _promotionType = promotion['promotion_type'] ?? 'percentage';
    // Target audience removed - all promotions are for customers
    _scopeType = promotion['scope_type'] ?? 'all_products';
    _isFeatured = promotion['is_featured'] ?? false;
    _isStackable = promotion['is_stackable'] ?? false;
    _requiresCoupon = promotion['requires_coupon'] ?? false;
    _priority = promotion['priority'] ?? 0;

    // Populate product selections
    if (promotion['product_ids'] != null) {
      _selectedProductIds = List<int>.from(promotion['product_ids']);
    }
    if (promotion['category_ids'] != null) {
      // This would need to be populated with actual category data
      _selectedCategories = [];
    }

    // Populate buy X get Y fields
    if (promotion['buy_x_quantity'] != null) {
      _buyXController.text = promotion['buy_x_quantity'].toString();
    }
    if (promotion['get_y_quantity'] != null) {
      _getYController.text = promotion['get_y_quantity'].toString();
    }
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
                        _buildTextField('Name', _nameController, Icons.title),
                        _buildTextField('Description', _descriptionController,
                            Icons.description,
                            maxLines: 3),
                      ]),
                      _buildFormSection('Promotion Settings', [
                        DropdownButtonFormField<String>(
                          value: _promotionType,
                          decoration: InputDecoration(
                            labelText: 'Promotion Type',
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
                                value: 'fixed_amount',
                                child: Text('Fixed Amount (\$)')),
                            DropdownMenuItem(
                                value: 'free_shipping',
                                child: Text('Free Shipping')),
                            DropdownMenuItem(
                                value: 'buy_x_get_y',
                                child: Text('Buy X Get Y')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _promotionType = value!;
                              // Reset scope type for certain promotion types
                              if (value == 'buy_x_get_y') {
                                _scopeType = 'specific_products';
                              } else if (value == 'free_shipping') {
                                _scopeType = 'all_products';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField('Discount Value', _discountController,
                              Icons.discount,
                              keyboardType: TextInputType.number),
                        ],
                        if (_promotionType == 'percentage') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Enter percentage (e.g., 20 for 20% off)',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (_promotionType == 'fixed_amount') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Enter amount in dollars (e.g., 10 for \$10 off)',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (_promotionType == 'buy_x_get_y') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Buy X Get Y promotion - select products below',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField('Minimum Order Amount',
                              _minAmountController, Icons.attach_money,
                              keyboardType: TextInputType.number),
                        ],
                        _buildMinOrderHelpText(),
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField('Maximum Discount Amount',
                              _maxDiscountController, Icons.attach_money,
                              keyboardType: TextInputType.number),
                        ],
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField(
                              'Usage Limit', _usageLimitController, Icons.block,
                              keyboardType: TextInputType.number),
                          _buildTextField('Usage Limit Per User',
                              _usagePerUserController, Icons.person,
                              keyboardType: TextInputType.number),
                          if (_scopeType == 'category' ||
                              _scopeType == 'brand') ...[
                            _buildTextField(
                                'Max Quantity Per Product',
                                _maxQuantityPerProductController,
                                Icons.shopping_cart,
                                keyboardType: TextInputType.number),
                            _buildTextField('Usage Limit Per Product',
                                _usageLimitPerProductController, Icons.block,
                                keyboardType: TextInputType.number),
                          ],
                        ],
                        if (_promotionType == 'buy_x_get_y') ...[
                          const SizedBox(height: 15),
                          _buildTextField('Buy Quantity (X)', _buyXController,
                              Icons.shopping_cart,
                              keyboardType: TextInputType.number),
                          _buildTextField('Get Quantity (Y)', _getYController,
                              Icons.card_giftcard,
                              keyboardType: TextInputType.number),
                        ],
                        const SizedBox(height: 15),
                        Text(
                          'This promotion applies to all customers',
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _scopeType,
                          decoration: InputDecoration(
                            labelText: 'Scope',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'all_products',
                                child: Text('All Products')),
                            DropdownMenuItem(
                                value: 'specific_products',
                                child: Text('Specific Products')),
                            DropdownMenuItem(
                                value: 'category', child: Text('Category')),
                          ],
                          onChanged: (value) {
                            // Clean, single setState call
                            setState(() {
                              // Clear selections when scope type changes
                              if (value != 'specific_products') {
                                _selectedProductIds.clear();
                              }
                              if (value != 'category') {
                                _selectedCategories.clear();
                              }

                              // Auto-adjust scope type for certain promotion types
                              if (_promotionType == 'buy_x_get_y' &&
                                  value != 'specific_products') {
                                _scopeType = 'specific_products';
                              } else if (_promotionType == 'free_shipping' &&
                                  value != 'all_products') {
                                _scopeType = 'all_products';
                              } else {
                                _scopeType = value ?? 'all_products';
                              }
                            });
                          },
                        ),
                      ]),
                      _buildFormSection('Product Selection', [
                        _buildProductSelectionWidget(),
                      ]),
                      _buildFormSection('Date Range', [
                        _buildDateField('Start Date', _startDate, (date) {
                          setState(() {
                            _startDate = date;
                          });
                        }),
                        const SizedBox(height: 15),
                        _buildDateField('End Date', _endDate, (date) {
                          setState(() {
                            _endDate = date;
                          });
                        }),
                      ]),
                      _buildFormSection('Settings', [
                        _buildSwitch('Active Promotion', _isActive,
                            (value) => setState(() => _isActive = value)),
                        _buildSwitch('Featured', _isFeatured,
                            (value) => setState(() => _isFeatured = value)),
                        _buildSwitch('Stackable', _isStackable,
                            (value) => setState(() => _isStackable = value)),
                        _buildSwitch('Requires Coupon', _requiresCoupon,
                            (value) => setState(() => _requiresCoupon = value)),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.primaryText.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '• Featured: Promotions marked as featured will be highlighted to customers and appear first in lists',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '• Stackable: When enabled, this promotion can be combined with other promotions and coupons',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '• Max Quantity Per Product: Limits how many of each product a customer can buy with this promotion',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '• Usage Limit Per Product: When reached, that specific product will no longer be eligible for the promotion',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final TextEditingController dateController = TextEditingController(
      text: date != null ? '${date.day}/${date.month}/${date.year}' : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: dateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select Date',
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today, color: AppColors.primaryText),
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: date ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (selectedDate != null) {
                  onChanged(selectedDate);
                  dateController.text =
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                }
              },
            ),
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
      ],
    );
  }

  Widget _buildProductSelectionWidget() {
    if (_scopeType == 'specific_products') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductSearchDropdown(),
          const SizedBox(height: 8),
          if (_selectedProductIds.isNotEmpty) ...[
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryText),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: _selectedProductIds.length,
                itemBuilder: (context, index) {
                  final productId = _selectedProductIds[index];
                  final product = _availableProducts.firstWhere(
                    (p) => p['id'] == productId,
                    orElse: () => {'name': 'Unknown Product', 'price': 0},
                  );
                  return ListTile(
                    title: Text(product['name'] ?? 'Unknown Product'),
                    subtitle: Text('\$${product['price']?.toString() ?? '0'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedProductIds.remove(productId);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    } else if (_scopeType == 'category') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryDropdown(),
          const SizedBox(height: 8),
          if (_selectedCategories.isNotEmpty) ...[
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryText),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: _selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = _selectedCategories[index];
                  return ListTile(
                    title: Text(category['name'] ?? 'Unknown Category'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedCategories.remove(category);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    } else {
      return Text(
        'This promotion applies to all products',
        style: TextStyle(
          color: AppColors.textSecondaryColor,
          fontSize: 14,
        ),
      );
    }
  }

  Widget _buildCategoryDropdown() {
    return _buildCustomDropdown(
      label: 'Select Categories',
      hint: 'Choose categories for this promotion',
      selectedCount: _selectedCategories.length,
      onTap: () => _showCategorySelectionDialog(),
    );
  }

  Widget _buildProductSearchDropdown() {
    return _buildCustomDropdown(
      label: 'Select Products',
      hint: 'Choose products for this promotion',
      selectedCount: _selectedProductIds.length,
      onTap: () => _showProductSelectionDialog(),
    );
  }

  Widget _buildCustomDropdown({
    required String label,
    required String hint,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    print('Building dropdown: $label, count: $selectedCount'); // Debug print
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryText),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCount == 0 ? hint : '$selectedCount selected',
                    style: TextStyle(
                      color: selectedCount == 0
                          ? AppColors.textSecondaryColor
                          : AppColors.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primaryText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProductSelectionDialog() {
    _productSearchQuery = ''; // Clear search when opening
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Products'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller:
                        TextEditingController(text: _productSearchQuery),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (query) {
                      _productSearchQuery = query;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Products list with checkboxes
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableProducts
                          .where((product) =>
                              _productSearchQuery.isEmpty ||
                              product['name']
                                      ?.toString()
                                      .toLowerCase()
                                      .contains(
                                          _productSearchQuery.toLowerCase()) ==
                                  true)
                          .length,
                      itemBuilder: (context, index) {
                        final filteredProducts = _availableProducts
                            .where((product) =>
                                _productSearchQuery.isEmpty ||
                                product['name']
                                        ?.toString()
                                        .toLowerCase()
                                        .contains(_productSearchQuery
                                            .toLowerCase()) ==
                                    true)
                            .toList();
                        final product = filteredProducts[index];
                        final productId = product['id'] as int;
                        final isSelected =
                            _selectedProductIds.contains(productId);

                        return CheckboxListTile(
                          title: Text(product['name'] ?? 'Unknown Product'),
                          subtitle:
                              Text('\$${product['price']?.toString() ?? '0'}'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            print(
                                'Product checkbox changed: $productId, value: $value'); // Debug print
                            if (value == true) {
                              if (!_selectedProductIds.contains(productId)) {
                                _selectedProductIds.add(productId);
                                print(
                                    'Added product: $productId, total: ${_selectedProductIds.length}'); // Debug print
                              }
                            } else {
                              _selectedProductIds.remove(productId);
                              print(
                                  'Removed product: $productId, total: ${_selectedProductIds.length}'); // Debug print
                            }
                            print(
                                'Updated _selectedProductIds: $_selectedProductIds'); // Debug print
                            // Update both dialog and main widget state
                            setDialogState(() {});
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedProductIds.clear();
                  });
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCategorySelectionDialog() {
    _categorySearchQuery = ''; // Clear search when opening
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Categories'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller:
                        TextEditingController(text: _categorySearchQuery),
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (query) {
                      _categorySearchQuery = query;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  // Categories list with checkboxes
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableCategories
                          .where((category) =>
                              _categorySearchQuery.isEmpty ||
                              category['name']
                                      ?.toString()
                                      .toLowerCase()
                                      .contains(
                                          _categorySearchQuery.toLowerCase()) ==
                                  true)
                          .length,
                      itemBuilder: (context, index) {
                        final filteredCategories = _availableCategories
                            .where((category) =>
                                _categorySearchQuery.isEmpty ||
                                category['name']
                                        ?.toString()
                                        .toLowerCase()
                                        .contains(_categorySearchQuery
                                            .toLowerCase()) ==
                                    true)
                            .toList();
                        final category = filteredCategories[index];
                        final categoryId = category['id'] as int;
                        final isSelected = _selectedCategories
                            .any((c) => c['id'] == categoryId);

                        return CheckboxListTile(
                          title: Text(category['name'] ?? 'Unknown Category'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            print(
                                'Category checkbox changed: $categoryId, value: $value'); // Debug print
                            if (value == true) {
                              if (!_selectedCategories
                                  .any((c) => c['id'] == categoryId)) {
                                _selectedCategories.add(category);
                                print(
                                    'Added category: $categoryId, total: ${_selectedCategories.length}'); // Debug print
                              }
                            } else {
                              _selectedCategories
                                  .removeWhere((c) => c['id'] == categoryId);
                              print(
                                  'Removed category: $categoryId, total: ${_selectedCategories.length}'); // Debug print
                            }
                            print(
                                'Updated _selectedCategories: $_selectedCategories'); // Debug print
                            // Update both dialog and main widget state
                            setDialogState(() {});
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategories.clear();
                  });
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
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
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please enter a promotion name', isError: true);
      return;
    }

    if (_promotionType != 'free_shipping' && _discountController.text.isEmpty) {
      _showSnackBar('Please enter a discount value', isError: true);
      return;
    }

    if (_promotionType == 'free_shipping' &&
        _discountController.text.isNotEmpty) {
      _showSnackBar('Free shipping promotions do not need a discount value',
          isError: true);
      return;
    }

    if (_promotionType == 'percentage') {
      try {
        final percentage = double.parse(_discountController.text);
        if (percentage <= 0 || percentage > 100) {
          _showSnackBar('Percentage must be between 1 and 100', isError: true);
          return;
        }
      } catch (e) {
        _showSnackBar('Please enter a valid percentage', isError: true);
        return;
      }
    } else if (_promotionType == 'fixed_amount') {
      try {
        final amount = double.parse(_discountController.text);
        if (amount <= 0) {
          _showSnackBar('Fixed amount must be greater than 0', isError: true);
          return;
        }
      } catch (e) {
        _showSnackBar('Please enter a valid amount', isError: true);
        return;
      }
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select start and end dates', isError: true);
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar('End date cannot be before start date', isError: true);
      return;
    }

    // Validate promotion type specific requirements
    // (This validation is now handled above)

    if (_promotionType == 'free_shipping' && _scopeType != 'all_products') {
      _showSnackBar('Free shipping promotions apply to all products',
          isError: true);
      return;
    }

    if (_promotionType == 'buy_x_get_y' && _scopeType != 'specific_products') {
      _showSnackBar('Buy X Get Y promotions require specific product selection',
          isError: true);
      return;
    }

    if (_scopeType == 'specific_products' && _selectedProductIds.isEmpty) {
      _showSnackBar('Please select at least one product for this promotion',
          isError: true);
      return;
    }

    if (_promotionType == 'buy_x_get_y') {
      try {
        final buyX = int.parse(_buyXController.text);
        final getY = int.parse(_getYController.text);
        if (buyX <= 0 || getY <= 0) {
          _showSnackBar('Buy X and Get Y quantities must be greater than 0',
              isError: true);
          return;
        }
        if (buyX < getY) {
          _showSnackBar(
              'Buy X quantity should be greater than or equal to Get Y quantity',
              isError: true);
          return;
        }
      } catch (e) {
        _showSnackBar('Please enter valid quantities for Buy X Get Y promotion',
            isError: true);
        return;
      }
    }

    try {
      final promotionData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'promotion_type': _promotionType,
        'discount_value': _promotionType != 'free_shipping'
            ? double.tryParse(_discountController.text) ?? 0.0
            : null,
        'minimum_order_amount': _minAmountController.text.isNotEmpty
            ? double.tryParse(_minAmountController.text) ?? 0.0
            : null,
        'max_discount_amount': _maxDiscountController.text.isNotEmpty
            ? double.tryParse(_maxDiscountController.text) ?? 0.0
            : null,
        'usage_limit': _usageLimitController.text.isNotEmpty
            ? int.tryParse(_usageLimitController.text) ?? 0
            : null,
        'usage_limit_per_user': _usagePerUserController.text.isNotEmpty
            ? int.tryParse(_usagePerUserController.text) ?? 1
            : 1,
        'max_quantity_per_product':
            _maxQuantityPerProductController.text.isNotEmpty
                ? int.tryParse(_maxQuantityPerProductController.text) ?? null
                : null,
        'usage_limit_per_product':
            _usageLimitPerProductController.text.isNotEmpty
                ? int.tryParse(_usageLimitPerProductController.text) ?? null
                : null,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'status': _isActive ? 'active' : 'inactive',
        // Target audience removed - all promotions are for customers
        'scope_type': _scopeType,
        'is_featured': _isFeatured,
        'is_stackable': _isStackable,
        'requires_coupon': _requiresCoupon,
        'priority': _priority,
        'product_ids':
            _scopeType == 'specific_products' ? _selectedProductIds : null,
        'category_ids': _scopeType == 'category'
            ? _selectedCategories.map((c) => c['id']).toList()
            : null,

        'buy_x_quantity': _promotionType == 'buy_x_get_y'
            ? int.tryParse(_buyXController.text) ?? 1
            : null,
        'get_y_quantity': _promotionType == 'buy_x_get_y'
            ? int.tryParse(_getYController.text) ?? 1
            : null,
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
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Promotions'),
                      Tab(text: 'Coupons'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPromotionsTab(),
                      _buildCouponsTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionsTab() {
    return Column(
      children: [
        // Promotions Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          'Promotions',
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
            ],
          ),
        ),
        // Promotions Search
        Container(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            onChanged: (q) {
              _filterPromotions(q);
            },
            decoration: InputDecoration(
              hintText: 'Search promotions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: AppColors.primaryText),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: AppColors.primaryText, width: 2),
              ),
            ),
          ),
        ),
        // Promotions List
        Expanded(
          child: _buildPromotionsList(),
        ),
      ],
    );
  }

  Widget _buildPromotionsList() {
    if (_isLoadingPromotions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredPromotions.isEmpty) {
      return Center(
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
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredPromotions.length,
      itemBuilder: (context, index) {
        final promotion = _filteredPromotions[index];
        return _buildPromotionCard(promotion);
      },
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
    final isActive = (promotion['status'] == 'active') && !isExpired;

    // Safely parse discount value
    String discountDisplay = 'N/A';
    try {
      if (promotion['discount_value'] != null) {
        final discount =
            double.tryParse(promotion['discount_value'].toString()) ?? 0.0;
        final type = promotion['promotion_type'] ?? 'percentage';
        discountDisplay =
            '${discount.toStringAsFixed(2)}${type == 'percentage' ? '%' : '\$'} OFF';
      }
    } catch (e) {
      discountDisplay = 'N/A';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                    promotion['name'] ?? 'Untitled Promotion',
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
                    discountDisplay,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: AppColors.textSecondaryColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${startDate != null ? '${startDate.day}/${startDate.month}/${startDate.year}' : 'N/A'} - ${endDate != null ? '${endDate.day}/${endDate.month}/${endDate.year}' : 'N/A'}',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (promotion['minimum_order_amount'] != null &&
                    (double.tryParse(
                                promotion['minimum_order_amount'].toString()) ??
                            0) >
                        0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Min: \$${promotion['minimum_order_amount']}',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Coupons
  Future<void> _loadCoupons() async {
    setState(() {
      _isLoadingCoupons = true;
    });

    try {
      final response = await _apiService.get('/coupons/admin/list');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _coupons = List<Map<String, dynamic>>.from(response.data['data']);
          _filteredCoupons = List.from(_coupons);
        });
      }
    } catch (e) {
      _showSnackBar('Error loading coupons: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCoupons = false;
      });
    }
  }

  void _filterCoupons(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCoupons = List.from(_coupons);
      } else {
        _filteredCoupons = _coupons.where((coupon) {
          final code = coupon['code']?.toString().toLowerCase() ?? '';
          final name = coupon['name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return code.contains(searchLower) || name.contains(searchLower);
        }).toList();
      }
    });
  }

  Widget _buildCouponsTab() {
    return Column(
      children: [
        // Coupons Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_activity,
                    size: 32,
                    color: AppColors.primaryText,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coupons',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          'Manage discount coupons and codes',
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddCouponDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Coupon'),
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
            ],
          ),
        ),
        // Coupons Search
        Container(
          padding: const EdgeInsets.all(20),
          child: TextField(
            controller: _searchController,
            onChanged: (q) {
              _filterCoupons(q);
            },
            decoration: InputDecoration(
              hintText: 'Search coupons...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: AppColors.primaryText),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: AppColors.primaryText, width: 2),
              ),
            ),
          ),
        ),
        // Coupons List
        Expanded(
          child: _buildCouponsList(),
        ),
      ],
    );
  }

  Widget _buildCouponsList() {
    if (_isLoadingCoupons) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_activity_outlined,
              size: 64,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No coupons found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredCoupons.length,
      itemBuilder: (context, index) {
        final coupon = _filteredCoupons[index];
        return _buildCouponCard(coupon);
      },
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final validFrom = coupon['valid_from'] != null
        ? DateTime.parse(coupon['valid_from'])
        : null;
    final validUntil = coupon['valid_until'] != null
        ? DateTime.parse(coupon['valid_until'])
        : null;
    final isExpired = validUntil != null && validUntil.isBefore(DateTime.now());
    final isActive = (coupon['is_active'] == true) && !isExpired;

    // Safely parse discount value
    String discountDisplay = 'N/A';
    try {
      if (coupon['discount_value'] != null) {
        final discount =
            double.tryParse(coupon['discount_value'].toString()) ?? 0.0;
        final type = coupon['discount_type'] ?? 'percentage';
        discountDisplay =
            '${discount.toStringAsFixed(2)}${type == 'percentage' ? '%' : '\$'} OFF';
      }
    } catch (e) {
      discountDisplay = 'N/A';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  Icons.local_activity,
                  color: AppColors.primaryText,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${coupon['code']} - ${coupon['name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCouponDialog(coupon);
                    } else if (value == 'delete') {
                      _deleteCoupon(coupon['id']);
                    } else if (value == 'toggle') {
                      _toggleCouponStatus(coupon);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on),
                          SizedBox(width: 8),
                          Text('Toggle Active'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
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
              coupon['description'] ?? 'No description',
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
                    discountDisplay,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: AppColors.textSecondaryColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${validFrom != null ? '${validFrom.day}/${validFrom.month}/${validFrom.year}' : 'N/A'} - ${validUntil != null ? '${validUntil.day}/${validUntil.month}/${validUntil.year}' : 'N/A'}',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (coupon['minimum_order_amount'] != null &&
                    (double.tryParse(
                                coupon['minimum_order_amount'].toString()) ??
                            0) >
                        0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Min: \$${coupon['minimum_order_amount']}',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCouponDialog() {
    _clearCouponForm();
    _showCouponDialog(isEditing: false);
  }

  void _showEditCouponDialog(Map<String, dynamic> coupon) {
    _populateCouponForm(coupon);
    _showCouponDialog(isEditing: true, couponId: coupon['id']);
  }

  void _clearCouponForm() {
    _codeController.clear();
    _couponNameController.clear();
    _couponDescriptionController.clear();
    _couponDiscountController.clear();
    _couponMinAmountController.clear();
    _couponMaxDiscountController.clear();
    _couponUsageLimitController.clear();
    _couponUsagePerUserController.clear();
    _couponValidFrom = null;
    _couponValidUntil = null;
    _couponIsActive = true;
    _couponDiscountType = 'percentage';
    _couponTargetAudience = 'both';
  }

  void _populateCouponForm(Map<String, dynamic> coupon) {
    _codeController.text = coupon['code'] ?? '';
    _couponNameController.text = coupon['name'] ?? '';
    _couponDescriptionController.text = coupon['description'] ?? '';
    _couponDiscountController.text = coupon['discount_value']?.toString() ?? '';
    _couponMinAmountController.text =
        coupon['minimum_order_amount']?.toString() ?? '';
    _couponMaxDiscountController.text =
        coupon['max_discount_amount']?.toString() ?? '';
    _couponUsageLimitController.text = coupon['usage_limit']?.toString() ?? '';
    _couponUsagePerUserController.text =
        coupon['usage_limit_per_user']?.toString() ?? '';
    _couponValidFrom = coupon['valid_from'] != null
        ? DateTime.parse(coupon['valid_from'])
        : null;
    _couponValidUntil = coupon['valid_until'] != null
        ? DateTime.parse(coupon['valid_until'])
        : null;
    _couponIsActive = coupon['is_active'] ?? true;
    _couponDiscountType = coupon['discount_type'] ?? 'percentage';
    _couponTargetAudience = coupon['target_audience'] ?? 'both';
  }

  void _showCouponDialog({required bool isEditing, int? couponId}) {
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
                    isEditing ? 'Edit Coupon' : 'Add New Coupon',
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
                        _buildTextField('Code', _codeController, Icons.code),
                        _buildTextField(
                            'Name', _couponNameController, Icons.title),
                        _buildTextField('Description',
                            _couponDescriptionController, Icons.description,
                            maxLines: 3),
                      ]),
                      _buildFormSection('Discount Settings', [
                        DropdownButtonFormField<String>(
                          value: _couponDiscountType,
                          decoration: InputDecoration(
                            labelText: 'Discount Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'percentage',
                                child: Text('Percentage (%)')),
                            DropdownMenuItem(
                                value: 'fixed_amount',
                                child: Text('Fixed Amount (\$)')),
                            DropdownMenuItem(
                                value: 'free_shipping',
                                child: Text('Free Shipping')),
                            DropdownMenuItem(
                                value: 'buy_x_get_y',
                                child: Text('Buy X Get Y')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _couponDiscountType = value ?? 'percentage';
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField('Discount Value',
                            _couponDiscountController, Icons.discount,
                            keyboardType: TextInputType.number),
                        _buildTextField('Minimum Order Amount',
                            _couponMinAmountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField('Maximum Discount Amount',
                            _couponMaxDiscountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField('Usage Limit',
                            _couponUsageLimitController, Icons.block,
                            keyboardType: TextInputType.number),
                        _buildTextField('Usage Limit Per User',
                            _couponUsagePerUserController, Icons.person,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _couponTargetAudience,
                          decoration: InputDecoration(
                            labelText: 'Target Audience',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'both', child: Text('All Customers')),
                            DropdownMenuItem(
                                value: 'B2C', child: Text('B2C Only')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _couponTargetAudience = value ?? 'both';
                            });
                          },
                        ),
                      ]),
                      _buildFormSection('Validity', [
                        _buildDateField('Valid From', _couponValidFrom, (date) {
                          setState(() {
                            _couponValidFrom = date;
                          });
                        }),
                        const SizedBox(height: 15),
                        _buildDateField('Valid Until', _couponValidUntil,
                            (date) {
                          setState(() {
                            _couponValidUntil = date;
                          });
                        }),
                        _buildSwitch('Active', _couponIsActive,
                            (value) => setState(() => _couponIsActive = value)),
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
                      onPressed: () => _saveCoupon(isEditing, couponId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEditing ? 'Update Coupon' : 'Add Coupon'),
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

  Future<void> _saveCoupon(bool isEditing, int? couponId) async {
    if (_codeController.text.isEmpty ||
        _couponDiscountController.text.isEmpty) {
      _showSnackBar('Please fill in code and discount value', isError: true);
      return;
    }

    try {
      final couponData = {
        'code': _codeController.text.toUpperCase(),
        'name': _couponNameController.text,
        'description': _couponDescriptionController.text,
        'discount_type': _couponDiscountType,
        'discount_value':
            double.tryParse(_couponDiscountController.text) ?? 0.0,
        'minimum_order_amount': _couponMinAmountController.text.isNotEmpty
            ? double.tryParse(_couponMinAmountController.text) ?? 0.0
            : null,
        'max_discount_amount': _couponMaxDiscountController.text.isNotEmpty
            ? double.tryParse(_couponMaxDiscountController.text) ?? 0.0
            : null,
        'usage_limit': _couponUsageLimitController.text.isNotEmpty
            ? int.tryParse(_couponUsageLimitController.text) ?? 0
            : null,
        'usage_limit_per_user': _couponUsagePerUserController.text.isNotEmpty
            ? int.tryParse(_couponUsagePerUserController.text) ?? 1
            : 1,
        'valid_from': _couponValidFrom?.toIso8601String(),
        'valid_until': _couponValidUntil?.toIso8601String(),
        'is_active': _couponIsActive,
        'target_audience': _couponTargetAudience,
      };

      if (isEditing && couponId != null) {
        await _apiService.put('/coupons/$couponId', data: couponData);
        _showSnackBar('Coupon updated successfully');
      } else {
        await _apiService.post('/coupons', data: couponData);
        _showSnackBar('Coupon added successfully');
      }

      Navigator.pop(context);
      _loadCoupons();
    } catch (e) {
      _showSnackBar('Error saving coupon: $e', isError: true);
    }
  }

  Future<void> _deleteCoupon(int couponId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: const Text(
            'Are you sure you want to delete this coupon? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/coupons/$couponId');
        _showSnackBar('Coupon deleted successfully');
        _loadCoupons();
      } catch (e) {
        _showSnackBar('Error deleting coupon: $e', isError: true);
      }
    }
  }

  Future<void> _toggleCouponStatus(Map<String, dynamic> coupon) async {
    try {
      final newActive = !(coupon['is_active'] == true);
      await _apiService.put('/coupons/${coupon['id']}/status',
          data: {'is_active': newActive});
      _showSnackBar('Coupon status updated successfully');
      _loadCoupons();
    } catch (e) {
      _showSnackBar('Error updating coupon status: $e', isError: true);
    }
  }

  Widget _buildMinOrderHelpText() {
    if (_promotionType == 'free_shipping' || _scopeType != 'category') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Minimum order amount required to activate this promotion (e.g., 50 for 20% off fruits)',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
