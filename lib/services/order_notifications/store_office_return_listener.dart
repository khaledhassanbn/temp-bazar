import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_notification_coordinator.dart';

bool _isReturnedToMerchantRaw(String? status) {
  if (status == null || status.isEmpty) return false;
  return status.trim().toLowerCase() == 'returned_to_merchant';
}

/// يستمع لتعديلات [orders] عندما يضع المكتب أو الطلب الحالة `returned_to_merchant`.
class StoreOfficeReturnListener {
  StoreOfficeReturnListener(this.storeId);

  final String storeId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _seenInitial = false;

  void start() {
    _sub?.cancel();
    _seenInitial = false;

    _sub = FirebaseFirestore.instance
        .collection('orders')
        .where('storeId', isEqualTo: storeId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!_seenInitial) {
              _seenInitial = true;
              return;
            }
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.modified) continue;
              final data = change.doc.data();
              if (data == null) continue;
              
              final deliveryRequest = data['deliveryRequest'] as Map<String, dynamic>? ?? {};
              
              final isReturnedMain = _isReturnedToMerchantRaw(data['orderStatus']?.toString() ?? data['status']?.toString());
              final isReturnedDelivery = _isReturnedToMerchantRaw(deliveryRequest['status']?.toString());
              
              if (isReturnedMain || isReturnedDelivery) {
                final returnedBy = (data['returnedBy'] ?? '').toString();
                OrderNotificationCoordinator.instance.notifyOfficeReturnedOrder(
                  orderDocumentId: change.doc.id,
                  storeId: storeId,
                  returnedBy: returnedBy.isNotEmpty ? returnedBy : null,
                  goodsPickedUp: data['goodsPickedUp'] == true,
                );
              }
            }
          },
          onError: (Object e, StackTrace st) {
            // ignore: avoid_print
            print('StoreOfficeReturnListener error: $e\n$st');
          },
        );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
