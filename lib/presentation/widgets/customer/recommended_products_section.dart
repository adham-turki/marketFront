import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/customer_provider.dart';
import 'product_card.dart';

class RecommendedProductsSection extends StatelessWidget {
  const RecommendedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final recommendedProducts = provider.recommendedProducts;

        if (recommendedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'منتجات مقترحة',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to all products page
                      context.push('/customer/products');
                    },
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Products Row
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = recommendedProducts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        context.push('/customer/product/${product.id}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
