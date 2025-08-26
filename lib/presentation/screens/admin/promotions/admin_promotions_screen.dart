import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';
import '../../../widgets/admin/auth_wrapper.dart';
import 'add_promotion_screen.dart';
import 'edit_promotion_screen.dart';

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
  String _selectedPromotionStatus = ArabicText.all;

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
  String _selectedCouponStatus = ArabicText.all;

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
      _showSnackBar('${ArabicText.errorLoadingPromotions}: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingPromotions = false;
      });
    }
  }

  void _filterPromotions(String query) {
    setState(() {
      _searchQuery = query;

      // Start with all promotions
      var filtered = List<Map<String, dynamic>>.from(_promotions);

      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((promotion) {
          final name = promotion['name']?.toString().toLowerCase() ?? '';
          final description =
              promotion['description']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              description.contains(searchLower);
        }).toList();
      }

      // Apply status filter
      if (_selectedPromotionStatus != ArabicText.all) {
        filtered = filtered.where((promotion) {
          final status = promotion['status'] ?? 'active';
          return status == _selectedPromotionStatus;
        }).toList();
      }

      _filteredPromotions = filtered;
    });
  }

  void _showAddPromotionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPromotionScreen(
          onPromotionAdded: (newPromotion) {
            print(
                'DEBUG: onPromotionAdded callback called with: $newPromotion');
            setState(() {
              _promotions.insert(0, newPromotion);
              _filteredPromotions.insert(0, newPromotion);
            });
            // Also refresh from server to ensure data consistency
            _loadPromotions();
            // Show success message on the promotions page
            print('DEBUG: About to show success message');
            _showSnackBar(ArabicText.promotionAdded, isError: false);
            print('DEBUG: Success message shown');
            // Force a rebuild to ensure the UI updates
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showEditPromotionDialog(Map<String, dynamic> promotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPromotionScreen(
          promotion: promotion,
          onPromotionUpdated: (updatedPromotion) {
            setState(() {
              // Find and update the promotion in the list
              final index = _promotions
                  .indexWhere((p) => p['id'] == updatedPromotion['id']);
              if (index != -1) {
                _promotions[index] = updatedPromotion;
                _filteredPromotions[index] = updatedPromotion;
              }
            });
            // Also refresh from server to ensure data consistency
            _loadPromotions();
            // Show success message
            _showSnackBar(ArabicText.promotionUpdated, isError: false);
          },
        ),
      ),
    );
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
                    isEditing
                        ? ArabicText.editPromotion
                        : ArabicText.addNewPromotion,
                    style: const TextStyle(
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
                      _buildFormSection(ArabicText.basicInformation, [
                        _buildTextField(
                            ArabicText.name, _nameController, Icons.title),
                        _buildTextField(ArabicText.description,
                            _descriptionController, Icons.description,
                            maxLines: 3),
                      ]),
                      _buildFormSection(ArabicText.promotionSettings, [
                        DropdownButtonFormField<String>(
                          value: _promotionType,
                          decoration: InputDecoration(
                            labelText: ArabicText.promotionType,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'percentage',
                                child: Text(ArabicText.percentage)),
                            DropdownMenuItem(
                                value: 'fixed_amount',
                                child: Text(ArabicText.fixedAmount)),
                            DropdownMenuItem(
                                value: 'free_shipping',
                                child: Text(ArabicText.freeShipping)),
                            DropdownMenuItem(
                                value: 'buy_x_get_y',
                                child: Text(ArabicText.buyXGetY)),
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
                          _buildTextField(ArabicText.discountValue,
                              _discountController, Icons.discount,
                              keyboardType: TextInputType.number),
                        ],
                        if (_promotionType == 'percentage') ...[
                          const SizedBox(height: 8),
                          const Text(
                            ArabicText.percentageHelpText,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (_promotionType == 'fixed_amount') ...[
                          const SizedBox(height: 8),
                          const Text(
                            ArabicText.fixedAmountHelpText,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ] else if (_promotionType == 'buy_x_get_y') ...[
                          const SizedBox(height: 8),
                          const Text(
                            ArabicText.buyXGetYHelpText,
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField(ArabicText.minimumOrderAmount,
                              _minAmountController, Icons.attach_money,
                              keyboardType: TextInputType.number),
                        ],
                        _buildMinOrderHelpText(),
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField(ArabicText.maximumDiscountAmount,
                              _maxDiscountController, Icons.attach_money,
                              keyboardType: TextInputType.number),
                        ],
                        if (_promotionType != 'free_shipping') ...[
                          _buildTextField(ArabicText.usageLimit,
                              _usageLimitController, Icons.block,
                              keyboardType: TextInputType.number),
                          _buildTextField(ArabicText.usageLimitPerUser,
                              _usagePerUserController, Icons.person,
                              keyboardType: TextInputType.number),
                          if (_scopeType == 'category' ||
                              _scopeType == 'brand') ...[
                            _buildTextField(
                                ArabicText.maxQuantityPerProduct,
                                _maxQuantityPerProductController,
                                Icons.shopping_cart,
                                keyboardType: TextInputType.number),
                            _buildTextField(ArabicText.usageLimitPerProduct,
                                _usageLimitPerProductController, Icons.block,
                                keyboardType: TextInputType.number),
                          ],
                        ],
                        if (_promotionType == 'buy_x_get_y') ...[
                          const SizedBox(height: 15),
                          _buildTextField(ArabicText.buyQuantity,
                              _buyXController, Icons.shopping_cart,
                              keyboardType: TextInputType.number),
                          _buildTextField(ArabicText.getQuantity,
                              _getYController, Icons.card_giftcard,
                              keyboardType: TextInputType.number),
                        ],
                        const SizedBox(height: 15),
                        const Text(
                          ArabicText.allCustomersText,
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _scopeType,
                          decoration: InputDecoration(
                            labelText: ArabicText.scope,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'all_products',
                                child: Text(ArabicText.allProducts)),
                            DropdownMenuItem(
                                value: 'specific_products',
                                child: Text(ArabicText.specificProducts)),
                            DropdownMenuItem(
                                value: 'category',
                                child: Text(ArabicText.category)),
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
                      _buildFormSection(ArabicText.productSelection, [
                        _buildProductSelectionWidget(),
                      ]),
                      _buildFormSection(ArabicText.dateRange, [
                        _buildDateField(ArabicText.startDate, _startDate,
                            (date) {
                          setState(() {
                            _startDate = date;
                          });
                        }),
                        const SizedBox(height: 15),
                        _buildDateField(ArabicText.endDate, _endDate, (date) {
                          setState(() {
                            _endDate = date;
                          });
                        }),
                      ]),
                      _buildFormSection(ArabicText.settings, [
                        _buildSwitch(ArabicText.activePromotion, _isActive,
                            (value) => setState(() => _isActive = value)),
                        _buildSwitch(ArabicText.featured, _isFeatured,
                            (value) => setState(() => _isFeatured = value)),
                        _buildSwitch(ArabicText.stackable, _isStackable,
                            (value) => setState(() => _isStackable = value)),
                        _buildSwitch(ArabicText.requiresCoupon, _requiresCoupon,
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
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ArabicText.helpAndInformation,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '• ${ArabicText.featured}: ${ArabicText.featuredDescription}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '• ${ArabicText.stackable}: ${ArabicText.stackableDescription}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '• ${ArabicText.maxQuantityPerProduct}: ${ArabicText.maxQuantityPerProductDescription}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '• ${ArabicText.usageLimitPerProduct}: ${ArabicText.usageLimitPerProductDescription}',
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
                      child: const Text(ArabicText.cancel),
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
                      child: Text(isEditing
                          ? ArabicText.editPromotion
                          : ArabicText.addNewPromotion),
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
          style: const TextStyle(
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
            borderSide: const BorderSide(color: AppColors.primaryText),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryText, width: 2),
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
            hintText: ArabicText.selectDate,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today,
                  color: AppColors.primaryText),
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
              borderSide: const BorderSide(color: AppColors.primaryText),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primaryText, width: 2),
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
                    orElse: () =>
                        {'name': ArabicText.unknownProduct, 'price': 0},
                  );
                  return ListTile(
                    title: Text(product['name'] ?? ArabicText.unknownProduct),
                    subtitle: Text('${product['price']?.toString() ?? '0'}₪'),
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
                    title: Text(category['name'] ?? ArabicText.unknownCategory),
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
      return const Text(
        ArabicText.thisPromotionAppliesToAllProducts,
        style: TextStyle(
          color: AppColors.textSecondaryColor,
          fontSize: 14,
        ),
      );
    }
  }

  Widget _buildCategoryDropdown() {
    return _buildCustomDropdown(
      label: ArabicText.selectCategories,
      hint: ArabicText.chooseCategoriesForPromotion,
      selectedCount: _selectedCategories.length,
      onTap: () => _showCategorySelectionDialog(),
    );
  }

  Widget _buildProductSearchDropdown() {
    return _buildCustomDropdown(
      label: ArabicText.selectProducts,
      hint: ArabicText.chooseProductsForPromotion,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
                    selectedCount == 0
                        ? hint
                        : '$selectedCount ${ArabicText.selected}',
                    style: TextStyle(
                      color: selectedCount == 0
                          ? AppColors.textSecondaryColor
                          : AppColors.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(
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
            title: const Text(ArabicText.selectProducts),
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
                      hintText:
                          '${ArabicText.search} ${ArabicText.products}...',
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
                          title: Text(
                              product['name'] ?? ArabicText.unknownProduct),
                          subtitle:
                              Text('${product['price']?.toString() ?? '0'}₪'),
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value == true) {
                              if (!_selectedProductIds.contains(productId)) {
                                _selectedProductIds.add(productId);
                              }
                            } else {
                              _selectedProductIds.remove(productId);
                            }

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
                child: const Text(ArabicText.cancel),
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
                child: const Text(ArabicText.clearAll),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text(ArabicText.done),
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
            title: const Text(ArabicText.selectCategories),
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
                      hintText:
                          '${ArabicText.search} ${ArabicText.categories}...',
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
                          title: Text(
                              category['name'] ?? ArabicText.unknownCategory),
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value == true) {
                              if (!_selectedCategories
                                  .any((c) => c['id'] == categoryId)) {
                                _selectedCategories.add(category);
                              }
                            } else {
                              _selectedCategories
                                  .removeWhere((c) => c['id'] == categoryId);
                            }

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
                child: const Text(ArabicText.cancel),
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
                child: const Text(ArabicText.clearAll),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Force main form to rebuild when dialog closes
                  setState(() {});
                },
                child: const Text(ArabicText.done),
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
      _showSnackBar(ArabicText.pleaseEnterPromotionName, isError: true);
      return;
    }

    if (_promotionType != 'free_shipping' && _discountController.text.isEmpty) {
      _showSnackBar(ArabicText.pleaseEnterDiscountValue, isError: true);
      return;
    }

    if (_promotionType == 'free_shipping' &&
        _discountController.text.isNotEmpty) {
      _showSnackBar(ArabicText.freeShippingNoDiscount, isError: true);
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
        _showSnackBar(ArabicText.pleaseEnterValidPercentage, isError: true);
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
        _showSnackBar(ArabicText.pleaseEnterValidAmount, isError: true);
        return;
      }
    }

    if (_startDate == null || _endDate == null) {
      _showSnackBar(ArabicText.pleaseSelectDates, isError: true);
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar(ArabicText.endDateBeforeStart, isError: true);
      return;
    }

    // Validate promotion type specific requirements
    // (This validation is now handled above)

    if (_promotionType == 'free_shipping' && _scopeType != 'all_products') {
      _showSnackBar(ArabicText.freeShippingAllProducts, isError: true);
      return;
    }

    if (_promotionType == 'buy_x_get_y' && _scopeType != 'specific_products') {
      _showSnackBar(ArabicText.buyXGetYRequiresProducts, isError: true);
      return;
    }

    if (_scopeType == 'specific_products' && _selectedProductIds.isEmpty) {
      _showSnackBar(ArabicText.pleaseSelectProductsForPromotion, isError: true);
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
          _showSnackBar(ArabicText.buyXGreaterThanY, isError: true);
          return;
        }
      } catch (e) {
        _showSnackBar(ArabicText.pleaseEnterValidQuantities, isError: true);
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
                ? int.tryParse(_maxQuantityPerProductController.text)
                : null,
        'usage_limit_per_product':
            _usageLimitPerProductController.text.isNotEmpty
                ? int.tryParse(_usageLimitPerProductController.text)
                : null,
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'status': _isActive ? ArabicText.active : ArabicText.inactive,
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
        _showSnackBar(ArabicText.promotionUpdatedSuccessfully);
      } else {
        await _apiService.post('/promotions', data: promotionData);
        _showSnackBar(ArabicText.promotionAddedSuccessfully);
      }

      Navigator.pop(context);
      _loadPromotions();
    } catch (e) {
      _showSnackBar('${ArabicText.errorSavingPromotion}: $e', isError: true);
    }
  }

  Future<void> _deletePromotion(int promotionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ArabicText.deletePromotion),
        content: const Text(ArabicText.confirmDeletePromotion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(ArabicText.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(ArabicText.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/promotions/$promotionId');
        _showSnackBar(ArabicText.promotionDeleted);
        _loadPromotions();
      } catch (e) {
        _showSnackBar('${ArabicText.errorDeletingPromotion}: $e',
            isError: true);
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
                      Tab(text: ArabicText.promotions),
                      Tab(text: ArabicText.coupons),
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
        // Search Bar
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: AppColors.primaryText,
                size: 24,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterPromotions,
                  decoration: InputDecoration(
                    hintText: ArabicText.searchPromotions,
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Filter
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryText),
                ),
                child: DropdownButton<String>(
                  value: _selectedPromotionStatus,
                  hint: const Text(
                    ArabicText.all,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                  underline: Container(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primaryText,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ArabicText.all,
                      child: Text(
                        ArabicText.all,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(
                        ArabicText.active,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text(
                        ArabicText.inactive,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPromotionStatus = newValue ?? ArabicText.all;
                    });
                    _filterPromotions(_searchController.text);
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddPromotionDialog,
                icon: const Icon(Icons.add),
                label: const Text(ArabicText.addNewPromotion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
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
            const Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppColors.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? ArabicText.noPromotionsYet
                  : ArabicText.noPromotionsFound,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryColor,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '${ArabicText.addYourFirst} ${ArabicText.promotions} ${ArabicText.toGetStarted}',
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
            '${discount.toStringAsFixed(2)}${type == 'percentage' ? '%' : '₪'} OFF';
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
                const Icon(
                  Icons.local_offer,
                  color: AppColors.primaryText,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    promotion['name'] ?? ArabicText.unnamedUser,
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
                          Text(ArabicText.edit),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(ArabicText.delete,
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert,
                      color: AppColors.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              promotion['description'] ?? ArabicText.noSpecialNotes,
              style: const TextStyle(
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
                    style: const TextStyle(
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
                    isActive ? ArabicText.active : ArabicText.inactive,
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
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.textSecondaryColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${startDate != null ? '${startDate.day}/${startDate.month}/${startDate.year}' : ArabicText.unknownDate} - ${endDate != null ? '${endDate.day}/${endDate.month}/${endDate.year}' : ArabicText.unknownDate}',
                        style: const TextStyle(
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
                    '${ArabicText.minimumOrder}: ${promotion['minimum_order_amount']}₪',
                    style: const TextStyle(
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
      _showSnackBar('${ArabicText.errorLoadingCoupons}: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCoupons = false;
      });
    }
  }

  void _filterCoupons(String query) {
    setState(() {
      // Start with all coupons
      var filtered = List<Map<String, dynamic>>.from(_coupons);

      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered.where((coupon) {
          final code = coupon['code']?.toString().toLowerCase() ?? '';
          final name = coupon['name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return code.contains(searchLower) || name.contains(searchLower);
        }).toList();
      }

      // Apply status filter
      if (_selectedCouponStatus != ArabicText.all) {
        filtered = filtered.where((coupon) {
          final status = coupon['status'] ?? 'active';
          return status == _selectedCouponStatus;
        }).toList();
      }

      _filteredCoupons = filtered;
    });
  }

  Widget _buildCouponsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: AppColors.primaryText,
                size: 24,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (q) {
                    _filterCoupons(q);
                  },
                  decoration: InputDecoration(
                    hintText: '${ArabicText.search} ${ArabicText.coupons}...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Status Filter
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryText),
                ),
                child: DropdownButton<String>(
                  value: _selectedCouponStatus,
                  hint: const Text(
                    ArabicText.all,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                  underline: Container(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primaryText,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ArabicText.all,
                      child: Text(
                        ArabicText.all,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(
                        ArabicText.active,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text(
                        ArabicText.inactive,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCouponStatus = newValue ?? ArabicText.all;
                      _filterCoupons(_searchController.text);
                    });
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddCouponDialog,
                icon: const Icon(Icons.add),
                label: const Text(ArabicText.addNewCoupon),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_activity_outlined,
              size: 64,
              color: AppColors.textSecondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              ArabicText.noCouponsFound,
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
            '${discount.toStringAsFixed(2)}${type == 'percentage' ? '%' : '₪'} OFF';
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
                const Icon(
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
                          Text(ArabicText.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on),
                          SizedBox(width: 8),
                          Text(ArabicText.toggleActive),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(ArabicText.delete,
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert,
                      color: AppColors.textSecondaryColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              coupon['description'] ?? ArabicText.noSpecialNotes,
              style: const TextStyle(
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
                    style: const TextStyle(
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
                    isActive ? ArabicText.active : ArabicText.inactive,
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
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.textSecondaryColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${validFrom != null ? '${validFrom.day}/${validFrom.month}/${validFrom.year}' : ArabicText.unknownDate} - ${validUntil != null ? '${validUntil.day}/${validUntil.month}/${validUntil.year}' : ArabicText.unknownDate}',
                        style: const TextStyle(
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
                    '${ArabicText.minimumOrder}: ${coupon['minimum_order_amount']}₪',
                    style: const TextStyle(
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
                    isEditing ? ArabicText.editCoupon : ArabicText.addNewCoupon,
                    style: const TextStyle(
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
                      _buildFormSection(ArabicText.basicInformation, [
                        _buildTextField(
                            ArabicText.couponCode, _codeController, Icons.code),
                        _buildTextField(ArabicText.name, _couponNameController,
                            Icons.title),
                        _buildTextField(ArabicText.description,
                            _couponDescriptionController, Icons.description,
                            maxLines: 3),
                      ]),
                      _buildFormSection(ArabicText.discountSettings, [
                        DropdownButtonFormField<String>(
                          value: _couponDiscountType,
                          decoration: InputDecoration(
                            labelText: ArabicText.discountType,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'percentage',
                                child: Text(ArabicText.percentage)),
                            DropdownMenuItem(
                                value: 'fixed_amount',
                                child: Text(ArabicText.fixedAmount)),
                            DropdownMenuItem(
                                value: 'free_shipping',
                                child: Text(ArabicText.freeShipping)),
                            DropdownMenuItem(
                                value: 'buy_x_get_y',
                                child: Text(ArabicText.buyXGetY)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _couponDiscountType = value ?? 'percentage';
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(ArabicText.discountValue,
                            _couponDiscountController, Icons.discount,
                            keyboardType: TextInputType.number),
                        _buildTextField(ArabicText.minimumOrderAmount,
                            _couponMinAmountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField(ArabicText.maximumDiscountAmount,
                            _couponMaxDiscountController, Icons.attach_money,
                            keyboardType: TextInputType.number),
                        _buildTextField(ArabicText.usageLimit,
                            _couponUsageLimitController, Icons.block,
                            keyboardType: TextInputType.number),
                        _buildTextField(ArabicText.usageLimitPerUser,
                            _couponUsagePerUserController, Icons.person,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _couponTargetAudience,
                          decoration: InputDecoration(
                            labelText: ArabicText.targetAudience,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryText),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'both',
                                child: Text(ArabicText.allCustomers)),
                            DropdownMenuItem(
                                value: 'B2C', child: Text(ArabicText.b2cOnly)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _couponTargetAudience = value ?? 'both';
                            });
                          },
                        ),
                      ]),
                      _buildFormSection(ArabicText.validity, [
                        _buildDateField(ArabicText.validFrom, _couponValidFrom,
                            (date) {
                          setState(() {
                            _couponValidFrom = date;
                          });
                        }),
                        const SizedBox(height: 15),
                        _buildDateField(
                            ArabicText.validUntil, _couponValidUntil, (date) {
                          setState(() {
                            _couponValidUntil = date;
                          });
                        }),
                        _buildSwitch(ArabicText.active, _couponIsActive,
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
                      child: const Text(ArabicText.cancel),
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
                      child: Text(isEditing
                          ? ArabicText.editCoupon
                          : ArabicText.addNewCoupon),
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
      _showSnackBar(ArabicText.pleaseFillInCodeAndDiscount, isError: true);
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
        _showSnackBar(ArabicText.couponUpdatedSuccessfully);
      } else {
        await _apiService.post('/coupons', data: couponData);
        _showSnackBar(ArabicText.couponAddedSuccessfully);
      }

      Navigator.pop(context);
      _loadCoupons();
    } catch (e) {
      _showSnackBar('${ArabicText.errorSavingCoupon}: $e', isError: true);
    }
  }

  Future<void> _deleteCoupon(int couponId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ArabicText.deleteCoupon),
        content: const Text(
            '${ArabicText.confirmDelete} ${ArabicText.coupons}؟ ${ArabicText.thisActionCannotBeUndone}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(ArabicText.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(ArabicText.delete)),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/coupons/$couponId');
        _showSnackBar(ArabicText.couponDeleted);
        _loadCoupons();
      } catch (e) {
        _showSnackBar('${ArabicText.errorDeletingCoupon}: $e', isError: true);
      }
    }
  }

  Future<void> _toggleCouponStatus(Map<String, dynamic> coupon) async {
    try {
      final newActive = !(coupon['is_active'] == true);
      await _apiService.put('/coupons/${coupon['id']}/status',
          data: {'is_active': newActive});
      _showSnackBar(ArabicText.couponUpdatedSuccessfully);
      _loadCoupons();
    } catch (e) {
      _showSnackBar('${ArabicText.errorUpdatingCoupon}: $e', isError: true);
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
          child: const Text(
            ArabicText.minimumOrderHelp,
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
