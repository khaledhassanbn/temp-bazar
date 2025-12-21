import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../ads/models/ad_model.dart';
import '../../../ads/services/ads_service.dart';
import '../../../authentication/guards/AuthGuard.dart';

class HomeAutoScrollingAds extends StatefulWidget {
  const HomeAutoScrollingAds({super.key});

  @override
  State<HomeAutoScrollingAds> createState() => _HomeAutoScrollingAdsState();
}

class _HomeAutoScrollingAdsState extends State<HomeAutoScrollingAds> {
  final ScrollController _scrollController = ScrollController();
  final AdsService _adsService = AdsService();

  late Timer _timer;
  double _scrollPosition = 0;
  bool _scrollForward = true;

  List<AdModel> _ads = [];
  bool _isLoading = true;

  // الصورة الافتراضية الثابتة
  final String _defaultImage = 'assets/images/egypt.jpg';

  @override
  void initState() {
    super.initState();
    _loadAds();
    _startAutoScroll();
  }

  // تحميل الإعلانات من Firestore (الإعلانات النشطة والصالحة فقط)
  Future<void> _loadAds() async {
    try {
      final ads = await _adsService.fetchActiveAds();
      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('خطأ في تحميل الإعلانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // بدء التمرير التلقائي
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (_scrollForward) {
          _scrollPosition += 260;
          if (_scrollPosition >= maxScroll) _scrollForward = false;
        } else {
          _scrollPosition -= 260;
          if (_scrollPosition <= 0) _scrollForward = true;
        }

        _scrollController.animateTo(
          _scrollPosition,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // التنقل إلى المتجر عند النقر على الإعلان
  void _navigateToStore(String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      context.push('/HomeMarketPage?marketLink=$storeId');
    }
  }

  // معالجة النقر على الصورة الافتراضية
  void _handleDefaultImageTap(BuildContext context) {
    final authGuard = Provider.of<AuthGuard>(context, listen: false);

    if (authGuard.userStatus == 'market_owner') {
      // إذا كان marketowner، افتح صفحة request ads
      context.push('/request-ads');
    } else {
      // إذا كان user، افتح صفحة PricingPage
      context.push('/pricingpage');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // عرض الصورة الافتراضية دائماً (سواء كان هناك إعلانات أم لا)
    return SizedBox(
      height: 130,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _ads.length + 1, // الإعلانات + الصورة الافتراضية
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          // آخر عنصر هو الصورة الافتراضية
          if (index == _ads.length) {
            return _buildDefaultAdItem();
          }

          // عرض الإعلانات
          final ad = _ads[index];
          final String imageToShow =
              ad.imageUrl != null && ad.imageUrl!.isNotEmpty
              ? ad.imageUrl!
              : _defaultImage;

          return GestureDetector(
            onTap: () {
              // إذا كان هناك إعلان حقيقي مع متجر، انتقل للمتجر
              if (ad.targetStoreId != null &&
                  ad.targetStoreId!.isNotEmpty &&
                  ad.imageUrl != null &&
                  ad.imageUrl!.isNotEmpty) {
                _navigateToStore(ad.targetStoreId);
              } else {
                // إذا كانت الصورة افتراضية، استخدم معالجة النقر الافتراضية
                _handleDefaultImageTap(context);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageToShow.startsWith('http')
                    ? Image.network(
                        imageToShow,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultImageContent();
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildDefaultImageContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  // بناء عنصر الصورة الافتراضية في القائمة
  Widget _buildDefaultAdItem() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(_defaultImage),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleDefaultImageTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(),
        ),
      ),
    );
  }

  // بناء محتوى الصورة الافتراضية
  Widget _buildDefaultImageContent() {
    return Image.asset(
      _defaultImage,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
        );
      },
    );
  }
}
