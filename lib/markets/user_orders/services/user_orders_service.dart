import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة جلب طلبات المستخدم
class UserOrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _statusPendingReviewArabic = 'قيد المراجعة';
  static const String _statusPendingReviewEnglish = 'pending';

  /// جلب طلبات المستخدم من المجموعه الموحده /orders
  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    // orderBy removed to avoid composite index requirement — sorting is done client-side
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapAndSortOrders);
  }

  List<Map<String, dynamic>> _mapAndSortOrders(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final orders = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['documentId'] = doc.id;
      return data;
    }).toList();

    orders.sort((a, b) {
      final aTs = a['createdAt'];
      final bTs = b['createdAt'];
      if (aTs is Timestamp && bTs is Timestamp) {
        return bTs.compareTo(aTs);
      }
      return 0;
    });

    return orders;
  }

  /// جلب طلب واحد من المجموعه الموحده /orders
  Future<DocumentSnapshot> getOrder(String userId, String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .get();
  }

  Future<void> cancelOrderByCustomer({
    required String orderId,
    required String userId,
    String? reason,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || normalizedUserId.toLowerCase() == 'null') {
      throw Exception('تعذر تحديد حساب العميل لهذا الطلب');
    }

    final orderRef = _firestore.collection('orders').doc(orderId);
    final userRef = _firestore.collection('users').doc(normalizedUserId);

    await _firestore.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('الطلب غير موجود');
      }

      final orderData = orderSnap.data() ?? <String, dynamic>{};
      final userSnap = await transaction.get(userRef);
      final userData = userSnap.data() ?? <String, dynamic>{};

      final currentStatus = _resolveCurrentStatus(orderData);
      final isPendingReview = _isPendingReviewStatus(currentStatus);
      final isAlreadyFinal = _isFinalStatus(currentStatus);
      if (isAlreadyFinal) {
        throw Exception('لا يمكن إلغاء هذا الطلب في حالته الحالية');
      }

      final now = FieldValue.serverTimestamp();
      final cancelReason =
          (reason == null || reason.trim().isEmpty) ? 'cancelled_by_customer' : reason.trim();

      final successfulRaw = userData['successfulOrders'];
      final cancelledRaw = userData['cancelledOrders'];
      int successfulOrders =
          successfulRaw is num ? successfulRaw.toInt() : 0;
      int cancelledOrders = cancelledRaw is num ? cancelledRaw.toInt() : 0;

      if (!isPendingReview) {
        cancelledOrders += 1;
      }

      final impactedTotal = successfulOrders + cancelledOrders;
      final reliability = impactedTotal == 0
          ? 100.0
          : ((successfulOrders / impactedTotal) * 100.0);

      transaction.update(orderRef, {
        'status': 'cancelled_by_customer',
        'orderStatus': 'cancelled_by_customer',
        'isActive': false,
        'cancelReason': cancelReason,
        'cancelledAt': now,
        'updatedAt': now,
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'cancelled_by_customer',
            'by': 'customer',
            'time': Timestamp.now(),
          }
        ]),
      });

      transaction.set(
        userRef,
        {
          'successfulOrders': successfulOrders,
          'cancelledOrders': cancelledOrders,
          'customerReliability': reliability.clamp(0, 100),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      final storeId = (orderData['storeId'] ?? orderData['marketId'] ?? '').toString();
      if (storeId.isNotEmpty) {
        final merchantNotificationRef =
            _firestore.collection('order_notifications').doc();
        transaction.set(merchantNotificationRef, {
          'type': 'order_cancelled_by_customer',
          'targetType': 'merchant',
          'storeId': storeId,
          'orderId': orderId,
          'userId': normalizedUserId,
          'title': 'إلغاء طلب من عميل',
          'body': 'قام العميل بإلغاء الطلب رقم $orderId',
          'isRead': false,
          'createdAt': now,
        });
      }

      final courierId = _extractCourierId(orderData);
      if (courierId.isNotEmpty) {
        final courierNotificationRef =
            _firestore.collection('order_notifications').doc();
        transaction.set(courierNotificationRef, {
          'type': 'order_cancelled_by_customer',
          'targetType': 'courier',
          'courierId': courierId,
          'orderId': orderId,
          'userId': normalizedUserId,
          'title': 'تم إلغاء الطلب',
          'body': 'قام العميل بإلغاء الطلب رقم $orderId',
          'isRead': false,
          'createdAt': now,
        });
      }
    });
  }

  Future<void> markOrderAsDeliveredSuccess({
    required String userId,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final userData = userSnap.data() ?? <String, dynamic>{};

      final successfulRaw = userData['successfulOrders'];
      final cancelledRaw = userData['cancelledOrders'];
      int successfulOrders =
          successfulRaw is num ? successfulRaw.toInt() : 0;
      final cancelledOrders = cancelledRaw is num ? cancelledRaw.toInt() : 0;

      successfulOrders += 1;
      final impactedTotal = successfulOrders + cancelledOrders;
      final reliability = impactedTotal == 0
          ? 100.0
          : ((successfulOrders / impactedTotal) * 100.0);

      transaction.set(
        userRef,
        {
          'successfulOrders': successfulOrders,
          'cancelledOrders': cancelledOrders,
          'customerReliability': reliability.clamp(0, 100),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> accountSuccessfulOrderIfNeeded({
    required String orderId,
    required String userId,
  }) async {
    final orderRef = _firestore.collection('orders').doc(orderId);
    await _firestore.runTransaction((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) return;
      final orderData = orderSnap.data() ?? <String, dynamic>{};
      final alreadyAccounted = orderData['successReliabilityAccounted'] == true;
      if (alreadyAccounted) return;

      final status = _resolveCurrentStatus(orderData);
      final normalized = status.trim().toLowerCase();
      const successStatuses = {
        'completed',
        'delivered',
        'تم التسليم',
        'الطلب مكتمل',
      };
      if (!successStatuses.contains(status) && !successStatuses.contains(normalized)) {
        return;
      }

      final userRef = _firestore.collection('users').doc(userId);
      final userSnap = await transaction.get(userRef);
      final userData = userSnap.data() ?? <String, dynamic>{};
      final successfulRaw = userData['successfulOrders'];
      final cancelledRaw = userData['cancelledOrders'];
      int successfulOrders =
          successfulRaw is num ? successfulRaw.toInt() : 0;
      final cancelledOrders = cancelledRaw is num ? cancelledRaw.toInt() : 0;

      successfulOrders += 1;
      final impactedTotal = successfulOrders + cancelledOrders;
      final reliability = impactedTotal == 0
          ? 100.0
          : ((successfulOrders / impactedTotal) * 100.0);

      transaction.update(orderRef, {
        'successReliabilityAccounted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        userRef,
        {
          'successfulOrders': successfulOrders,
          'cancelledOrders': cancelledOrders,
          'customerReliability': reliability.clamp(0, 100),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  String _resolveCurrentStatus(Map<String, dynamic> data) {
    final deliveryRequest = _asStringDynamicMap(data['deliveryRequest']);
    if (deliveryRequest != null && deliveryRequest['status'] != null) {
      return deliveryRequest['status'].toString();
    }
    final status = (data['status'] ?? '').toString().trim();
    final orderStatus = (data['orderStatus'] ?? '').toString().trim();
    if (status.isNotEmpty) return status;
    if (orderStatus.isNotEmpty) return orderStatus;
    return '';
  }

  bool _isPendingReviewStatus(String value) {
    final normalized = value.trim().toLowerCase();
    return value == _statusPendingReviewArabic ||
        normalized == _statusPendingReviewEnglish ||
        normalized == 'pending_review';
  }

  bool _isFinalStatus(String value) {
    final normalized = value.trim().toLowerCase();
    const finalStatuses = {
      'completed',
      'delivered',
      'cancelled_by_customer',
      'cancelled_by_merchant',
      'rejected',
      'customer_rejected',
      'تم التسليم',
      'الطلب مكتمل',
      'تم رفض الطلب',
      'تم إلغاء الطلب',
    };
    return finalStatuses.contains(value) || finalStatuses.contains(normalized);
  }

  String _extractCourierId(Map<String, dynamic> orderData) {
    if ((orderData['assignedCourierId'] ?? '').toString().isNotEmpty) {
      return orderData['assignedCourierId'].toString();
    }
    final deliveryRequest = _asStringDynamicMap(orderData['deliveryRequest']);
    if (deliveryRequest != null) {
      final keys = ['courierId', 'driverId', 'assignedDriverId'];
      for (final key in keys) {
        final value = (deliveryRequest[key] ?? '').toString();
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  Map<String, dynamic>? _asStringDynamicMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return null;
  }

  // ======== حالات التطبيق القديم (قبل مكتب الشحن) ========
  static String getLegacyStatusArabic(String status) {
    // لو القيمة أصلاً عربية، نرجعها كما هي
    if (status == 'قيد المراجعة' ||
        status == 'تم استلام الطلب' ||
        status == 'جارى تسليم للدليفري' ||
        status == 'تم التسليم للطيار' ||
        status == 'تم رفض الطلب') {
      return status;
    }

    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم استلام الطلب';
      case 'preparing':
        return 'جارى تسليم للدليفري';
      case 'delivered':
        return 'تم التسليم للطيار';
      case 'rejected':
        return 'تم رفض الطلب';
      default:
        return status;
    }
  }

  static int getLegacyStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0xFFFFA000; // برتقالي
      case 'accepted':
        return 0xFF2196F3; // أزرق
      case 'preparing':
        return 0xFFFFA000; // برتقالي
      case 'delivered':
        return 0xFF4CAF50; // أخضر
      case 'rejected':
        return 0xFFF44336; // أحمر
      default:
        return 0xFF9E9E9E; // رمادي
    }
  }

  // ======== حالات تطبيق مكتب الشحن / المندوب (request delivery) ========
  static String getDeliveryStatusArabic(String status) {
    // لو القيمة عربية بالفعل
    if (status == 'في انتظار قبول المكتب' ||
        status == 'تم قبوله من المكتب' ||
        status == 'تم تعيين مندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'تم استلام الطلب' ||
        status == 'تم التسليم' ||
        status == 'رفض من المندوب' ||
        status == 'الزبون رفض الاستلام' ||
        status == 'مرفوض نهائياً') {
      return status;
    }

    switch (status.toLowerCase()) {
      case 'pending':
        return 'في انتظار قبول المكتب';
      case 'accepted':
        return 'تم قبوله من المكتب';
      case 'assigned':
        return 'تم تعيين مندوب';
      case 'driver_accepted':
        return 'المندوب قبل الطلب';
      case 'picked_up':
        // استلم المندوب الطلب من التاجر وهو الآن فى الطريق للزبون
        return 'المندوب في الطريق';
      case 'completed':
        return 'تم التسليم';
      case 'driver_rejected':
        return 'رفض من المندوب';
      case 'customer_rejected':
        return 'الزبون رفض الاستلام';
      case 'rejected':
        return 'مرفوض نهائياً';
      default:
        return status;
    }
  }

  static int getDeliveryStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0xFFFFA000; // برتقالي
      case 'accepted':
        return 0xFF2196F3; // أزرق
      case 'assigned':
        return 0xFF2196F3; // أزرق
      case 'driver_accepted':
        return 0xFFFF9800; // برتقالي
      case 'picked_up':
        return 0xFF9C27B0; // بنفسجي
      case 'completed':
        return 0xFF4CAF50; // أخضر
      case 'driver_rejected':
      case 'customer_rejected':
      case 'rejected':
        return 0xFFF44336; // أحمر
      default:
        return 0xFF9E9E9E; // رمادي
    }
  }
}
