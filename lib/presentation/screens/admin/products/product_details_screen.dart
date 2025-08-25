import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.product['name'] ?? ArabicText.productDetails,
          style: const TextStyle(
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
              AppColors.primaryText.withOpacity(0.05),
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedImageSection(),
              const SizedBox(height: 24),
              _buildEnhancedBasicInfoSection(),
              const SizedBox(height: 24),
              _buildEnhancedPricingSection(),
              const SizedBox(height: 24),
              _buildEnhancedInventorySection(),
              const SizedBox(height: 24),
              _buildEnhancedAdditionalDetailsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedImageSection() {
    final featuredImage = widget.product['featured_image_url'];

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: featuredImage != null && featuredImage.isNotEmpty
            ? Image.network(
                featuredImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildEnhancedPlaceholderImage();
                },
              )
            : _buildEnhancedPlaceholderImage(),
      ),
    );
  }

  Widget _buildEnhancedPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inventory_2,
                size: 80,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Image Available',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBasicInfoSection() {
    return _buildInfoCard(
      title: ArabicText.basicInformation,
      icon: Icons.info_outline,
      children: [
        _buildInfoRow(ArabicText.name, widget.product['name'] ?? 'N/A'),
        _buildInfoRow(ArabicText.description,
            widget.product['description'] ?? 'No description'),
        _buildInfoRow(ArabicText.sku, widget.product['sku'] ?? 'N/A'),
        _buildInfoRow(ArabicText.category, _getCategoryName()),
      ],
    );
  }

  Widget _buildEnhancedPricingSection() {
    return _buildInfoCard(
      title: ArabicText.pricing,
      icon: Icons.attach_money,
      children: [
        _buildInfoRow(
          ArabicText.price,
          '${(double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}₪',
          valueColor: AppColors.successColor,
        ),
      ],
    );
  }

  Widget _buildEnhancedInventorySection() {
    final stockQuantity = widget.product['stock_quantity'] ?? 0;

    return _buildInfoCard(
      title: ArabicText.inventory,
      icon: Icons.inventory_2,
      children: [
        _buildInfoRow(
          ArabicText.quantity,
          stockQuantity.toString(),
          valueColor:
              stockQuantity > 0 ? AppColors.successColor : AppColors.errorColor,
        ),
        _buildInfoRow(ArabicText.minStockLevel,
            (widget.product['min_stock_level'] ?? 0).toString()),
        _buildInfoRow(ArabicText.maxStockLevel,
            (widget.product['max_stock_level'] ?? 0).toString()),
        _buildInfoRow(ArabicText.unit, widget.product['unit'] ?? 'piece'),
      ],
    );
  }

  Widget _buildEnhancedAdditionalDetailsSection() {
    return _buildInfoCard(
      title: 'تفاصيل إضافية',
      icon: Icons.settings,
      children: [
        _buildInfoRow(ArabicText.featured,
            widget.product['is_featured'] == true ? 'نعم' : 'لا'),
        _buildInfoRow(ArabicText.active,
            widget.product['is_active'] == true ? 'نعم' : 'لا'),
        _buildInfoRow(
            ArabicText.created, _formatDate(widget.product['created_at'])),
        _buildInfoRow(
            ArabicText.lastUpdated, _formatDate(widget.product['updated_at'])),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  color: AppColors.primaryText.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryText.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryText,
                  size: 28,
                ),
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (valueColor ?? AppColors.primaryText).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (valueColor ?? AppColors.primaryText).withOpacity(0.3),
                ),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName() {
    final category = widget.product['category'];
    if (category is Map) {
      return category['name'] ?? 'Unknown';
    }
    return category?.toString() ?? 'Uncategorized';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}
