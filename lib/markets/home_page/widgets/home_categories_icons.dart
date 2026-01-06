import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/Model/model.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';

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

    // تصفية فئة "هدايا" وعرض أول 3 فئات
    final filteredCategories = categoryVm.categories
        .where(
          (cat) =>
              cat.id.toLowerCase() != 'gifts' &&
              cat.name.toLowerCase() != 'هدايا',
        )
        .take(3)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 110,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredCategories.length + 1,
            itemBuilder: (context, index) {
              if (index == filteredCategories.length) {
                return _buildViewAllItem(context, index);
              }

              final category = filteredCategories[index];
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
      ),
    );
  }

  Widget _buildViewAllItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => context.push('/CategoriesGrid'),
      child:
          Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.mainColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
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

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryModel category,
    bool isSelected,
    CategoryFilterViewModel filterVm,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        context.go('/CategoryMarketPage?categoryId=${category.id}');
      },
      child:
          Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildCategoryImage(category),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

  Widget _buildCategoryImage(CategoryModel category) {
    if (category.icon.isNotEmpty) {
      if (category.icon.startsWith('http')) {
        return Image.network(
          category.icon,
          fit: BoxFit.contain,
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
        // If it's a local asset but doesn't have the full path, add it
        final imagePath = category.icon.startsWith('assets/')
            ? category.icon
            : 'assets/images/categories/${category.icon}';

        return Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
        );
      }
    }
    return Image.asset(
      'assets/images/categories/${category.id}.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
    );
  }

  Widget _buildFallbackIcon(String categoryId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        _getCategoryIcon(categoryId),
        size: 36,
        color: AppColors.mainColor,
      ),
    );
  }

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
