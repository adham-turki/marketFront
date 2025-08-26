import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/connection_test.dart';

class AddProductScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductAdded;

  const AddProductScreen({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  final List<File> _selectedImages = [];
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    print('AddProductScreen initState called');
    _apiService.init();
    print('API service initialized');
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final isConnected = await ConnectionTest.testBackendConnection();
      if (!isConnected) {
        _showSnackBar('فشل الاتصال بالخادم. يرجى التأكد من تشغيل الخادم.',
            isError: true);
        return;
      }

      final response = await _apiService.get('/categories');

      if (response.statusCode == 200 && response.data['success']) {
        // Fix: Backend returns 'data' not 'categories'
        final categoriesData = response.data['data'] ?? [];

        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesData);
        });
      } else {
        _showSnackBar(
            'فشل تحميل الفئات: ${response.data['message'] ?? 'خطأ غير معروف'}',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorLoadingCategories}: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar(ArabicText.pleaseSelectCategory, isError: true);
      return;
    }

    if (_selectedImages.isEmpty) {
      _showSnackBar(ArabicText.pleaseSelectAtLeastOneImage, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, upload images
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        try {
          final response = await _apiService.post('/upload', data: {
            'image': image,
          });
          if (response.statusCode == 200 && response.data['success']) {
            imageUrls.add(response.data['image_url']);
          }
        } catch (e) {
          print('Error uploading image: $e');
          // Continue with other images
        }
      }

      // Create product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'sku': _skuController.text.trim(),
        'barcode': _barcodeController.text.trim(),
        'category_id': _selectedCategory,
        'images': imageUrls,
        'is_featured': _isFeatured,
        'is_active': _isActive,
      };

      // Save product
      final response = await _apiService.post('/products', data: productData);

      if (response.statusCode == 200 && response.data['success']) {
        final newProduct = response.data['product'];
        widget.onProductAdded(newProduct);
        _showSnackBar(ArabicText.productAdded);

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showSnackBar(response.data['message'] ?? ArabicText.errorAddingProduct,
            isError: true);
      }
    } catch (e) {
      _showSnackBar('${ArabicText.errorAddingProduct}: $e', isError: true);
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

  Widget _buildEnhancedTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
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
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  Icon(icon, color: AppColors.primaryText.withOpacity(0.6)),
              hintText: label,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ArabicText.productCategory,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),

        // Debug info in development
        if (_categories.isEmpty && !_isLoadingCategories)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Debug: No categories loaded. Categories count: ${_categories.length}',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadCategories,
                  icon:
                      Icon(Icons.refresh, color: Colors.orange[800], size: 16),
                  tooltip: 'إعادة تحميل الفئات',
                ),
              ],
            ),
          ),

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
            value: _selectedCategory,
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              hintText: _isLoadingCategories
                  ? ArabicText.loading
                  : _categories.isEmpty
                      ? 'لا توجد فئات متاحة'
                      : ArabicText.selectCategory,
            ),
            items: _categories
                .map((category) => DropdownMenuItem(
                      value: category['id'].toString(),
                      child: Text(category['name'] ?? 'Unknown Category'),
                    ))
                .toList(),
            onChanged: _isLoadingCategories || _categories.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          ArabicText.productImages,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
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
          child: InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppColors.primaryText.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط لاختيار الصور',
                    style: TextStyle(
                      color: AppColors.primaryText.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          ArabicText.selectedImages,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
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
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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

  Widget _buildEnhancedSwitch(
      String label, bool value, Function(bool) onChanged) {
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
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryText,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSection(
      String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryText, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          ArabicText.addNewProduct,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryText,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 253, 248, 248),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                _buildEnhancedSection(
                  'المعلومات الأساسية',
                  Icons.info_outline,
                  [
                    _buildEnhancedTextField(
                      ArabicText.productName,
                      _nameController,
                      Icons.inventory_2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال اسم المنتج';
                        }
                        return null;
                      },
                    ),
                    _buildEnhancedTextField(
                      ArabicText.description,
                      _descriptionController,
                      Icons.description,
                      maxLines: 3,
                    ),
                    _buildEnhancedCategoryDropdown(),
                  ],
                ),

                // Product Details Section
                _buildEnhancedSection(
                  'تفاصيل المنتج',
                  Icons.details_outlined,
                  [
                    _buildEnhancedTextField(
                      ArabicText.sku,
                      _skuController,
                      Icons.qr_code,
                    ),
                    _buildEnhancedTextField(
                      ArabicText.barcode,
                      _barcodeController,
                      Icons.qr_code_2,
                    ),
                  ],
                ),

                // Pricing Section
                _buildEnhancedSection(
                  'التسعير',
                  Icons.attach_money,
                  [
                    _buildEnhancedTextField(
                      ArabicText.price,
                      _priceController,
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال السعر';
                        }
                        if (double.tryParse(value) == null) {
                          return 'يرجى إدخال سعر صحيح';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                // Inventory Section
                _buildEnhancedSection(
                  'المخزون',
                  Icons.inventory_2_outlined,
                  [
                    _buildEnhancedTextField(
                      ArabicText.productStock,
                      _stockController,
                      Icons.inventory_2,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الكمية في المخزون';
                        }
                        if (int.tryParse(value) == null) {
                          return 'يرجى إدخال كمية صحيحة';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                // Images Section
                _buildEnhancedSection(
                  'صور المنتج',
                  Icons.image_outlined,
                  [
                    _buildEnhancedImagePicker(),
                    if (_selectedImages.isNotEmpty) _buildSelectedImages(),
                  ],
                ),

                // Settings Section
                _buildEnhancedSection(
                  'الإعدادات',
                  Icons.settings_outlined,
                  [
                    _buildEnhancedSwitch(
                      ArabicText.featuredProduct,
                      _isFeatured,
                      (value) => setState(() => _isFeatured = value),
                    ),
                    _buildEnhancedSwitch(
                      ArabicText.activeProduct,
                      _isActive,
                      (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Enhanced Save Button
                Container(
                  width: double.infinity,
                  height: 56,
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
                    onPressed: _isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryText,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 24),
                              SizedBox(width: 12),
                              Text(ArabicText.save,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
