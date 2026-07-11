import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'delivery_fee_settings.dart';

/// خدمة مركزية لحساب وإدارة رسوم التوصيل
class DeliveryFeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// كاش للإعدادات لتجنب القراءة المتكررة من Firestore
  DeliveryFeeSettings? _cachedSettings;
  DateTime? _cacheTime;
  static const _cacheValidityMinutes = 5;

  /// مسار الإعدادات في Firestore
  static const String _settingsPath = 'settings';
  static const String _settingsDoc = 'delivery_fee';

  /// جلب إعدادات رسوم التوصيل من Firestore
  Future<DeliveryFeeSettings> getSettings({bool forceRefresh = false}) async {
    // التحقق من صلاحية الكاش
    if (!forceRefresh && _cachedSettings != null && _cacheTime != null) {
      final cacheAge = DateTime.now().difference(_cacheTime!);
      if (cacheAge.inMinutes < _cacheValidityMinutes) {
        return _cachedSettings!;
      }
    }

    try {
      final doc = await _firestore.collection(_settingsPath).doc(_settingsDoc).get();

      if (doc.exists && doc.data() != null) {
        _cachedSettings = DeliveryFeeSettings.fromMap(doc.data()!);
      } else {
        // استخدام القيم الافتراضية إذا لم توجد إعدادات
        _cachedSettings = DeliveryFeeSettings.defaults();
        // حفظ القيم الافتراضية في Firestore
        await _firestore.collection(_settingsPath).doc(_settingsDoc).set(
          _cachedSettings!.toMap(),
        );
      }
      _cacheTime = DateTime.now();
      return _cachedSettings!;
    } catch (e) {
      print('خطأ في جلب إعدادات رسوم التوصيل: $e');
      return DeliveryFeeSettings.defaults();
    }
  }

  /// تحديث إعدادات رسوم التوصيل (للأدمن فقط)
  Future<bool> updateSettings(DeliveryFeeSettings settings) async {
    try {
      await _firestore.collection(_settingsPath).doc(_settingsDoc).set(
        settings.toMap(),
      );
      // تحديث الكاش
      _cachedSettings = settings;
      _cacheTime = DateTime.now();
      return true;
    } catch (e) {
      print('خطأ في تحديث إعدادات رسوم التوصيل: $e');
      return false;
    }
  }

  /// حساب رسوم التوصيل بناءً على المسافة ونطاقات التسعير
  double calculateDeliveryFee(double distanceKm, DeliveryFeeSettings settings) {
    final zones = settings.sortedZones;
    if (zones.isEmpty) return 0;

    for (final zone in zones) {
      if (distanceKm > zone.from && distanceKm <= zone.to) {
        return zone.fee;
      }
    }

    if (distanceKm <= zones.first.to) {
      return zones.first.fee;
    }

    return zones.last.fee;
  }

  /// حساب رسوم التوصيل مع جلب الإعدادات تلقائياً
  Future<double> calculateDeliveryFeeAsync(double distanceKm) async {
    final settings = await getSettings();
    return calculateDeliveryFee(distanceKm, settings);
  }

  /// حساب المسافة بين نقطتين باستخدام Haversine Formula (بالكيلومتر)
  static double calculateDistance(
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

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// حساب المسافة من GeoPoint
  static double calculateDistanceFromGeoPoints(
    GeoPoint userLocation,
    GeoPoint storeLocation,
  ) {
    return calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      storeLocation.latitude,
      storeLocation.longitude,
    );
  }

  /// حساب وقت التوصيل التقديري (بالدقائق)
  /// deliveryTime = (distanceKm / 20 * 60) + 15
  static int calculateDeliveryTime(double distanceKm) {
    return ((distanceKm / 20) * 60 + 15).round();
  }

  /// مسح الكاش لإجبار إعادة التحميل
  void clearCache() {
    _cachedSettings = null;
    _cacheTime = null;
  }
}
