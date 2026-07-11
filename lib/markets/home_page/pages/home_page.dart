import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/markets/grid_of_categories/ViewModel/ViewModel.dart';
import 'package:bazar_suez/markets/grid_of_categories/Model/model.dart';
import 'package:bazar_suez/markets/Markets_after_category/service/category_store_service.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/instashop_store_card.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_service.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_settings.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

import '../../cart/viewmodels/cart_view_model.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';
import '../../saved_locations/widgets/saved_locations_sheet.dart';
import '../../../authentication/guards/AuthGuard.dart';
import '../../../ads/models/ad_model.dart';
import '../../../notifications/widgets/inbox_badge.dart';

class HomeAppColors {
  static const primary = Color(0xFF4E99B4);
  static const primaryDark = Color(0xFF4E99B4);
  static const primaryLight = Color(0xFF5BA8E8);
  static const accent = Color(0xFF4CBBF5);
  static const background = Color.fromARGB(255, 255, 255, 255);
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
  List<StoreModel> _topSellingStores = [];
  bool _loadingTopStores = true;
  final CategoryStoreService _storeService = CategoryStoreService();
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  DeliveryFeeSettings? _deliverySettings;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late final PageController _bannerCtrl =
      PageController(viewportFraction: 0.93);
  late Timer _bannerTimer;

  Future<void> _selectCategory(String categoryId) async {
    setState(() => _selectedCategoryId = categoryId);
    if (!mounted) return;
    context.push('/CategoryMarketPage?categoryId=$categoryId');
  }

