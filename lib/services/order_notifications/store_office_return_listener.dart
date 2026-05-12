import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_notification_coordinator.dart';

bool _isReturnedToMerchantRaw(String? status) {
  if (status == null || status.isEmpty) return false;
  return status.trim().toLowerCase() == 'returned_to_merchant';
}

void _emitIfReturned({
  required String storeId,
  required String? status,
  required String orderDocumentId,
}) {
  if (!_isReturnedToMerchantRaw(status)) return;
  if (orderDocumentId.isEmpty) return;
  OrderNotificationCoordinator.instance.notifyOfficeReturnedOrder(
    orderDocumentId: orderDocumentId,
    storeId: storeId,
  );
}

/// يستمع لتعديلات [present_order] و [request delivery] عندما يضع المكتب
/// الحالة `returned_to_merchant` (أحدهما أو كلاهما قد يُحدَّث حسب الخادم).
class StoreOfficeReturnListener {
  StoreOfficeReturnListener(this.storeId);

  final String storeId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _presentSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _deliverySub;
  bool _seenPresentInitial = false;
  bool _seenDeliveryInitial = false;

  void start() {
    _presentSub?.cancel();
    _deliverySub?.cancel();
    _seenPresentInitial = false;
    _seenDeliveryInitial = false;

    _presentSub = FirebaseFirestore.instance
        .collection('markets')
        .doc(storeId)
        .collection('present_order')
        .snapshots()
        .listen(
          (snapshot) {
            if (!_seenPresentInitial) {
              _seenPresentInitial = true;
              return;
            }
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.modified) continue;
              _emitIfReturned(
                storeId: storeId,
                status: change.doc.data()?['status']?.toString(),
                orderDocumentId: change.doc.id,
              );
            }
          },
          onError: (Object e, StackTrace st) {
            // ignore: avoid_print
            print('StoreOfficeReturnListener (present_order): $e\n$st');
          },
        );

    _deliverySub = FirebaseFirestore.instance
        .collection('request delivery')
        .where('marketId', isEqualTo: storeId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!_seenDeliveryInitial) {
              _seenDeliveryInitial = true;
              return;
            }
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.modified) continue;
              final data = change.doc.data();
              final orderDocumentId =
                  data?['orderDocumentId']?.toString() ?? '';
              _emitIfReturned(
                storeId: storeId,
                status: data?['status']?.toString(),
                orderDocumentId: orderDocumentId,
              );
            }
          },
          onError: (Object e, StackTrace st) {
            // ignore: avoid_print
            print('StoreOfficeReturnListener (request delivery): $e\n$st');
          },
        );
  }

  Future<void> dispose() async {
    await _presentSub?.cancel();
    await _deliverySub?.cancel();
    _presentSub = null;
    _deliverySub = null;
  }
}
