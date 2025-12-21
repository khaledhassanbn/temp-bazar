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
import '../widgets/home_auto_scrolling_ads.dart';
import '../widgets/home_categories_stores_section.dart';
import '../widgets/best_rated_stores_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 🔹 تحميل الفئات عند فتح الصفحة
    Future.microtask(() async {
      final categoryVm = Provider.of<CategoryViewModel>(context, listen: false);
      final filterVm = Provider.of<CategoryFilterViewModel>(context, listen: false);
      
      await categoryVm.fetchCategories();
      
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // المحتوى الرئيسي
            categoryViewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      // =======================================================================
                      // 🔹 SliverAppBar - تصميم مثل Talabat (برتقالي)
                      // =======================================================================
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: true,
                        expandedHeight: 120,
                        collapsedHeight: 120,
                        backgroundColor: AppColors.mainColor,
                        elevation: 0,
                        surfaceTintColor: AppColors.mainColor,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            color: AppColors.mainColor,
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ---------------------------------------------------------------
                                    // 🔹 عنوان التوصيل + أيقونة السلة
                                    // ---------------------------------------------------------------
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: LocationAppBarWidget(),
                                        ),
                                        // أيقونة السلة
                                        GestureDetector(
                                          onTap: () => context.go('/CartPage'),
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.shopping_cart_outlined,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                              if (cartViewModel.itemCount > 0)
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
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                    child: Text(
                                                      '${cartViewModel.itemCount}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 10),
                                    
                                    // ---------------------------------------------------------------
                                    // 🔹 شريط البحث (أبيض على الخلفية البرتقالية)
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
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.search,
                                              color: Colors.grey[500],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "ابحث عن منتج أو متجر...",
                                                style: TextStyle(
                                                  color: Colors.grey[500],
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

                            // 🔹 إعلانات متحركة
                            const HomeAutoScrollingAds(),

                            const SizedBox(height: 24),

                            // ===================================================================
                            // 🔹 أفضل المطاعم تصنيفاً
                            // ===================================================================
                            const BestRatedStoresSection(),

                            const SizedBox(height: 24),

                            // ===================================================================
                            // 🔹 الأقسام داخل الفئات
                            // ===================================================================
                            const HomeCategoriesStoresSection(),

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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: AppColors.mainColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'أين تريد التوصيل؟',
                  style: TextStyle(
                    fontSize: 20,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
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
