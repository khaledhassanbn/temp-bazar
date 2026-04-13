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
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final double screenW = MediaQuery.sizeOf(context).width;
    final int cacheW = (screenW * dpr).round();
    final int cacheH = (coverHeight * dpr).round();

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
              child: store?.coverUrl != null && store!.coverUrl!.isNotEmpty
                  ? Image.network(
                      store!.coverUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: cacheW,
                      cacheHeight: cacheH,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.network(
                          'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=800',
                          fit: BoxFit.cover,
                          cacheWidth: cacheW,
                          cacheHeight: cacheH,
                          filterQuality: FilterQuality.medium,
                        );
                      },
                    )
                  : Image.network(
                      'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=800',
                      fit: BoxFit.cover,
                      cacheWidth: cacheW,
                      cacheHeight: cacheH,
                      filterQuality: FilterQuality.medium,
                    ),
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
