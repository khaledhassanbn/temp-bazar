import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'package:bazar_suez/markets/cart/viewmodels/cart_view_model.dart';
import 'package:bazar_suez/markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'package:bazar_suez/markets/create_market/services/categories_service.dart'
    as cms;
import 'package:bazar_suez/markets/home_page/services/featured_stores_service.dart';
import 'package:bazar_suez/markets/saved_locations/widgets/saved_locations_sheet.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/search_bar_widget.dart';
import 'package:bazar_suez/theme/app_color.dart';

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
  final FeaturedStoresService _featuredStoresService = FeaturedStoresService();
  List<FeaturedStoreResult> _featuredStores = [];
  bool _isLoadingFeatured = false;

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
      _loadFeaturedStores();
    });
    // إضافة listener للبحث
    _searchController.addListener(() {
      setState(() {}); // تحديث القائمة عند تغيير نص البحث
    });
  }

  Future<void> _loadFeaturedStores() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final stores = await _featuredStoresService.getFeaturedStores(limit: 10);
      if (mounted) {
        setState(() {
          _featuredStores = stores;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFeatured = false);
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

  // حساب المسافة بين نقطتين (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // حساب وقت التوصيل (بالدقائق)
  int _calculateDeliveryTime(double distanceKm) {
    return ((distanceKm / 20) * 60 + 15).round();
  }

  // حساب رسوم التوصيل (5 جنيه لكل كيلو)
  double _calculateDeliveryFee(double distanceKm) {
    return distanceKm * 5;
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

    final filteredStores = _filterStores(vm.stores, _searchController.text);

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
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
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
                        _truncateAddress(
                          locationVm.displayAddress,
                          15,
                        ),
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
                  onTap: () => context.go('/CartPage'),
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
                                    '${vm.stores.length}',
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

                      // Featured Stores list
                      if (_isLoadingFeatured)
                        const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_featuredStores.isEmpty)
                        const SizedBox.shrink()
                      else
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _featuredStores.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final result = _featuredStores[index];
                              return _buildRecommendedStoreCard(result);
                            },
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Filter Chips
                      if (vm.subCategories.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: vm.subCategories.map((sub) {
                              final isSelected =
                                  vm.selectedSubCategoryId == sub.id;
                              return GestureDetector(
                                onTap: () {
                                  final newId = isSelected ? null : sub.id;
                                  vm.setSubCategory(newId);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.mainColor
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.mainColor
                                          : Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text(
                                    sub.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

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
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
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
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildStoreCard(filteredStores[index]),
                        );
                      },
                      childCount: filteredStores.length,
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildRecommendedStoreCard(FeaturedStoreResult result) {
    final store = result.store;
    final locationVm = context.watch<SavedLocationsViewModel>();

    // حساب المسافة والوقت والرسوم محلياً
    double? distanceKm;
    int? deliveryTime = result.deliveryTimeMinutes;
    double? deliveryFee;

    if (locationVm.activeLocation != null && store.location != null) {
      distanceKm = _calculateDistance(
        locationVm.activeLocation!.latitude,
        locationVm.activeLocation!.longitude,
        store.location!.latitude,
        store.location!.longitude,
      );
      deliveryTime = _calculateDeliveryTime(distanceKm);
      deliveryFee = _calculateDeliveryFee(distanceKm); // 5 جنيه لكل كيلو
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
      child: GestureDetector(
        onTap: () {
          context.push('/HomeMarketPage?marketLink=${store.link}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
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
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (deliveryTime != null && deliveryTime > 0)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$deliveryTime\nدقيقة',
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        store.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${store.totalReviews})',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (deliveryFee != null && deliveryFee > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.motorcycle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${deliveryFee.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 13,
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
        locationVm.activeLocation!.latitude,
        locationVm.activeLocation!.longitude,
        store.location!.latitude,
        store.location!.longitude,
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
              padding: const EdgeInsets.all(16),
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
