import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';
import 'dart:math' as math;

/// Service لجلب المتاجر القريبة
/// Backend يحسب المسافة باستخدام Haversine Formula
class NearbyStoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// حساب المسافة بين نقطتين باستخدام Haversine Formula (بالكيلومتر)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// حساب وقت التوصيل التقديري (بالدقائق)
  /// deliveryTime = (distanceKm / 20 * 60) + 15
  int _calculateDeliveryTime(double distanceKm) {
    return ((distanceKm / 20) * 60 + 15).round();
  }

  /// جلب موقع المستخدم من Firestore
  Future<GeoPoint?> _getUserLocation(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data();
      if (data == null) return null;

      // محاولة جلب الموقع من الحقول المختلفة
      if (data['location'] is GeoPoint) {
        return data['location'] as GeoPoint;
      }

      // محاولة من saved_locations (العنوان الافتراضي)
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

      // محاولة من أول عنوان محفوظ
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

  /// جلب المتاجر القريبة
  /// Flutter يرسل userId فقط، Backend يحسب المسافة
  Future<List<NearbyStoreResult>> getNearbyStores({
    int limit = 10,
    double maxDistanceKm = 50.0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // جلب موقع المستخدم
    final userLocation = await _getUserLocation(user.uid);
    if (userLocation == null) {
      print('⚠️ لا يوجد موقع محفوظ للمستخدم');
      return [];
    }

    // جلب كل المتاجر النشطة
    final storesQuery = await _firestore
        .collection('markets')
        .where('isVisible', isEqualTo: true)
        .where('storeStatus', isEqualTo: true)
        .get();

    final List<NearbyStoreResult> nearbyStores = [];

    for (var doc in storesQuery.docs) {
      final data = doc.data();
      final storeLocation = data['location'] as GeoPoint?;

      if (storeLocation == null) continue;

      // حساب المسافة (Backend calculation)
      final distanceKm = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        storeLocation.latitude,
        storeLocation.longitude,
      );

      // تصفية المتاجر البعيدة جداً
      if (distanceKm > maxDistanceKm) continue;

      // جلب إحصائيات التقييم
      double averageRating = 0.0;
      int totalReviews = 0;
      try {
        final statsDoc = await _firestore
            .collection('markets')
            .doc(doc.id)
            .collection('statistics')
            .doc('rating')
            .get();

        if (statsDoc.exists) {
          final statsData = statsDoc.data();
          averageRating = (statsData?['averageRating'] ?? 0.0).toDouble();
          totalReviews = statsData?['totalReviews'] ?? 0;
        }
      } catch (e) {
        // تجاهل الخطأ
      }

      // إنشاء StoreModel
      final store = StoreModel.fromMap(doc.id, {
        ...data,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
      });

      // التحقق من أن الترخيص نشط
      if (store.isLicenseExpired) continue;

      // حساب وقت التوصيل
      final deliveryTimeMinutes = _calculateDeliveryTime(distanceKm);

      nearbyStores.add(
        NearbyStoreResult(
          store: store,
          distanceKm: distanceKm,
          deliveryTimeMinutes: deliveryTimeMinutes,
        ),
      );
    }

    // ترتيب من الأقرب للأبعد
    nearbyStores.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // إرجاع العدد المطلوب
    return nearbyStores.take(limit).toList();
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
