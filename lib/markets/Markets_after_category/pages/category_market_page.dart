import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'package:bazar_suez/markets/create_market/services/categories_service.dart'
    as cms;
import 'package:bazar_suez/markets/saved_locations/widgets/saved_locations_sheet.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/category_stores_filter_bar.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/category_main_strip.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/category_subcategories_strip.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/instashop_store_card.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_service.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_settings.dart';

class CategoryMarketPage extends StatefulWidget {
  final String? categoryId;
  const CategoryMarketPage({super.key, this.categoryId});

  @override
  State<CategoryMarketPage> createState() => _CategoryMarketPageState();
}

class _CategoryMarketPageState extends State<CategoryMarketPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _categoryName;
  String? _activeCategoryId;
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  DeliveryFeeSettings? _deliverySettings;

  @override
  void initState() {
    super.initState();
    _activeCategoryId = widget.categoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyCategory(widget.categoryId);
      _loadDeliverySettings();
    });
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CategoryMarketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId &&
        widget.categoryId != null &&
        widget.categoryId!.isNotEmpty) {
      _activeCategoryId = widget.categoryId;
      _applyCategory(widget.categoryId);
    }
  }

  Future<void> _applyCategory(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return;
    final vm = context.read<CategoryFilterViewModel>();
    if (vm.selectedCategoryId != categoryId) {
      await vm.setCategory(categoryId);
    }
    await _loadCategoryName(categoryId);
    if (mounted) {
      setState(() => _activeCategoryId = categoryId);
    }
  }

  Future<void> _loadDeliverySettings() async {
    try {
      final settings = await _deliveryFeeService.getSettings();
      if (mounted) {
        setState(() => _deliverySettings = settings);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deliverySettings = DeliveryFeeSettings.defaults());
      }
    }
  }

  Future<void> _loadCategoryName(String categoryId) async {
    try {
      final category = await cms.CategoriesService.getCategoryById(categoryId);
      if (mounted) {
        setState(() {
          _categoryName = category?.name;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onMainCategorySelected(String categoryId) async {
    final vm = context.read<CategoryFilterViewModel>();
    if (_activeCategoryId == categoryId && vm.selectedCategoryId == categoryId) {
      return;
    }
    setState(() => _activeCategoryId = categoryId);
    await vm.setCategory(categoryId);
    await _loadCategoryName(categoryId);
    if (mounted) {
      context.go('/CategoryMarketPage?categoryId=$categoryId');
    }
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                          'الفلاتر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CategoryStoresFilterBar(primaryColor: AppColors.mainColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _calculateDeliveryTime(double distanceKm) {
    return DeliveryFeeService.calculateDeliveryTime(distanceKm);
  }

  double _calculateDeliveryFee(double distanceKm) {
    if (_deliverySettings == null) return 30.0;
    return _deliveryFeeService.calculateDeliveryFee(
      distanceKm,
      _deliverySettings!,
    );
  }

  double _calculateDistance(GeoPoint userLocation, GeoPoint storeLocation) {
    return DeliveryFeeService.calculateDistanceFromGeoPoints(
      userLocation,
      storeLocation,
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

  List<StoreModel> _filterStores(List<StoreModel> stores, String query) {
    if (query.isEmpty) return stores;
    final q = _normalize(query);
    return stores.where((store) {
      final name = _normalize(store.name);
      return name.contains(q);
    }).toList();
  }

  String _truncateAddress(String address, int maxLength) {
    if (address.length <= maxLength) return address;
    return '${address.substring(0, maxLength - 3)}...';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryFilterViewModel>();
    final cartVm = context.watch<CartViewModel>();
    final locationVm = context.watch<SavedLocationsViewModel>();

    final filteredStores = _filterStores(
      vm.sortedStores,
      _searchController.text,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: vm.isLoading
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
                onPressed: () => context.go('/HomePage'),
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
                          'التوصيل إلى',
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
              actions: [
                InkWell(
                  onTap: () => goIfAuthed(
                    context,
                    '/CartPage',
                    message: 'سجّل دخولك لعرض سلة المشتريات',
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        if (cartVm.itemCount > 0)
                          Positioned(
                            top: -6,
                            left: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartVm.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'ابحث عن أي منتج أو متجر',
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
              child: CategoryMainStrip(
                selectedCategoryId:
                    _activeCategoryId ?? widget.categoryId ?? vm.selectedCategoryId,
                onCategorySelected: _onMainCategorySelected,
              ),
            ),

            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverToBoxAdapter(
                child: CategorySubcategoriesStrip(
                  subCategories: vm.subCategories,
                  selectedSubCategoryId: vm.selectedSubCategoryId,
                  onSubCategorySelected: vm.setSubCategory,
                ),
              ),

              if (filteredStores.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'لا توجد متاجر متاحة',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

              if (filteredStores.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final store = filteredStores[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildStoreCard(store, vm, locationVm),
                      );
                    }, childCount: filteredStores.length),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(
    StoreModel store,
    CategoryFilterViewModel vm,
    SavedLocationsViewModel locationVm,
  ) {
    int? deliveryTime;
    double? deliveryFee;

    if (locationVm.activeLocation != null && store.location != null) {
      final distanceKm = _calculateDistance(
        locationVm.activeLocation!,
        store.location!,
      );
      deliveryTime = _calculateDeliveryTime(distanceKm);
      deliveryFee = _calculateDeliveryFee(distanceKm);
    }

    return InstashopStoreCard(
      store: store,
      deliveryTimeMin: deliveryTime,
      deliveryFee: deliveryFee,
      subCategoryLabel: vm.subCategoryNameForStore(store.id),
      categoryLabel: _categoryName,
      onTap: () => context.push('/HomeMarketPage?marketLink=${store.link}'),
    );
  }
}
