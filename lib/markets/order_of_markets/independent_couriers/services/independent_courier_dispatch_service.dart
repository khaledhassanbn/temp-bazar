import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../../services/delivery_fee/delivery_fee_service.dart';
import '../../../../services/independent_courier/independent_courier_settings_service.dart';

class IndependentCourierDispatchService {
  final FirebaseFirestore _firestore;
  final IndependentCourierSettingsService _courierSettingsService;

  IndependentCourierDispatchService({
    FirebaseFirestore? firestore,
    IndependentCourierSettingsService? courierSettingsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _courierSettingsService =
            courierSettingsService ?? IndependentCourierSettingsService();

  DocumentReference<Map<String, dynamic>> orderRef(String orderId) {
    return _firestore.collection('orders').doc(orderId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDispatchOrder(
    String orderId,
  ) {
    return orderRef(orderId).snapshots();
  }

  Future<void> createOrResendIndependentCourierOrder({
    required String orderId,
    required String storeId,
    required Map<String, dynamic> storeData,
    required Map<String, dynamic> presentOrderData,
    required List<String> courierUids,
  }) async {
    if (courierUids.isEmpty) {
      throw ArgumentError('courierUids cannot be empty');
    }
    if (courierUids.length > 3) {
      throw ArgumentError('Maximum 3 couriers allowed');
    }

    final isEnabled = await _courierSettingsService
        .isIndependentCourierEnabledForStore(storeId);
    if (!isEnabled) {
      throw StateError(
        IndependentCourierSettingsService.serviceUnavailableMessage,
      );
    }

    final customerInfo =
        presentOrderData['customerInfo'] as Map<String, dynamic>? ?? {};

    final GeoPoint? storeLocation = storeData['location'] is GeoPoint
        ? storeData['location'] as GeoPoint
        : null;
    final GeoPoint? customerLocation = customerInfo['location'] is GeoPoint
        ? customerInfo['location'] as GeoPoint
        : null;

    final double? distanceStoreCustomer = (storeLocation != null &&
            customerLocation != null)
        ? DeliveryFeeService.calculateDistanceFromGeoPoints(
            storeLocation,
            customerLocation,
          )
        : null;

    final courierResponses = <String, String>{
      for (final uid in courierUids) uid: 'pending',
    };

    final payload = <String, dynamic>{
      // REQUIRED ORDER STRUCTURE
      'orderId': orderId,
      'storeId': storeId,
      'assignedCourierId': null,
      'availableCouriers': courierUids,
      'courierResponses': courierResponses,
      'status': 'searching',
      'dispatchType': 'independent_courier',
      'dispatchStatus': 'waiting_courier_response',
      'createdAt': FieldValue.serverTimestamp(),

      // STORE DATA
      'storeName': (storeData['name'] ?? '').toString(),
      'storePhone': (storeData['phone'] ?? '').toString(),
      'storeAddress':
          (storeData['address'] ?? storeData['description'] ?? '').toString(),
      'storeLatitude': storeLocation?.latitude,
      'storeLongitude': storeLocation?.longitude,

      // CUSTOMER DATA
      'customerName': (customerInfo['name'] ?? '').toString(),
      'customerPhone': (customerInfo['phone'] ?? '').toString(),
      'customerAddress': (customerInfo['address'] ?? '').toString(),
      'customerLatitude': customerLocation?.latitude,
      'customerLongitude': customerLocation?.longitude,

      // ORDER DATA
      'deliveryPrice': presentOrderData['deliveryFee'] ?? 0,
      'orderPrice': presentOrderData['totalAmount'] ?? presentOrderData['subtotal'] ?? 0,
      'orderItems': presentOrderData['items'] ?? [],
      'invoiceDetails': {
        'subtotal': presentOrderData['subtotal'] ?? 0,
        'deliveryFee': presentOrderData['deliveryFee'] ?? 0,
        'serviceFee': presentOrderData['serviceFee'] ?? 0,
        'totalAmount': presentOrderData['totalAmount'] ?? 0,
      },
      'notes': presentOrderData['notes'] ?? '',
      'distanceBetweenStoreAndCustomer': distanceStoreCustomer,

      // extra metadata to aid debugging / future extension
      'source': 'store_app',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    String? oldCourierId;

    // Ensure single document for same order
    await _firestore.runTransaction((tx) async {
      final ref = orderRef(orderId);
      final snap = await tx.get(ref);

      if (!snap.exists) {
        tx.set(ref, {
          ...payload,
          for (final uid in courierUids) 'access.$uid': true,
        });
        return;
      }

      final data = snap.data() ?? <String, dynamic>{};
      final assigned = (data['assignedCourierId'] ?? '').toString();
      if (assigned.isNotEmpty) {
        oldCourierId = assigned;
      }

      // If there was an assigned courier, we are reassigning. We will:
      // 1. Keep track of previousCourierId.
      // 2. Mark the previous courier's response as 'cancelled_by_merchant'.
      // 3. Clear the assignment by setting assignedCourierId to null.
      Map<String, dynamic> mergedCourierResponses = Map<String, dynamic>.from(data['courierResponses'] ?? {});
      if (assigned.isNotEmpty) {
        mergedCourierResponses[assigned] = 'cancelled_by_merchant';
      }
      // Add the new couriers' pending statuses
      for (final uid in courierUids) {
        mergedCourierResponses[uid] = 'pending';
      }

      final accessUpdates = <String, dynamic>{};
      for (final uid in courierUids) {
        accessUpdates['access.$uid'] = true;
      }
      if (assigned.isNotEmpty) {
        accessUpdates['access.$assigned'] = FieldValue.delete();
      }

      tx.update(ref, {
        ...payload,
        'courierResponses': mergedCourierResponses,
        if (assigned.isNotEmpty) 'previousCourierId': assigned,
        if (assigned.isNotEmpty) 'reassignedAt': FieldValue.serverTimestamp(),
        // keep original createdAt if present
        if (data['createdAt'] != null) 'createdAt': data['createdAt'],
        ...accessUpdates,
      });
    });

    if (oldCourierId != null && oldCourierId!.isNotEmpty) {
      try {
        await FirebaseDatabase.instance.ref('couriers_live/$oldCourierId/currentOrderId').remove();
        await FirebaseDatabase.instance.ref('couriers_live/$oldCourierId/current_order_id').remove();
      } catch (e) {
        print('Error clearing courier currentOrderId in RTDB: $e');
      }
    }
  }
}
