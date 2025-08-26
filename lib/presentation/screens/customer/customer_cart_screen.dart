import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer/cart_item_widget.dart';
import '../../widgets/customer/coupon_section.dart';

class CustomerCartScreen extends StatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  State<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends State<CustomerCartScreen> {
  bool _isLoading = false;

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
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CustomerProvider>();
      await provider.loadCart();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل السلة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
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
          'سلة التسوق',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to wishlist
              context.push('/customer/wishlist');
            },
            icon: Icon(
              Icons.favorite,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                final cartItems = provider.cartItems;

                if (cartItems.isEmpty) {
                  return _buildEmptyCart();
                }

                return Column(
                  children: [
                    // Cart Items List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CartItemWidget(
                              cartItem: cartItem,
                              onQuantityChanged: (newQuantity) {
                                provider.updateCartItemQuantity(
                                  cartItem.id,
                                  newQuantity,
                                );
                              },
                              onRemove: () {
                                provider.removeFromCart(cartItem.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Coupon Section
                    const CouponSection(),

                    // Order Summary
                    _buildOrderSummary(provider),

                    // Checkout Button
                    _buildCheckoutButton(provider),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.primaryText.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'سلة التسوق فارغة',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بالتسوق لإضافة منتجات إلى سلة التسوق',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.go('/customer/home');
            },
            child: const Text('ابدأ التسوق'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CustomerProvider provider) {
    final cartSummary = provider.cartSummary;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي',
                style: TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
              Text(
                '${cartSummary.subtotal.toStringAsFixed(2)} ريال',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التوصيل',
                style: TextStyle(
                  color: AppColors.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
              Text(
                '${cartSummary.deliveryFee.toStringAsFixed(2)} ريال',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Divider(color: AppColors.textSecondaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${cartSummary.total.toStringAsFixed(2)} ريال',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(CustomerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            // Navigate to checkout
            context.push('/customer/checkout');
          },
          icon: Icon(
            Icons.shopping_bag,
            color: AppColors.white,
            size: 24,
          ),
          label: Text(
            'إتمام الطلب الآن',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
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
    );
  }
}
