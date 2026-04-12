import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../create_market/models/store_model.dart';
import '../viewmodels/home_data_provider.dart';

/// قسم أفضل المطاعم أو أشهر البقالات
class TopRatedStoresSection extends StatelessWidget {
  final String title;
  final bool isRestaurants; // true = مطاعم, false = بقالات

  const TopRatedStoresSection({
    super.key,
    required this.title,
    this.isRestaurants = true,
  });

  @override
  Widget build(BuildContext context) {
    final homeData = context.watch<HomeDataProvider>();

    final stores = isRestaurants
        ? homeData.topRatedRestaurants
        : homeData.topRatedGroceries;

    if (homeData.isLoadingTopRated) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان القسم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // قائمة المتاجر الأفقية
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              final store = stores[index];
              return _buildStoreCard(context, store, homeData, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    StoreModel store,
    HomeDataProvider homeData,
    int index,
  ) {
    final isFavourite = homeData.favouriteStoreIds.contains(store.id);

    return GestureDetector(
      onTap: () {
        context.push('/HomeMarketPage?marketLink=${store.link}');
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // صورة الغلاف مع لوجو المتجر
            Stack(
              children: [
                // صورة الغلاف
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: store.coverUrl != null && store.coverUrl!.isNotEmpty
                        ? Image.network(
                            store.coverUrl!,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                // لوجو المتجر في الأعلى
                if (store.logoUrl != null && store.logoUrl!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.network(
                          store.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.store,
                              size: 30,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // القلب والتقييم في الأعلى اليسار
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // القلب
                      GestureDetector(
                        onTap: () => homeData.toggleFavourite(store.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavourite ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // التقييم
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              store.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (store.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${store.totalReviews})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // معلومات المتجر
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم المتجر على اليمين
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // الوصف على اليمين
                  if (store.description.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        store.description,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // وقت التوصيل ومبلغ التوصيل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // مبلغ التوصيل
                      Row(
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.deliveryFee != null
                                ? '${store.deliveryFee!.toStringAsFixed(0)} جنيه'
                                : 'مجاني',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      // وقت التوصيل
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.deliveryTime != null
                                ? '${store.deliveryTime} دقيقة'
                                : '30-45 دقيقة',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms),
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
}
