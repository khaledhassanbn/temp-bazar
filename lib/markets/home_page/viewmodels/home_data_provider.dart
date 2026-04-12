import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

import '../../create_market/models/store_model.dart';
import '../../favourite_markets/services/favourite_markets_service.dart';
import '../../favourite_markets/models/favourite_market_model.dart';
import '../../../ads/services/ads_service.dart';
import '../../../services/delivery_fee/delivery_fee_service.dart';
import '../../../services/delivery_fee/delivery_fee_settings.dart';
import '../../license/services/license_service.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Result models
// ══════════════════════════════════════════════════════════════════════════════

/// نتيجة المتجر المختار (إعلان)
class FeaturedStoreResult {
  final StoreModel store;
  final double? distanceKm;
  final int? deliveryTimeMinutes;
  final double? deliveryFee;

  FeaturedStoreResult({
    required this.store,
    this.distanceKm,
    this.deliveryTimeMinutes,
    this.deliveryFee,
  });

  String get deliveryTimeText {
    if (deliveryTimeMinutes == null) return 'غير متاح';
    return '$deliveryTimeMinutes دقيقة';
  }

  String get deliveryFeeText {
    if (deliveryFee == null) return 'غير متاح';
    return '${deliveryFee!.toStringAsFixed(0)} جنيه';
  }
}

/// نتيجة المتجر القريب
class NearbyStoreResult {
  final StoreModel store;
  final double distanceKm;
  final int deliveryTimeMinutes;

  NearbyStoreResult({
    required this.store,
    required this.distanceKm,
    required this.deliveryTimeMinutes,
  });

