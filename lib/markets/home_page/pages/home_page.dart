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

import '../widgets/top_rated_stores_section.dart';
import '../widgets/featured_stores_section.dart';
import '../../license/widgets/license_warning_banner.dart';
import '../../account/pages/account_page.dart';
import '../viewmodels/home_data_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // تحميل البيانات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  /// تحميل كل البيانات بالتوازي
  Future<void> _loadAllData() async {
    if (!mounted) return;

    final homeData = Provider.of<HomeDataProvider>(context, listen: false);
    final locationVm = Provider.of<SavedLocationsViewModel>(
      context,
      listen: false,
    );
    final categoryVm = Provider.of<CategoryViewModel>(context, listen: false);
    final filterVm = Provider.of<CategoryFilterViewModel>(
      context,
      listen: false,
    );

    // تحميل الفئات + بيانات الصفحة الرئيسية بالتوازي
    await Future.wait([
      homeData.loadHomeData(locationVm: locationVm),
      _loadCategories(categoryVm, filterVm),
    ]);
  }

  Future<void> _loadCategories(
    CategoryViewModel categoryVm,
    CategoryFilterViewModel filterVm,
  ) async {
    await categoryVm.fetchCategories();
    if (!mounted) return;

    if (categoryVm.categories.isNotEmpty) {
      final categoryIds = categoryVm.categories.map((c) => c.id).toList();
      await filterVm.fetchStoresForAllCategories(categoryIds, limit: 8);
    }
  }

  void _scrollListener() {
    if (!mounted) return;
    final offset = _scrollController.offset;
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
    final homeData = Provider.of<HomeDataProvider>(context);

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
                      // 🔹 SliverAppBar
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
                              Container(color: Colors.white),
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(25),
                                  bottomRight: Radius.circular(25),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      'assets/images/create_market.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(color: AppColors.mainColor),
                                    ),
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
                                  ],
                                ),
                              ),
                              Positioned(
                                top: MediaQuery.of(context).padding.top + 8,
                                right: 16,
                                left: 16,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: _isScrolled ? 0.0 : 1.0,
                                  child: IgnorePointer(
                                    ignoring: _isScrolled,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildCartIcon(
                                              context,
                                              cartViewModel,
                                            ),
                                            Expanded(
                                              child: LocationAppBarWidget(),
                                            ),
                                            _buildMenuIcon(context),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                        SizedBox(
                                          height:
                                              280 -
                                              (MediaQuery.of(
                                                    context,
                                                  ).padding.top +
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
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: _isScrolled
                            ? Row(
                                children: [
                                  _buildCartIcon(context, cartViewModel),
                                  const Spacer(),
                                  LocationAppBarWidget(),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      if (locationViewModel.hasLocation) {
                                        context.go('/Search');
                                      } else {
                                        _showLocationsSheet();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildMenuIcon(context),
                                ],
                              )
                            : null,
                      ),

                      // =======================================================================
                      // 🔹 محتوى الصفحة
                      // ==6=====================================================================
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            if (homeData.myStore != null)
                              LicenseWarningBanner(
                                store: homeData.myStore!,
                              ).animate().fadeIn(duration: 300.ms),

                            if (homeData.myStore != null &&
                                (homeData.myStore!.daysUntilExpiry <= 3 ||
                                    homeData.myStore!.isLicenseExpired))
                              const SizedBox(height: 12),

                            // 🔹 أيقونات الفئات
                            HomeCategoriesIcons().animate().fadeIn(
                              duration: 400.ms,
                              delay: 100.ms,
                            ),

                            // 🔹 المتاجر المختارة (مختارات)
                            FeaturedStoresSection().animate().fadeIn(
                              duration: 400.ms,
                              delay: 150.ms,
                            ),

                            const SizedBox(height: 16),

                            // 🔹 أفضل المطاعم
                            TopRatedStoresSection(
                              title: 'أفضل المطاعم',
                              isRestaurants: true,
                            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                            // 🔹 أشهر البقالات
                            TopRatedStoresSection(
                              title: 'أشهر البقالات',
                              isRestaurants: false,
                            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
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

  // بناء أيقونة القائمة (3 شرط)
  Widget _buildMenuIcon(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AccountPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.menu, color: Colors.white, size: 24),
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
