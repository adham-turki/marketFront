import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/arabic_text.dart';

class AdditionalSettingsSection extends StatelessWidget {
  final TextEditingController usageLimitController;
  final TextEditingController usagePerUserController;
  final TextEditingController maxQuantityPerProductController;
  final TextEditingController usageLimitPerProductController;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isFeatured;
  final bool isStackable;
  final bool requiresCoupon;
  final int priority;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<bool?> onActiveChanged;
  final ValueChanged<bool?> onFeaturedChanged;
  final ValueChanged<bool?> onStackableChanged;
  final ValueChanged<bool?> onRequiresCouponChanged;
  final ValueChanged<int?> onPriorityChanged;

  const AdditionalSettingsSection({
    Key? key,
    required this.usageLimitController,
    required this.usagePerUserController,
    required this.maxQuantityPerProductController,
    required this.usageLimitPerProductController,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isFeatured,
    required this.isStackable,
    required this.requiresCoupon,
    required this.priority,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onActiveChanged,
    required this.onFeaturedChanged,
    required this.onStackableChanged,
    required this.onRequiresCouponChanged,
    required this.onPriorityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildFormSection('الإعدادات الإضافية', [
      _buildTextField(
        ArabicText.usageLimit,
        usageLimitController,
        Icons.people,
        keyboardType: TextInputType.number,
        hint: 'إجمالي عدد مرات استخدام هذا العرض',
      ),
      _buildTextField(
        ArabicText.usageLimitPerUser,
        usagePerUserController,
        Icons.person,
        keyboardType: TextInputType.number,
        hint: 'الحد الأقصى لعدد مرات استخدام المستخدم الواحد لهذا العرض',
      ),
      _buildTextField(
        ArabicText.maxQuantityPerProduct,
        maxQuantityPerProductController,
        Icons.inventory,
        keyboardType: TextInputType.number,
        hint: 'الحد الأقصى لكمية كل منتج التي يمكن خصمها',
      ),
      _buildTextField(
        ArabicText.usageLimitPerProduct,
        usageLimitPerProductController,
        Icons.local_offer,
        keyboardType: TextInputType.number,
        hint: 'عند الوصول إلى هذا الحد، لن يكون المنتج مؤهلاً للعرض',
      ),
      _buildDateFields(context),
      _buildCheckboxes(),
      _buildPriorityField(),
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
    String? hint,
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
            hintText: hint,
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

  Widget _buildDateFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فترة العرض',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                ArabicText.startDate,
                startDate,
                onStartDateChanged,
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildDateField(
                context,
                ArabicText.endDate,
                endDate,
                onEndDateChanged,
                Icons.calendar_today,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date,
    ValueChanged<DateTime?> onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryText),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : ArabicText.selectDate,
                    style: TextStyle(
                      color: date != null
                          ? AppColors.primaryText
                          : AppColors.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckboxTile(
          ArabicText.active,
          'تفعيل هذا العرض',
          isActive,
          (value) => onActiveChanged(value),
        ),
        _buildCheckboxTile(
          ArabicText.featured,
          'إظهار هذا العرض بشكل بارز (يشرح ما يعنيه المميز)',
          isFeatured,
          (value) => onFeaturedChanged(value),
        ),
        _buildCheckboxTile(
          ArabicText.stackable,
          'يمكن دمجه مع عروض أخرى (يشرح ما يعنيه قابل للتجميع)',
          isStackable,
          (value) => onStackableChanged(value),
        ),
        _buildCheckboxTile(
          ArabicText.requiresCoupon,
          'يجب على المستخدمين إدخال رمز كوبون لتفعيل هذا العرض',
          requiresCoupon,
          (value) => onRequiresCouponChanged(value),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondaryColor,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأولوية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: priority,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryText),
            ),
          ),
          items: List.generate(10, (index) => index).map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text('$value'),
            );
          }).toList(),
          onChanged: (value) => onPriorityChanged(value),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
