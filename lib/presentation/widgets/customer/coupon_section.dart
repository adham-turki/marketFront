import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CouponSection extends StatelessWidget {
  const CouponSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Coupon Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_offer,
              color: AppColors.successColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Coupon Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لديك 3 كوبونات',
                  style: TextStyle(
                    color: AppColors.successColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'يمكنك تطبيقها على طلبك',
                  style: TextStyle(
                    color: AppColors.successColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              _showCouponDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'تطبيق',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCouponDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'الكوبونات المتاحة',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCouponItem(
              context,
              code: 'WELCOME20',
              discount: 'خصم 20%',
              description: 'خصم على أول طلب',
              isActive: true,
            ),
            _buildCouponItem(
              context,
              code: 'FREESHIP',
              discount: 'توصيل مجاني',
              description: 'للطلبات أكثر من 100 ريال',
              isActive: true,
            ),
            _buildCouponItem(
              context,
              code: 'SAVE50',
              discount: 'خصم 50 ريال',
              description: 'للطلبات أكثر من 200 ريال',
              isActive: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إغلاق',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponItem(
    BuildContext context, {
    required String code,
    required String discount,
    required String description,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.successColor.withOpacity(0.1)
            : AppColors.textSecondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.successColor.withOpacity(0.3)
              : AppColors.textSecondaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Coupon Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        color: isActive
                            ? AppColors.successColor
                            : AppColors.textSecondaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.successColor
                            : AppColors.textSecondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.successColor.withOpacity(0.8)
                        : AppColors.textSecondaryColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Apply Button
          if (isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyCoupon(context, code);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'تطبيق',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _applyCoupon(BuildContext context, String code) {
    // TODO: Implement coupon application logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تطبيق الكوبون $code بنجاح'),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
