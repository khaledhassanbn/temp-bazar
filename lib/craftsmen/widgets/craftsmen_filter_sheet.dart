import 'package:flutter/material.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// ورقة فلترة: المسافة، التقييم، عدد التواصلات (الطلبات)، وترتيب النتائج.
class CraftsmenFilterSheet extends StatefulWidget {
  final CraftsmanFilterOptions initial;
  final ValueChanged<CraftsmanFilterOptions> onApply;

  const CraftsmenFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required CraftsmanFilterOptions initial,
    required ValueChanged<CraftsmanFilterOptions> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CraftsmenFilterSheet(initial: initial, onApply: onApply),
      ),
    );
  }

  @override
  State<CraftsmenFilterSheet> createState() => _CraftsmenFilterSheetState();
}

class _CraftsmenFilterSheetState extends State<CraftsmenFilterSheet> {
  late CraftsmanFilterOptions _f;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فلترة وترتيب',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _f = const CraftsmanFilterOptions(
                          professionId: null,
                          groupId: null,
                        );
                      });
                    },
                    child: const Text('إعادة تعيين'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _sectionTitle('ترتيب حسب'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _sortChip('الأقرب', CraftsmanSortBy.distance),
                  _sortChip('التقييم', CraftsmanSortBy.rating),
                  _sortChip('عدد الطلبات', CraftsmanSortBy.contactCount),
                  _sortChip('الأحدث', CraftsmanSortBy.newest),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle('أقصى مسافة (كم)'),
              Wrap(
                spacing: 8,
                children: [
                  _distanceChip(null, 'الكل'),
                  ...CraftsmanFilterOptions.distancePresetsKm.map(
                    (km) => _distanceChip(km, '$km كم'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle('الحد الأدنى للتقييم'),
              Wrap(
                spacing: 8,
                children: [
                  _ratingChip(0, 'الكل'),
                  ...CraftsmanFilterOptions.ratingPresets.map(
                    (r) => _ratingChip(r, '$r+'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _sectionTitle('الحد الأدنى لعدد الطلبات / التواصلات'),
              Wrap(
                spacing: 8,
                children: [
                  _contactChip(0, 'الكل'),
                  ...CraftsmanFilterOptions.contactCountPresets.map(
                    (n) => _contactChip(n, '$n+'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onApply(_f);
                  Navigator.pop(context);
                },
                child: const Text('تطبيق الفلتر', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      );

  Widget _sortChip(String label, CraftsmanSortBy sort) {
    final selected = _f.sortBy == sort;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _f = _f.copyWith(sortBy: sort)),
      selectedColor: AppColors.mainColor.withOpacity(0.2),
      checkmarkColor: AppColors.mainColor,
    );
  }

  Widget _distanceChip(double? km, String label) {
    final selected = _f.maxDistanceKm == km;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _f = km == null
            ? _f.copyWith(clearMaxDistance: true)
            : _f.copyWith(maxDistanceKm: km);
      }),
      selectedColor: AppColors.mainColor.withOpacity(0.2),
    );
  }

  Widget _ratingChip(double min, String label) {
    final selected = _f.minRating == min;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _f = _f.copyWith(minRating: min)),
      selectedColor: AppColors.mainColor.withOpacity(0.2),
    );
  }

  Widget _contactChip(int min, String label) {
    final selected = _f.minContactCount == min;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _f = _f.copyWith(minContactCount: min)),
      selectedColor: AppColors.mainColor.withOpacity(0.2),
    );
  }
}
