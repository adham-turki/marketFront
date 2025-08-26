import 'package:go_router/go_router.dart';
import '../../presentation/screens/shared/landing_screen.dart';
import '../../presentation/screens/shared/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/shared/home_screen.dart';
import '../../presentation/screens/admin/admin_main_screen.dart';
import '../../presentation/widgets/admin/auth_wrapper.dart';
import '../../presentation/screens/customer/customer_home_screen.dart';
import '../../presentation/screens/customer/customer_cart_screen.dart';
import '../../presentation/screens/customer/customer_product_details_screen.dart';
import '../../presentation/screens/customer/category_products_screen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/customer',
        builder: (context, state) => const RegisterScreen(userType: 'customer'),
      ),
      GoRoute(
        path: '/register/supermarket',
        builder: (context, state) =>
            const RegisterScreen(userType: 'supermarket'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Admin routes
      GoRoute(
        path: '/admin/panel',
        builder: (context, state) => const AdminAuthWrapper(
          child: AdminMainScreen(),
        ),
      ),

      // Customer routes
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/customer/cart',
        builder: (context, state) => const CustomerCartScreen(),
      ),
      GoRoute(
        path: '/customer/product/:id',
        builder: (context, state) => CustomerProductDetailsScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/customer/category/:id',
        builder: (context, state) => CategoryProductsScreen(
          categoryId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
}
