import 'package:flutter/foundation.dart';
import '../../../core/network/api_service.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? unit;
  final String? imageUrl;
  final int categoryId;
  final String categoryName;
  final bool isActive;
  final bool isFeatured;
  final double? discountPercentage;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.unit,
    this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.isFeatured,
    this.discountPercentage,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stockQuantity:
          int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString(),
      imageUrl: json['image_url']?.toString(),
      categoryId: int.tryParse(json['category_id']?.toString() ?? '') ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
      discountPercentage: json['discount_percentage'] != null
          ? double.parse(json['discount_percentage'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final String? unit;
  final String? notes;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.unit,
    this.notes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      unit: json['unit'],
      notes: json['notes'],
    );
  }
}

class CartSummary {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int itemCount;

  CartSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      subtotal: double.parse(json['subtotal'].toString()),
      deliveryFee: double.parse(json['delivery_fee']?.toString() ?? '0'),
      total: double.parse(json['total'].toString()),
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class Promotion {
  final int id;
  final String name;
  final String? description;
  final String promotionType;
  final double? discountValue;
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isFeatured;

  Promotion({
    required this.id,
    required this.name,
    this.description,
    required this.promotionType,
    this.discountValue,
    this.imageUrl,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.isFeatured,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      promotionType: json['promotion_type'],
      discountValue: json['discount_value'] != null
          ? double.parse(json['discount_value'].toString())
          : null,
      imageUrl: json['image_url'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      isFeatured: json['is_featured'] ?? false,
    );
  }
}

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<Category> _categories = [];
  List<CartItem> _cartItems = [];
  List<Promotion> _promotions = [];
  Product? _currentProduct;
  List<Product> _recommendedProducts = [];
  CartSummary? _cartSummary;

  // Getters
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<CartItem> get cartItems => _cartItems;
  List<Promotion> get promotions => _promotions;
  Product? get currentProduct => _currentProduct;
  List<Product> get recommendedProducts => _recommendedProducts;
  CartSummary get cartSummary =>
      _cartSummary ??
      CartSummary(
        subtotal: 0,
        deliveryFee: 0,
        total: 0,
        itemCount: 0,
      );

  // Load categories
  Future<void> loadCategories() async {
    try {
      final response = await _apiService.get('/categories');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _categories = data.map((json) => Category.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading categories: $e');
      }
      rethrow;
    }
  }

  // Load products
  Future<void> loadProducts() async {
    try {
      final response = await _apiService.get('/products');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _products = data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading products: $e');
      }
      rethrow;
    }
  }

  // Load promotions
  Future<void> loadPromotions() async {
    try {
      final response = await _apiService.get('/promotions/featured');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _promotions = data.map((json) => Promotion.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading promotions: $e');
      }
      rethrow;
    }
  }

  // Load cart
  Future<void> loadCart() async {
    try {
      final response = await _apiService.get('/cart');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        final items = (data?['items'] as List?) ?? [];
        _cartItems = items.map((json) => CartItem.fromJson(json)).toList();
        final summary = data?['summary'] as Map<String, dynamic>?;
        _cartSummary = summary != null
            ? CartSummary.fromJson(summary)
            : CartSummary(subtotal: 0, deliveryFee: 0, total: 0, itemCount: 0);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
      rethrow;
    }
  }

  // Load product details
  Future<void> loadProductDetails(int productId) async {
    try {
      final response = await _apiService.get('/products/$productId');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        _currentProduct = Product.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading product details: $e');
      }
      rethrow;
    }
  }

  // Load recommended products
  Future<void> loadRecommendedProducts(int productId) async {
    try {
      final response = await _apiService.get('/products', queryParameters: {
        'limit': 10,
        'exclude_id': productId,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _recommendedProducts =
            data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recommended products: $e');
      }
      rethrow;
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    try {
      final response =
          await _apiService.get('/products/search', queryParameters: {
        'search': query,
        'limit': 50,
      });
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        _products = data.map((json) => Product.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching products: $e');
      }
      rethrow;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(int categoryId) {
    return _products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }

  // Add to cart
  Future<void> addToCart(int productId, int quantity, {String? notes}) async {
    try {
      final Map<String, dynamic> payload = {
        'product_id': productId,
        'quantity': quantity,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      final response = await _apiService.post('/cart/add', data: payload);

      if (response.statusCode == 200) {
        await loadCart(); // Reload cart to get updated data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to cart: $e');
      }
      rethrow;
    }
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(int itemId, int quantity) async {
    try {
      final response = await _apiService.post('/cart/item/$itemId', data: {
        'quantity': quantity,
      });

      if (response.statusCode == 200) {
        await loadCart(); // Reload cart to get updated data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating cart item: $e');
      }
      rethrow;
    }
  }

  // Remove from cart
  Future<void> removeFromCart(int itemId) async {
    try {
      final response = await _apiService.delete('/cart/item/$itemId');

      if (response.statusCode == 200) {
        await loadCart(); // Reload cart to get updated data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing from cart: $e');
      }
      rethrow;
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      final response = await _apiService.delete('/cart/clear');

      if (response.statusCode == 200) {
        await loadCart(); // Reload cart to get updated data
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cart: $e');
      }
      rethrow;
    }
  }
}
