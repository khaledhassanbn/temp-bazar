import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import '../../../services/delivery_fee/delivery_fee_service.dart';

/// Service لجلب أفضل المطاعم وأشهر البقالات
/// الاختيار بناءً على: أعلى تقييم ثم أكبر عدد تقييمات
/// ORDER BY rating DESC, reviewsCount DESC
class TopRatedStoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  /// جلب أفضل المتاجر حسب التقييم
  /// categoryId: null = كل الفئات، أو فئة محددة
  Future<List<StoreModel>> getTopRatedStores({
    String? categoryId,
    int limit = 10,
  }) async {
    try {
      // جلب موقع المستخدم
      final user = _auth.currentUser;
      GeoPoint? userLocation;
      if (user != null) {
        userLocation = await _getUserLocation(user.uid);
      }

      // جلب إعدادات رسوم التوصيل
      final deliverySettings = await _deliveryFeeService.getSettings();

      // جلب كل المتاجر النشطة
      Query<Map<String, dynamic>> query = _firestore
          .collection('markets')
          .where('isVisible', isEqualTo: true)
          .where('storeStatus', isEqualTo: true);

      // إذا كانت هناك فئة محددة، نحتاج إلى تصفية حسب الفئة
      // (هذا يتطلب معرفة بنية البيانات - سنفترض أن المتاجر مرتبطة بالفئات)
      final storesSnapshot = await query.get();

      final List<StoreWithRating> storesWithRatings = [];

      // جلب التقييمات لكل متجر
      for (var doc in storesSnapshot.docs) {
        try {
          final statsDoc = await _firestore
              .collection('markets')
              .doc(doc.id)
              .collection('statistics')
              .doc('rating')
              .get();

          double averageRating = 0.0;
          int totalReviews = 0;

          if (statsDoc.exists) {
            final statsData = statsDoc.data();
            averageRating = (statsData?['averageRating'] ?? 0.0).toDouble();
            totalReviews = statsData?['totalReviews'] ?? 0;
          }

          final data = doc.data();
          var store = StoreModel.fromMap(doc.id, {
            ...data,
            'averageRating': averageRating,
            'totalReviews': totalReviews,
          });

          // تصفية المتاجر المنتهية الترخيص
          if (store.isLicenseExpired) continue;

          // حساب المسافة وتحديث المتجر
          if (userLocation != null && store.location != null) {
            final distanceKm = DeliveryFeeService.calculateDistanceFromGeoPoints(
              userLocation,
              store.location!,
            );
            final deliveryTime = _calculateDeliveryTime(distanceKm);
            final deliveryFee = _deliveryFeeService.calculateDeliveryFee(
              distanceKm,
              deliverySettings,
            );

            store = store.copyWith(
              deliveryFee: deliveryFee,
              deliveryTime: deliveryTime,
            );
          }

          // إذا كانت هناك فئة محددة، تحقق من أن المتجر ينتمي لها
          if (categoryId != null) {
            // يمكنك إضافة منطق التحقق من الفئة هنا
            // على سبيل المثال: data['categoryId'] == categoryId
          }

          storesWithRatings.add(StoreWithRating(
            store: store,
            rating: averageRating,
            reviewsCount: totalReviews,
          ));
        } catch (e) {
          print('خطأ في جلب بيانات المتجر ${doc.id}: $e');
          continue;
        }
      }

      // ترتيب حسب: rating DESC, reviewsCount DESC
      storesWithRatings.sort((a, b) {
        // أولاً: حسب التقييم (الأعلى أولاً)
        final ratingComparison = b.rating.compareTo(a.rating);
        if (ratingComparison != 0) return ratingComparison;

        // ثانياً: حسب عدد التقييمات (الأكثر أولاً)
        return b.reviewsCount.compareTo(a.reviewsCount);
      });

      // إرجاع العدد المطلوب
      return storesWithRatings
          .take(limit)
          .map((item) => item.store)
          .toList();
    } catch (e) {
      print('خطأ في جلب أفضل المتاجر: $e');
      return [];
    }
  }

  /// جلب أفضل المطاعم (فئة محددة)
  Future<List<StoreModel>> getTopRatedRestaurants({
    int limit = 10,
  }) async {
    // يمكنك تمرير categoryId للمطاعم هنا
    return getTopRatedStores(categoryId: null, limit: limit);
  }

  /// جلب أشهر البقالات (فئة محددة)
  Future<List<StoreModel>> getTopRatedGroceries({
    int limit = 10,
  }) async {
    // يمكنك تمرير categoryId للبقالات هنا
    return getTopRatedStores(categoryId: null, limit: limit);
  }
}

/// Helper class لتخزين المتجر مع تقييمه
class StoreWithRating {
  final StoreModel store;
  final double rating;
  final int reviewsCount;

  StoreWithRating({
    required this.store,
    required this.rating,
    required this.reviewsCount,
  });
}


