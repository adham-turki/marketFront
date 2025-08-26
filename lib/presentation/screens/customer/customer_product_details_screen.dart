import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer/product_image_widget.dart';
import '../../widgets/customer/recommended_products_section.dart';

class CustomerProductDetailsScreen extends StatefulWidget {
  final String productId;

  const CustomerProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<CustomerProductDetailsScreen> createState() =>
      _CustomerProductDetailsScreenState();
}

class _CustomerProductDetailsScreenState
    extends State<CustomerProductDetailsScreen> {
  bool _isLoading = false;
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Auth guard: redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) {
        context.go('/login');
        return;
      }
      _loadProductDetails();
    });
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CustomerProvider>();
      await provider.loadProductDetails(int.parse(widget.productId));
      await provider.loadRecommendedProducts(int.parse(widget.productId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل تفاصيل المنتج: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToCart() {
    final provider = context.read<CustomerProvider>();
    provider.addToCart(
      int.parse(widget.productId),
      _quantity,
    );

    // No snackbar per request
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // TODO: Implement favorite functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                final product = provider.currentProduct;
                if (product == null) {
                  return const Center(child: Text('المنتج غير موجود'));
                }

                return CustomScrollView(
                  slivers: [
                    // Custom App Bar with Product Image
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppColors.white,
                      elevation: 0,
                      leading: IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryText,
                        ),
                      ),
                      title: Text(
                        'تفاصيل المنتج',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? Colors.red
                                : AppColors.primaryText,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Share product
                          },
                          icon: Icon(
                            Icons.share,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: ProductImageWidget(
                          imageUrl: product.imageUrl ?? '',
                          productName: product.name,
                        ),
                      ),
                    ),

                    // Product Information
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name and Rating
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: TextStyle(
                                      color: AppColors.primaryText,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox.shrink(),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Price
                            Text(
                              '${product.price.toStringAsFixed(2)} ريال / ${product.unit ?? 'قطعة'}',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quantity Selector
                            Row(
                              children: [
                                Text(
                                  'الكمية:',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primaryText
                                          .withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.remove,
                                          color: AppColors.primaryText,
                                          size: 20,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_quantity',
                                          style: TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (_quantity <
                                              (product.stockQuantity ?? 99)) {
                                            setState(() => _quantity++);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: AppColors.primaryText,
                                          size: 20,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Text(
                              'الوصف',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description ?? 'لا يوجد وصف متاح',
                              style: TextStyle(
                                color: AppColors.textSecondaryColor,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Recommended Products
                            const RecommendedProductsSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final product = provider.currentProduct;
        if (product == null) return const SizedBox.shrink();

        final totalPrice = product.price * _quantity;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Price and Discount Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'السعر الإجمالي ${totalPrice.toStringAsFixed(2)} ريال',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.discountPercentage != null &&
                        product.discountPercentage! > 0)
                      Text(
                        'خصم ${product.discountPercentage}%',
                        style: TextStyle(
                          color: AppColors.successColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              // Add to Cart Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _addToCart,
                  icon: Icon(
                    Icons.shopping_bag,
                    color: AppColors.white,
                    size: 24,
                  ),
                  label: Text(
                    'إضافة إلى السلة',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
