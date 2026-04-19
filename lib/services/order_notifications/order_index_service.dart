import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_notification_constants.dart';

/// كتابة سجل طلب خفيف في `orders` ليُطلق [sendNewOrderNotification] (Cloud Function)
/// ويُستخدَم لاستعلام `status == new` في تطبيق التاجر.
class OrderIndexService {
  OrderIndexService._();
  static final OrderIndexService instance = OrderIndexService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ينشئ/يحدّث المستند [orderId] داخل `orders` بنفس مُعرّف طلب `present_order`.
  Future<void> createOrUpdateOrderIndex({
    required String orderId,
    required String storeId,
    required String userId,
  }) {
    return _db.collection('orders').doc(orderId).set(
      {
        OrderNotificationFields.id: orderId,
        OrderNotificationFields.storeId: storeId,
        OrderNotificationFields.userId: userId,
        OrderNotificationFields.status: OrderIndexStatus.newOrder,
        OrderNotificationFields.createdAt: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
