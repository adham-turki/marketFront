import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/customer_provider.dart';
import '../customer/customer_home_screen.dart';
import '../../widgets/customer/product_card.dart';

class CategoryProductsScreen extends StatelessWidget {
  final int categoryId;
  const CategoryProductsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
        ),
        title: Text('عرض الكل', style: TextStyle(color: AppColors.primaryText)),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          final products = provider.getProductsByCategory(categoryId);
          if (products.isEmpty) {
            return Center(
              child: Text('لا يوجد منتجات',
                  style: TextStyle(color: AppColors.primaryText)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('/customer/product/${product.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
