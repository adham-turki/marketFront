import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class ProductSelectionSection extends StatelessWidget {
  final String scopeType;
  final List<Map<String, dynamic>> availableProducts;
  final List<int> selectedProductIds;
  final List<Map<String, dynamic>> selectedCategories;
  final List<Map<String, dynamic>> availableCategories;
  final Function(int) onProductSelected;
  final Function(int) onProductDeselected;
  final Function(Map<String, dynamic>) onCategorySelected;
  final Function(Map<String, dynamic>) onCategoryDeselected;
  final VoidCallback onShowProductDialog;
  final VoidCallback onShowCategoryDialog;

  const ProductSelectionSection({
    Key? key,
    required this.scopeType,
    required this.availableProducts,
    required this.selectedProductIds,
    required this.selectedCategories,
    required this.availableCategories,
    required this.onProductSelected,
    required this.onProductDeselected,
    required this.onCategorySelected,
    required this.onCategoryDeselected,
    required this.onShowProductDialog,
    required this.onShowCategoryDialog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildFormSection('Product Selection', [
      _buildScopeDropdown(),
      const SizedBox(height: 15),
      _buildProductSelectionWidget(),
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

  Widget _buildScopeDropdown() {
    return DropdownButtonFormField<String>(
      value: scopeType,
      decoration: InputDecoration(
        labelText: 'Scope',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryText),
        ),
      ),
      items: [
        const DropdownMenuItem(
          value: 'all_products',
          child: Text('All Products'),
        ),
        const DropdownMenuItem(
          value: 'specific_products',
          child: Text('Specific Products'),
        ),
        const DropdownMenuItem(
          value: 'category',
          child: Text('Category'),
        ),
      ],
      onChanged: (value) {
        // This will be handled by the parent widget
      },
    );
  }

  Widget _buildProductSelectionWidget() {
    if (scopeType == 'specific_products') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomDropdown(
            label: 'Select Products',
            hint: 'Tap to select products',
            selectedCount: selectedProductIds.length,
            onTap: onShowProductDialog,
          ),
          const SizedBox(height: 8),
          if (selectedProductIds.isNotEmpty) ...[
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryText),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: selectedProductIds.length,
                itemBuilder: (context, index) {
                  final productId = selectedProductIds[index];
                  final product = availableProducts.firstWhere(
                    (p) => p['id'] == productId,
                    orElse: () => {'name': 'Unknown Product', 'price': 0},
                  );
                  return ListTile(
                    title: Text(product['name'] ?? 'Unknown Product'),
                    subtitle: Text('${product['price']?.toString() ?? '0'}₪'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => onProductDeselected(productId),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    } else if (scopeType == 'category') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomDropdown(
            label: 'Select Categories',
            hint: 'Tap to select categories',
            selectedCount: selectedCategories.length,
            onTap: onShowCategoryDialog,
          ),
          const SizedBox(height: 8),
          if (selectedCategories.isNotEmpty) ...[
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryText),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = selectedCategories[index];
                  return ListTile(
                    title: Text(category['name'] ?? 'Unknown Category'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => onCategoryDeselected(category),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    } else {
      return Text(
        'This promotion applies to all products',
        style: TextStyle(
          color: AppColors.textSecondaryColor,
          fontSize: 14,
        ),
      );
    }
  }

  Widget _buildCustomDropdown({
    required String label,
    required String hint,
    required int selectedCount,
    required VoidCallback onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryText),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCount == 0 ? hint : '$selectedCount selected',
                    style: TextStyle(
                      color: selectedCount == 0
                          ? AppColors.textSecondaryColor
                          : AppColors.primaryText,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.primaryText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
