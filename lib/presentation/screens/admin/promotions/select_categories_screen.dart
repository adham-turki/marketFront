import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/arabic_text.dart';
import '../../../../core/network/api_service.dart';

class SelectCategoriesScreen extends StatefulWidget {
  final List<int> selectedCategoryIds;
  final Function(List<int>) onCategoriesSelected;

  const SelectCategoriesScreen({
    super.key,
    required this.selectedCategoryIds,
    required this.onCategoriesSelected,
  });

  @override
  State<SelectCategoriesScreen> createState() => _SelectCategoriesScreenState();
}

class _SelectCategoriesScreenState extends State<SelectCategoriesScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filteredCategories = [];
  List<int> _selectedCategoryIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = List.from(widget.selectedCategoryIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _apiService.init();
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading categories...');
      final response = await _apiService.get('/categories');
      print('Categories response status: ${response.statusCode}');
      print('Categories response data: ${response.data}');

      if (response.statusCode == 200 && response.data['success']) {
        final categories = response.data['data'] ?? [];
        print('Categories found: ${categories.length}');
        print('Categories data: $categories');

        setState(() {
          _categories = List<Map<String, dynamic>>.from(categories);
          _filteredCategories = List.from(_categories);
        });
        print('Categories loaded: ${_categories.length}');
      } else {
        print('Categories API failed: ${response.data}');
      }
    } catch (e) {
      print('Categories error: $e');
      _showSnackBar('${ArabicText.errorLoadingCategories}: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = List.from(_categories);
      } else {
        _filteredCategories = _categories
            .where((category) =>
                category['name']
                    ?.toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ??
                false)
            .toList();
      }
    });
  }

  void _toggleCategorySelection(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  void _saveSelection() {
    widget.onCategoriesSelected(_selectedCategoryIds);
    Navigator.pop(context);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorColor : AppColors.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'SelectCategoriesScreen build - isLoading: $_isLoading, categories: ${_categories.length}, filtered: ${_filteredCategories.length}');
    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicText.selectCategories,
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSelection,
            child: const Text(
              ArabicText.save,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCategories,
              decoration: InputDecoration(
                hintText: 'البحث في الفئات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty
                                  ? Icons.category_outlined
                                  : Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'لا توجد فئات متاحة'
                                  : 'لا توجد نتائج للبحث',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          final isSelected =
                              _selectedCategoryIds.contains(category['id']);

                          print(
                              'Building category item: ${category['name']} (ID: ${category['id']})');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: CheckboxListTile(
                              title: Text(
                                category['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: category['description'] != null &&
                                      category['description']
                                          .toString()
                                          .isNotEmpty
                                  ? Text(category['description'])
                                  : null,
                              value: isSelected,
                              onChanged: (bool? value) {
                                _toggleCategorySelection(category['id']);
                              },
                              secondary: CircleAvatar(
                                backgroundColor:
                                    AppColors.primaryText.withOpacity(0.1),
                                child: Text(
                                  (category['name'] ?? '')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(ArabicText.cancel),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _saveSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                ),
                child: Text('تم اختيار ${_selectedCategoryIds.length} فئة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
