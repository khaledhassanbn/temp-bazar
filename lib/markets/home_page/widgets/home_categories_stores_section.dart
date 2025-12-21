import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/Model/model.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'home_store_grid_card.dart';

/// ويدجت لعرض الفئات مع المتاجر في الصفحة الرئيسية
/// - إذا لم يتم اختيار فئة → عرض كل الفئات مع 8 متاجر لكل فئة
/// - إذا تم اختيار فئة → عرض 16 متجر من الفئة المختارة فقط في شبكة 4×4
class HomeCategoriesStoresSection extends StatefulWidget {
  const HomeCategoriesStoresSection({super.key});

  @override
  State<HomeCategoriesStoresSection> createState() =>
      _HomeCategoriesStoresSectionState();
}

class _HomeCategoriesStoresSectionState
    extends State<HomeCategoriesStoresSection> {
  @override
  void initState() {
    super.initState();
    _loadCategoryStores();
  }

  void _loadCategoryStores() {
    Future.microtask(() {
      final categoryVm = context.read<CategoryViewModel>();
      final filterVm = context.read<CategoryFilterViewModel>();

      // Load stores for all categories
      if (categoryVm.categories.isNotEmpty &&
          filterVm.categoryStoresMap.isEmpty) {
        final categoryIds =
            categoryVm.categories.map((c) => c.id).toList();
        filterVm.fetchStoresForAllCategories(categoryIds, limit: 8);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final filterVm = context.watch<CategoryFilterViewModel>();

    // إذا تم اختيار فئة معينة → عرض 16 متجر منها فقط
    if (filterVm.selectedCategoryId != null) {
      return _buildSelectedCategorySection(filterVm, categoryVm);
    }

    // إذا لم يتم اختيار فئة → عرض كل الفئات مع متاجرها
    return _buildAllCategoriesSections(filterVm, categoryVm);
  }

  /// عرض الفئة المختارة فقط مع 16 متجر
  Widget _buildSelectedCategorySection(
    CategoryFilterViewModel filterVm,
    CategoryViewModel categoryVm,
  ) {
    // Find category name
    final category = categoryVm.categories.firstWhere(
      (c) => c.id == filterVm.selectedCategoryId,
      orElse: () => CategoryModel(id: '', name: 'غير معروف', order: 0, icon: ''),
    );

    if (filterVm.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stores = filterVm.stores.take(16).toList();

    if (stores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.store_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'لا توجد متاجر في هذه الفئة',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go(
                    '/FoodHomePage?categoryId=${filterVm.selectedCategoryId}',
                  );
                },
                child: Text(
                  'اظهار الكل',
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid 4×4
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 30) / 4; // 4 items with spacing
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: stores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final store = entry.value;
                  return SizedBox(
                    width: itemWidth,
                    child: HomeStoreGridCard(store: store)
                        .animate()
                        .scale(duration: 300.ms, delay: (index * 50).ms)
                        .fadeIn(duration: 300.ms),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  /// عرض كل الفئات مع متاجرها (8 متاجر لكل فئة)
  Widget _buildAllCategoriesSections(
    CategoryFilterViewModel filterVm,
    CategoryViewModel categoryVm,
  ) {
    if (filterVm.isLoadingCategoryStores) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Trigger loading if needed
    if (categoryVm.categories.isNotEmpty &&
        filterVm.categoryStoresMap.isEmpty &&
        !filterVm.isLoadingCategoryStores) {
      _loadCategoryStores();
    }

    return Column(
      children: categoryVm.categories.map((category) {
        final stores = filterVm.categoryStoresMap[category.id] ?? [];

        // Skip empty categories
        if (stores.isEmpty) return const SizedBox.shrink();

        return _buildCategorySection(category, stores);
      }).toList(),
    );
  }

  /// Section لفئة واحدة مع متاجرها
  Widget _buildCategorySection(CategoryModel category, List stores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: اسم الفئة + اظهار الكل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/FoodHomePage?categoryId=${category.id}');
                },
                child: Text(
                  'اظهار الكل',
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid 2×4 (8 stores max)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 30) / 4; // 4 items with spacing
              final displayStores = stores.length > 8 ? stores.sublist(0, 8) : stores;
              return Wrap(
                spacing: 10,
                runSpacing: 12,
                children: displayStores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final store = entry.value;
                  return SizedBox(
                    width: itemWidth,
                    child: HomeStoreGridCard(store: store)
                        .animate()
                        .scale(duration: 300.ms, delay: (index * 50).ms)
                        .fadeIn(duration: 300.ms),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
