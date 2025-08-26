import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import '../../../core/network/api_service.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customer/category_filter_button.dart';
import '../../widgets/customer/product_card.dart';
import '../../widgets/customer/promotion_slider.dart';
import '../../widgets/customer/search_bar_widget.dart';
import '../../widgets/customer/cart_fab.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // Auth guard: redirect to login if not authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!auth.isAuthenticated) {
        context.go('/login');
        return;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CustomerProvider>();
      await provider.loadCategories();
      await provider.loadProducts();
      await provider.loadPromotions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearch(String query) {
    // Handle search functionality
    context.read<CustomerProvider>().searchProducts(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Header + Promotional Slider with continuous gradient background
          _buildHeaderWithSlider(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBarWidget(
              controller: _searchController,
              onSearch: _onSearch,
            ),
          ),

          // Category Filters
          _buildCategoryFilters(),

          // Products Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildProductsContent(),
          ),
        ],
      ),
      floatingActionButton: const CartFAB(),
    );
  }

  // Row-only header to be embedded at the top of the discount section
  Widget _buildHeaderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.white,
            child: Icon(
              Icons.person,
              color: AppColors.primaryText,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),

          // Greeting Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صباح الخير، مرحباً بك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ماذا تريد أن تشتري اليوم؟',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Action Icons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.push('/customer/cart');
                },
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  context.go('/login');
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New: Wrap header and promotions inside one gradient block so primary fades to white
  Widget _buildHeaderWithSlider() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryText,
            AppColors.primaryText.withOpacity(0.75),
            AppColors.white,
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          _buildHeaderRow(),
          const PromotionSlider(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        // Only categories that have products
        final categories = provider.categories
            .where((c) => provider.getProductsByCategory(c.id).isNotEmpty)
            .toList();

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 for "All" button
            itemBuilder: (context, index) {
              if (index == 0) {
                return CategoryFilterButton(
                  category: 'all',
                  name: 'الكل',
                  icon: Icons.all_inclusive,
                  isSelected: _selectedCategory == 'all',
                  onTap: () => _onCategorySelected('all'),
                );
              }

              final category = categories[index - 1];
              return CategoryFilterButton(
                category: category.id.toString(),
                name: category.name,
                icon: Icons.category,
                isSelected: _selectedCategory == category.id.toString(),
                onTap: () => _onCategorySelected(category.id.toString()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductsContent() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        if (_selectedCategory == 'all') {
          return _buildAllCategoriesView(provider);
        } else {
          return _buildSingleCategoryView(provider);
        }
      },
    );
  }

  Widget _buildAllCategoriesView(CustomerProvider provider) {
    final categories = provider.categories
        .where((c) => provider.getProductsByCategory(c.id).isNotEmpty)
        .toList();
    // Always show 'Fruits' first if exists; otherwise keep original order.
    final fruitsIndex = categories.indexWhere((c) =>
        c.name.trim() == 'الفواكه' || c.name.toLowerCase().contains('fruit'));
    if (fruitsIndex > 0) {
      final fruits = categories.removeAt(fruitsIndex);
      categories.insert(0, fruits);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryProducts = provider.getProductsByCategory(category.id);

        if (categoryProducts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header with View All Button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/customer/category/${category.id}');
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
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryProducts.length,
                itemBuilder: (context, productIndex) {
                  final product = categoryProducts[productIndex];
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

  Widget _buildSingleCategoryView(CustomerProvider provider) {
    final selectedCategoryId = int.tryParse(_selectedCategory);
    if (selectedCategoryId == null) return const SizedBox.shrink();

    final categoryProducts = provider.getProductsByCategory(selectedCategoryId);
    final category = provider.categories.firstWhere(
      (cat) => cat.id == selectedCategoryId,
      orElse: () => throw Exception('Category not found'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _onCategorySelected('all'),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                category.name,
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categoryProducts.length,
            itemBuilder: (context, index) {
              final product = categoryProducts[index];
              return ProductCard(
                product: product,
                onTap: () {
                  context.push('/customer/product/${product.id}');
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
