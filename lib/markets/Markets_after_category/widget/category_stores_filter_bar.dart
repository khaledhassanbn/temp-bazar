import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';

class CategoryStoresFilterBar extends StatelessWidget {
  final Color primaryColor;

  const CategoryStoresFilterBar({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryFilterViewModel>();
    final isDefault = !vm.filterAlphabetical &&
        !vm.filterMostReviews &&
        !vm.filterBestSelling &&
        !vm.filterMinRating4 &&
        vm.selectedSubCategoryId == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChipButton(
              label: vm.selectedSubCategoryId == null
                  ? 'الفئات الفرعية'
                  : 'الفئات الفرعية ✓',
              selected: vm.selectedSubCategoryId != null,
              primaryColor: primaryColor,
              onTap: () => _showSubCategoryBottomSheet(context),
            ),
            const SizedBox(width: 6),
            _ChipButton(
              label: 'A to Z',
              selected: vm.filterAlphabetical,
              primaryColor: primaryColor,
              onTap: vm.toggleAlphabetical,
            ),
            const SizedBox(width: 6),
            _ChipButton(
              label: 'تقييمات مرتفعة',
              selected: vm.filterMostReviews,
              primaryColor: primaryColor,
              onTap: vm.toggleMostReviews,
            ),
            const SizedBox(width: 6),
            _ChipButton(
              label: 'أكثر مبيعاً',
              selected: vm.filterBestSelling,
              primaryColor: primaryColor,
              onTap: vm.toggleBestSelling,
            ),
            const SizedBox(width: 6),
            _ChipButton(
              label: 'تقييم 4.0+',
              selected: vm.filterMinRating4,
              primaryColor: primaryColor,
              onTap: vm.toggleMinRating4,
            ),
            const SizedBox(width: 6),
            _ChipButton(
              label: 'المقترحات',
              selected: isDefault,
              primaryColor: primaryColor,
              onTap: vm.clearAllFilters,
            ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryBottomSheet(BuildContext context) {
    final vm = context.read<CategoryFilterViewModel>();
    String? selectedId = vm.selectedSubCategoryId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                          const Expanded(
                            child: Text(
                              'الفئات الفرعية',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                onTap: () => setSheetState(() => selectedId = null),
                                title: const Text(
                                  'كل الفئات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: Radio<String?>(
                                  value: null,
                                  groupValue: selectedId,
                                  onChanged: (_) =>
                                      setSheetState(() => selectedId = null),
                                  activeColor: primaryColor,
                                ),
                              ),
                              const Divider(height: 1),
                              ...vm.subCategories.map((sub) {
                                return Column(
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 6),
                                      onTap: () =>
                                          setSheetState(() => selectedId = sub.id),
                                      title: Text(
                                        sub.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Radio<String?>(
                                        value: sub.id,
                                        groupValue: selectedId,
                                        onChanged: (_) => setSheetState(
                                          () => selectedId = sub.id,
                                        ),
                                        activeColor: primaryColor,
                                      ),
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            vm.setSubCategory(selectedId);
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'تطبيق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ChipButton({
    required this.label,
    required this.onTap,
    required this.primaryColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primaryColor : primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}
