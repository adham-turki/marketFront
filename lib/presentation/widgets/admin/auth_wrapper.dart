import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdminAuthWrapper extends StatelessWidget {
  final Widget child;
  final String? redirectPath;

  const AdminAuthWrapper({
    super.key,
    required this.child,
    this.redirectPath,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is admin
        if (!authProvider.isAdmin) {
          // Redirect to home if not admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(redirectPath ?? '/home');
          });
          return const Scaffold(
            backgroundColor: AppColors.primaryBackground,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is authenticated and is admin, show the child widget
        return child;
      },
    );
  }
}