  Future<void> _loadTopSellingStores() async {
    try {
      final stores = await _storeService.getAllStores();
      final activeStores = stores
          .where((s) => s.isVisible && s.storeStatus)
          .toList()
        ..sort(
          (a, b) => b.completedOrderCount.compareTo(a.completedOrderCount),
        );
      if (mounted) {
        setState(() {
          _topSellingStores = activeStores.take(5).toList();
          _loadingTopStores = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTopStores = false);
    }
  }

  Future<void> _loadDeliverySettings() async {
    try {
      final settings = await _deliveryFeeService.getSettings();
      if (mounted) setState(() => _deliverySettings = settings);
    } catch (_) {
      if (mounted) {
        setState(() => _deliverySettings = DeliveryFeeSettings.defaults());
      }
    }
  }

  Widget _buildTopSellingStoreCard(
    StoreModel store,
    SavedLocationsViewModel locationVm,
  ) {
    int? deliveryTime;
    double? deliveryFee;

    if (locationVm.activeLocation != null &&
        store.location != null &&
        _deliverySettings != null) {
      final distanceKm = DeliveryFeeService.calculateDistanceFromGeoPoints(
        locationVm.activeLocation!,
        store.location!,
      );
      deliveryTime = DeliveryFeeService.calculateDeliveryTime(distanceKm);
      deliveryFee = _deliveryFeeService.calculateDeliveryFee(
        distanceKm,
        _deliverySettings!,
      );
    }

    return InstashopStoreCard(
      store: store,
      deliveryTimeMin: deliveryTime,
      deliveryFee: deliveryFee,
      onTap: () => context.push('/HomeMarketPage?marketLink=${store.link}'),
    );
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
    _loadTopSellingStores();
    _loadDeliverySettings();

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
                  _buildBannerSection(),
                  const ServiceProvidersSection(),
                  ModernCategoriesSection(
                    selectedCategoryId: _selectedCategoryId,
                    onCategorySelected: _selectCategory,
                  ),
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
    if (FirebaseAuth.instance.currentUser != null) {
      _showSavedLocationsSheet();
      return;
    }
    showAuthBottomSheet(
      context,
      message: 'سجّل دخولك لحفظ عناوين التوصيل وتحديد موقعك',
      onAuthenticated: _showSavedLocationsSheet,
    );
  }

  void _showSavedLocationsSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SavedLocationsSheet(),
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
                                  locationVm.isInitializing ||
                                  locationVm.isLoading;

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
                                      constraints: const BoxConstraints(
                                        maxWidth: 180,
                                      ),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              locationVm
                                                  .locationPermissionDenied
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                            onTap: () {
                              pushIfAuthed(
                                context,
                                '/CartPage',
                                message: 'سجّل دخولك لعرض سلة المشتريات',
                              );
                            },
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
      padding: const EdgeInsets.fromLTRB(
        _InstashopMetrics.horizontalPadding,
        14,
        _InstashopMetrics.horizontalPadding,
        0,
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('app_settings')
            .doc('home_ads')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final rawAds = (data?['ads'] is List)
              ? (data?['ads'] as List)
              : const [];

          final ads =
              rawAds
                  .map(
                    (e) =>
                        e is Map<String, dynamic> ? AdModel.fromMap(e) : null,
                  )
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

          final bannerHeight =
              MediaQuery.sizeOf(context).height *
              _InstashopMetrics.bannerHeightRatio;

          return Column(
            children: [
              SizedBox(
                height: bannerHeight,
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
                          ? () => pushIfAuthed(
                              context,
                              '/request-ads',
                              message: 'سجّل دخولك لطلب إعلانات لمتجرك',
                            )
                          : () => pushIfAuthed(
                              context,
                              '/pricingpage',
                              message:
                                  'سجّل دخولك لإنشاء متجرك والاشتراك في باقة',
                            );
                      return _BannerCard(
                        image: AssetImage(assetPath),
                        onTap: onTap,
                      );
                    }

                    final ad = ads[i - 1];
                    return _BannerCard(
                      image: NetworkImage(ad.imageUrl!),
                      onTap: () => _handleAdTap(context, ad),
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

  void _handleAdTap(BuildContext context, AdModel ad) {
    final targetId = ad.targetStoreId;
    switch (ad.effectiveTargetType) {
      case AdTargetType.imageOnly:
        if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
          _showZoomedImage(context, ad.imageUrl!);
        }
      case AdTargetType.craftsman:
        if (targetId != null && targetId.isNotEmpty) {
          context.push('/craftsman/$targetId');
        }
      case AdTargetType.store:
      default:
        if (targetId != null && targetId.isNotEmpty) {
          context.push('/HomeMarketPage?marketLink=$targetId');
        }
    }
  }

  void _showZoomedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashSaleSection() {
    final locationVm = context.watch<SavedLocationsViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InstashopSectionHeader(
            title: 'الأكثر مبيعاً',
            topSpacing: 4,
          ),
          if (_loadingTopStores)
            const SizedBox(
              height: 240,
              child: Center(
                child: CircularProgressIndicator(
                  color: HomeAppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_topSellingStores.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'لا توجد متاجر حالياً',
                  style: TextStyle(
                    color: HomeAppColors.textMed,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 248,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: _topSellingStores.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => SizedBox(
                  width: MediaQuery.sizeOf(ctx).width * 0.82,
                  child: _buildTopSellingStoreCard(
                    _topSellingStores[i],
                    locationVm,
                  ),
                ),
              ),
            ),
        ],
      ),
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
        InboxBadge(
          child: GestureDetector(
            onTap: () => context.push('/inbox'),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_InstashopMetrics.bannerRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_InstashopMetrics.bannerRadius),
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

// ─── Service provider model ───────────────────────────────────────────────────
class ServiceProviderCategory {
  final String id;
  final String name;
  final String nameEn;
  final IconData icon;
  final List<Color> gradient;

  const ServiceProviderCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.icon,
    required this.gradient,
  });
}

const List<ServiceProviderCategory> kServiceCategories = [
  ServiceProviderCategory(
    id: 'plumber',
    name: 'سباكة',
    nameEn: 'Plumbing',
    icon: Icons.plumbing_rounded,
    gradient: [Color(0xFF4E99B4), Color(0xFF2D7A96)],
  ),
  ServiceProviderCategory(
    id: 'electric',
    name: 'كهرباء',
    nameEn: 'Electric',
    icon: Icons.electric_bolt_rounded,
    gradient: [Color(0xFFFFB347), Color(0xFFFF7043)],
  ),
  ServiceProviderCategory(
    id: 'satellite',
    name: 'دش',
    nameEn: 'Satellite',
    icon: Icons.satellite_alt_rounded,
    gradient: [Color(0xFF667EEA), Color(0xFF764BA2)],
  ),
  ServiceProviderCategory(
    id: 'teacher',
    name: 'مدرسين',
    nameEn: 'Tutors',
    icon: Icons.school_rounded,
    gradient: [Color(0xFF11998E), Color(0xFF38EF7D)],
  ),
  ServiceProviderCategory(
    id: 'painter',
    name: 'دهان',
    nameEn: 'Painting',
    icon: Icons.format_paint_rounded,
    gradient: [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
  ),
  ServiceProviderCategory(
    id: 'ac',
    name: 'تكييف',
    nameEn: 'AC Repair',
    icon: Icons.ac_unit_rounded,
    gradient: [Color(0xFF43CEA2), Color(0xFF185A9D)],
  ),
  ServiceProviderCategory(
    id: 'carpenter',
    name: 'نجارة',
    nameEn: 'Carpentry',
    icon: Icons.handyman_rounded,
    gradient: [Color(0xFFF953C6), Color(0xFFB91D73)],
  ),
  ServiceProviderCategory(
    id: 'cleaning',
    name: 'تنظيف',
    nameEn: 'Cleaning',
    icon: Icons.cleaning_services_rounded,
    gradient: [Color(0xFF0F2027), Color(0xFF2C5364)],
  ),
];

// ─── Instashop category grid metrics (reverse-engineered from reference UI) ───
class _InstashopMetrics {
  static const double horizontalPadding = 20;
  static const int crossAxisCount = 3;
  static const double crossAxisSpacing = 8;
  static const double mainAxisSpacing = 28;
  static const double imageFillRatio = 0.88;
  static const double labelGap = 10;
  static const double labelFontSize = 13;
  static const double labelLineHeight = 1.25;
  static const int labelMaxLines = 2;
  static const double labelAreaHeight = 34;
  static const int categoriesPerScrollPage = 6;
  static const int serviceProviderVisibleCount = 4;
  static const double serviceSpacing = 4;
  static const String categoryLabelFont = 'IBMPlexSansArabic';
  static const double bannerHeightRatio = 0.20;
  static const double bannerRadius = 16;
  static const double sectionTopSpacing = 10;
  static const double sectionHeaderBottom = 6;
  static const double sectionAfterCategories = 2;

  final double screenWidth;

  const _InstashopMetrics(this.screenWidth);

  factory _InstashopMetrics.of(BuildContext context) =>
      _InstashopMetrics(MediaQuery.sizeOf(context).width);

  double get gridWidth => screenWidth - horizontalPadding * 2;

  double get cellWidth =>
      (gridWidth - crossAxisSpacing * (crossAxisCount - 1)) / crossAxisCount;

  double get imageSize => cellWidth * imageFillRatio;

  double get imageSlotHeight => imageSize;

  double get itemHeight => imageSlotHeight + labelGap + labelAreaHeight;

  double get serviceCellWidth =>
      (gridWidth - serviceSpacing * (serviceProviderVisibleCount - 1)) /
      serviceProviderVisibleCount;

  double get serviceImageSize => serviceCellWidth * imageFillRatio;

  double get serviceItemHeight =>
      serviceImageSize + labelGap + labelAreaHeight;

  int rowCountFor(int itemCount) =>
      (itemCount / crossAxisCount).ceil().clamp(1, 99);

  double gridHeightFor(int itemCount) {
    final rows = rowCountFor(itemCount);
    return itemHeight * rows + mainAxisSpacing * (rows - 1);
  }

  double get gridHeight => gridHeightFor(categoriesPerScrollPage);

  double get sectionTitleSize => 20;
  double get seeAllSize => 13;
}

class _InstashopSectionStyles {
  static TextStyle title(double size) => TextStyle(
        color: const Color(0xFF1A1A1A),
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        fontFamily: 'NotoSansArabic',
      );

  static TextStyle seeAll(double size) => TextStyle(
        color: HomeAppColors.primary,
        fontSize: size,
        fontWeight: FontWeight.w600,
        fontFamily: 'NotoSansArabic',
      );

  static TextStyle categoryLabel({
    required bool isSelected,
  }) =>
      TextStyle(
        color: isSelected ? HomeAppColors.primary : const Color(0xFF262626),
        fontSize: _InstashopMetrics.labelFontSize,
        fontWeight: FontWeight.w700,
        height: _InstashopMetrics.labelLineHeight,
        fontFamily: _InstashopMetrics.categoryLabelFont,
      );
}

class _InstashopSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final double topSpacing;

  const _InstashopSectionHeader({
    required this.title,
    this.onSeeAll,
    this.topSpacing = _InstashopMetrics.sectionTopSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _InstashopMetrics.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _InstashopMetrics.horizontalPadding,
        topSpacing,
        _InstashopMetrics.horizontalPadding,
        _InstashopMetrics.sectionHeaderBottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _InstashopSectionStyles.title(metrics.sectionTitleSize),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'عرض الكل',
                style: _InstashopSectionStyles.seeAll(metrics.seeAllSize),
              ),
            ),
        ],
      ),
    );
  }
}

// Ground shadow classes removed as shadows are now embedded inside image assets.

class ModernCategoriesSection extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const ModernCategoriesSection({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryViewModel>(
      builder: (context, vm, _) {
        if (!vm.hasLoaded && !vm.isLoading) {
          Future.microtask(() => vm.fetchCategories());
        }

        return ColoredBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InstashopSectionHeader(
                title: 'الفئات',
                onSeeAll: () => context.push('/CategoriesGrid'),
              ),
              if (vm.isLoading)
                SizedBox(
                  height: _InstashopMetrics.of(context).gridHeight,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: HomeAppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (vm.categories.isEmpty)
                const SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'لا توجد فئات',
                      style: TextStyle(color: Color(0xFF9AAAC0)),
                    ),
                  ),
                )
              else
                _CategoriesGridWithScroll(
                  categories: vm.categories
                      .where((cat) => CategoryModel.isVisibleOnHomePage(cat.name))
                      .toList(),
                  selectedCategoryId: selectedCategoryId,
                  onCategorySelected: onCategorySelected,
                ),
              const SizedBox(height: _InstashopMetrics.sectionAfterCategories),
            ],
          ),
        );
      },
    );
  }
}

