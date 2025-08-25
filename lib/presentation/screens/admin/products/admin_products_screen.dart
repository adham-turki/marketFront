import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';
import '../../../widgets/admin/auth_wrapper.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart';
import 'add_category_screen.dart';
import 'edit_product_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/models/notification_model.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class AdminProductsScreenWithAuth extends StatelessWidget {
  const AdminProductsScreenWithAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminAuthWrapper(
      child: AdminProductsScreen(),
    );
  }
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedCategoryFilter; // Add category filter variable
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Form controllers for add/edit product
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _minStockLevelController =
      TextEditingController();
  final TextEditingController _maxStockLevelController =
      TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isFeatured = false;
  bool _isActive = true;
  final List<File> _selectedImages = [];
  List<String> _imageUrls = [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadProducts();
    _loadCategories();

    // Check for low stock products and create notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLowStockProducts();
    });
  }

  // Check for low stock products and create notifications
  Future<void> _checkLowStockProducts() async {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.checkLowStockProducts();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking low stock products: $e');
      }
    }
  }

  // Create notification when product stock is updated
  void _createStockUpdateNotification(
      Map<String, dynamic> product, int oldStock, int newStock) {
    final notificationProvider = context.read<NotificationProvider>();

    if (newStock <= (product['min_stock_level'] ?? 5)) {
      notificationProvider.createLocalNotification(
        title: 'تنبيه مخزون منخفض',
        message:
            '${product['name']} وصل إلى الحد الأدنى للمخزون (المخزون الحالي: $newStock)',
        notificationType: 'stock_alert',
        priority: newStock == 0 ? 'urgent' : 'high',
        relatedId: product['id'],
        relatedType: 'product',
        actionUrl: '/admin/products/${product['id']}',
        imageUrl: 'https://example.com/stock-icon.png',
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();

    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minStockLevelController.dispose();
    _maxStockLevelController.dispose();
    _unitController.dispose();
    _weightController.dispose();
    _tagsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.get('/products/admin/list');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response.data['data']);
          _filteredProducts = List.from(_products);
        });
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorLoadingProducts}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.get('/categories');
      if (response.statusCode == 200 && response.data['success']) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorLoadingCategories}: $e', isError: true);
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty && _selectedCategoryFilter == null) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((product) {
          // Text search filtering
          bool matchesSearch = true;
          if (query.isNotEmpty) {
            final name = product['name']?.toString().toLowerCase() ?? '';
            final category =
                product['category']?['name']?.toString().toLowerCase() ?? '';
            final searchLower = query.toLowerCase();

            matchesSearch =
                name.contains(searchLower) || category.contains(searchLower);
          }

          // Category filtering
          bool matchesCategory = true;
          if (_selectedCategoryFilter != null) {
            matchesCategory =
                product['category']?['name'] == _selectedCategoryFilter;
          }

          return matchesSearch && matchesCategory;
        }).toList();
      }
    });
  }

  void _onCategoryFilterChanged(String? newValue) {
    setState(() {
      _selectedCategoryFilter = newValue;
    });
    _filterProducts(_searchQuery);
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryFilter = null;
      _searchQuery = '';
    });
    _searchController.clear();
    _filteredProducts = List.from(_products);
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          onProductAdded: (newProduct) {
            setState(() {
              _products.insert(0, newProduct);
              _filteredProducts.insert(0, newProduct);
            });
          },
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) async {
    // Ensure categories are loaded before populating the form
    if (_categories.isEmpty) {
      await _loadCategories();
    }
    _populateForm(product);
    _showProductDialog(isEditing: true, productId: product['id']);
  }

  void _showEditProductPage(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          product: product,
          onProductUpdated: (updatedProduct) {
            setState(() {
              final index =
                  _products.indexWhere((p) => p['id'] == updatedProduct['id']);
              if (index != -1) {
                _products[index] = updatedProduct;
                _filteredProducts = List.from(_products);
              }
            });
          },
        ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedCategoryId = null;

    _skuController.clear();
    _barcodeController.clear();
    _priceController.clear();
    _stockQuantityController.clear();
    _minStockLevelController.clear();
    _maxStockLevelController.clear();
    _unitController.clear();
    _weightController.clear();
    _tagsController.clear();
    _isFeatured = false;
    _isActive = true;
    _selectedImages.clear();
    _imageUrls.clear();
  }

  void _populateForm(Map<String, dynamic> product) {
    _nameController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';

    // Safely set the category ID, ensuring it exists in the categories list
    final productCategoryId =
        product['category_id'] ?? product['category']?['id'];
    if (productCategoryId != null && _categories.isNotEmpty) {
      final categoryExists =
          _categories.any((cat) => cat['id'] == productCategoryId);
      _selectedCategoryId = categoryExists ? productCategoryId : null;
    } else {
      _selectedCategoryId = null;
    }

    _skuController.text = product['sku'] ?? '';
    _barcodeController.text = product['barcode'] ?? '';
    _priceController.text = product['price']?.toString() ?? '';
    _stockQuantityController.text = product['stock_quantity']?.toString() ?? '';
    _minStockLevelController.text =
        product['min_stock_level']?.toString() ?? '';
    _maxStockLevelController.text =
        product['max_stock_level']?.toString() ?? '';
    _unitController.text = product['unit'] ?? '';
    _weightController.text = product['weight']?.toString() ?? '';
    _tagsController.text = (product['tags'] as List?)?.join(', ') ?? '';
    _isFeatured = product['is_featured'] ?? false;
    _isActive = product['is_active'] ?? true;
    _imageUrls = List<String>.from(product['image_urls'] ?? []);
  }

  void _showProductDialog({required bool isEditing, int? productId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.width * 0.98
              : MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.width < 600
              ? MediaQuery.of(context).size.height * 0.98
              : MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced Header with primary background and white text
              Container(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 20.0 : 28.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryText,
                      AppColors.primaryText.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryText.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isEditing ? Icons.edit : Icons.add_circle_outline,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? ArabicText.editProduct
                                : ArabicText.addNewProduct,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditing
                                ? 'Update product information and settings'
                                : 'Add a new product to your inventory',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.primaryText,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content with enhanced background
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryText.withOpacity(0.02),
                        AppColors.primaryBackground,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 600 ? 20.0 : 28.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEnhancedFormSection(
                            '${ArabicText.basicInformation}', [
                          _buildEnhancedTextField(ArabicText.productName,
                              _nameController, Icons.inventory_2),
                          _buildEnhancedTextField(ArabicText.description,
                              _descriptionController, Icons.description,
                              maxLines: 3),
                          _buildEnhancedCategoryDropdown(),
                        ]),
                        _buildEnhancedFormSection(
                            '${ArabicText.productDetails}', [
                          _buildEnhancedTextField(
                              ArabicText.sku, _skuController, Icons.qr_code),
                          _buildEnhancedTextField(ArabicText.barcode,
                              _barcodeController, Icons.qr_code_2),
                          _buildEnhancedTextField(ArabicText.unit,
                              _unitController, Icons.straighten),
                          _buildEnhancedTextField('${ArabicText.weight} (كجم)',
                              _weightController, Icons.monitor_weight),
                        ]),
                        _buildEnhancedFormSection('${ArabicText.pricing}', [
                          _buildEnhancedTextField(ArabicText.price,
                              _priceController, Icons.attach_money,
                              keyboardType: TextInputType.number),
                        ]),
                        _buildEnhancedFormSection('${ArabicText.inventory}', [
                          _buildEnhancedTextField(ArabicText.productStock,
                              _stockQuantityController, Icons.inventory_2,
                              keyboardType: TextInputType.number),
                          _buildEnhancedTextField('${ArabicText.minStockLevel}',
                              _minStockLevelController, Icons.warning,
                              keyboardType: TextInputType.number),
                          _buildEnhancedTextField('${ArabicText.maxStockLevel}',
                              _maxStockLevelController, Icons.trending_up,
                              keyboardType: TextInputType.number),
                        ]),
                        _buildEnhancedFormSection('${ArabicText.images}', [
                          _buildEnhancedImagePicker(),
                          if (_imageUrls.isNotEmpty) _buildEnhancedImageUrls(),
                        ]),
                        _buildEnhancedFormSection('${ArabicText.settings}', [
                          _buildEnhancedTextField(
                              '${ArabicText.tags} (مفصولة بفواصل)',
                              _tagsController,
                              Icons.tag),
                          _buildEnhancedSwitch(
                              ArabicText.featuredProduct,
                              _isFeatured,
                              (value) => setState(() => _isFeatured = value)),
                          _buildEnhancedSwitch(
                              ArabicText.activeProduct,
                              _isActive,
                              (value) => setState(() => _isActive = value)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),

              // Enhanced Footer with better shadows
              Container(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 600 ? 20.0 : 28.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.textSecondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            ArabicText.cancel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryText.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _saveProduct(isEditing, productId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing
                                ? ArabicText.updateProduct
                                : ArabicText.addProduct,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildEnhancedFormSection(String title, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width < 600 ? 24.0 : 32.0),
      padding:
          EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 20.0 : 28.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: AppColors.primaryText,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryText.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getSectionIcon(title),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
              height: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0),
          ...children,
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case ArabicText.basicInformation:
        return Icons.info_outline;
      case ArabicText.productDetails:
        return Icons.details_outlined;
      case ArabicText.pricing:
        return Icons.attach_money;
      case ArabicText.inventory:
        return Icons.inventory_2_outlined;
      case ArabicText.images:
        return Icons.image_outlined;
      case ArabicText.settings:
        return Icons.settings_outlined;
      default:
        return Icons.category_outlined;
    }
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

  Widget _buildEnhancedTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.width < 600 ? 20.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color: AppColors.textSecondaryColor.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryText.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryText,
                    size: 22,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: value ? AppColors.primaryText : Colors.grey[100],
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (value ? AppColors.primaryText : Colors.grey[400]!)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? Colors.white : Colors.grey[600],
              size: 26,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 15,
                    color: value
                        ? AppColors.primaryText
                        : AppColors.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryText,
            activeTrackColor: AppColors.primaryText.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryText),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            ArabicText.loading,
            style: TextStyle(color: AppColors.textSecondaryColor),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<int>(
        value: _getValidCategoryValue(),
        decoration: InputDecoration(
          labelText: ArabicText.productCategory,
          prefixIcon: Icon(Icons.category, color: AppColors.primaryText),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryText),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.primaryText, width: 2),
          ),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem<int>(
            value: category['id'],
            child: Text(category['name'] ?? ArabicText.uncategorized),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategoryId = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return ArabicText.pleaseSelectCategory;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEnhancedCategoryDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              ArabicText.productCategory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<int>(
              value: _getValidCategoryValue(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
              decoration: InputDecoration(
                hintText: ArabicText.selectCategory,
                hintStyle: TextStyle(
                  color: AppColors.textSecondaryColor.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryText.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              dropdownColor: Colors.white,
              items: _categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category['id'],
                  child: Text(
                    category['name'] ?? ArabicText.unknownCategory,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get a valid category value for the dropdown
  int? _getValidCategoryValue() {
    if (_categories.isEmpty) return null;

    // If we have a selected category ID, check if it exists in the current categories list
    if (_selectedCategoryId != null) {
      final categoryExists =
          _categories.any((cat) => cat['id'] == _selectedCategoryId);
      if (categoryExists) {
        return _selectedCategoryId;
      }
    }

    // If no valid selection or categories changed, return the first category
    return _categories.first['id'];
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryBackground,
            foregroundColor: AppColors.primaryText,
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              ArabicText.productImages,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryText,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryText.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ArabicText.productImages,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ArabicText.clickToSelectImages,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryText.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library, size: 22),
                          label: Text(ArabicText.selectImage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ArabicText.selectedImages} (${_selectedImages.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          _selectedImages[index],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.red.withOpacity(0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUrls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ArabicText.currentImages,
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imageUrls.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedImageUrls() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${ArabicText.currentImages} (${_imageUrls.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrls[index],
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 36,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ArabicText.imageError,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _saveProduct(bool isEditing, int? productId) async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategoryId == null) {
      _showSnackBar(ArabicText.pleaseFillRequired, isError: true);
      return;
    }

    try {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId,
        'sku': _skuController.text,
        'barcode': _barcodeController.text,
        'price': double.parse(_priceController.text),
        'stock_quantity': int.parse(_stockQuantityController.text),
        'min_stock_level': int.parse(_minStockLevelController.text),
        'max_stock_level': int.parse(_maxStockLevelController.text),
        'unit':
            _unitController.text.isNotEmpty ? _unitController.text : 'piece',
        'weight': _weightController.text.isNotEmpty
            ? double.parse(_weightController.text)
            : null,
        'tags': _tagsController.text.isNotEmpty
            ? _tagsController.text.split(',').map((e) => e.trim()).toList()
            : [],
        'is_featured': _isFeatured,
        'is_active': _isActive,
        'image_urls': _imageUrls,
      };

      if (isEditing && productId != null) {
        await _apiService.put('/products/$productId', data: productData);
        _showSnackBar(ArabicText.productUpdated);
      } else {
        await _apiService.post('/products', data: productData);
        _showSnackBar(ArabicText.productAdded);
      }

      Navigator.pop(context);
      _loadProducts();
    } catch (e) {
      String errorMessage = ArabicText.errorSavingProduct;

      // Handle DioException for better error parsing
      if (e.toString().contains('DioException')) {
        try {
          // Extract error details from the response
          final errorString = e.toString();
          if (errorString.contains('SKU') &&
              errorString.contains('already exists')) {
            errorMessage = 'SKU already exists. Please use a different SKU.';
          } else if (errorString.contains('Barcode') &&
              errorString.contains('already exists')) {
            errorMessage =
                'Barcode already exists. Please use a different barcode.';
          } else if (errorString.contains('validation')) {
            errorMessage = 'Please check your input data and try again.';
          } else if (errorString.contains('400')) {
            errorMessage = 'Invalid data provided. Please check all fields.';
          } else if (errorString.contains('500')) {
            errorMessage = 'Server error occurred. Please try again later.';
          } else {
            errorMessage =
                'Network error. Please check your connection and try again.';
          }
        } catch (parseError) {
          errorMessage = ArabicText.errorSavingProductTryAgain;
        }
      }

      _showSnackBar(errorMessage, isError: true);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ArabicText.deleteProduct),
        content: Text(ArabicText.confirmDeleteProduct),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ArabicText.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ArabicText.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/products/$productId');
        _showSnackBar(ArabicText.productDeleted);
        _loadProducts();
      } catch (e) {
        _showSnackBar('${ArabicText.errorDeletingProduct}: $e', isError: true);
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

  // Category management methods
  void _showAddCategoryDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(
          onCategoryAdded: (newCategory) {
            setState(() {
              _categories.insert(0, newCategory);
            });
          },
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    _showCategoryDialog(isEditing: true, categoryId: category['id']);
  }

  void _showCategoryDialog({required bool isEditing, int? categoryId}) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();

    if (isEditing && categoryId != null) {
      final category = _categories.firstWhere((c) => c['id'] == categoryId);
      nameController.text = category['name'] ?? '';
      descriptionController.text = category['description'] ?? '';
      imageUrlController.text = category['image_url'] ?? '';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isEditing ? ArabicText.editCategory : ArabicText.addNewCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: ArabicText.categoryName,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: ArabicText.description,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: ArabicText.imageUrl,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ArabicText.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                _showSnackBar(ArabicText.categoryNameRequired, isError: true);
                return;
              }

              try {
                final categoryData = {
                  'name': nameController.text,
                  'description': descriptionController.text,
                  'image_url': imageUrlController.text.isNotEmpty
                      ? imageUrlController.text
                      : null,
                };

                if (isEditing && categoryId != null) {
                  await _apiService.put('/categories/$categoryId',
                      data: categoryData);
                  _showSnackBar(ArabicText.categoryUpdated);
                } else {
                  await _apiService.post('/categories', data: categoryData);
                  _showSnackBar(ArabicText.categoryAdded);
                }

                Navigator.pop(context);
                _loadCategories();
              } catch (e) {
                _showSnackBar('${ArabicText.errorSavingCategory}: $e',
                    isError: true);
              }
            },
            child: Text(isEditing ? ArabicText.update : ArabicText.add),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(int categoryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ArabicText.deleteCategory),
        content: Text(ArabicText.confirmDeleteCategory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ArabicText.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ArabicText.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.delete('/categories/$categoryId');
        _showSnackBar(ArabicText.categoryDeleted);
        _loadCategories();
      } catch (e) {
        _showSnackBar('${ArabicText.errorDeletingCategory}: $e', isError: true);
      }
    }
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Enhanced Category Image with better shadows
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: category['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        category['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            size: 40,
                            color: AppColors.textSecondaryColor,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.category,
                      size: 40,
                      color: AppColors.textSecondaryColor,
                    ),
            ),

            const SizedBox(width: 16),

            // Category Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'] ?? ArabicText.uncategorized,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (category['description'] != null &&
                      category['description'].isNotEmpty)
                    Text(
                      category['description'],
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Enhanced Actions with smaller buttons
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryText.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _showEditCategoryDialog(category),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    tooltip: ArabicText.edit,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _deleteCategory(category['id']),
                    icon:
                        const Icon(Icons.delete, color: Colors.white, size: 18),
                    tooltip: ArabicText.delete,
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              backgroundColor: AppColors.primaryText,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            )
          : FloatingActionButton(
              onPressed: _showAddCategoryDialog,
              backgroundColor: AppColors.primaryText,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
      body: Column(
        children: [
          // Enhanced Tabs with better shadows
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryText,
              unselectedLabelColor: AppColors.textSecondaryColor,
              indicatorColor: AppColors.primaryText,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.inventory_2, size: 24),
                  text: ArabicText.products,
                ),
                Tab(
                  icon: Icon(Icons.category_outlined, size: 24),
                  text: ArabicText.categories,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Products Tab
                Column(
                  children: [
                    // Enhanced Search and Filters with better shadows
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _filterProducts,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    '${ArabicText.search} ${ArabicText.products}',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondaryColor,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterProducts('');
                              },
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Enhanced Category Filter Dropdown with white text
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            decoration: BoxDecoration(
                              color: AppColors.primaryText,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryText,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryText.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCategoryFilter,
                              dropdownColor: AppColors.primaryText,
                              hint: Text(
                                ArabicText.all,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              underline: Container(),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.white,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    ArabicText.all,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ..._categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category['name'],
                                    child: Text(
                                      category['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: _onCategoryFilterChanged,
                            ),
                          ),
                          // Clear Filters Button
                          if (_selectedCategoryFilter != null)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                onPressed: _clearAllFilters,
                                icon: Icon(
                                  Icons.clear_all,
                                  color: AppColors.textSecondaryColor,
                                ),
                                tooltip: ArabicText.clearAllFilters,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Products List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 64,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? ArabicText.noProductsYet
                                            : ArabicText.noProductsFound,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: AppColors.textSecondaryColor,
                                        ),
                                      ),
                                      if (_searchQuery.isEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '${ArabicText.addYourFirst} ${ArabicText.products} ${ArabicText.toGetStarted}',
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
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = _filteredProducts[index];
                                    return _buildProductCard(product);
                                  },
                                ),
                    ),
                  ],
                ),

                // Categories Tab
                Column(
                  children: [
                    // Categories List
                    Expanded(
                      child: _categories.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 64,
                                    color: AppColors.textSecondaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    ArabicText.noCategoriesYet,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${ArabicText.addYourFirst} ${ArabicText.categories} ${ArabicText.toGetStarted}',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return _buildCategoryCard(category);
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Enhanced Product Image with better shadows
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: product['featured_image_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          product['featured_image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.inventory_2,
                              size: 32,
                              color: AppColors.textSecondaryColor,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: AppColors.textSecondaryColor,
                      ),
              ),

              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['name'] ?? ArabicText.productWithoutName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product['is_featured'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              ArabicText.featuredProduct,
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (product['is_active'] == false)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              ArabicText.inactiveProduct,
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ArabicText.productCategory}: ${product['category']?['name'] ?? ArabicText.uncategorized}',
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryText.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${ArabicText.price}: ${(double.tryParse(product['price']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}₪',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product['stock_quantity'] > 0
                                ? AppColors.successColor.withOpacity(0.1)
                                : AppColors.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: product['stock_quantity'] > 0
                                  ? AppColors.successColor.withOpacity(0.3)
                                  : AppColors.errorColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${ArabicText.productStock}: ${product['stock_quantity'] ?? 0}',
                            style: TextStyle(
                              color: product['stock_quantity'] > 0
                                  ? AppColors.successColor
                                  : AppColors.errorColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Enhanced Actions with smaller buttons
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryText,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryText.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _showEditProductPage(product),
                      icon:
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                      tooltip: ArabicText.edit,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => _deleteProduct(product['id']),
                      icon: const Icon(Icons.delete,
                          color: Colors.white, size: 16),
                      tooltip: ArabicText.delete,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
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
