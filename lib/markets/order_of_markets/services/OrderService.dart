import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/order_status_helper.dart';
import 'package:bazar_suez/markets/wallet/services/commission_service.dart';

class OrderService {
  Stream<QuerySnapshot> streamPresentOrders(String marketId) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamPastOrders(
    String marketId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // orderBy removed to avoid composite index requirement — sorting is done client-side
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .where('isActive', isEqualTo: false);

    return query.snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPresentOrder(
    String marketId,
    String documentId,
  ) {
    return FirebaseFirestore.instance
        .collection('orders')
        .doc(documentId)
        .get();
  }

  Future<void> updatePresentOrderStatus(
    String marketId,
    String documentId,
    String newStatus,
  ) async {
    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(documentId)
        .update({
          'status': newStatus,
          'orderStatus': _mapToDbStatus(newStatus),
          'updatedAt': FieldValue.serverTimestamp(),
          'statusHistory': FieldValue.arrayUnion([
            {
              'status': newStatus,
              'time': Timestamp.fromDate(now),
            }
          ]),
        });
  }

  // Keep updateUserOrder for backward compatibility, but target unified order doc
  Future<void> updateUserOrder(
    String userId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now();
    final updatedData = Map<String, dynamic>.from(data);
    if (data.containsKey('status')) {
      updatedData['orderStatus'] = _mapToDbStatus(data['status']);
      updatedData['statusHistory'] = FieldValue.arrayUnion([
        {
          'status': data['status'],
          'time': Timestamp.fromDate(now),
        }
      ]);
    }
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(documentId)
        .update(updatedData);
  }

  /// ينقل الطلب إلى الطلبات السابقة إذا اكتمل التوصيل ولم يُنقل بعد
  Future<bool> finalizeDeliveredOrder(
    String marketId,
    String documentId,
  ) async {
    final orderDoc = await getPresentOrder(marketId, documentId);
    if (!orderDoc.exists) return false;

    final data = orderDoc.data() ?? <String, dynamic>{};
    if (data['isActive'] == false) return false;
    if (!OrderStatusHelper.isDelivered(data)) return false;

    await moveToPastOrder(
      marketId,
      documentId,
      data,
      'تم التسليم للطيار',
    );

    final customerInfo =
        data['customerInfo'] as Map<String, dynamic>? ?? {};
    final customerId =
        customerInfo['userId'] as String? ?? data['userId'] as String?;
    if (customerId != null && customerId.isNotEmpty) {
      try {
        await updateUserOrder(customerId, documentId, {
          'status': 'تم التسليم للطيار',
          'updatedAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    return true;
  }

  /// مزامنة الطلبات المكتملة التى لم تُنقل بعد إلى الطلبات السابقة
  Future<void> syncCompletedOrdersForMarket(String marketId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      if (OrderStatusHelper.isDelivered(doc.data())) {
        try {
          await finalizeDeliveredOrder(marketId, doc.id);
        } catch (_) {}
      }
    }
  }

  Future<void> moveToPastOrder(
    String marketId,
    String documentId,
    Map<String, dynamic> orderData,
    String newStatus,
  ) async {
    final completedAt = FieldValue.serverTimestamp();
    final now = DateTime.now();

    // Instead of copying, we update isActive to false in the unified collection
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(documentId)
        .update({
          'isActive': false,
          'status': newStatus,
          'orderStatus': _mapToDbStatus(newStatus),
          'updatedAt': completedAt,
          'completedAt': completedAt,
          'statusHistory': FieldValue.arrayUnion([
            {
              'status': newStatus,
              'time': Timestamp.fromDate(now),
            }
          ]),
        });

    // خصم العمولة عند التسليم الناجح فقط
    if (newStatus == 'تم التسليم للطيار' || newStatus == 'التسليم الذاتي') {
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('markets').doc(marketId).get();
        final ownerId = storeDoc.data()?['ownerId'] as String?;
        
        if (ownerId != null) {
          final dynamic totalAmountRaw = orderData['totalAmount'];
          final num totalAmountNum = totalAmountRaw is num
              ? totalAmountRaw
              : num.tryParse('$totalAmountRaw') ?? 0;
          
          await CommissionService().deductOrderCommission(
            orderId: documentId,
            storeId: marketId,
            ownerId: ownerId,
            orderTotal: totalAmountNum.toDouble(),
          );
        }
      } catch (e) {
        // Best-effort: لا نمنع إكمال الطلب بسبب فشل خصم العمولة
        // ignore: avoid_print
        print('Failed to deduct commission for order $documentId: $e');
      }
    }

    // 3) update store statistics if delivered to driver
    if (newStatus == 'تم التسليم للطيار') {
      final dynamic totalAmountRaw = orderData['totalAmount'];
      final num totalAmountNum = totalAmountRaw is num
          ? totalAmountRaw
          : num.tryParse('$totalAmountRaw') ?? 0;
      try {
        // Use server-side timestamp semantics for day bucketing
        final DateTime completionDate = Timestamp.now().toDate();
        await _updateStoreStatistics(
          marketId,
          totalAmountNum.toDouble(),
          completionDate,
        );
      } catch (e) {
        // Best-effort: don't block order move on stats failure
        // ignore: avoid_print
        print('Failed to update statistics for $marketId: $e');
      }

      try {
        final items = orderData['items'] as List<dynamic>? ?? const [];
        await _updateStoreProductSales(marketId, items);
      } catch (e) {
        // ignore: avoid_print
        print('Failed to update product sales stats for $marketId: $e');
      }
    }
  }

  String _mapToDbStatus(String arabicStatus) {
    switch (arabicStatus) {
      case 'قيد المراجعة':
        return 'pending';
      case 'تم استلام الطلب':
        return 'accepted';
      case 'جارى تسليم للدليفري':
        return 'delivering';
      case 'التسليم الذاتي':
        return 'self_delivery';
      case 'تم التسليم للطيار':
        return 'completed';
      case 'تم رفض الطلب':
        return 'rejected';
      default:
        return arabicStatus;
    }
  }

  Future<void> _updateStoreStatistics(
    String storeId,
    double orderAmount,
    DateTime completedAt,
  ) async {
    final String year = completedAt.year.toString();
    final String month = completedAt.month.toString().padLeft(2, '0');
    final String dayKey =
        '${completedAt.year.toString().padLeft(4, '0')}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';

    final DocumentReference<Map<String, dynamic>> statsDoc = FirebaseFirestore
        .instance
        .collection('markets')
        .doc(storeId)
        .collection('statistics')
        .doc(year);

    await statsDoc.set({
      'summary': {
        'totalSales': FieldValue.increment(orderAmount),
        'totalOrders': FieldValue.increment(1),
      },
      'months': {
        month: {
          'totalSales': FieldValue.increment(orderAmount),
          'totalOrders': FieldValue.increment(1),
        },
      },
      'days': {
        dayKey: {
          'totalSales': FieldValue.increment(orderAmount),
          'totalOrders': FieldValue.increment(1),
        },
      },
    }, SetOptions(merge: true));
  }

  Future<void> _updateStoreProductSales(String storeId, List<dynamic> items) async {
    if (items.isEmpty) return;

    final Map<String, dynamic> productUpdates = {};
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final productName = (item['productName'] ?? '').toString().trim();
      if (productName.isEmpty) continue;

      final rawQty = item['quantity'];
      final qty = rawQty is num ? rawQty.toInt() : int.tryParse('$rawQty') ?? 0;
      if (qty > 0) {
        // Clean dot characters so Firestore doesn't treat them as subkeys
        final safeName = productName.replaceAll('.', '_');
        productUpdates['sales.$safeName'] = FieldValue.increment(qty);
      }
    }

    if (productUpdates.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('markets')
        .doc(storeId)
        .collection('statistics')
        .doc('product_sales')
        .set(productUpdates, SetOptions(merge: true));
  }
}
