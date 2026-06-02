// lib/markets/order_of_markets/courier_tracking/models/courier_live_data.dart

import 'dart:math' as math;

/// حالة المندوب النهائية بعد تطبيق State Engine
enum CourierStatus {
  online,
  busy,
  offline,
}

/// بيانات المندوب الحية من Firebase Realtime Database
/// مصدر البيانات: couriers_live/{courierId}
class CourierLiveData {
  /// موقع المندوب (Primary: root lat/lng — Fallback: currentLocation)
  final double latitude;
  final double longitude;

  /// السرعة بالكم/ساعة
  final double speed;

  /// اتجاه الحركة بالدرجات (0–360) — يُستخدم لتدوير الـ Marker
  final double heading;

  /// آخر تحديث للموقع (timestamp بالميلي ثانية)
  final int lastLocationUpdate;

  /// حالة المندوب الخام من RTDB
  final String rawCourierStatus;

  /// آخر ظهور (timestamp)
  final int lastSeen;

  const CourierLiveData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.lastLocationUpdate,
    required this.rawCourierStatus,
    required this.lastSeen,
  });

  /// State Engine: تحديد الحالة النهائية للمندوب
  CourierStatus get status {
    switch (rawCourierStatus.toLowerCase().trim()) {
      case 'offline':
        return CourierStatus.offline;
      case 'busy':
        return CourierStatus.busy;
      default:
        return CourierStatus.online;
    }
  }

  /// Factory لبناء الـ model من بيانات RTDB الخام
  factory CourierLiveData.fromRtdb(Map<dynamic, dynamic> data) {
    // Location Resolution Logic
    // PRIMARY: latitude + longitude (root)
    // FALLBACK: currentLocation.latitude + longitude
    double lat = 0.0;
    double lng = 0.0;

    final rootLat = data['latitude'];
    final rootLng = data['longitude'];

    if (rootLat is num && rootLng is num) {
      lat = rootLat.toDouble();
      lng = rootLng.toDouble();
    } else {
      // Fallback إلى currentLocation
      final currentLocation = data['currentLocation'];
      if (currentLocation is Map) {
        final clLat = currentLocation['latitude'];
        final clLng = currentLocation['longitude'];
        if (clLat is num) lat = clLat.toDouble();
        if (clLng is num) lng = clLng.toDouble();
      }
    }

    // speed
    final speedRaw = data['speed'];
    final double speed = speedRaw is num ? speedRaw.toDouble() : 0.0;

    // heading
    final headingRaw = data['heading'];
    final double heading = headingRaw is num ? headingRaw.toDouble() : 0.0;

    // lastLocationUpdate
    final lastLocRaw = data['lastLocationUpdate'];
    final int lastLocationUpdate = lastLocRaw is num ? lastLocRaw.toInt() : 0;

    // courierStatus
    final courierStatusRaw = data['courierStatus'];
    final String rawCourierStatus =
        courierStatusRaw != null ? courierStatusRaw.toString() : 'offline';

    // lastSeen
    final lastSeenRaw = data['lastSeen'];
    final int lastSeen = lastSeenRaw is num ? lastSeenRaw.toInt() : 0;

    return CourierLiveData(
      latitude: lat,
      longitude: lng,
      speed: speed,
      heading: heading,
      lastLocationUpdate: lastLocationUpdate,
      rawCourierStatus: rawCourierStatus,
      lastSeen: lastSeen,
    );
  }

  /// حساب المسافة بين موقعين باستخدام Haversine Formula
  /// يُرجع المسافة بالمتر
  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final double dLat = _toRad(lat2 - lat1);
    final double dLon = _toRad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// حساب المسافة بالكيلومتر
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return haversineMeters(lat1, lon1, lat2, lon2) / 1000.0;
  }

  static double _toRad(double deg) => deg * (math.pi / 180);

  CourierLiveData copyWith({
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    int? lastLocationUpdate,
    String? rawCourierStatus,
    int? lastSeen,
  }) {
    return CourierLiveData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      rawCourierStatus: rawCourierStatus ?? this.rawCourierStatus,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
