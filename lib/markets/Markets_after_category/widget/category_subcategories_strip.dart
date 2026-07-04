import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/create_market/services/categories_service.dart'
    as cms;
import 'package:bazar_suez/theme/app_color.dart';

class CategorySubcategoriesStrip extends StatelessWidget {
  final List<cms.SubCategory> subCategories;
  final String? selectedSubCategoryId;
  final ValueChanged<String?> onSubCategorySelected;

  const CategorySubcategoriesStrip({
    super.key,
    required this.subCategories,
    required this.selectedSubCategoryId,
    required this.onSubCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (subCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(
            'الفئات الفرعية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: subCategories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = selectedSubCategoryId == null;
                return _SubCategoryTile(
                  label: 'الكل',
                  isSelected: isSelected,
                  onTap: () => onSubCategorySelected(null),
                );
              }
              final sub = subCategories[index - 1];
              final isSelected = selectedSubCategoryId == sub.id;
              return _SubCategoryTile(
                label: sub.name,
                isSelected: isSelected,
                onTap: () => onSubCategorySelected(sub.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubCategoryTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubCategoryTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconForLabel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('خصم') || lower.contains('عرض')) {
      return Icons.local_offer_rounded;
    }
    if (lower.contains('توصيل')) return Icons.delivery_dining_rounded;
    if (lower.contains('طازج') || lower.contains('خضار')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('لحوم') || lower.contains('دواجن')) {
      return Icons.set_meal_rounded;
    }
    if (lower.contains('مخبوز') || lower.contains('خبز')) {
      return Icons.bakery_dining_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.mainColor.withValues(alpha: 0.12)
                    : const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.mainColor
                      : const Color(0xFFE8E8E8),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                _iconForLabel(label),
                color: isSelected ? AppColors.mainColor : const Color(0xFF9E9E9E),
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.mainColor : const Color(0xFF424242),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
