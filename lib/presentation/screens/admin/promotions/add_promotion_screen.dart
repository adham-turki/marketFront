import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';
import 'select_categories_screen.dart';
import 'select_products_screen.dart';

class AddPromotionScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onPromotionAdded;

  const AddPromotionScreen({
    super.key,
    required this.onPromotionAdded,
  });

  @override
  State<AddPromotionScreen> createState() => _AddPromotionScreenState();
}

class _AddPromotionScreenState extends State<AddPromotionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountPercentageController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();
  final _maxQuantityPerProductController = TextEditingController();
  final _usageLimitPerProductController = TextEditingController();
  final _priorityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedType = 'نسبة مئوية';
  DateTime? _startDate;
  DateTime? _endDate;
  List<int> _selectedCategoryIds = [];
  List<int> _selectedProductIds = [];
  bool _isFeatured = false;
  bool _isStackable = false;
  bool _isActive = true;
  bool _isLoading = false;
  String _scopeType = 'all_products';

  final List<String> _typeOptions = [
    'نسبة مئوية',
    'مبلغ ثابت',
    'شحن مجاني',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.init();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _discountPercentageController.dispose();
    _minimumOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _maxQuantityPerProductController.dispose();
    _usageLimitPerProductController.dispose();
    _priorityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showCategorySelectionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectCategoriesScreen(
          selectedCategoryIds: _selectedCategoryIds,
          onCategoriesSelected: (List<int> selectedIds) {
            setState(() {
              _selectedCategoryIds = selectedIds;
            });
          },
        ),
      ),
    );
  }

  void _showProductSelectionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectProductsScreen(
          selectedProductIds: _selectedProductIds,
          onProductsSelected: (List<int> selectedIds) {
            setState(() {
              _selectedProductIds = selectedIds;
            });
          },
        ),
      ),
    );
  }

  String _getPromotionType() {
    switch (_selectedType) {
      case 'نسبة مئوية':
        return 'percentage';
      case 'مبلغ ثابت':
        return 'fixed_amount';
      case 'شحن مجاني':
        return 'free_shipping';
      default:
        return 'percentage';
    }
  }

  double? _getDiscountValue() {
    if (_selectedType == 'شحن مجاني') {
      return null; // Free shipping doesn't need discount value
    }
    final value = double.tryParse(_discountPercentageController.text);
    if (value == null || value <= 0) {
      return null; // Return null for invalid values
    }
    return value;
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showSnackBar('يرجى اختيار التاريخ', isError: true);
      return;
    }

    // Validate discount value for non-free shipping promotions
    if (_selectedType != 'شحن مجاني') {
      final discountValue = double.tryParse(_discountPercentageController.text);
      if (discountValue == null || discountValue <= 0) {
        _showSnackBar('يرجى إدخال قيمة خصم صحيحة', isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final promotionData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'promotion_type': _getPromotionType(),
        'discount_value': _getDiscountValue(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'status': _isActive ? 'active' : 'inactive',
        'scope_type': _scopeType,
        'is_featured': _isFeatured,
        'is_stackable': _isStackable,
        'product_ids':
            _scopeType == 'specific_products' ? _selectedProductIds : null,
        'category_ids': _scopeType == 'category' ? _selectedCategoryIds : null,
        // Add required fields with values from form
        'minimum_order_amount': _minimumOrderController.text.isNotEmpty
            ? double.tryParse(_minimumOrderController.text) ?? 0.0
            : 0.0,
        'max_discount_amount': _maxDiscountController.text.isNotEmpty
            ? double.tryParse(_maxDiscountController.text) ?? 1000.0
            : 1000.0,
        'usage_limit': _usageLimitController.text.isNotEmpty
            ? int.tryParse(_usageLimitController.text) ?? 100
            : 100,
        'usage_limit_per_user': 1,
        'max_quantity_per_product':
            _maxQuantityPerProductController.text.isNotEmpty
                ? int.tryParse(_maxQuantityPerProductController.text) ?? 10
                : 10,
        'usage_limit_per_product':
            _usageLimitPerProductController.text.isNotEmpty
                ? int.tryParse(_usageLimitPerProductController.text) ?? 5
                : 5,
        'requires_coupon': false,
        'priority': _priorityController.text.isNotEmpty
            ? int.tryParse(_priorityController.text) ?? 0
            : 0,
        'buy_x_quantity': null,
        'get_y_quantity': null,
        'image_url': _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
      };

      print('Sending promotion data: $promotionData');

      final response =
          await _apiService.post('/promotions', data: promotionData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('DEBUG: Promotion created successfully, calling callback');
        // First call the callback to update the promotions page
        widget.onPromotionAdded(response.data['promotion'] ?? response.data);
        print('DEBUG: Callback completed, navigating back');
        // Then navigate back
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(
            response.data['message'] ?? ArabicText.errorAddingPromotion,
            isError: true);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorAddingPromotion}: $e', isError: true);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicText.addNewPromotion,
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المعلومات الأساسية',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminTextPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                ArabicText.promotionName,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ArabicText.pleaseFillInRequiredFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                ArabicText.promotionDescription,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ArabicText.pleaseFillInRequiredFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'رابط الصورة (اختياري)',
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'https://example.com/image.jpg',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ArabicText.promotionType,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _typeOptions
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 20),
              Text(
                ArabicText.discountPercentage,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _discountPercentageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: '%',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ArabicText.pleaseFillInRequiredFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicText.startDate,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'اختر التاريخ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ArabicText.endDate,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'اختر التاريخ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'نطاق التطبيق',
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'جميع المنتجات',
                      style: TextStyle(color: AppColors.adminTextPrimary),
                    ),
                    value: 'all_products',
                    groupValue: _scopeType,
                    onChanged: (value) => setState(() => _scopeType = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'منتجات محددة',
                      style: TextStyle(color: AppColors.adminTextPrimary),
                    ),
                    value: 'specific_products',
                    groupValue: _scopeType,
                    onChanged: (value) => setState(() => _scopeType = value!),
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'فئات محددة',
                      style: TextStyle(color: AppColors.adminTextPrimary),
                    ),
                    value: 'category',
                    groupValue: _scopeType,
                    onChanged: (value) => setState(() => _scopeType = value!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_scopeType == 'category') ...[
                const Text(
                  'اختر الفئات',
                  style: TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showCategorySelectionPage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_selectedCategoryIds.isEmpty
                              ? 'اختر الفئات'
                              : 'تم اختيار ${_selectedCategoryIds.length} فئة'),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (_scopeType == 'specific_products') ...[
                const Text(
                  'اختر المنتجات',
                  style: TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showProductSelectionPage,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_selectedProductIds.isEmpty
                              ? 'اختر المنتجات'
                              : 'تم اختيار ${_selectedProductIds.length} منتج'),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
              const Text(
                'إعدادات إضافية',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.adminTextPrimary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الحد الأدنى للطلب',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _minimumOrderController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            suffixText: '₪',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 0) {
                                return 'يرجى إدخال مبلغ صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الحد الأقصى للخصم',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxDiscountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            suffixText: '₪',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'يرجى إدخال مبلغ صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حد الاستخدام الإجمالي',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usageLimitController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: TextStyle(
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final limit = int.tryParse(value);
                              if (limit == null || limit <= 0) {
                                return 'يرجى إدخال رقم صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حد الاستخدام لكل منتج',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxQuantityPerProductController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: TextStyle(
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final limit = int.tryParse(value);
                              if (limit == null || limit <= 0) {
                                return 'يرجى إدخال رقم صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حد الاستخدام لكل منتج',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usageLimitPerProductController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: TextStyle(
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final limit = int.tryParse(value);
                              if (limit == null || limit <= 0) {
                                return 'يرجى إدخال رقم صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الأولوية',
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priorityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            hintStyle: TextStyle(
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final priority = int.tryParse(value);
                              if (priority == null || priority < 0) {
                                return 'يرجى إدخال رقم صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ArabicText.isFeatured,
                    style: const TextStyle(
                      color: AppColors.adminTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isFeatured,
                    onChanged: (value) => setState(() => _isFeatured = value),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ArabicText.isStackable,
                    style: const TextStyle(
                      color: AppColors.adminTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isStackable,
                    onChanged: (value) => setState(() => _isStackable = value),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ArabicText.isActive,
                    style: const TextStyle(
                      color: AppColors.adminTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text(ArabicText.cancel),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePromotion,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text(ArabicText.save),
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
