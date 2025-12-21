import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchActiveOffices() async {
    // جلب كل المكاتب أولاً ثم الفلترة في الذاكرة لتجنب الحاجة لفهرس مركب
    final query = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'office')
        .get();

    // فلترة المكاتب: status = true و walletBalance > 10
    final offices = query.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((office) {
          final status = office['status'];
          final walletBalance = office['walletBalance'];
          final balance = walletBalance is num ? walletBalance.toDouble() : 0.0;
          return status == true && balance > 10;
        })
        .toList();

    return offices;
  }

  Future<void> createRequest(Map<String, dynamic> data) async {
    try {
      print('📤 محاولة إرسال طلب التوصيل...');
      print('📋 البيانات: ${data.keys.toList()}');

      // تنظيف البيانات من أي قيم null غير صالحة
      final cleanedData = <String, dynamic>{};
      data.forEach((key, value) {
        if (value != null) {
          cleanedData[key] = value;
        }
      });

      final docRef = await _firestore.collection('request delivery').add({
        ...cleanedData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ تم إنشاء الطلب بنجاح: ${docRef.id}');
    } catch (e, stackTrace) {
      print('❌ خطأ في إنشاء طلب التوصيل: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow; // إعادة رمي الخطأ حتى يتم التعامل معه في الـ ViewModel
    }
  }

  // الاستماع لطلبات التوصيل المرفوضة لمتجر معين
  Stream<List<Map<String, dynamic>>> streamRejectedRequests(String marketId) {
    return _firestore
        .collection('request delivery')
        .where('marketId', isEqualTo: marketId)
        .where('status', isEqualTo: 'rejected')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // حذف طلب توصيل بعد معالجته
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('request delivery').doc(requestId).delete();
  }

  // تحديث حالة طلب التوصيل
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    await _firestore.collection('request delivery').doc(requestId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