// ── 6 per scroll page (3×2) — all store categories ──────────────────────────
class _CategoriesGridWithScroll extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const _CategoriesGridWithScroll({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  Widget _buildPageGrid(
    _InstashopMetrics metrics,
    List<CategoryModel> pageItems,
  ) {
    final rows = <Widget>[];

    for (var i = 0; i < pageItems.length; i += _InstashopMetrics.crossAxisCount) {
      final end = (i + _InstashopMetrics.crossAxisCount < pageItems.length)
          ? i + _InstashopMetrics.crossAxisCount
          : pageItems.length;
      final rowItems = pageItems.sublist(i, end);

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < _InstashopMetrics.crossAxisCount; j++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: j == 0 ? 0 : _InstashopMetrics.crossAxisSpacing / 2,
                      right: j == _InstashopMetrics.crossAxisCount - 1
                          ? 0
                          : _InstashopMetrics.crossAxisSpacing / 2,
                    ),
                    child: j < rowItems.length
                        ? _InstashopCategoryTile(
                            metrics: metrics,
                            category: rowItems[j],
                            isSelected:
                                selectedCategoryId == rowItems[j].id,
                            onTap: () => onCategorySelected(rowItems[j].id),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      );

      if (end < pageItems.length) {
        rows.add(const SizedBox(height: _InstashopMetrics.mainAxisSpacing));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  List<List<CategoryModel>> _chunkPages(List<CategoryModel> items) {
    const pageSize = _InstashopMetrics.categoriesPerScrollPage;
    final pages = <List<CategoryModel>>[];
    for (var i = 0; i < items.length; i += pageSize) {
      final end = (i + pageSize < items.length) ? i + pageSize : items.length;
      pages.add(items.sublist(i, end));
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _InstashopMetrics.of(context);
    final pages = _chunkPages(categories);
    final pageHeight = metrics.gridHeight;

    if (pages.length <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _InstashopMetrics.horizontalPadding,
        ),
        child: _buildPageGrid(metrics, pages.first),
      );
    }

    return SizedBox(
      height: pageHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: _InstashopMetrics.horizontalPadding,
        ),
        itemCount: pages.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: _InstashopMetrics.crossAxisSpacing),
        itemBuilder: (ctx, pageIndex) {
          return SizedBox(
            width: metrics.gridWidth,
            child: _buildPageGrid(metrics, pages[pageIndex]),
          );
        },
      ),
    );
  }
}

