import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/grid_of_categories/Model/model.dart';
import 'package:bazar_suez/markets/grid_of_categories/ViewModel/ViewModel.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CategoryMainStrip extends StatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const CategoryMainStrip({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryMainStrip> createState() => _CategoryMainStripState();
}

class _CategoryMainStripState extends State<CategoryMainStrip> {
  final ScrollController _scrollController = ScrollController();
  String? _lastScrolledCategoryId;

  @override
  void didUpdateWidget(CategoryMainStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      _lastScrolledCategoryId = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<CategoryModel> _filterCategories(List<CategoryModel> categories) {
    return categories.where((cat) {
      final name = cat.name.trim();
      return name != 'خدمات' && !name.contains('صنايعية') && name != 'مستلزمات';
    }).toList();
  }

  void _scrollToSelected(List<CategoryModel> categories) {
    final selectedId = widget.selectedCategoryId;
    if (selectedId == null || selectedId == _lastScrolledCategoryId) return;

    final index = categories.indexWhere((cat) => cat.id == selectedId);
    if (index < 0) return;

    _lastScrolledCategoryId = selectedId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      const itemWidth = 76.0;
      const separatorWidth = 4.0;
      const horizontalPadding = 12.0;
      final targetOffset =
          horizontalPadding + index * (itemWidth + separatorWidth);

      final viewportWidth = _scrollController.position.viewportDimension;
      final centeredOffset =
          targetOffset - (viewportWidth / 2) + (itemWidth / 2);

      _scrollController.animateTo(
        centeredOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryViewModel>(
      builder: (context, vm, _) {
        if (!vm.hasLoaded && !vm.isLoading) {
          Future.microtask(() => vm.fetchCategories());
        }

        if (vm.isLoading) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.mainColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final categories = _filterCategories(vm.categories);
        if (categories.isEmpty) return const SizedBox.shrink();

        _scrollToSelected(categories);

        return SizedBox(
          height: 104,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = widget.selectedCategoryId == category.id;
              return _CategoryStripItem(
                category: category,
                isSelected: isSelected,
                onTap: () => widget.onCategorySelected(category.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryStripItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryStripItem({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: _CategoryImage(icon: category.icon),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.mainColor : const Color(0xFF757575),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mainColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String icon;

  const _CategoryImage({required this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon.isEmpty) {
      return Icon(Icons.category_rounded, color: AppColors.mainColor, size: 36);
    }

    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: icon,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) =>
            Icon(Icons.category_rounded, color: AppColors.mainColor, size: 36),
      );
    }

    final assetPath = icon.contains('/')
        ? icon
        : 'assets/images/categories/$icon';

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.category_rounded, color: AppColors.mainColor, size: 36),
    );
  }
}
