import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/viewmodels/craftsmen_list_viewmodel.dart';
import 'package:bazar_suez/craftsmen/widgets/craftsman_category_main_strip.dart';
import 'package:bazar_suez/craftsmen/widgets/craftsman_professions_strip.dart';
import 'package:bazar_suez/craftsmen/widgets/craftsmen_filter_sheet.dart';
import 'package:bazar_suez/craftsmen/widgets/instashop_craftsman_card.dart';
import 'package:bazar_suez/markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'package:bazar_suez/markets/saved_locations/widgets/saved_locations_sheet.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// صفحة عرض الصنايعية حسب الفئة — بنفس أسلوب صفحة المتاجر بعد اختيار الفئة.
class CraftsmenCategoryPage extends StatefulWidget {
  final String? groupId;
  final String? professionId;

  const CraftsmenCategoryPage({super.key, this.groupId, this.professionId});

  @override
  State<CraftsmenCategoryPage> createState() => _CraftsmenCategoryPageState();
}

class _CraftsmenCategoryPageState extends State<CraftsmenCategoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late CraftsmenListViewModel _vm;
  String? _activeGroupId;
  String? _activeProfessionId;

  @override
  void initState() {
    super.initState();
    _activeGroupId = _resolveInitialGroupId();
    _activeProfessionId = widget.professionId;
    _vm = CraftsmenListViewModel(initialFilters: _buildFilters());
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.load());
  }

  @override
  void didUpdateWidget(covariant CraftsmenCategoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId ||
        oldWidget.professionId != widget.professionId) {
      _activeGroupId = _resolveInitialGroupId();
      _activeProfessionId = widget.professionId;
      _vm.applyFilters(_buildFilters());
    }
  }

  String? _resolveInitialGroupId() {
    if (widget.groupId != null && widget.groupId!.isNotEmpty) {
      return widget.groupId;
    }
    if (widget.professionId != null) {
      return findProfessionById(widget.professionId)?.groupId;
    }
    return kCraftsmanCategoryGroups.first.id;
  }

  CraftsmanFilterOptions _buildFilters() {
    return CraftsmanFilterOptions(
      groupId: _activeProfessionId == null ? _activeGroupId : null,
      professionId: _activeProfessionId,
      sortBy: CraftsmanSortBy.distance,
      sortAscending: true,
    );
  }

  CraftsmanCategoryGroup? get _activeGroup {
    final id = _activeGroupId;
    if (id == null) return null;
    for (final g in kCraftsmanCategoryGroups) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> _onMainGroupSelected(String groupId) async {
    if (_activeGroupId == groupId && _activeProfessionId == null) return;

    setState(() {
      _activeGroupId = groupId;
      _activeProfessionId = null;
    });

    await _vm.applyFilters(_buildFilters());

    if (mounted) {
      context.go('/CraftsmenCategoryPage?groupId=$groupId');
    }
  }

  Future<void> _onProfessionSelected(String? professionId) async {
    if (_activeProfessionId == professionId) return;

    setState(() => _activeProfessionId = professionId);

    await _vm.applyFilters(_buildFilters());

    if (!mounted || _activeGroupId == null) return;

    final uri = professionId == null
        ? '/CraftsmenCategoryPage?groupId=$_activeGroupId'
        : '/CraftsmenCategoryPage?groupId=$_activeGroupId&professionId=$professionId';
    context.go(uri);
  }

  void _showFiltersSheet() {
    CraftsmenFilterSheet.show(
      context,
      initial: _vm.filters.copyWith(
        groupId: _activeProfessionId == null ? _activeGroupId : null,
        professionId: _activeProfessionId,
      ),
      onApply: (filters) {
        _vm.applyFilters(
          filters.copyWith(
            groupId: _activeProfessionId == null ? _activeGroupId : null,
            professionId: _activeProfessionId,
          ),
        );
      },
    );
  }

  String _normalize(String input) {
    final diacritics = RegExp('[\u064B-\u0652]');
    return input
        .replaceAll(diacritics, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase()
        .trim();
  }

  List<CraftsmanSearchResult> _filterByName(
    List<CraftsmanSearchResult> results,
    String query,
  ) {
    if (query.isEmpty) return results;
    final q = _normalize(query);
    return results.where((r) {
      final name = _normalize(r.craftsman.name);
      final profession = _normalize(r.craftsman.professionName);
      final area = _normalize(r.craftsman.areaName ?? '');
      return name.contains(q) || profession.contains(q) || area.contains(q);
    }).toList();
  }

  String _truncateAddress(String address, int maxLength) {
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength - 3)}...';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationVm = context.watch<SavedLocationsViewModel>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final group = _activeGroup;
          final profession = findProfessionById(_activeProfessionId);
          final filteredResults = _filterByName(
            _vm.results,
            _searchController.text,
          );

          return Scaffold(
            backgroundColor: Colors.white,
            floatingActionButton: _vm.isLoading
                ? null
                : FloatingActionButton.extended(
                    onPressed: _showFiltersSheet,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.mainColor,
                    ),
                    label: const Text(
                      'فلاتر',
                      style: TextStyle(
                        color: AppColors.mainColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  backgroundColor: AppColors.mainColor,
                  expandedHeight: 148.0,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/craftsmen'),
                  ),
                  centerTitle: true,
                  title: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SavedLocationsSheet(),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'الخدمة في',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                        if (locationVm.hasLocation) ...[
                          const SizedBox(height: 2),
                          Text(
                            _truncateAddress(locationVm.displayAddress, 22),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppColors.mainColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.grey[500],
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: 'ابحث عن صنايعي أو مهنة',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: CraftsmanCategoryMainStrip(
                    selectedGroupId: _activeGroupId,
                    onGroupSelected: _onMainGroupSelected,
                  ),
                ),

                if (_vm.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (group != null)
                    SliverToBoxAdapter(
                      child: CraftsmanProfessionsStrip(
                        professions: group.professions,
                        selectedProfessionId: _activeProfessionId,
                        onProfessionSelected: _onProfessionSelected,
                      ),
                    ),

                  if (filteredResults.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.handyman_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profession != null
                                    ? 'لا يوجد صنايعية متخصصين في ${profession.nameAr}'
                                    : 'لا يوجد صنايعية في هذه الفئة',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (filteredResults.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final result = filteredResults[index];
                          _vm.logImpression(result.craftsman.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InstashopCraftsmanCard(
                              result: result,
                              professionLabel: profession?.nameAr,
                              groupLabel: group?.nameAr,
                            ),
                          );
                        }, childCount: filteredResults.length),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
