import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../cart/viewmodels/cart_view_model.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';
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
  final LicenseService _licenseService = LicenseService();
  StoreModel? _myStore;
  bool _licenseLoading = false;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    searchController.dispose();
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
        backgroundColor: const Color(0xFFF8F9FA),
        body: Stack(
          children: [
            // المحتوى الرئيسي
            categoryViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // =======================================================================
                      // 🔹 SliverAppBar - تصميم حديث
                      // =======================================================================
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: true,
                        expandedHeight: 130,
                        collapsedHeight: 130,
                        backgroundColor: AppColors.mainColor,
                        elevation: 0,
                        surfaceTintColor: AppColors.mainColor,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.mainColor,
                                  AppColors.mainColor.withOpacity(0.9),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ---------------------------------------------------------------
                                    // 🔹 عنوان التوصيل + أيقونات
                                    // ---------------------------------------------------------------
                                    Row(
                                      children: [
                                        // عنوان التوصيل
                                        const Expanded(
                                          child: LocationAppBarWidget(),
                                        ),
                                        // أيقونة السلة (على اليسار)
                                        _buildIconButton(
                                          icon: Icons.shopping_cart_outlined,
                                          badgeCount: cartViewModel.itemCount,
                                          onTap: () => context.go('/CartPage'),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // ---------------------------------------------------------------
                                    // 🔹 شريط البحث
                                    // ---------------------------------------------------------------
                                    GestureDetector(
                                      onTap: () {
                                        if (locationViewModel.hasLocation) {
                                          context.go('/Search');
                                        } else {
                                          _showLocationsSheet();
                                        }
                                      },
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
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 14),
                                            Icon(
                                              Icons.search,
                                              color: Colors.grey[400],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "ابحث عن متجر أو منتج ...",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
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
