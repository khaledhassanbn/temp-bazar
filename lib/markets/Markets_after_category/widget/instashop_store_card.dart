import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'package:bazar_suez/theme/app_color.dart';

class InstashopStoreCard extends StatelessWidget {
  final StoreModel store;
  final int? deliveryTimeMin;
  final double? deliveryFee;
  final String? subCategoryLabel;
  final String? categoryLabel;
  final VoidCallback onTap;
  final double? width;

  const InstashopStoreCard({
    super.key,
    required this.store,
    required this.onTap,
    this.deliveryTimeMin,
    this.deliveryFee,
    this.subCategoryLabel,
    this.categoryLabel,
    this.width,
  });

  String get _deliveryTimeLabel {
    if (deliveryTimeMin == null || deliveryTimeMin! <= 0) return '';
    final min = deliveryTimeMin!;
    final max = min + 10;
    return '$min-$max دقيقة';
  }

  bool get _isFreeDelivery =>
      deliveryFee != null && deliveryFee! <= 0;

  String get _reviewsLabel {
    if (store.totalReviews >= 500) return '(500+)';
    if (store.totalReviews > 0) return '(${store.totalReviews})';
    return '';
  }

  String get _storeTypeLabel {
    if (subCategoryLabel != null && subCategoryLabel!.isNotEmpty) {
      return subCategoryLabel!;
    }
    if (categoryLabel != null && categoryLabel!.isNotEmpty) {
      return categoryLabel!;
    }
    return 'متجر';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildCoverSection(),
              ),
            ),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverSection() {
    return Stack(
      children: [
        Container(
          height: 168,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            image: store.coverUrl != null && store.coverUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(store.coverUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: store.coverUrl == null || store.coverUrl!.isEmpty
              ? const Center(
                  child: Icon(Icons.store, size: 48, color: Colors.grey),
                )
              : null,
        ),
        // طبقة تظليل موحّدة فوق الكفر
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.14),
                  Colors.black.withValues(alpha: 0.22),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _StoreLogoBadge(
            logoUrl: store.logoUrl,
            storeName: store.name,
          ),
        ),
        if (_isFreeDelivery)
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'توصيل مجاني',
                style: TextStyle(
                  color: Color(0xFF6A1B9A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                const SizedBox(width: 3),
                Text(
                  store.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                if (_reviewsLabel.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    _reviewsLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_deliveryTimeLabel.isNotEmpty)
                Text(
                  _deliveryTimeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _storeTypeLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StoreLogoBadge extends StatelessWidget {
  final String? logoUrl;
  final String storeName;

  const _StoreLogoBadge({
    required this.logoUrl,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorWidget: (_, __, ___) => _fallbackContent(size),
            )
          : _fallbackContent(size),
    );
  }

  Widget _fallbackContent(double size) {
    final initial = storeName.trim().isNotEmpty
        ? storeName.trim().characters.first.toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      color: AppColors.mainColor.withValues(alpha: 0.85),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
