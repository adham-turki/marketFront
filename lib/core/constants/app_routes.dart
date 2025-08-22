import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/shared/landing_screen.dart';
import '../../presentation/screens/shared/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/shared/home_screen.dart';
import '../../presentation/screens/admin/admin_main_screen.dart';
import '../../presentation/widgets/admin/auth_wrapper.dart';

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
    ],
  );
}
