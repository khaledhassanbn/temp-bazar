import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../theme/app_color.dart';
import '../services/nearby_stores_service.dart';

/// قسم المتاجر القريبة منك
class NearbyStoresSection extends StatefulWidget {
  const NearbyStoresSection({super.key});

  @override
  State<NearbyStoresSection> createState() => _NearbyStoresSectionState();
}

class _NearbyStoresSectionState extends State<NearbyStoresSection> {
  final NearbyStoresService _service = NearbyStoresService();
  List<NearbyStoreResult> _stores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyStores();
  }

  Future<void> _loadNearbyStores() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final stores = await _service.getNearbyStores(limit: 10);
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في جلب المتاجر القريبة: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stores.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: AppColors.nearbySectionBg, // 👈 الخلفية الرمادي
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'المتاجر القريبة منك',
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
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 8),
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                final result = _stores[index];
                return _buildNearbyStoreCard(result, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStoreCard(NearbyStoreResult result, int index) {
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        context.push('/HomeMarketPage?marketLink=${result.store.link}');
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار المتجر
            Container(
              width: 70,
              height: 70,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: result.store.logoUrl != null &&
                      result.store.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        result.store.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Icon(
                      Icons.store,
                      size: 40,
                      color: Colors.grey[400],
                    ),
            ),

            // اسم المتجر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                result.store.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // المسافة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.mainColor,
                ),
                const SizedBox(width: 4),
                Text(
                  result.distanceText,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // وقت التوصيل
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  result.deliveryTimeText,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ),
    );
  }
}
