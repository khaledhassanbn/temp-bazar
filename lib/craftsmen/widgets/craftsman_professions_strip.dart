import 'package:flutter/material.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanProfessionsStrip extends StatelessWidget {
  final List<CraftsmanProfession> professions;
  final String? selectedProfessionId;
  final ValueChanged<String?> onProfessionSelected;

  const CraftsmanProfessionsStrip({
    super.key,
    required this.professions,
    required this.selectedProfessionId,
    required this.onProfessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (professions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Text(
            'المهن المتخصصة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        SizedBox(
          height: 102,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: professions.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = selectedProfessionId == null;
                return _ProfessionTile(
                  label: 'الكل',
                  isSelected: isSelected,
                  onTap: () => onProfessionSelected(null),
                );
              }
              final profession = professions[index - 1];
              final isSelected = selectedProfessionId == profession.id;
              return _ProfessionTile(
                label: profession.nameAr,
                isSelected: isSelected,
                onTap: () => onProfessionSelected(profession.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfessionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfessionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconForLabel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('سباك') || lower.contains('سباكة')) {
      return Icons.plumbing_rounded;
    }
    if (lower.contains('كهرب')) return Icons.electric_bolt_rounded;
    if (lower.contains('تكييف')) return Icons.ac_unit_rounded;
    if (lower.contains('نجار')) return Icons.carpenter_rounded;
    if (lower.contains('دهان') || lower.contains('نقاش')) {
      return Icons.format_paint_rounded;
    }
    if (lower.contains('نظاف')) return Icons.cleaning_services_rounded;
    if (lower.contains('دش') || lower.contains('شبك')) {
      return Icons.satellite_alt_rounded;
    }
    if (lower.contains('نقل')) return Icons.local_shipping_rounded;
    if (lower.contains('مدرس')) return Icons.school_rounded;
    if (lower.contains('كامير')) return Icons.videocam_rounded;
    if (lower.contains('حدائق')) return Icons.yard_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 6),
            SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
