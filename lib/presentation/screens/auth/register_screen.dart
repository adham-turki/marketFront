import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/arabic_text.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;

  const RegisterScreen({
    super.key,
    required this.userType,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getUserTypeDisplayName() {
    return widget.userType == 'customer'
        ? ArabicText.customer
        : ArabicText.supermarket;
  }

  String _getUserTypeIcon() {
    return widget.userType == 'customer' ? '👤' : '🏪';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      full_name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: widget.userType,
    );

    if (success && mounted) {
      context.go('/home');
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
                        child: Text(
                          _getUserTypeIcon(),
                          style: TextStyle(
                            fontSize:
                                screenWidth * 0.15, // Responsive font size
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
                                    'إنشاء حساب ${_getUserTypeDisplayName()}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'انضم إلى ${ArabicText.appName} ك${widget.userType == 'customer' ? 'عميل' : 'سوبر ماركت'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondaryColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  CustomTextField(
                                    controller: _nameController,
                                    labelText: ArabicText.fullName,
                                    hintText: 'أدخل اسمك الكامل',
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return ArabicText.fieldRequired;
                                      }
                                      if (value.trim().length < 2) {
                                        return 'يجب أن يكون الاسم على الأقل حرفين';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    controller: _phoneController,
                                    labelText: ArabicText.phoneNumber,
                                    hintText: 'أدخل رقم هاتفك',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return ArabicText.fieldRequired;
                                      }
                                      if (value.trim().length < 10) {
                                        return ArabicText.invalidPhone;
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
                                        return ArabicText.fieldRequired;
                                      }
                                      if (value.length < 8) {
                                        return ArabicText.passwordTooShort;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    labelText: ArabicText.confirmPassword,
                                    hintText: 'أكد كلمة المرور',
                                    obscureText: !_isConfirmPasswordVisible,
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: AppColors.textSecondaryColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return ArabicText.fieldRequired;
                                      }
                                      if (value != _passwordController.text) {
                                        return ArabicText.passwordsDoNotMatch;
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
                                            : _register,
                                        isLoading: authProvider.isLoading,
                                        child: Text(
                                          ArabicText.signUp,
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
                                    onPressed: () => context.go('/login'),
                                    child: Text(
                                      '${ArabicText.alreadyHaveAccount} ${ArabicText.login}',
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
