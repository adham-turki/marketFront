import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProductImageWidget extends StatelessWidget {
  final String imageUrl;
  final String productName;

  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackImage();
              },
            )
          : _buildFallbackImage(),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryText.withOpacity(0.1),
            AppColors.lightBackground,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: AppColors.primaryText.withOpacity(0.5),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            productName,
            style: TextStyle(
              color: AppColors.primaryText.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد صورة متاحة',
            style: TextStyle(
              color: AppColors.textSecondaryColor.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
