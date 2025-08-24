import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/arabic_text.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController codeController;
  final bool requiresCoupon;
  final Function(bool?) onRequiresCouponChanged;

  const BasicInfoSection({
    Key? key,
    required this.nameController,
    required this.descriptionController,
    required this.codeController,
    required this.requiresCoupon,
    required this.onRequiresCouponChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildFormSection(ArabicText.basicInformation, [
      _buildTextField(
        ArabicText.name,
        nameController,
        Icons.label,
      ),
      _buildTextField(
        ArabicText.description,
        descriptionController,
        Icons.description,
        maxLines: 3,
      ),
      _buildTextField(
        '${ArabicText.couponCode} (اختياري)',
        codeController,
        Icons.confirmation_number,
      ),
      _buildSwitch(
        ArabicText.requiresCoupon,
        requiresCoupon,
        onRequiresCouponChanged,
      ),
    ]);
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 15),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryText),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildSwitch(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }
}
