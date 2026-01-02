import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../cart/viewmodels/cart_view_model.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import '../../Markets_after_category/widget/search_bar_widget.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';
import '../../saved_locations/widgets/location_app_bar_widget.dart';
import '../../saved_locations/widgets/saved_locations_sheet.dart';
import '../widgets/home_categories_icons.dart';
import '../widgets/nearby_stores_section.dart';
import '../widgets/top_rated_stores_section.dart';
import '../widgets/featured_stores_section.dart';
import '../../license/services/license_service.dart';
import '../../license/widgets/license_warning_banner.dart';
import '../../create_market/models/store_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LicenseService _licenseService = LicenseService();
  StoreModel? _myStore;
  bool _licenseLoading = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 🔹 تحميل حالة الترخيص فوراً (بشكل مستقل)
    _loadLicenseStatus();

    // 🔹 تحميل الفئات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    final categoryVm = Provider.of<CategoryViewModel>(context, listen: false);
    final filterVm = Provider.of<CategoryFilterViewModel>(
      context,
      listen: false,
    );

    await categoryVm.fetchCategories();
    if (!mounted) return;

    // Load stores for all categories for home page display
    if (categoryVm.categories.isNotEmpty) {
      final categoryIds = categoryVm.categories.map((c) => c.id).toList();
      await filterVm.fetchStoresForAllCategories(categoryIds, limit: 8);
    }
  }

  void _scrollListener() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    // animation تدريجي: يبدأ الاختفاء عند 50 بكسل ويكتمل عند 150 بكسل
    final newScrolled = offset > 50;
    if (newScrolled != _isScrolled) {
      setState(() => _isScrolled = newScrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showLocationsSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SavedLocationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final cartViewModel = Provider.of<CartViewModel>(context);
    final locationViewModel = Provider.of<SavedLocationsViewModel>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // المحتوى الرئيسي
            categoryViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // =======================================================================
                      // 🔹 SliverAppBar - تصميم جديد مشابه لـ HungerStation
                      // =======================================================================
                      SliverAppBar(
                        expandedHeight: 280,
                        pinned: true,
                        backgroundColor: AppColors.mainColor,
                        collapsedHeight: 80,
                        toolbarHeight: 80,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              // صورة الخلفية
                              Image.asset(
                                'assets/images/create_market.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.mainColor),
                              ),
                              // طبقة تدرج لوني
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // محتوى AppBar
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 8,
                                right: 16,
                                left: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // عنوان التوصيل (في أقصى اليمين - يظهر أولاً في RTL)
                                        LocationAppBarWidget(),
                                        // أيقونة السلة على اليسار (تظهر آخراً في RTL)
                                        _buildCartIcon(context, cartViewModel),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // شريط البحث
                                    GestureDetector(
                                      onTap: () {
                                        if (locationViewModel.hasLocation) {
                                          context.go('/Search');
                                        } else {
                                          _showLocationsSheet();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
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
                                    // مساحة قابلة للنقر (خفية) تحت البحث حتى نهاية AppBar
                                    SizedBox(
                                      height:
                                          280 -
                                          (MediaQuery.of(context).padding.top +
                                              8 +
                                              40 +
                                              20 +
                                              46),
                                      child: GestureDetector(
                                        onTap: () {
                                          context.push('/request-ads');
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: _isScrolled
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // أيقونة البحث فقط
                                  GestureDetector(
                                    onTap: () {
                                      if (locationViewModel.hasLocation) {
                                        context.go('/Search');
                                      } else {
                                        _showLocationsSheet();
                                      }
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // عنوان التوصيل (في أقصى اليمين)
                                  LocationAppBarWidget(),
                                  const SizedBox(width: 8),
                                  _buildCartIcon(context, cartViewModel),
                                ],
                              )
                            : null,
                      ),

                      // =======================================================================
                      // 🔹 محتوى الصفحة
                      // =======================================================================
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            if (_myStore != null)
                              LicenseWarningBanner(
                                store: _myStore!,
                              ).animate().fadeIn(duration: 300.ms),

                            if (_myStore != null &&
                                (_myStore!.daysUntilExpiry <= 3 ||
                                    _myStore!.isLicenseExpired))
                              const SizedBox(height: 12),

                            // 🔹 أيقونات الفئات
                            const HomeCategoriesIcons().animate().fadeIn(
                              duration: 400.ms,
                              delay: 100.ms,
                            ),

                            const SizedBox(height: 16),

                            // 🔹 المتاجر المختارة (مختارات)
                            const FeaturedStoresSection().animate().fadeIn(
                              duration: 400.ms,
                              delay: 150.ms,
                            ),

                            const SizedBox(height: 24),

                            // 🔹 المتاجر القريبة منك
                            const NearbyStoresSection().animate().fadeIn(
                              duration: 400.ms,
                              delay: 200.ms,
                            ),

                            const SizedBox(height: 24),

                            // 🔹 أفضل المطاعم
                            const TopRatedStoresSection(
                              title: 'أفضل المطاعم',
                              isRestaurants: true,
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                            const SizedBox(height: 24),

                            // 🔹 أشهر البقالات
                            const TopRatedStoresSection(
                              title: 'أشهر البقالات',
                              isRestaurants: false,
                            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),

            // =======================================================================
            // 🔹 طبقة الحجب عند عدم تحديد الموقع
            // =======================================================================
            if (!locationViewModel.hasLocation && !locationViewModel.isLoading)
              _buildLocationBlockingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartIcon(BuildContext context, CartViewModel cartViewModel) {
    return InkWell(
      onTap: () => context.go('/CartPage'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
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
            if (cartViewModel.itemCount > 0)
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
                    '${cartViewModel.itemCount}',
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
    );
  }

  Future<void> _loadLicenseStatus() async {
    if (_licenseLoading) return;
    if (!mounted) return;
    setState(() => _licenseLoading = true);
    try {
      final marketId = await _licenseService.resolveCurrentUserMarketId();
      if (!mounted) return;
      if (marketId == null) {
        if (mounted) {
          setState(() => _licenseLoading = false);
        }
        return;
      }
      final store = await _licenseService.fetchStore(marketId);
      if (!mounted) return;
      if (mounted) {
        setState(() {
          _myStore = store;
          _licenseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _licenseLoading = false);
      }
    }
  }

  /// طبقة الحجب عند عدم تحديد الموقع
  Widget _buildLocationBlockingOverlay() {
    return GestureDetector(
      onTap: _showLocationsSheet,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor,
                        AppColors.mainColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'أين تريد التوصيل؟',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'حدد موقعك لنعرض لك المتاجر القريبة منك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showLocationsSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'اختر الموقع',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
