import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryFilterViewModel>();
    if (vm.subCategories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 105,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: vm.subCategories.length,
        itemBuilder: (context, index) {
          final sub = vm.subCategories[index];
          final bool isSelected = vm.selectedSubCategoryId == sub.id;
          return GestureDetector(
            onTap: () {
              final newId = isSelected ? null : sub.id;
              vm.setSubCategory(newId);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mainColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.mainColor.withOpacity(0.4)
                        : Colors.grey.shade300,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    sub.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
