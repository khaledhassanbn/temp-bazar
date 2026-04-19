import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'market_info_card.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

class MarketCoverSection extends StatelessWidget {
  final double coverHeight;
  final double infoBoxHeight;
  final double scrollOffset;
  final StoreModel? store;

  const MarketCoverSection({
    super.key,
    required this.coverHeight,
    required this.infoBoxHeight,
    required this.scrollOffset,
    this.store,
  });

  @override
  Widget build(BuildContext context) {
    final double parallax = (scrollOffset * 0.5).clamp(0, coverHeight);

    return RepaintBoundary(
      child: SizedBox(
        height: coverHeight + 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🔹 الغلاف (صورة من قاعدة البيانات أو الصورة التقليدية) مع parallax effect
            Positioned(
              top: -parallax,
              left: 0,
              right: 0,
              height: coverHeight,
              child: store == null
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFE9F5EF), Color(0xFFFFFFFF)],
                        ),
                      ),
                    )
                  : (store?.coverUrl != null && store!.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: store!.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: coverHeight,
                          filterQuality: FilterQuality.medium,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFE9F5EF),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFE9F5EF),
                          ),
                        )
                      : Container(color: const Color(0xFFE9F5EF))),
            ),

            // 🔹 المساحة البيضاء في الأسفل
            Positioned(
              top: coverHeight - 30,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.white),
            ),

            // 🔹 صندوق المعلومات (نصفه فوق الكفر ونصفه في المساحة البيضاء)
            Positioned(
              top: coverHeight - infoBoxHeight / 2 - 50,
              left: 16,
              right: 16,
              child: SizedBox(
                height: infoBoxHeight,
                child: MarketInfoCard(
                  marketName: store?.name ?? '...',
                  marketDescription: store?.description ?? '',
                  marketLogo: store?.logoUrl ?? '',
                  rating: store?.averageRating ?? 0.0,
                  reviewCount: store?.totalReviews ?? 0,
                  deliveryTime: '40-60 دقيقة',
                  deliveryFee: '6.99 ج.م',
                  phone: store?.phone,
                  facebook: store?.facebook,
                  instagram: store?.instagram,
                  marketLink: store?.link,
                  storeId: store?.id,
                  location: store?.location,
                  showAddress: store?.showAddress ?? false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
