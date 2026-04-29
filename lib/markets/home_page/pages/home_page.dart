import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/markets/grid_of_categories/ViewModel/ViewModel.dart';
import 'package:bazar_suez/markets/grid_of_categories/Model/model.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

import '../../cart/viewmodels/cart_view_model.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';
import '../../saved_locations/widgets/saved_locations_sheet.dart';
import '../../../authentication/guards/AuthGuard.dart';
import '../../../ads/models/ad_model.dart';

class HomeAppColors {
  static const primary = Color(0xFF4E99B4);
  static const primaryDark = Color(0xFF4E99B4);
  static const primaryLight = Color(0xFF5BA8E8);
  static const accent = Color(0xFF4CBBF5);
  static const background = Color.fromARGB(255, 251, 253, 255);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF4E99B4);
  static const textMed = Color(0xFF5A6A8A);
  static const textLight = Color(0xFF9AAAC0);
  static const discountRed = Color(0xFF3A8FE0);
  static const timerBg = Color(0xFF2B7FD4);
  static const gradStart = Color.fromARGB(255, 29, 102, 148);
  static const gradEnd = Color(0xFF4E99B4);
}





class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _bannerPage = 0;
  int _bannerItemCount = 1;
  String? _selectedCategoryId;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final PageController _bannerCtrl = PageController();
  late Timer _bannerTimer;

  Future<void> _selectCategory(String categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    setState(() => _selectedCategoryId = categoryId);
    await context.read<CategoryFilterViewModel>().setCategory(categoryId);
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_bannerItemCount <= 1) return;
      final next = (_bannerPage + 1) % _bannerItemCount;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bannerTimer.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeAppColors.background,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecialForYouHeader(),
                  _buildBannerSection(),
                  _buildCategoriesSection(),
                  _buildFlashSaleSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SavedLocationsSheet(),
    );
  }

  Widget _buildSpecialForYouHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'متاجر مميزة',
            style: TextStyle(
              color: HomeAppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: HomeAppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: HomeAppColors.primary,
            image: DecorationImage(
              image: AssetImage('assets/images/appbar.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Consumer<SavedLocationsViewModel>(
                            builder: (context, locationVm, _) {
                              final isBusy =
                                  locationVm.isInitializing || locationVm.isLoading;

                              final title = isBusy
                                  ? 'جاري تحديد الموقع...'
                                  : locationVm.displayAddress;

                              return GestureDetector(
                                onTap: _openLocationSheet,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: locationVm.locationPermissionDenied
                                              ? Colors.white.withOpacity(0.85)
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isBusy)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Consumer<CartViewModel>(
                        builder: (context, cartVm, _) {
                          return GestureDetector(
                            onTap: () => context.push('/CartPage'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  if (cartVm.itemCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${cartVm.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    final auth = context.watch<AuthGuard>();
    final isMarketOwner = auth.isMarketOwner;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('app_settings')
            .doc('home_ads')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final rawAds = (data?['ads'] is List) ? (data?['ads'] as List) : const [];

          final ads = rawAds
              .map((e) => e is Map<String, dynamic> ? AdModel.fromMap(e) : null)
              .whereType<AdModel>()
              .where((ad) => ad.isValid)
              .toList()
            ..sort((a, b) => a.slotId.compareTo(b.slotId));

          // Always prepend a default banner depending on user type.
          final totalCount = 1 + ads.length;
          if (_bannerItemCount != totalCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _bannerItemCount = totalCount;
                if (_bannerPage >= _bannerItemCount) _bannerPage = 0;
              });
            });
          }

          return Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _bannerCtrl,
                  onPageChanged: (p) => setState(() => _bannerPage = p),
                  itemCount: totalCount,
                  itemBuilder: (ctx, i) {
                    // index 0 => default banner
                    if (i == 0) {
                      final assetPath = isMarketOwner
                          ? 'assets/images/adsmarket.jpg'
                          : 'assets/images/create_market.png';
                      final onTap = isMarketOwner
                          ? () => context.push('/request-ads')
                          : () => context.push('/pricingpage');
                      return _BannerCard(
                        image: AssetImage(assetPath),
                        onTap: onTap,
                      );
                    }

                    final ad = ads[i - 1];
                    final marketLink = ad.targetStoreId;
                    return _BannerCard(
                      image: NetworkImage(ad.imageUrl!),
                      onTap: marketLink == null || marketLink.isEmpty
                          ? null
                          : () => context.push(
                                '/HomeMarketPage?marketLink=$marketLink',
                              ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _bannerPage == i ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _bannerPage == i
                          ? HomeAppColors.primary
                          : HomeAppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<CategoryViewModel>(
      builder: (context, vm, _) {
        // تحميل الفئات إذا لم تُحمَّل بعد
        if (!vm.hasLoaded && !vm.isLoading) {
          Future.microtask(() => vm.fetchCategories());
        }

        final displayCats = vm.categories.take(8).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الفئات',
                    style: TextStyle(
                      color: HomeAppColors.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/CategoriesGrid'),
                    child: const Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: HomeAppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (vm.isLoading)
                const SizedBox(
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: HomeAppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (displayCats.isEmpty)
                const SizedBox(
                  height: 90,
                  child: Center(
                    child: Text(
                      'لا توجد فئات',
                      style: TextStyle(color: HomeAppColors.textMed),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayCats.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final cat = displayCats[i];
                      return _CategoryCard(
                        category: cat,
                        onTap: () => _selectCategory(cat.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlashSaleSection() {
    return Consumer2<CategoryViewModel, CategoryFilterViewModel>(
      builder: (context, catVm, filterVm, _) {
        final categories = catVm.categories;

        // عند أول تحميل للفئات: اختر الأولى تلقائياً
        if (categories.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = categories.first.id;
          Future.microtask(() {
            filterVm.setCategory(categories.first.id);
          });
        }

        final stores = (_selectedCategoryId != null &&
                filterVm.selectedCategoryId == _selectedCategoryId)
            ? filterVm.stores.take(8).toList()
            : <StoreModel>[];

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── الفئات الفرعية للفئة المختارة (بديل عنوان "تسوق حسب الفئة")
              if (filterVm.subCategories.isNotEmpty) ...[
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filterVm.subCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      final sub = filterVm.subCategories[i];
                      final selected = filterVm.selectedSubCategoryId == sub.id;
                      return GestureDetector(
                        onTap: () {
                          final nextId = selected ? null : sub.id;
                          filterVm.setSubCategory(nextId);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? HomeAppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: selected
                                  ? HomeAppColors.primary
                                  : HomeAppColors.textLight
                                      .withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            sub.name,
                            style: TextStyle(
                              color: selected ? Colors.white : HomeAppColors.textMed,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── قائمة المتاجر
              if (filterVm.isLoading)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: HomeAppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (stores.isEmpty)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'لا توجد متاجر في هذه الفئة',
                      style: TextStyle(
                        color: HomeAppColors.textMed,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (ctx, i) =>
                        _HomeStoreCard(store: stores[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}



class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/Search'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ابحث عن متجر',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback? onTap;
  const _BannerCard({required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HomeAppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: HomeAppColors.primaryLight),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onTap;
  const _CategoryCard({required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: ClipOval(child: _buildCategoryImage(category.icon)),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: HomeAppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String icon) {
    if (icon.isEmpty) {
      return const Icon(
        Icons.category_outlined,
        color: HomeAppColors.primary,
        size: 32,
      );
    }
    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: icon,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HomeAppColors.primary,
          ),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.category_outlined,
          color: HomeAppColors.primary,
          size: 32,
        ),
      );
    }
    // صورة محلية
    final path =
        icon.startsWith('assets/') ? icon : 'assets/images/categories/$icon';
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: 70,
      height: 70,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.category_outlined,
        color: HomeAppColors.primary,
        size: 32,
      ),
    );
  }
}

class _HomeStoreCard extends StatelessWidget {
  final StoreModel store;
  const _HomeStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/HomeMarketPage?marketLink=${store.link}'),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── صورة الغلاف + بادج التقييم
                    SizedBox(
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _coverImage(),
                        ],
                      ),
                    ),

                    // ── مساحة التفاصيل (مع ترك فراغ للّوجو العائم)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 26, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  store.name,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    store.averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                  if (store.totalReviews > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${store.totalReviews})',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (store.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              store.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ── لوجو المتجر (floating) بين الغلاف والنص
                Positioned(
                  top: 120 - 24,
                  right: 14,
                  child: _LogoBadge(logoUrl: store.logoUrl, size: 48),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverImage() {
    final url = store.coverUrl;
    if (url == null || url.isEmpty) return _storeIcon();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: HomeAppColors.background,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HomeAppColors.primary,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _storeIcon(),
    );
  }

  Widget _storeIcon() {
    return Container(
      height: 120,
      width: double.infinity,
      color: HomeAppColors.background,
      child: const Center(
        child: Icon(
          Icons.store_outlined,
          size: 48,
          color: HomeAppColors.primary,
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final String? logoUrl;
  final double size;
  const _LogoBadge({required this.logoUrl, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: (logoUrl != null &&
                logoUrl!.isNotEmpty &&
                (logoUrl!.startsWith('http://') ||
                    logoUrl!.startsWith('https://')))
            ? CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: HomeAppColors.primary,
                ),
              )
            : const Icon(
                Icons.storefront_rounded,
                size: 18,
                color: HomeAppColors.primary,
              ),
      ),
    );
  }
}

