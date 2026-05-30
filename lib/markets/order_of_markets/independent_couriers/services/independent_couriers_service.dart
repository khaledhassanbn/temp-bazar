import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/independent_courier.dart';
import '../../../../services/delivery_fee/delivery_fee_service.dart';

class IndependentCouriersService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _rtdb;

  IndependentCouriersService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? rtdb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _rtdb = rtdb ?? FirebaseDatabase.instance;

  Stream<List<IndependentCourier>> streamApprovedCouriersWithLiveStatus({
    required GeoPoint? storeLocation,
  }) {
    final courierRequestsStream = _firestore
        .collection('courier_requests')
        .where('status', isEqualTo: 'approved')
        .snapshots();

    // We "merge" RTDB live status by fetching each courier's node periodically.
    // This keeps implementation simple + avoids leaking RTDB listeners in large lists.
    // UI requirements are realtime; we re-poll via RTDB streams per courier in VM for selected screen.
    return courierRequestsStream.asyncMap((snapshot) async {
      final baseCouriers =
          snapshot.docs.map(IndependentCourier.fromCourierRequestDoc).toList();

      final results = <IndependentCourier>[];
      for (final courier in baseCouriers) {
        final live = await _getCourierLiveOnce(courier.uid);
        final merged = _mergeLive(
          courier: courier,
          live: live,
          storeLocation: storeLocation,
        );
        results.add(merged);
      }

      results.sort((a, b) {
        final da = a.distanceKmFromStore;
        final db = b.distanceKmFromStore;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

      return results;
    });
  }

  Future<Map<String, dynamic>?> _getCourierLiveOnce(String courierUid) async {
    try {
      final snapshot =
          await _rtdb.ref('couriers_live/$courierUid').get().timeout(
                const Duration(seconds: 8),
                onTimeout: () => throw TimeoutException('RTDB timeout'),
              );
      final value = snapshot.value;
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  IndependentCourier _mergeLive({
    required IndependentCourier courier,
    required Map<String, dynamic>? live,
    required GeoPoint? storeLocation,
  }) {
    final courierStatus =
        (live?['courierStatus'] ?? live?['status'] ?? '').toString().toLowerCase();
    final isOnline = courierStatus == 'online';
    final currentOrderId = (live?['currentOrderId'] ?? live?['current_order_id'])
        ?.toString();

    double? lat;
    double? lng;
    final latRaw = live?['latitude'] ?? live?['lat'];
    final lngRaw = live?['longitude'] ?? live?['lng'];
    if (latRaw is num) lat = latRaw.toDouble();
    if (lngRaw is num) lng = lngRaw.toDouble();
    if (lat == null && latRaw != null) lat = double.tryParse(latRaw.toString());
    if (lng == null && lngRaw != null) lng = double.tryParse(lngRaw.toString());

    double? distanceKm;
    if (storeLocation != null && lat != null && lng != null) {
      distanceKm = DeliveryFeeService.calculateDistance(
        storeLocation.latitude,
        storeLocation.longitude,
        lat,
        lng,
      );
    }

    return courier.copyWith(
      isOnline: isOnline,
      currentOrderId: currentOrderId,
      latitude: lat,
      longitude: lng,
      distanceKmFromStore: distanceKm,
    );
  }
}