// ── Instashop-style category tile: floating PNG on white ─────────────────────
class _InstashopCategoryTile extends StatelessWidget {
  final _InstashopMetrics metrics;
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _InstashopCategoryTile({
    required this.metrics,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = isSelected ? metrics.imageSize * 1.04 : metrics.imageSize;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: metrics.imageSlotHeight,
            width: double.infinity,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: imageSize,
                height: imageSize,
                child: _CategoryPngImage(
                  icon: category.icon,
                  size: imageSize,
                ),
              ),
            ),
          ),
          const SizedBox(height: _InstashopMetrics.labelGap),
          Text(
            category.name,
            style: _InstashopSectionStyles.categoryLabel(
              isSelected: isSelected,
            ),
            textAlign: TextAlign.center,
            maxLines: _InstashopMetrics.labelMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CategoryPngImage extends StatelessWidget {
  final String icon;
  final double size;

  const _CategoryPngImage({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.category_rounded,
      color: HomeAppColors.primary,
      size: size * 0.48,
    );

    if (icon.isEmpty) return fallback;

    if (icon.startsWith('http://') || icon.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: icon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: size * 0.28,
            height: size * 0.28,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: HomeAppColors.primary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    final path = icon.startsWith('assets/')
        ? icon
        : 'assets/images/categories/$icon';
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGET 2 — Service Providers Section
// ═════════════════════════════════════════════════════════════════════════════

class ServiceProvidersSection extends StatelessWidget {
  const ServiceProvidersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = _InstashopMetrics.of(context);

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InstashopSectionHeader(
            title: 'مزودو الخدمات',
            onSeeAll: () => context.push('/craftsmen'),
          ),
          SizedBox(
            height: metrics.serviceItemHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: _InstashopMetrics.horizontalPadding,
              ),
              itemCount: kServiceCategories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: _InstashopMetrics.serviceSpacing),
              itemBuilder: (ctx, i) => SizedBox(
                width: metrics.serviceCellWidth,
                child: _ServiceProviderTile(
                  imageSize: metrics.serviceImageSize,
                  service: kServiceCategories[i],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Service provider tile — same Instashop proportions as store categories ─────
class _ServiceProviderTile extends StatelessWidget {
  final double imageSize;
  final ServiceProviderCategory service;

  const _ServiceProviderTile({
    required this.imageSize,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/craftsmen?category=${service.id}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: imageSize,
            width: double.infinity,
            child: Center(
              child: Icon(
                service.icon,
                color: service.gradient.first,
                size: imageSize * 0.52,
              ),
            ),
          ),
          const SizedBox(height: _InstashopMetrics.labelGap),
          Text(
            service.name,
            style: _InstashopSectionStyles.categoryLabel(isSelected: false),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
