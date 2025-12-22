import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_color.dart';
import '../../../ads/models/ad_model.dart';
import '../../../ads/services/ads_service.dart';
import '../../../authentication/guards/AuthGuard.dart';

/// بانر العروض الترويجية بتصميم حديث
class HomePromotionalBanner extends StatefulWidget {
  const HomePromotionalBanner({super.key});

  @override
  State<HomePromotionalBanner> createState() => _HomePromotionalBannerState();
}

class _HomePromotionalBannerState extends State<HomePromotionalBanner> {
  final PageController _pageController = PageController();
  final AdsService _adsService = AdsService();

  Timer? _autoScrollTimer;
  int _currentPage = 0;

  List<AdModel> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final ads = await _adsService.fetchActiveAds();
      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoading = false;
        });
        _startAutoScroll();
      }
    } catch (e) {
      print('خطأ في تحميل الإعلانات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() {
    final totalPages = _ads.length + 1; // الإعلانات + البانر الافتراضي
    if (totalPages <= 1) return;
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % totalPages;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToStore(String? storeId) {
    if (storeId != null && storeId.isNotEmpty) {
      context.push('/HomeMarketPage?marketLink=$storeId');
    }
  }

  /// معالجة الضغط على البانر الافتراضي
  void _handleDefaultBannerTap() {
    final authGuard = Provider.of<AuthGuard>(context, listen: false);
    if (authGuard.userStatus == 'market_owner') {
      // صاحب متجر → صفحة طلب الإعلانات
      context.push('/request-ads');
    } else {
      // مستخدم عادي → صفحة الباقات
      context.push('/pricingpage');
    }
  }

  /// الحصول على صورة البانر الافتراضي حسب نوع المستخدم
  String _getDefaultBannerImage() {
    final authGuard = Provider.of<AuthGuard>(context, listen: false);
    if (authGuard.userStatus == 'market_owner') {
      return 'assets/images/adsmarket.jpg';
    } else {
      return 'assets/images/create_market.png';
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // عدد الصفحات = الإعلانات + البانر الافتراضي
    final totalPages = _ads.length + 1;

    return Column(
      children: [
        // البانر الرئيسي
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: totalPages,
            itemBuilder: (context, index) {
              // آخر صفحة هي البانر الافتراضي
              if (index == _ads.length) {
                return _buildDefaultBanner();
              }
              // الإعلانات الحقيقية
              return _buildAdBanner(_ads[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        // مؤشرات الصفحات
        if (totalPages > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.mainColor
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }

  /// بانر الإعلان الحقيقي
  Widget _buildAdBanner(AdModel ad) {
    return GestureDetector(
      onTap: () {
        if (ad.targetStoreId != null && ad.targetStoreId!.isNotEmpty) {
          _navigateToStore(ad.targetStoreId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
              ? Image.network(
                  ad.imageUrl!,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.mainColor.withOpacity(0.1),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  /// البانر الافتراضي - صورة حسب نوع المستخدم
  Widget _buildDefaultBanner() {
    return GestureDetector(
      onTap: _handleDefaultBannerTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            _getDefaultBannerImage(),
            fit: BoxFit.fill,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.7)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 50, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 8),
            Text(
              'أعلن معنا',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
