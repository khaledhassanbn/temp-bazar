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
import '../widgets/home_promotional_banner.dart';
import '../widgets/home_categories_icons.dart';
import '../widgets/home_stores_section.dart';
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
  bool _showHeader = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // 🔹 تحميل حالة الترخيص فوراً (بشكل مستقل)
    _loadLicenseStatus();

    // 🔹 تحميل الفئات عند فتح الصفحة
    Future.microtask(() async {
      if (!mounted) return;
      final categoryVm = Provider.of<CategoryViewModel>(context, listen: false);
      final filterVm = Provider.of<CategoryFilterViewModel>(context, listen: false);
      
      await categoryVm.fetchCategories();
      if (!mounted) return;
      
      // Load stores for all categories for home page display
      if (categoryVm.categories.isNotEmpty) {
        final categoryIds = categoryVm.categories.map((c) => c.id).toList();
        await filterVm.fetchStoresForAllCategories(categoryIds, limit: 8);
      }
    });
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    if (offset > _lastOffset && _showHeader) {
      setState(() => _showHeader = false);
    } else if (offset < _lastOffset && !_showHeader) {
      setState(() => _showHeader = true);
    }
    _lastOffset = offset;
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showLocationsSheet() {
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
                      // 🔹 SliverAppBar - تصميم حديث مع حركة السكرول (باستخدام Delegate)
                      // =======================================================================
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: HomeAppBarDelegate(
                          cartViewModel: cartViewModel,
                          locationViewModel: locationViewModel,
                          paddingTop: MediaQuery.of(context).padding.top,
                          onSearchTap: () {
                            if (locationViewModel.hasLocation) {
                              context.go('/Search');
                            } else {
                              _showLocationsSheet();
                            }
                          },
                        ),
                      ),

                      // =======================================================================
                      // 🔹 محتوى الصفحة
                      // =======================================================================
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            if (_myStore != null)
                              LicenseWarningBanner(store: _myStore!)
                                  .animate()
                                  .fadeIn(duration: 300.ms),

                            if (_myStore != null && (_myStore!.daysUntilExpiry <= 3 || _myStore!.isLicenseExpired))
                              const SizedBox(height: 12),

                            // 🔹 بانر العروض الترويجية
                            const HomePromotionalBanner()
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),

                            const SizedBox(height: 8),

                            // 🔹 أيقونات الفئات
                            const HomeCategoriesIcons()
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 100.ms),

                            const SizedBox(height: 8),

                            // 🔹 قسم المتاجر
                            const HomeStoresSection()
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 200.ms),

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

  /// بناء زر أيقونة
  Widget _buildIconButton({
    required IconData icon,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              left: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
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
        setState(() => _licenseLoading = false);
        return;
      }
      final store = await _licenseService.fetchStore(marketId);
      if (!mounted) return;
      setState(() {
        _myStore = store;
        _licenseLoading = false;
      });
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
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

/// كلاس مخصص للتحكم في شريط التطبيق المتحرك
class HomeAppBarDelegate extends SliverPersistentHeaderDelegate {
  final CartViewModel cartViewModel;
  final SavedLocationsViewModel locationViewModel;
  final VoidCallback onSearchTap;
  final double paddingTop;

  HomeAppBarDelegate({
    required this.cartViewModel,
    required this.locationViewModel,
    required this.onSearchTap,
    required this.paddingTop,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // حساب نسبة الظهور للعنوان
    // يختفي تدريجياً خلال أول 50 بكسل من السكرول
    final double titleOpacity = (1.0 - (shrinkOffset / 50)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainColor, // لون احتياطي
        gradient: LinearGradient(
          colors: [
            AppColors.mainColor,
            AppColors.mainColor.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. عنوان التوصيل وأيقونة السلة (في الأعلى)
          Positioned(
            top: paddingTop + 8, // مسافة من الـ Status Bar
            left: 16,
            right: 16,
            child: Opacity(
              opacity: titleOpacity,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    // عنوان التوصيل
                    const Expanded(
                      child: LocationAppBarWidget(),
                    ),
                    // أيقونة السلة
                    _buildCartIcon(context),
                  ],
                ),
              ),
            ),
          ),

          // 2. شريط البحث (في الأسفل دائماً)
          Positioned(
            bottom: 10,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: onSearchTap,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          ),
        ],
      ),
    );
  }

  // بناء أيقونة السلة داخلياً
  Widget _buildCartIcon(BuildContext context) {
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

  @override
  // أقصى ارتفاع: TopPadding + المسافة العلوية (8) + قسم العنوان (40) + فراغ (8) + البحث (46) + هامش سفلي (10)
  // المجموع = TopPadding + 112 تقريباً. لنقل 120 لضمان الراحة
  double get maxExtent => paddingTop + 120;

  @override
  // أقل ارتفاع: TopPadding + البحث (46) + هامش سفلي (10) + فراغ بسيط فوقه (8) = 64 تقريباً
  // أو بتبسيط: 80 بكسل شاملة الـ SafeArea وشريط البحث
  // لنجعلها: TopPadding + 70
  double get minExtent => paddingTop + 70;

  @override
  bool shouldRebuild(covariant HomeAppBarDelegate oldDelegate) {
    return oldDelegate.cartViewModel != cartViewModel ||
           oldDelegate.locationViewModel != locationViewModel ||
           oldDelegate.paddingTop != paddingTop;
  }
}
