import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
          widget.product['name'] ?? 'Product Details',
          style: const TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildPricingSection(),
            const SizedBox(height: 24),
            _buildInventorySection(),
            const SizedBox(height: 24),
            _buildAdditionalDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final featuredImage = widget.product['featured_image_url'];

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: featuredImage != null && featuredImage.isNotEmpty
            ? Image.network(
                featuredImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.inventory_2,
          size: 80,
          color: AppColors.textSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildInfoCard(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow('Name', widget.product['name'] ?? 'N/A'),
        _buildInfoRow(
            'Description', widget.product['description'] ?? 'No description'),
        _buildInfoRow('SKU', widget.product['sku'] ?? 'N/A'),
        _buildInfoRow('Category', _getCategoryName()),
      ],
    );
  }

  Widget _buildPricingSection() {
    return _buildInfoCard(
      title: 'Pricing',
      icon: Icons.attach_money,
      children: [
        _buildInfoRow(
          'Price',
          '${(double.tryParse(widget.product['price']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2)}₪',
          valueColor: AppColors.successColor,
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    final stockQuantity = widget.product['stock_quantity'] ?? 0;

    return _buildInfoCard(
      title: 'Inventory',
      icon: Icons.inventory_2,
      children: [
        _buildInfoRow(
          'Stock Quantity',
          stockQuantity.toString(),
          valueColor:
              stockQuantity > 0 ? AppColors.successColor : AppColors.errorColor,
        ),
        _buildInfoRow('Min Stock Level',
            (widget.product['min_stock_level'] ?? 0).toString()),
        _buildInfoRow('Max Stock Level',
            (widget.product['max_stock_level'] ?? 0).toString()),
        _buildInfoRow('Unit', widget.product['unit'] ?? 'piece'),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return _buildInfoCard(
      title: 'Additional Details',
      icon: Icons.settings,
      children: [
        _buildInfoRow(
            'Featured', widget.product['is_featured'] == true ? 'Yes' : 'No'),
        _buildInfoRow(
            'Active', widget.product['is_active'] == true ? 'Yes' : 'No'),
        _buildInfoRow('Created', _formatDate(widget.product['created_at'])),
        _buildInfoRow(
            'Last Updated', _formatDate(widget.product['updated_at'])),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(icon, color: AppColors.primaryText, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ?? AppColors.primaryText,
                fontWeight: FontWeight.w500,
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
