import 'package:flutter/material.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanCategoryMainStrip extends StatefulWidget {
  final String? selectedGroupId;
  final ValueChanged<String> onGroupSelected;

  const CraftsmanCategoryMainStrip({
    super.key,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  @override
  State<CraftsmanCategoryMainStrip> createState() =>
      _CraftsmanCategoryMainStripState();
}

class _CraftsmanCategoryMainStripState extends State<CraftsmanCategoryMainStrip> {
  final ScrollController _scrollController = ScrollController();
  String? _lastScrolledGroupId;

  @override
  void didUpdateWidget(CraftsmanCategoryMainStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGroupId != widget.selectedGroupId) {
      _lastScrolledGroupId = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'plumbing':
        return Icons.plumbing;
      case 'carpenter':
        return Icons.carpenter;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'videocam':
        return Icons.videocam;
      case 'yard':
        return Icons.yard;
      case 'build':
        return Icons.build;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'person':
        return Icons.person;
      default:
        return Icons.home_work;
    }
  }

  void _scrollToSelected() {
    final selectedId = widget.selectedGroupId;
    if (selectedId == null || selectedId == _lastScrolledGroupId) return;

    final index = kCraftsmanCategoryGroups.indexWhere((g) => g.id == selectedId);
    if (index < 0) return;

    _lastScrolledGroupId = selectedId;
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
    _scrollToSelected();

    return SizedBox(
      height: 104,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kCraftsmanCategoryGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final group = kCraftsmanCategoryGroups[index];
          final isSelected = widget.selectedGroupId == group.id;
          return _GroupStripItem(
            group: group,
            icon: _iconFor(group.iconName),
            isSelected: isSelected,
            onTap: () => widget.onGroupSelected(group.id),
          );
        },
      ),
    );
  }
}

class _GroupStripItem extends StatelessWidget {
  final CraftsmanCategoryGroup group;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GroupStripItem({
    required this.group,
    required this.icon,
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
              child: Center(
                child: Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              group.nameAr,
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
