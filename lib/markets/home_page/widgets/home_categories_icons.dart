import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/Model/model.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';

/// ويدجت لعرض أيقونات الفئات بشكل أفقي
/// عند الضغط على فئة، يتم تحديدها وعرض متاجرها في القسم التالي
class HomeCategoriesIcons extends StatelessWidget {
  const HomeCategoriesIcons({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final filterVm = context.watch<CategoryFilterViewModel>();

    if (categoryVm.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (categoryVm.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم مع زر كل الفئات
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تصفح حسب الفئة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                // زر كل الفئات
                TextButton.icon(
                  onPressed: () => context.push('/CategoriesGrid'),
                  icon: Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: AppColors.mainColor,
                  ),
                  label: Text(
                    'كل الفئات',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // قائمة الفئات
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categoryVm.categories.length,
              itemBuilder: (context, index) {
                final category = categoryVm.categories[index];
                final isSelected = filterVm.selectedCategoryId == category.id;

                return _buildCategoryItem(
                  context,
                  category,
                  isSelected,
                  filterVm,
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryModel category,
    bool isSelected,
    CategoryFilterViewModel filterVm,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          // إلغاء التحديد
          filterVm.clearCategoryFilter();
        } else {
          // تحديد الفئة وجلب متاجرها
          filterVm.selectCategoryAndFetchStores(category.id);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // صورة الفئة
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.mainColor
                      : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.mainColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildCategoryImage(category),
              ),
            ),
            const SizedBox(height: 8),
            // اسم الفئة
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().scale(
            duration: 300.ms,
            delay: (index * 50).ms,
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
    );
  }

  /// بناء صورة الفئة
  Widget _buildCategoryImage(CategoryModel category) {
    // إذا كانت الفئة لها أيقونة (URL)
    if (category.icon.isNotEmpty) {
      if (category.icon.startsWith('http')) {
        // صورة من الإنترنت
        return Image.network(
          category.icon,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.mainColor,
              ),
            );
          },
        );
      } else {
        // صورة محلية من assets
        return Image.asset(
          category.icon,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
        );
      }
    }
    
    // محاولة تحميل صورة من assets/images/categories/
    return Image.asset(
      'assets/images/categories/${category.id}.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
    );
  }

  /// أيقونة احتياطية في حالة عدم وجود صورة
  Widget _buildFallbackIcon(String categoryId) {
    return Container(
      color: AppColors.mainColor.withOpacity(0.1),
      child: Icon(
        _getCategoryIcon(categoryId),
        size: 28,
        color: AppColors.mainColor,
      ),
    );
  }

  // أيقونات الفئات الافتراضية
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'grocery':
        return Icons.shopping_basket;
      case 'fashion':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'beauty':
        return Icons.spa;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'gifts':
        return Icons.card_giftcard;
      case 'furniture':
        return Icons.chair;
      case 'sports':
        return Icons.sports_soccer;
      case 'books':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }
}
