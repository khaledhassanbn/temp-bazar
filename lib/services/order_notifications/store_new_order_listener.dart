import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_notification_constants.dart';
import 'order_notification_coordinator.dart';

/// يستمع لمستندات `orders` بحالة `new` لمتجر معيّن (واجهة المتجر الأمامية).
class StoreNewOrderListener {
  StoreNewOrderListener(this.storeId);

  final String storeId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _seenInitialSnapshot = false;

  void start() {
    _sub?.cancel();
    _seenInitialSnapshot = false;
    _sub = FirebaseFirestore.instance
        .collection('orders')
        .where(OrderNotificationFields.storeId, isEqualTo: storeId)
        .where(OrderNotificationFields.status, isEqualTo: OrderIndexStatus.newOrder)
        // حماية من تحميل/معالجة عدد ضخم من الطلبات القديمة عند فتح التطبيق.
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            // أول snapshot غالباً يحتوي على كل المستندات الحالية ويظهر كـ "added" في docChanges.
            // تجاهله يمنع ثِقل فتح الصفحات/عرض حوارات متتالية لطلبات قديمة.
            if (!_seenInitialSnapshot) {
              _seenInitialSnapshot = true;
              return;
            }
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                OrderNotificationCoordinator.instance.notifyNewOrder(
                  orderId: change.doc.id,
                  storeId: storeId,
                );
              }
            }
          },
          onError: (Object e, StackTrace st) {
            // تجنّب تعطيل التطبيق؛ يمكن إرسال إلى Crashlytics لاحقاً.
            // ignore: avoid_print
            print('StoreNewOrderListener error: $e\n$st');
          },
        );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
