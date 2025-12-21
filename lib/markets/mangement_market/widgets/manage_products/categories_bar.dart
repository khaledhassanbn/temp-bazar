import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../../add_product/models/product_models.dart';

class ManageProductsCategoriesBar extends StatelessWidget {
  const ManageProductsCategoriesBar({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onReorderRequested,
    required this.isFixedCategory,
    required this.proxyHeight,
    required this.proxyMaxWidth,
  });

  final List<ProductCategoryModel> categories;
  final bool isLoading;
  final ProductCategoryModel? selectedCategory;
  final Future<void> Function(ProductCategoryModel category) onCategorySelected;
  final void Function(int oldIndex, int newIndex) onReorderRequested;
  final bool Function(ProductCategoryModel category) isFixedCategory;
  final double proxyHeight;
  final double proxyMaxWidth;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categories.isEmpty) {
      return const Center(child: Text('لا توجد فئات بعد، أضف فئة جديدة للبدء'));
    }

    return ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      buildDefaultDragHandles: false,
      itemCount: categories.length,
      proxyDecorator: (child, index, animation) {
        return Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: proxyMaxWidth,
              maxHeight: proxyHeight,
            ),
            child: child,
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < 0 || oldIndex >= categories.length) return;
        if (newIndex < 0 || newIndex > categories.length) return;

        final moving = categories[oldIndex];
        ProductCategoryModel? target;
        if (newIndex < categories.length) {
          target = categories[newIndex];
        }

        if (isFixedCategory(moving) ||
            (target != null && isFixedCategory(target))) {
          return;
        }

        onReorderRequested(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory?.id == category.id;
        final displayOrder = category.order != 0 ? category.order : (index + 1);

        final chip = Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: proxyHeight,
          child: ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected
                      ? Colors.white
                      : AppColors.mainColor,
                  child: Text(
                    '$displayOrder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.mainColor : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            selected: isSelected,
            backgroundColor: Colors.white,
            selectedColor: AppColors.mainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.transparent : Colors.black12,
              ),
            ),
            onSelected: (_) => onCategorySelected(category),
          ),
        );

        if (!isFixedCategory(category)) {
          return ReorderableDelayedDragStartListener(
            key: ValueKey('cat-${category.id}'),
            index: index,
            child: chip,
          );
        }

        return KeyedSubtree(key: ValueKey('cat-${category.id}'), child: chip);
      },
    );
  }
}
