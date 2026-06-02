// lib/markets/order_of_markets/courier_tracking/services/courier_live_tracking_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/courier_live_data.dart';

/// خدمة الاستماع الفوري لموقع وحالة المندوب من Firebase Realtime Database
/// مصدر البيانات الوحيد (Single Source of Truth): couriers_live/{courierId}
class CourierLiveTrackingService {
  final FirebaseDatabase _rtdb;

  CourierLiveTrackingService({FirebaseDatabase? rtdb})
      : _rtdb = rtdb ?? FirebaseDatabase.instance;

  /// Stream يستمع لحظيًا للتغيرات في couriers_live/{courierId}
  /// يُصدر [CourierLiveData] عند كل تغيير دون polling
  Stream<CourierLiveData?> streamCourierLive(String courierId) {
    return _rtdb
        .ref('couriers_live/$courierId')
        .onValue
        .map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      if (value is! Map) return null;
      return CourierLiveData.fromRtdb(Map<dynamic, dynamic>.from(value));
    });
  }

  /// قراءة واحدة (one-shot) لبيانات المندوب
  Future<CourierLiveData?> getCourierLiveOnce(String courierId) async {
    try {
      final snapshot = await _rtdb
          .ref('couriers_live/$courierId')
          .get()
          .timeout(const Duration(seconds: 8));
      final value = snapshot.value;
      if (value == null || value is! Map) return null;
      return CourierLiveData.fromRtdb(Map<dynamic, dynamic>.from(value));
    } catch (_) {
      return null;
    }
  }
}
