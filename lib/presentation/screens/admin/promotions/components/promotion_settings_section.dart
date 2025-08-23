import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class PromotionSettingsSection extends StatelessWidget {
  final String promotionType;
  final Function(String?) onPromotionTypeChanged;
  final TextEditingController discountController;
  final TextEditingController minAmountController;
  final TextEditingController maxDiscountController;
  final TextEditingController buyXController;
  final TextEditingController getYController;

  const PromotionSettingsSection({
    Key? key,
    required this.promotionType,
    required this.onPromotionTypeChanged,
    required this.discountController,
    required this.minAmountController,
    required this.maxDiscountController,
    required this.buyXController,
    required this.getYController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildFormSection('Promotion Settings', [
      _buildPromotionTypeDropdown(),
      const SizedBox(height: 15),
      if (promotionType != 'free_shipping') ...[
        _buildTextField(
          'Discount Value',
          discountController,
          Icons.discount,
          keyboardType: TextInputType.number,
        ),
      ],
      _buildHelpText(),
      if (promotionType != 'free_shipping') ...[
        _buildTextField(
          'Minimum Order Amount',
          minAmountController,
          Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        _buildMinOrderHelpText(),
        _buildTextField(
          'Maximum Discount Amount',
          maxDiscountController,
          Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
      ],
      if (promotionType == 'buy_x_get_y') ...[
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Buy X Quantity',
                buyXController,
                Icons.shopping_cart,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildTextField(
                'Get Y Quantity',
                getYController,
                Icons.card_giftcard,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildPromotionTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: promotionType,
      decoration: InputDecoration(
        labelText: 'Promotion Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryText),
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: 'percentage',
          child: Text('Percentage (%)'),
        ),
        const DropdownMenuItem(
          value: 'fixed_amount',
          child: Text('Fixed Amount (₪)'),
        ),
        const DropdownMenuItem(
          value: 'free_shipping',
          child: Text('Free Shipping'),
        ),
        const DropdownMenuItem(
          value: 'buy_x_get_y',
          child: Text('Buy X Get Y'),
        ),
      ],
      onChanged: onPromotionTypeChanged,
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

  Widget _buildHelpText() {
    if (promotionType == 'percentage') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Enter percentage (e.g., 20 for 20% off)',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 15),
        ],
      );
    } else if (promotionType == 'fixed_amount') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Enter amount in ILS (e.g., 10 for 10₪ off)',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 15),
        ],
      );
    } else if (promotionType == 'buy_x_get_y') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'Buy X Get Y promotion - select products below',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 15),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMinOrderHelpText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          'Minimum order amount required to activate this promotion',
          style: TextStyle(
            color: AppColors.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}
