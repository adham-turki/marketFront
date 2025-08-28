import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              Icons.search,
              color: AppColors.textSecondaryColor,
              size: 24,
            ),
          ),

          // Search Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.customerTextPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن الخضروات والفواكه والمزيد...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondaryColor.withOpacity(0.7),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _isSearching = true;
                  });
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (widget.controller.text == value) {
                      widget.onSearch(value);
                    }
                  });
                } else {
                  setState(() {
                    _isSearching = false;
                  });
                  widget.onSearch('');
                }
              },
              onSubmitted: (value) {
                widget.onSearch(value);
              },
            ),
          ),

          // Clear Button (when searching)
          if (_isSearching)
            IconButton(
              onPressed: () {
                widget.controller.clear();
                setState(() {
                  _isSearching = false;
                });
                widget.onSearch('');
              },
              icon: Icon(
                Icons.clear,
                color: AppColors.textSecondaryColor,
                size: 20,
              ),
            ),

          // Filter Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryText.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // Show filter options
                _showFilterOptions(context);
              },
              icon: Icon(
                Icons.tune,
                color: AppColors.primaryText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'خيارات البحث',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Filter Options
            _buildFilterOption(
              context,
              icon: Icons.category,
              title: 'الفئة',
              subtitle: 'اختر فئة المنتج',
              onTap: () {
                // Handle category filter
                Navigator.pop(context);
              },
            ),

            _buildFilterOption(
              context,
              icon: Icons.attach_money,
              title: 'السعر',
              subtitle: 'نطاق السعر',
              onTap: () {
                // Handle price filter
                Navigator.pop(context);
              },
            ),

            _buildFilterOption(
              context,
              icon: Icons.star,
              title: 'التقييم',
              subtitle: 'تقييم المنتج',
              onTap: () {
                // Handle rating filter
                Navigator.pop(context);
              },
            ),

            _buildFilterOption(
              context,
              icon: Icons.local_offer,
              title: 'العروض',
              subtitle: 'المنتجات المعروضة',
              onTap: () {
                // Handle offers filter
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryText.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryText,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.textSecondaryColor,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textSecondaryColor,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
