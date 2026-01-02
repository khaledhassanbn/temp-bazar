import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/featured_stores_service.dart';
import '../../favourite_markets/services/favourite_markets_service.dart';

/// قسم المتاجر المختارة (المتاجر التي لها إعلانات نشطة)
class FeaturedStoresSection extends StatefulWidget {
  const FeaturedStoresSection({super.key});

  @override
  State<FeaturedStoresSection> createState() => _FeaturedStoresSectionState();
}

class _FeaturedStoresSectionState extends State<FeaturedStoresSection> {
  final FeaturedStoresService _service = FeaturedStoresService();
  final FavouriteMarketsService _favouriteService = FavouriteMarketsService();
  List<FeaturedStoreResult> _stores = [];
  Set<String> _favouriteStoreIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedStores();
    _loadFavouriteStores();
  }

  Future<void> _loadFeaturedStores() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stores = await _service.getFeaturedStores(limit: 10);
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في جلب المتاجر المختارة: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavouriteStores() async {
    try {
      final favourites = await _favouriteService.getFavouriteMarkets();
      if (!mounted) return;
      setState(() {
        _favouriteStoreIds = favourites.map((f) => f.marketId).toSet();
      });
    } catch (e) {
      print('خطأ في جلب المتاجر المفضلة: $e');
    }
  }

  Future<void> _toggleFavourite(String marketId) async {
    final isFavourite = _favouriteStoreIds.contains(marketId);

    if (isFavourite) {
      await _favouriteService.removeFavouriteMarket(marketId);
    } else {
      await _favouriteService.addFavouriteMarket(marketId);
    }

    if (!mounted) return;
    await _loadFavouriteStores();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
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
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemCount: _stores.length,
            itemBuilder: (context, index) {
              final result = _stores[index];
              return _buildStoreCard(result, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(FeaturedStoreResult result, int index) {
    final isFavourite = _favouriteStoreIds.contains(result.store.id);

    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        context.push('/HomeMarketPage?marketLink=${result.store.link}');
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // صورة الغلاف مع لوجو المتجر
            Stack(
              children: [
                // صورة الغلاف
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child:
                        result.store.coverUrl != null &&
                            result.store.coverUrl!.isNotEmpty
                        ? Image.network(
                            result.store.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                // لوجو المتجر في الأعلى
                if (result.store.logoUrl != null &&
                    result.store.logoUrl!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Stack(
                      children: [
                        Container(
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
                              result.store.logoUrl!,
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
                      ],
                    ),
                  ),
                // شارة "إعلان" في أسفل يسار الصورة
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'إعلان',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        onTap: () => _toggleFavourite(result.store.id),
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
                              result.store.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (result.store.totalReviews > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${result.store.totalReviews})',
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
                      result.store.name,
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
                  if (result.store.description.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        result.store.description,
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
                      if (result.deliveryFee != null)
                        Row(
                          children: [
                            Icon(
                              Icons.delivery_dining,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.deliveryFeeText,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      // وقت التوصيل
                      if (result.deliveryTimeMinutes != null)
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              result.deliveryTimeText,
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
