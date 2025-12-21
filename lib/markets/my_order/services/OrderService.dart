import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  Stream<QuerySnapshot> streamPresentOrders(String marketId) {
    return FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('present_order')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> streamPastOrders(
    String marketId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('past_order');

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThan: Timestamp.fromDate(endDate));
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPresentOrder(
    String marketId,
    String documentId,
  ) {
    return FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('present_order')
        .doc(documentId)
        .get();
  }

  Future<void> updatePresentOrderStatus(
    String marketId,
    String documentId,
    String newStatus,
  ) async {
    await FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('present_order')
        .doc(documentId)
        .update({
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateUserOrder(
    String userId,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(documentId)
        .update(data);
  }

  Future<void> moveToPastOrder(
    String marketId,
    String documentId,
    Map<String, dynamic> orderData,
    String newStatus,
  ) async {
    final completedAt = FieldValue.serverTimestamp();
    final updatedOrderData = {
      ...orderData,
      'status': newStatus,
      'updatedAt': completedAt,
      'completedAt': completedAt,
    };

    // 1) copy to past_order
    await FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('past_order')
        .doc(documentId)
        .set(updatedOrderData);

    // 2) delete from present_order
    await FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .collection('present_order')
        .doc(documentId)
        .delete();

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
}
