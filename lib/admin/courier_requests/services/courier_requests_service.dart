import 'package:cloud_firestore/cloud_firestore.dart';

class CourierRequestsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// الحصول على تدفق فوري (Stream) لجميع طلبات تسجيل المناديب
  /// مرتبة تنازلياً حسب تاريخ الإنشاء إن وجد
  Stream<QuerySnapshot<Map<String, dynamic>>> getCourierRequestsStream() {
    return _firestore
        .collection('courier_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// قبول طلب المندوب
  /// يغير الحالة إلى approved
  Future<void> approveRequest(String requestId) async {
    await _firestore.collection('courier_requests').doc(requestId).update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// رفض طلب المندوب مع حفظ سبب الرفض
  /// يغير الحالة إلى rejected ويحفظ سبب الرفض
  Future<void> rejectRequest(String requestId, String reason) async {
    await _firestore.collection('courier_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
