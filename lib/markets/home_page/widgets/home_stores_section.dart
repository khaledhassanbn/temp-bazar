import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../../grid_of_categories/Model/model.dart';
import '../../grid_of_categories/ViewModel/ViewModel.dart';
import '../../Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import '../../create_market/models/store_model.dart';
import 'home_store_card.dart';

/// ويدجت لعرض المتاجر في الصفحة الرئيسية
/// - إذا تم اختيار فئة → عرض متاجر الفئة المختارة
/// - إذا لم يتم اختيار فئة → عرض كل الفئات مع متاجرها
class HomeStoresSection extends StatelessWidget {
  const HomeStoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryVm = context.watch<CategoryViewModel>();
    final filterVm = context.watch<CategoryFilterViewModel>();

    // إذا تم اختيار فئة معينة
    if (filterVm.selectedCategoryId != null) {
      return _buildSelectedCategorySection(context, filterVm, categoryVm);
    }

    // إذا لم يتم اختيار فئة
    return _buildAllCategoriesSections(context, filterVm, categoryVm);
  }

  /// عرض الفئة المختارة فقط مع متاجرها
  Widget _buildSelectedCategorySection(
    BuildContext context,
    CategoryFilterViewModel filterVm,
    CategoryViewModel categoryVm,
  ) {
    // البحث عن اسم الفئة
    final category = categoryVm.categories.firstWhere(
      (c) => c.id == filterVm.selectedCategoryId,
      orElse: () => CategoryModel(id: '', name: 'غير معروف', order: 0, icon: ''),
    );

    if (filterVm.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final stores = filterVm.stores;

    if (stores.isEmpty) {
      return _buildEmptyState(category.name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader(
          context,
          title: category.name,
          onSeeAll: () {
            context.go('/FoodHomePage?categoryId=${filterVm.selectedCategoryId}');
          },
        ),
        const SizedBox(height: 12),
        // Grid of stores
        _buildStoresGrid(stores),
      ],
    );
  }

  /// عرض كل الفئات مع متاجرها
  Widget _buildAllCategoriesSections(
    BuildContext context,
    CategoryFilterViewModel filterVm,
    CategoryViewModel categoryVm,
  ) {
    if (filterVm.isLoadingCategoryStores) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: categoryVm.categories.map((category) {
        final stores = filterVm.categoryStoresMap[category.id] ?? [];

        // تخطي الفئات الفارغة
        if (stores.isEmpty) return const SizedBox.shrink();

        return _buildCategorySection(context, category, stores);
      }).toList(),
    );
  }

  /// Section لفئة واحدة مع متاجرها
  Widget _buildCategorySection(
    BuildContext context,
    CategoryModel category,
    List stores,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildSectionHeader(
          context,
          title: category.name,
          onSeeAll: () {
            context.go('/FoodHomePage?categoryId=${category.id}');
          },
        ),
        const SizedBox(height: 12),
        // Horizontal list of stores
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stores.length > 8 ? 8 : stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return HomeStoreCard(
                store: store,
                discount: index % 3 == 0 ? '${(index + 1) * 5}%' : null,
                deliveryInfo: 'توصيل سريع',
              ).animate().fadeIn(
                    duration: 300.ms,
                    delay: (index * 50).ms,
                  );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Header للقسم
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mainColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اظهار الكل',
                  style: TextStyle(
                    color: AppColors.mainColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.mainColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grid للمتاجر
  Widget _buildStoresGrid(List<StoreModel> stores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: stores.length > 12 ? 12 : stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          return _buildGridStoreCard(context, store, index);
        },
      ),
    );
  }

  /// كارت المتجر في الشبكة
  Widget _buildGridStoreCard(BuildContext context, StoreModel store, int index) {
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المتجر
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                          ? Image.network(
                              store.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),
                  // شارة الخصم
                  if (index % 4 == 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'خصم ${(index + 1) * 5}%',
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
            // معلومات المتجر
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          store.averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (store.totalReviews > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${store.totalReviews})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Icon(Icons.delivery_dining, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'سريع',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(
            duration: 300.ms,
            delay: (index * 50).ms,
            begin: const Offset(0.9, 0.9),
            end: const Offset(1, 1),
          ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.store, size: 40, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildEmptyState(String categoryName) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد متاجر في $categoryName',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
