import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import '../../../ads/services/ads_service.dart';
import '../../../services/delivery_fee/delivery_fee_service.dart';

/// Service لجلب المتاجر المختارة (التي لها إعلانات نشطة)
class FeaturedStoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdsService _adsService = AdsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();

  /// حساب وقت التوصيل التقديري (بالدقائق)
  int _calculateDeliveryTime(double distanceKm) {
    return DeliveryFeeService.calculateDeliveryTime(distanceKm);
  }


  /// جلب موقع المستخدم من Firestore
  Future<GeoPoint?> _getUserLocation(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data();
      if (data == null) return null;

      if (data['location'] is GeoPoint) {
        return data['location'] as GeoPoint;
      }

      final savedLocationsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .where('isDefault', isEqualTo: true)
          .limit(1);

      final savedLocations = await savedLocationsRef.get();
      if (savedLocations.docs.isNotEmpty) {
        final locationData = savedLocations.docs.first.data();
        if (locationData['location'] is GeoPoint) {
          return locationData['location'] as GeoPoint;
        }
      }

      final allLocations = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_locations')
          .limit(1)
          .get();

      if (allLocations.docs.isNotEmpty) {
        final locationData = allLocations.docs.first.data();
        if (locationData['location'] is GeoPoint) {
          return locationData['location'] as GeoPoint;
        }
      }

      return null;
    } catch (e) {
      print('خطأ في جلب موقع المستخدم: $e');
      return null;
    }
  }

  /// جلب المتاجر المختارة (التي لها إعلانات نشطة) مع حساب المسافة ووقت التوصيل
  Future<List<FeaturedStoreResult>> getFeaturedStores({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // جلب موقع المستخدم
      final userLocation = await _getUserLocation(user.uid);

      // جلب إعدادات رسوم التوصيل
      final deliverySettings = await _deliveryFeeService.getSettings();

      // جلب الإعلانات النشطة
      final activeAds = await _adsService.fetchActiveAds();

      // استخراج storeIds من الإعلانات النشطة
      final storeIds = activeAds
          .where(
            (ad) => ad.targetStoreId != null && ad.targetStoreId!.isNotEmpty,
          )
          .map((ad) => ad.targetStoreId!)
          .toSet()
          .toList();

      if (storeIds.isEmpty) return [];

      // جلب المتاجر
      final List<FeaturedStoreResult> results = [];

      const int chunkSize = 10;
      for (var i = 0; i < storeIds.length; i += chunkSize) {
        final chunk = storeIds.sublist(
          i,
          i + chunkSize > storeIds.length ? storeIds.length : i + chunkSize,
        );

        final query = await _firestore
            .collection('markets')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final storeList = await Future.wait(
          query.docs.map((doc) async {
            final data = doc.data();
            try {
              final statsDoc = await _firestore
                  .collection('markets')
                  .doc(doc.id)
                  .collection('statistics')
                  .doc('rating')
                  .get();

              if (statsDoc.exists) {
                final statsData = statsDoc.data();
                data['averageRating'] = statsData?['averageRating'] ?? 0.0;
                data['totalReviews'] = statsData?['totalReviews'] ?? 0;
              }
            } catch (e) {
              // تجاهل الخطأ
            }
            return StoreModel.fromMap(doc.id, data);
          }),
        );

        // حساب المسافة ووقت التوصيل ومبلغ التوصيل
        for (final store in storeList) {
          if (store.isLicenseExpired) continue;

          double? distanceKm;
          int? deliveryTimeMinutes;
          double? deliveryFee;

          if (userLocation != null && store.location != null) {
            distanceKm = DeliveryFeeService.calculateDistanceFromGeoPoints(
              userLocation,
              store.location!,
            );
            deliveryTimeMinutes = _calculateDeliveryTime(distanceKm);
            deliveryFee = _deliveryFeeService.calculateDeliveryFee(
              distanceKm,
              deliverySettings,
            );
          }

          results.add(
            FeaturedStoreResult(
              store: store,
              distanceKm: distanceKm,
              deliveryTimeMinutes: deliveryTimeMinutes,
              deliveryFee: deliveryFee,
            ),
          );
        }
      }

      // إرجاع العدد المطلوب
      return results.take(limit).toList();
    } catch (e) {
      print('خطأ في جلب المتاجر المختارة: $e');
      return [];
    }
  }
}

/// نتيجة المتجر المختار
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
