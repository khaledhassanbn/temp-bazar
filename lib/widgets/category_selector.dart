import 'package:flutter/material.dart';
import '../markets/create_market/services/categories_service.dart';
import '../theme/app_color.dart';

class CategorySelector extends StatefulWidget {
  final String? selectedCategoryId;
  final String? selectedSubCategory; // holds subcategory id
  final Function(String?, String?) onCategoryChanged; // (id, name_ar)
  final Function(String?, String?) onSubCategoryChanged; // (id, name_ar)
  final bool required;
  final String categoryLabel;
  final String subCategoryLabel;

  const CategorySelector({
    Key? key,
    this.selectedCategoryId,
    this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
    this.required = false,
    this.categoryLabel = 'الفئة الرئيسية',
    this.subCategoryLabel = 'التصنيف الفرعي',
  }) : super(key: key);

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;
  String? _selectedSubCategory;
  List<SubCategory> _availableSubCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedSubCategory = widget.selectedSubCategory;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoriesService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });

        // إذا كان هناك فئة مختارة، قم بتحميل التصنيفات الفرعية
        if (_selectedCategoryId != null) {
          _onCategoryChanged(_selectedCategoryId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubCategory = null; // إعادة تعيين التصنيف الفرعي
      _availableSubCategories = [];
    });

    // تحديث التصنيفات الفرعية المتاحة
    if (categoryId != null) {
      final selectedCategory = _categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => Category(id: '', name: '', order: 0, subcategories: []),
      );
      setState(() {
        _availableSubCategories = selectedCategory.subcategories;
      });
      widget.onCategoryChanged(selectedCategory.id, selectedCategory.name);
    } else {
      widget.onCategoryChanged(null, null);
    }
    widget.onSubCategoryChanged(null, null);
  }

  void _onSubCategoryChanged(String? subCategoryId) {
    setState(() {
      _selectedSubCategory = subCategoryId;
    });
    if (subCategoryId == null) {
      widget.onSubCategoryChanged(null, null);
      return;
    }
    final sub = _availableSubCategories.firstWhere(
      (s) => s.id == subCategoryId,
      orElse: () => SubCategory(id: '', name: '', order: 0),
    );
    widget.onSubCategoryChanged(sub.id, sub.name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // اختيار الفئة الرئيسية
        _buildCategoryDropdown(),
        const SizedBox(height: 8),

        // اختيار التصنيف الفرعي (يظهر فقط إذا كانت هناك تصنيفات فرعية)
        if (_availableSubCategories.isNotEmpty) _buildSubCategoryDropdown(),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.categoryLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.mainColor,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 3),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _isLoading
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    value:
                        _selectedCategoryId != null &&
                            _categories.any((c) => c.id == _selectedCategoryId)
                        ? _selectedCategoryId
                        : null,
                    decoration: InputDecoration(
                      hintText: 'اختر ${widget.categoryLabel.toLowerCase()}',
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: Colors.white,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.id,
                        child: Text(category.name, textAlign: TextAlign.right),
                      );
                    }).toList(),
                    onChanged: _onCategoryChanged,
                    validator: widget.required
                        ? (value) {
                            if (value == null || value.isEmpty) {
                              return 'هذا الحقل مطلوب';
                            }
                            return null;
                          }
                        : null,
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSubCategoryDropdown() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subCategoryLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.mainColor,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 3),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value:
                  _selectedSubCategory != null &&
                      _availableSubCategories.any(
                        (s) => s.id == _selectedSubCategory,
                      )
                  ? _selectedSubCategory
                  : null,
              decoration: InputDecoration(
                hintText:
                    'اختر ${widget.subCategoryLabel.toLowerCase()} (اختياري)',
                counterText: "",
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _availableSubCategories.map((subCategory) {
                return DropdownMenuItem<String>(
                  value: subCategory.id,
                  child: Text(subCategory.name, textAlign: TextAlign.right),
                );
              }).toList(),
              onChanged: _onSubCategoryChanged,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
