import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/arabic_text.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Check user role and route accordingly
      if (authProvider.isAdmin) {
        // Route admin/owner users directly to admin panel (products page)
        context.go('/admin/panel');
      } else {
        // Route regular users to home
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight = screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
    final gradientHeight = safeAreaHeight * 0.33;

    return Scaffold(
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Stack(
          children: [
            // Top curved shape (1/3 of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: gradientHeight + MediaQuery.of(context).padding.top,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.secondaryBackground,
                ),
              ),
            ),
            // Bottom white background (2/3 of screen)
            Positioned(
              top: gradientHeight + MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.white,
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Icon section - positioned in the curved area
                    SizedBox(
                      height:
                          gradientHeight * 0.7, // 70% of curved area for icon
                      child: Center(
                        child: Container(
                          width: screenWidth * 0.2, // 20% of screen width
                          height: screenWidth * 0.2, // 20% of screen width
                          decoration: BoxDecoration(
                            color: AppColors.primaryText,
                            borderRadius: BorderRadius.circular(
                                screenWidth * 0.05), // 5% of screen width
                          ),
                          child: Icon(
                            Icons.login,
                            size: screenWidth * 0.1, // 10% of screen width
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Form section - overlaps curved and white areas
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(0, -gradientHeight * 0.15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'مرحباً بعودتك!',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'سجل دخولك إلى حساب تريد سوبر',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _phoneController,
                                    labelText: ArabicText.phoneNumber,
                                    hintText: 'أدخل رقم هاتفك',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'يرجى إدخال رقم هاتفك';
                                      }
                                      if (value.trim().length < 10) {
                                        return 'يرجى إدخال رقم هاتف صحيح';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: ArabicText.password,
                                    hintText: 'أدخل كلمة المرور',
                                    obscureText: !_isPasswordVisible,
                                    prefixIcon: Icons.lock,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'يرجى إدخال كلمة المرور';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return CustomButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : _login,
                                        isLoading: authProvider.isLoading,
                                        child: Text(
                                          ArabicText.login,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Error Message
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      if (authProvider
                                          .errorMessage.isNotEmpty) {
                                        return Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.errorColor
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            authProvider.errorMessage,
                                            style: TextStyle(
                                              color: AppColors.errorColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => context.go('/'),
                                    child: Text(
                                      'ليس لديك حساب؟ سجل الآن',
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
