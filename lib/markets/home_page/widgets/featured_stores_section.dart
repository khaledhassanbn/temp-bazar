import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_data_provider.dart';

class FeaturedStoresSection extends StatelessWidget {
  const FeaturedStoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    final homeData = context.watch<HomeDataProvider>();

    if (homeData.isLoadingFeatured) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (homeData.featuredStores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'مختارات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: homeData.featuredStores.length,
            itemBuilder: (context, index) {
              return _buildStoreCard(
                context,
                homeData.featuredStores[index],
                homeData,
                index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    FeaturedStoreResult result,
    HomeDataProvider homeData,
    int index,
  ) {
    final isFavourite = homeData.favouriteStoreIds.contains(result.store.id);

    return GestureDetector(
      onTap: () {
        context.push('/HomeMarketPage?marketLink=${result.store.link}');
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
            /// ================== الصورة ==================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: result.store.coverUrl?.isNotEmpty == true
                        ? Image.network(
                            result.store.coverUrl!,
                            fit: BoxFit.fill,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),

                /// اللوجو
                if (result.store.logoUrl?.isNotEmpty == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          result.store.logoUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                /// القلب + التقييم
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            homeData.toggleFavourite(result.store.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavourite ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              result.store.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${result.store.totalReviews})',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// ================== المعلومات ==================
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// الاسم + إعلان
                  Row(
                    children: [
                      Text(
                        result.store.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color.fromARGB(255, 196, 196, 196),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'إعلان',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color.fromARGB(255, 169, 169, 169),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// الوصف
                  if (result.store.description.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        result.store.description,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (result.deliveryFee != null)
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining, size: 14),
                            const SizedBox(width: 4),
                            Text(result.deliveryFeeText,
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      if (result.deliveryTimeMinutes != null)
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14),
                            const SizedBox(width: 4),
                            Text(result.deliveryTimeText,
                                style: const TextStyle(fontSize: 11)),
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
      child: const Center(
        child: Icon(Icons.store, size: 40, color: Colors.grey),
      ),
    );
  }
}