  String get distanceText {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} م';
    }
    return '${distanceKm.toStringAsFixed(1)} كم';
  }

  String get deliveryTimeText {
    return '$deliveryTimeMinutes دقيقة';
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HomeDataProvider — ViewModel مركزي للصفحة الرئيسية
// ══════════════════════════════════════════════════════════════════════════════

class HomeDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdsService _adsService = AdsService();
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  final FavouriteMarketsService _favouriteService = FavouriteMarketsService();
  final LicenseService _licenseService = LicenseService();

  // ─── الحالة ──────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _isDisposed = false;
  String? _error;

  // ─── البيانات المحسوبة ────────────────────────────────────────────────

  List<FeaturedStoreResult> _featuredStores = [];
  List<NearbyStoreResult> _nearbyStores = [];
  List<StoreModel> _topRatedRestaurants = [];
  List<StoreModel> _topRatedGroceries = [];
  Set<String> _favouriteStoreIds = {};
  StoreModel? _myStore;

  // ─── Getters ─────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get error => _error;

  List<FeaturedStoreResult> get featuredStores => _featuredStores;
  List<NearbyStoreResult> get nearbyStores => _nearbyStores;
  List<StoreModel> get topRatedRestaurants => _topRatedRestaurants;
  List<StoreModel> get topRatedGroceries => _topRatedGroceries;
  Set<String> get favouriteStoreIds => _favouriteStoreIds;
  StoreModel? get myStore => _myStore;

  bool get isLoadingFeatured => _isLoading && _featuredStores.isEmpty;
  bool get isLoadingNearby => _isLoading && _nearbyStores.isEmpty;
  bool get isLoadingTopRated =>
      _isLoading &&
      _topRatedRestaurants.isEmpty &&
      _topRatedGroceries.isEmpty;

  // ─── Safe notifyListeners ────────────────────────────────────────────

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 🔥 تحميل كل بيانات الصفحة الرئيسية بالتوازي
  // ══════════════════════════════════════════════════════════════════════════

  /// يحمّل البيانات مرة واحدة، أو يُعيد التحميل إذا force = true
  Future<void> loadHomeData({
    required SavedLocationsViewModel locationVm,
    bool force = false,
  }) async {
    // لو البيانات محمّلة ومش طالب إعادة تحميل — ارجع فوراً
    if (_hasLoadedOnce && !force) return;

    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        _safeNotify();
        return;
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // الخطوة 1: تحميل 4 أشياء بالتوازي (كلهم مستقلين عن بعض)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      final results = await Future.wait([
        // [0] كل المتاجر النشطة — query واحد بدلاً من 3
        _fetchAllActiveStores(),
        // [1] الإعلانات النشطة
        _adsService.fetchActiveAds(),
        // [2] إعدادات التوصيل — مرة واحدة بدلاً من 3
        _deliveryFeeService.getSettings(),
        // [3] المفضلات — مرة واحدة بدلاً من 3
        _favouriteService.getFavouriteMarkets(),
        // [4] حالة الترخيص (للبانر)
        _loadMyStore(),
      ]);

      if (_isDisposed) return;

      final allStores = results[0] as List<StoreModel>;
      final activeAds = results[1] as List<dynamic>;
      final deliverySettings = results[2] as DeliveryFeeSettings;
      final favourites = results[3] as List<FavouriteMarketModel>;
      // results[4] is _myStore (already set inside _loadMyStore)

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // الخطوة 2: استخلاص موقع المستخدم من SavedLocationsViewModel
      // (بدلاً من 4 queries لـ Firestore)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      final GeoPoint? userLocation = locationVm.activeLocation;

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // الخطوة 3: حساب المسافة والتوصيل لكل متجر (محلياً — بدون queries)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      // المفضلات
      _favouriteStoreIds = favourites.map((e) => e.marketId).toSet();

      // ── Featured Stores (من الإعلانات النشطة) ──
      final adStoreIds = activeAds
          .where((ad) =>
              ad.targetStoreId != null && ad.targetStoreId!.isNotEmpty)
          .map((ad) => ad.targetStoreId! as String)
          .toSet();

      // فلترة المتاجر المغلقة حسب isOpenNow (من الـ Cloud Function) أو الحساب المحلي
      _featuredStores = allStores
          .where((store) =>
              adStoreIds.contains(store.id) && !store.isClosedByWorkingHours)
          .map((store) {
        double? distanceKm;
        int? deliveryTimeMinutes;
        double? deliveryFee;

        if (userLocation != null && store.location != null) {
          distanceKm = _calculateDistance(userLocation, store.location!);
          deliveryTimeMinutes = _calculateDeliveryTime(distanceKm);
          deliveryFee = _deliveryFeeService.calculateDeliveryFee(
            distanceKm,
            deliverySettings,
          );
        }

        return FeaturedStoreResult(
          store: store,
          distanceKm: distanceKm,
          deliveryTimeMinutes: deliveryTimeMinutes,
          deliveryFee: deliveryFee,
        );
      }).take(10).toList();

      // ── Nearby Stores (مرتبة بالمسافة) — بستثناء المغلقة ──
      if (userLocation != null) {
        final nearbyList = <NearbyStoreResult>[];

        for (final store in allStores) {
          if (store.location == null) continue;
          if (store.isClosedByWorkingHours) continue; // تخطي المتاجر المغلقة

          final distanceKm = _calculateDistance(userLocation, store.location!);
          if (distanceKm > 50.0) continue; // أبعد من 50 كم

          nearbyList.add(NearbyStoreResult(
            store: store,
            distanceKm: distanceKm,
            deliveryTimeMinutes: _calculateDeliveryTime(distanceKm),
          ));
        }

        nearbyList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        _nearbyStores = nearbyList.take(10).toList();
      } else {
        _nearbyStores = [];
      }

      // ── Top Rated (مرتبة بالتقييم) — بستثناء المغلقة ──
      // نسخة مرتبة بالتقييم ثم عدد المراجعات
      final sortedByRating = List<StoreModel>.from(
        allStores.where((store) => !store.isClosedByWorkingHours),
      );
      sortedByRating.sort((a, b) {
        final ratingCmp = b.averageRating.compareTo(a.averageRating);
        if (ratingCmp != 0) return ratingCmp;
        return b.totalReviews.compareTo(a.totalReviews);
      });

      // إضافة معلومات التوصيل
      List<StoreModel> _enrichWithDelivery(List<StoreModel> stores) {
        return stores.map((store) {
          if (userLocation != null && store.location != null) {
            final distanceKm =
                _calculateDistance(userLocation, store.location!);
            return store.copyWith(
              deliveryFee: _deliveryFeeService.calculateDeliveryFee(
                distanceKm,
                deliverySettings,
              ),
              deliveryTime: _calculateDeliveryTime(distanceKm),
            );
          }
          return store;
        }).toList();
      }

      // TODO: لما تضيف categoryId للمتاجر، فلتر هنا
      // حالياً نستخدم نفس المنطق القديم (كلهم)
      _topRatedRestaurants =
          _enrichWithDelivery(sortedByRating.take(10).toList());
      _topRatedGroceries =
          _enrichWithDelivery(sortedByRating.take(10).toList());

      _hasLoadedOnce = true;
      _isLoading = false;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ HomeDataProvider error: $e');
      _error = 'فشل تحميل البيانات';
      _isLoading = false;
      _safeNotify();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // المفضلات — Toggle
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> toggleFavourite(String marketId) async {
    final isFav = _favouriteStoreIds.contains(marketId);

    // Optimistic update
    if (isFav) {
      _favouriteStoreIds.remove(marketId);
    } else {
      _favouriteStoreIds.add(marketId);
    }
    _safeNotify();

    try {
      if (isFav) {
        await _favouriteService.removeFavouriteMarket(marketId);
      } else {
        await _favouriteService.addFavouriteMarket(marketId);
      }
    } catch (_) {
      // Revert on failure
      if (isFav) {
        _favouriteStoreIds.add(marketId);
      } else {
        _favouriteStoreIds.remove(marketId);
      }
      _safeNotify();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// جلب كل المتاجر النشطة مرة واحدة — بدون N+1!
  /// الـ averageRating و totalReviews بيتقرأوا من document المتجر مباشرة
  Future<List<StoreModel>> _fetchAllActiveStores() async {
    try {
      final snapshot = await _firestore
          .collection('markets')
          .where('isVisible', isEqualTo: true)
          .where('storeStatus', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => StoreModel.fromMap(doc.id, doc.data()))
          .where((store) => !store.isLicenseExpired)
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching stores: $e');
      return [];
    }
  }

  /// جلب بيانات متجري (للبانر)
  Future<void> _loadMyStore() async {
    try {
      final marketId = await _licenseService.resolveCurrentUserMarketId();
      if (marketId == null) return;
      _myStore = await _licenseService.fetchStore(marketId);
    } catch (_) {
      // لا يُعيق التحميل
    }
  }

  /// حساب المسافة بين نقطتين (Haversine)
  double _calculateDistance(GeoPoint from, GeoPoint to) {
    return DeliveryFeeService.calculateDistanceFromGeoPoints(from, to);
  }

  /// حساب وقت التوصيل التقديري
  int _calculateDeliveryTime(double distanceKm) {
    return DeliveryFeeService.calculateDeliveryTime(distanceKm);
  }
}
