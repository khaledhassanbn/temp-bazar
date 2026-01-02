import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/Model/model.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';

/// ويدجت لعرض أيقونات الفئات بشكل شبكي (4 في الصف)
/// عند الضغط على فئة، يتم فتح صفحة الفئة
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

    // تصفية فئة "هدايا" وعرض أول 7 فئات
    final filteredCategories = categoryVm.categories
        .where((cat) => 
            cat.id.toLowerCase() != 'gifts' && 
            cat.name.toLowerCase() != 'هدايا')
        .take(7)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'وش ودك تطلب اليوم؟',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // شبكة الفئات 4 في الصف
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredCategories.length + 1, // +1 لزر "كل الفئات"
              itemBuilder: (context, index) {
                // العنصر الأخير هو زر "عرض كل الفئات" (بديل عن "هدايا")
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
        ],
      ),
    );
  }

  Widget _buildViewAllItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => context.push('/CategoriesGrid'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                color: AppColors.mainColor,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'كل الفئات',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold, // 🔥 خط عريض دائماً
              color: AppColors.mainColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().scale(
            duration: 300.ms,
            delay: (index * 30).ms,
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
        // فتح صفحة الفئة مباشرة
        context.go('/FoodHomePage?categoryId=${category.id}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // صورة الفئة بدون إطار
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCategoryImage(category),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // اسم الفئة
          Text(
            category.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold, // 🔥 خط عريض دائماً
              color: isSelected ? AppColors.mainColor : Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().scale(
            duration: 300.ms,
            delay: (index * 30).ms,
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
          ),
    );
  }

  /// بناء صورة الفئة بدون خلفية (مثل PNG شفاف)
  Widget _buildCategoryImage(CategoryModel category) {
    // إذا كانت الفئة لها أيقونة (URL)
    if (category.icon.isNotEmpty) {
      if (category.icon.startsWith('http')) {
        // صورة من الإنترنت
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
        // صورة محلية من assets
        return Image.asset(
          category.icon,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
        );
      }
    }
    
    // محاولة تحميل صورة من assets/images/categories/
    return Image.asset(
      'assets/images/categories/${category.id}.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildFallbackIcon(category.id),
    );
  }

  /// أيقونة احتياطية في حالة عدم وجود صورة
  Widget _buildFallbackIcon(String categoryId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIcon(categoryId),
        size: 32,
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

