import 'package:flutter/material.dart';
import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/viewmodels/craftsmen_list_viewmodel.dart';
import 'package:bazar_suez/craftsmen/widgets/craftsman_card.dart';
import 'package:bazar_suez/craftsmen/widgets/craftsmen_filter_sheet.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// قائمة الصنايعية مع فلترة المسافة والتقييم وعدد الطلبات.
class CraftsmenListPage extends StatefulWidget {
  final String? groupId;
  final String? professionId;
  final String? sort;
  final String? query;

  const CraftsmenListPage({
    super.key,
    this.groupId,
    this.professionId,
    this.sort,
    this.query,
  });

  @override
  State<CraftsmenListPage> createState() => _CraftsmenListPageState();
}

class _CraftsmenListPageState extends State<CraftsmenListPage> {
  late final CraftsmenListViewModel _vm;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = CraftsmenListViewModel(
      initialFilters: _buildInitialFilters(),
    );
    _searchCtrl.text = widget.query ?? '';
    _vm.load();
    _searchCtrl.addListener(() {
      _vm.applyFilters(
        _vm.filters.copyWith(areaQuery: _searchCtrl.text),
      );
    });
  }

  CraftsmanFilterOptions _buildInitialFilters() {
    CraftsmanSortBy sortBy = CraftsmanSortBy.distance;
    switch (widget.sort) {
      case 'rating':
        sortBy = CraftsmanSortBy.rating;
        break;
      case 'contacts':
        sortBy = CraftsmanSortBy.contactCount;
        break;
      case 'newest':
        sortBy = CraftsmanSortBy.newest;
        break;
    }
    return CraftsmanFilterOptions(
      groupId: widget.groupId,
      professionId: widget.professionId,
      areaQuery: widget.query,
      sortBy: sortBy,
      sortAscending: sortBy == CraftsmanSortBy.distance,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.professionId != null) {
      return findProfessionById(widget.professionId)?.nameAr ?? 'الصنايعية';
    }
    if (widget.groupId != null) {
      return findGroupNameById(widget.groupId) ?? 'الصنايعية';
    }
    return 'تصفح الصنايعية';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          title: Text(_title),
        ),
        body: Column(
          children: [
            _ActiveFiltersBar(vm: _vm),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو المنطقة...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  if (_vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_vm.error != null) {
                    return Center(child: Text(_vm.error!));
                  }
                  if (_vm.results.isEmpty) {
                    return const Center(
                      child: Text('لا توجد نتائج — جرّب تعديل الفلتر'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _vm.load,
                    child: ListView.builder(
                      itemCount: _vm.results.length,
                      itemBuilder: (context, i) {
                        final r = _vm.results[i];
                        return CraftsmanCard(
                          result: r,
                          onImpression: () =>
                              _vm.logImpression(r.craftsman.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => CraftsmenFilterSheet.show(
            context,
            initial: _vm.filters,
            onApply: _vm.applyFilters,
          ),
          backgroundColor: AppColors.mainColor,
          icon: const Icon(Icons.tune, color: Colors.white),
          label: const Text('فلترة', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _ActiveFiltersBar extends StatelessWidget {
  final CraftsmenListViewModel vm;

  const _ActiveFiltersBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    final f = vm.filters;
    final chips = <Widget>[];

    String sortLabel;
    switch (f.sortBy) {
      case CraftsmanSortBy.distance:
        sortLabel = 'الأقرب';
        break;
      case CraftsmanSortBy.rating:
        sortLabel = 'التقييم';
        break;
      case CraftsmanSortBy.contactCount:
        sortLabel = 'عدد الطلبات';
        break;
      case CraftsmanSortBy.newest:
        sortLabel = 'الأحدث';
        break;
    }
    chips.add(_chip('ترتيب: $sortLabel'));

    if (f.maxDistanceKm != null) {
      chips.add(_chip('حتى ${f.maxDistanceKm!.toInt()} كم'));
    }
    if (f.minRating > 0) {
      chips.add(_chip('تقييم ${f.minRating}+'));
    }
    if (f.minContactCount > 0) {
      chips.add(_chip('${f.minContactCount}+ طلب'));
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: chips),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.mainColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
