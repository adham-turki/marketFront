import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AdvancedFilterSection extends StatefulWidget {
  final List<FilterOption> filterOptions;
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback onClearFilters;
  final bool showSearchBar;
  final String? searchHint;

  const AdvancedFilterSection({
    super.key,
    required this.filterOptions,
    required this.currentFilters,
    required this.onFiltersChanged,
    required this.onClearFilters,
    this.showSearchBar = true,
    this.searchHint,
  });

  @override
  State<AdvancedFilterSection> createState() => _AdvancedFilterSectionState();
}

class _AdvancedFilterSectionState extends State<AdvancedFilterSection> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.currentFilters['search'] ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with expand/collapse
          _buildHeader(),

          // Search bar
          if (widget.showSearchBar) _buildSearchBar(),

          // Filter options
          if (_isExpanded) _buildFilterOptions(),

          // Active filters display
          if (_hasActiveFilters()) _buildActiveFilters(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Advanced Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primaryColor,
            ),
            label: Text(
              _isExpanded ? 'Collapse' : 'Expand',
              style: const TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.searchHint ?? 'Search...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    _updateFilter('search', '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
        onChanged: (value) {
          _updateFilter('search', value);
        },
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.filterOptions.map((option) {
          return _buildFilterOption(option);
        }).toList(),
      ),
    );
  }

  Widget _buildFilterOption(FilterOption option) {
    switch (option.type) {
      case FilterType.dropdown:
        return _buildDropdownFilter(option);
      case FilterType.dateRange:
        return _buildDateRangeFilter(option);
      case FilterType.checkbox:
        return _buildCheckboxFilter(option);
      case FilterType.range:
        return _buildRangeFilter(option);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDropdownFilter(FilterOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.currentFilters[option.key] ?? option.defaultValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryText),
              ),
            ),
            items: option.options?.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value),
                  );
                }).toList() ??
                [],
            onChanged: (value) {
              _updateFilter(option.key, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter(FilterOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
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
                  'From',
                  '${option.key}_from',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'To',
                  '${option.key}_to',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, String key, IconData icon) {
    final date = widget.currentFilters[key];
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          _updateFilter(key, selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryText),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : label,
                style: TextStyle(
                  color: date != null
                      ? AppColors.primaryText
                      : AppColors.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxFilter(FilterOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: option.options?.map((value) {
                  final isSelected =
                      (widget.currentFilters[option.key] ?? []).contains(value);
                  return FilterChip(
                    label: Text(value),
                    selected: isSelected,
                    onSelected: (selected) {
                      final currentValues = List<String>.from(
                        widget.currentFilters[option.key] ?? [],
                      );
                      if (selected) {
                        currentValues.add(value);
                      } else {
                        currentValues.remove(value);
                      }
                      _updateFilter(option.key, currentValues);
                    },
                    selectedColor: AppColors.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryColor,
                  );
                }).toList() ??
                [],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFilter(FilterOption option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Min',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateFilter('${option.key}_min', value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Max',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateFilter('${option.key}_max', value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final activeFilters = widget.currentFilters.entries
        .where((entry) => entry.value != null && entry.value != '')
        .where((entry) => entry.key != 'search')
        .toList();

    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Filters:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClearFilters,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFilters.map((filter) {
              return Chip(
                label: Text('${filter.key}: ${filter.value}'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  _updateFilter(filter.key, null);
                },
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primaryColor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return widget.currentFilters.entries
        .any((entry) => entry.value != null && entry.value != '');
  }

  void _updateFilter(String key, dynamic value) {
    final newFilters = Map<String, dynamic>.from(widget.currentFilters);
    if (value == null || value == '') {
      newFilters.remove(key);
    } else {
      newFilters[key] = value;
    }
    widget.onFiltersChanged(newFilters);
  }
}

class FilterOption {
  final String key;
  final String label;
  final FilterType type;
  final List<String>? options;
  final String? defaultValue;

  const FilterOption({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.defaultValue,
  });
}

enum FilterType {
  dropdown,
  dateRange,
  checkbox,
  range,
}
