import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onProductUpdated;

  const EditProductScreen({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateForm();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _minStockLevelController.dispose();
    _maxStockLevelController.dispose();
    _unitController.dispose();
    _weightController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _populateForm() {
    _nameController.text = widget.product['name'] ?? '';
    _descriptionController.text = widget.product['description'] ?? '';
    _skuController.text = widget.product['sku'] ?? '';
    _barcodeController.text = widget.product['barcode'] ?? '';
    _priceController.text = widget.product['price']?.toString() ?? '';
    _stockQuantityController.text =
        widget.product['stock_quantity']?.toString() ?? '';
    _minStockLevelController.text =
        widget.product['min_stock_level']?.toString() ?? '';
    _maxStockLevelController.text =
        widget.product['max_stock_level']?.toString() ?? '';
    _unitController.text = widget.product['unit'] ?? '';
    _weightController.text = widget.product['weight']?.toString() ?? '';
    _tagsController.text = (widget.product['tags'] as List?)?.join(', ') ?? '';
    _isFeatured = widget.product['is_featured'] ?? false;
    _isActive = widget.product['is_active'] ?? true;
    _imageUrls = List<String>.from(widget.product['image_urls'] ?? []);
    _selectedCategoryId =
        widget.product['category_id'] ?? widget.product['category']?['id'];
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

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategoryId == null) {
      _showSnackBar(ArabicText.pleaseFillRequired, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

      await _apiService.put('/products/${widget.product['id']}',
          data: productData);

      // Update the product data and notify parent
      final updatedProduct = Map<String, dynamic>.from(widget.product);
      updatedProduct.addAll(productData);
      widget.onProductUpdated(updatedProduct);

      _showSnackBar(ArabicText.productUpdated);
      Navigator.pop(context);
    } catch (e) {
      String errorMessage = ArabicText.errorSavingProduct;
      if (e.toString().contains('DioException')) {
        try {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text(
          ArabicText.editProduct,
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedSection(
                ArabicText.basicInformation,
                Icons.info_outline,
                [
                  _buildTextField(ArabicText.productName, _nameController,
                      Icons.inventory_2),
                  _buildTextField(ArabicText.description,
                      _descriptionController, Icons.description,
                      maxLines: 3),
                  _buildCategoryDropdown(),
                ],
              ),
              _buildEnhancedSection(
                ArabicText.productDetails,
                Icons.details_outlined,
                [
                  _buildTextField(
                      ArabicText.sku, _skuController, Icons.qr_code),
                  _buildTextField(
                      ArabicText.barcode, _barcodeController, Icons.qr_code_2),
                  _buildTextField(
                      ArabicText.unit, _unitController, Icons.straighten),
                  _buildTextField('${ArabicText.weight} (كجم)',
                      _weightController, Icons.monitor_weight),
                ],
              ),
              _buildEnhancedSection(
                ArabicText.pricing,
                Icons.attach_money,
                [
                  _buildTextField(
                      ArabicText.price, _priceController, Icons.attach_money,
                      keyboardType: TextInputType.number),
                ],
              ),
              _buildEnhancedSection(
                ArabicText.inventory,
                Icons.inventory_2_outlined,
                [
                  _buildTextField(ArabicText.productStock,
                      _stockQuantityController, Icons.inventory_2,
                      keyboardType: TextInputType.number),
                  _buildTextField(ArabicText.minStockLevel,
                      _minStockLevelController, Icons.warning,
                      keyboardType: TextInputType.number),
                  _buildTextField(ArabicText.maxStockLevel,
                      _maxStockLevelController, Icons.trending_up,
                      keyboardType: TextInputType.number),
                ],
              ),
              _buildEnhancedSection(
                ArabicText.images,
                Icons.image_outlined,
                [
                  _buildImagePicker(),
                  if (_imageUrls.isNotEmpty) _buildImageUrls(),
                ],
              ),
              _buildEnhancedSection(
                ArabicText.settings,
                Icons.settings_outlined,
                [
                  _buildTextField('${ArabicText.tags} (مفصولة بفواصل)',
                      _tagsController, Icons.tag),
                  _buildSwitch(ArabicText.featuredProduct, _isFeatured,
                      (value) => setState(() => _isFeatured = value)),
                  _buildSwitch(ArabicText.activeProduct, _isActive,
                      (value) => setState(() => _isActive = value)),
                ],
              ),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
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
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              label,
              style: const TextStyle(
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
                  child: Icon(icon, color: AppColors.primaryText, size: 22),
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

  Widget _buildCategoryDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
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
              value: _selectedCategoryId,
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
                  child: const Icon(Icons.category_outlined,
                      color: Colors.white, size: 22),
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

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
            padding: const EdgeInsets.all(12),
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
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryText,
            activeTrackColor: AppColors.primaryText.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        ArabicText.productImages,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        ArabicText.clickToSelectImages,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryText.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library, size: 20),
                          label: const Text(ArabicText.selectImage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ArabicText.selectedImages} (${_selectedImages.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImages[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.red.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${ArabicText.currentImages} (${_imageUrls.length})',
              style: const TextStyle(
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
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 16),
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
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
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
                                          size: 32,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          ArabicText.imageError,
                                          style: TextStyle(
                                            fontSize: 12,
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
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageUrls.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 6,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                ArabicText.updateProduct,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
