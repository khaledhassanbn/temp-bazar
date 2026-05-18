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
import 'package:bazar_suez/markets/Markets_after_category/widget/search_bar_widget.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/category_stores_filter_bar.dart';
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
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  DeliveryFeeSettings? _deliverySettings;

  @override
  void initState() {
    super.initState();
    // تحميل بيانات الكاتيجوري الأولية إذا وصلت من الراوتر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        final vm = context.read<CategoryFilterViewModel>();
        vm.setCategory(widget.categoryId);
        _loadCategoryName(widget.categoryId!);
      }
      _loadDeliverySettings();
    });
    // إضافة listener للبحث
    _searchController.addListener(() {
      setState(() {}); // تحديث القائمة عند تغيير نص البحث
    });
  }

  Future<void> _loadDeliverySettings() async {
    try {
      final settings = await _deliveryFeeService.getSettings();
      if (mounted) {
        setState(() => _deliverySettings = settings);
      }
    } catch (e) {
      // استخدام القيم الافتراضية
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // حساب وقت التوصيل (بالدقائق)
  int _calculateDeliveryTime(double distanceKm) {
    return DeliveryFeeService.calculateDeliveryTime(distanceKm);
  }

  // حساب رسوم التوصيل باستخدام النظام المتدرج
  double _calculateDeliveryFee(double distanceKm) {
    if (_deliverySettings == null) return 30.0; // قيمة افتراضية
    return _deliveryFeeService.calculateDeliveryFee(
      distanceKm,
      _deliverySettings!,
    );
  }

  // حساب المسافة بين نقطتين
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
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.mainColor,
              expandedHeight: 140.0,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'التوصيل إلى',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                    if (locationVm.hasLocation) ...[
                      const SizedBox(height: 2),
                      Text(
                        _truncateAddress(locationVm.displayAddress, 15),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
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
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                            top: -8,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartVm.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 12.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (locationVm.hasLocation) {
                                    context.go('/Search');
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          const SavedLocationsSheet(),
                                    );
                                  }
                                },
                                child: AbsorbPointer(
                                  child: SearchBarWidget(
                                    suggestions: const [
                                      "متجر",
                                      "منتج",
                                      "ملابس",
                                      "أجهزة",
                                      "طعام",
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${vm.sortedStores.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (vm.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommended Stores Section
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'متاجر موصى بها',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Top 4 best-selling stores in this category
                      Builder(
                        builder: (context) {
                          final bestSelling = vm.stores.toList()
                            ..sort(
                              (a, b) => b.completedOrderCount.compareTo(
                                a.completedOrderCount,
                              ),
                            );
                          final top4 = bestSelling.take(4).toList();
                          if (top4.isEmpty) return const SizedBox.shrink();
                          return SizedBox(
                            height: 245,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: top4.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                return _buildRecommendedStoreCard(top4[index]);
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      CategoryStoresFilterBar(
                        primaryColor: AppColors.mainColor,
                      ),
                      const SizedBox(height: 8),

                      // Category Name
                      Text(
                        _categoryName ?? 'المتاجر',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Empty Check
                      if (filteredStores.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'لا توجد متاجر متاحة',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Stores List using SliverList
              if (filteredStores.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildStoreCard(filteredStores[index]),
                      );
                    }, childCount: filteredStores.length),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedStoreCard(StoreModel store) {
    final locationVm = context.watch<SavedLocationsViewModel>();

    // حساب المسافة والوقت والرسوم محلياً
    double? distanceKm;
    int? deliveryTime;
    double? deliveryFee;

    if (locationVm.activeLocation != null && store.location != null) {
      distanceKm = _calculateDistance(
        locationVm.activeLocation!,
        store.location!,
      );
      deliveryTime = _calculateDeliveryTime(distanceKm);
      deliveryFee = _calculateDeliveryFee(distanceKm);
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: () {
          context.push('/HomeMarketPage?marketLink=${store.link}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: store.coverUrl != null && store.coverUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(store.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: store.coverUrl == null || store.coverUrl!.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.store,
                            size: 40,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
                // شعار المتجر متداخل على اليسار بين الكفر والنص (مربع)
                Positioned(
                  bottom: -18,
                  left: 12,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: store.logoUrl != null && store.logoUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(store.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: store.logoUrl == null || store.logoUrl!.isEmpty
                        ? const Icon(Icons.store, size: 22, color: Colors.grey)
                        : null,
                  ),
                ),
                if (deliveryTime != null && deliveryTime > 0)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$deliveryTime دقيقة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        store.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${store.totalReviews})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (deliveryFee != null && deliveryFee > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.motorcycle,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${deliveryFee.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    final locationVm = context.watch<SavedLocationsViewModel>();
    double? distanceKm;
    int? deliveryTime;
    double? deliveryFee;

    // حساب المسافة والوقت والرسوم
    if (locationVm.activeLocation != null && store.location != null) {
      distanceKm = _calculateDistance(
        locationVm.activeLocation!,
        store.location!,
      );
      deliveryTime = _calculateDeliveryTime(distanceKm);
      deliveryFee = _calculateDeliveryFee(distanceKm);
    }
    return GestureDetector(
      onTap: () {
        context.push('/HomeMarketPage?marketLink=${store.link}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: store.coverUrl != null && store.coverUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(store.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: store.coverUrl == null || store.coverUrl!.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.store,
                            size: 60,
                            color: Colors.grey,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
                // شعار المتجر متداخل على اليسار بين الكفر والنص (مربع)
                Positioned(
                  bottom: -20,
                  left: 12,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: store.logoUrl != null && store.logoUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(store.logoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: store.logoUrl == null || store.logoUrl!.isEmpty
                        ? const Icon(Icons.store, size: 24, color: Colors.grey)
                        : null,
                  ),
                ),
                if (deliveryTime != null && deliveryTime > 0)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$deliveryTime\nدقيقة',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        store.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${store.totalReviews})',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (deliveryFee != null && deliveryFee > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.motorcycle,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${deliveryFee.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
