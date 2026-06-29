import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/independent_courier.dart';
import '../../../../services/delivery_fee/delivery_fee_service.dart';

class IndependentCouriersService {
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _rtdb;

  Map<String, Map<String, dynamic>>? _liveCache;
  DateTime? _liveCacheAt;
  static const _liveCacheTtl = Duration(seconds: 8);

  IndependentCouriersService({
    FirebaseFirestore? firestore,
    FirebaseDatabase? rtdb,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _rtdb = rtdb ?? FirebaseDatabase.instance;

  Stream<List<IndependentCourier>> streamApprovedCouriersWithLiveStatus({
    required GeoPoint? storeLocation,
  }) {
    return _firestore
        .collection('courier_requests')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((snapshot) async {
      final baseCouriers =
          snapshot.docs.map(IndependentCourier.fromCourierRequestDoc).toList();

      final uids = baseCouriers.map((c) => c.uid).toList(growable: false);
      final liveByUid = await _getCouriersLiveForUids(uids);
      final enriched = baseCouriers
          .map(
            (courier) => _mergeLive(
              courier: courier,
              live: liveByUid[courier.uid],
              storeLocation: storeLocation,
            ),
          )
          .toList(growable: false);

      return _sortByDistance(enriched);
    });
  }

  /// جلب لمرة واحدة (لإعادة الإرسال التلقائي).
  Future<List<IndependentCourier>> fetchApprovedCouriersWithLiveStatus({
    required GeoPoint? storeLocation,
  }) async {
    final snapshot = await _firestore
        .collection('courier_requests')
        .where('status', isEqualTo: 'approved')
        .get();

    final baseCouriers =
        snapshot.docs.map(IndependentCourier.fromCourierRequestDoc).toList();
    final uids = baseCouriers.map((c) => c.uid).toList(growable: false);
    final liveByUid = await _getCouriersLiveForUids(uids);
    final enriched = baseCouriers
        .map(
          (courier) => _mergeLive(
            courier: courier,
            live: liveByUid[courier.uid],
            storeLocation: storeLocation,
          ),
        )
        .toList(growable: false);

    return _sortByDistance(enriched);
  }

  List<IndependentCourier> _sortByDistance(List<IndependentCourier> couriers) {
    final results = List<IndependentCourier>.from(couriers);
    results.sort((a, b) {
      final da = a.distanceKmFromStore;
      final db = b.distanceKmFromStore;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return results;
  }

  Future<Map<String, Map<String, dynamic>>> _getCouriersLiveForUids(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return const {};

    final now = DateTime.now();
    final useCache = _liveCache != null &&
        _liveCacheAt != null &&
        now.difference(_liveCacheAt!) < _liveCacheTtl;
    if (useCache) {
      final cached = <String, Map<String, dynamic>>{};
      for (final uid in uids) {
        final live = _liveCache![uid];
        if (live != null) cached[uid] = live;
      }
      if (cached.length == uids.length) return cached;
    }

    // قواعد RTDB تسمح بقراءة couriers_live/{uid} فقط وليس العقدة الأب
    final entries = await Future.wait(
      uids.map((uid) async {
        try {
          final snapshot = await _rtdb.ref('couriers_live/$uid').get().timeout(
                const Duration(seconds: 2),
                onTimeout: () => throw TimeoutException('RTDB timeout'),
              );
          final value = snapshot.value;
          if (value is Map) {
            return MapEntry(uid, Map<String, dynamic>.from(value));
          }
        } catch (_) {}
        return MapEntry(uid, <String, dynamic>{});
      }),
    );

    final parsed = Map<String, Map<String, dynamic>>.fromEntries(entries);
    _liveCache = {...?_liveCache, ...parsed};
    _liveCacheAt = now;
    return parsed;
  }

  IndependentCourier _mergeLive({
    required IndependentCourier courier,
    required Map<String, dynamic>? live,
    required GeoPoint? storeLocation,
  }) {
    final courierStatus =
        (live?['courierStatus'] ?? live?['status'] ?? 'offline')
            .toString()
            .toLowerCase()
            .trim();
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

    if (lat == null || lng == null) {
      final currentLocation = live?['currentLocation'];
      if (currentLocation is Map) {
        final clLat = currentLocation['latitude'];
        final clLng = currentLocation['longitude'];
        if (clLat is num) lat = clLat.toDouble();
        if (clLng is num) lng = clLng.toDouble();
        if (lat == null && clLat != null) {
          lat = double.tryParse(clLat.toString());
        }
        if (lng == null && clLng != null) {
          lng = double.tryParse(clLng.toString());
        }
      }
    }

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

