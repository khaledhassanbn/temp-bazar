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
      print('📤 محاولة إرسال طلب التوصيل لـ unified orders...');
      print('📋 البيانات: ${data.keys.toList()}');

      final orderId = data['orderDocumentId'] as String? ?? data['orderId'] as String;
      final officeId = data['officeId'] as String;

      // تنظيف البيانات من أي قيم null غير صالحة
      final cleanedData = <String, dynamic>{};
      data.forEach((key, value) {
        if (value != null) {
          cleanedData[key] = value;
        }
      });

      final deliveryRequestData = {
        'officeId': officeId,
        'officeName': cleanedData['officeName'],
        'officePhone': cleanedData['officePhone'],
        'officeEmail': cleanedData['officeEmail'],
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'assignedDriverName': null,
        'assignedDriverPhone': null,
      };

      await _firestore.collection('orders').doc(orderId).update({
        'deliveryRequest': deliveryRequestData,
        'access.$officeId': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ تم إنشاء طلب التوصيل بنجاح في المستند: $orderId');
    } catch (e, stackTrace) {
      print('❌ خطأ في إنشاء طلب التوصيل: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // الاستماع لطلبات التوصيل المرفوضة لمتجر معين
  Stream<List<Map<String, dynamic>>> streamRejectedRequests(String marketId) {
    return _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .where('deliveryRequest.status', isEqualTo: 'rejected')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final docData = doc.data();
                final deliveryRequest = docData['deliveryRequest'] as Map<String, dynamic>? ?? {};
                return {
                  'id': doc.id,
                  'orderDocumentId': doc.id,
                  'officeName': deliveryRequest['officeName'],
                  ...deliveryRequest,
                };
              })
              .toList(),
        );
  }

  /// ✅ stream all delivery requests for a specific market
  Stream<List<Map<String, dynamic>>> streamRequestsForMarket(
    String marketId,
  ) {
    return _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                final docData = doc.data();
                return docData['deliveryRequest'] != null;
              })
              .map((doc) {
                final docData = doc.data();
                final deliveryRequest = docData['deliveryRequest'] as Map<String, dynamic>? ?? {};
                return {
                  'id': doc.id,
                  'orderDocumentId': doc.id,
                  ...deliveryRequest,
                };
              })
              .toList(),
        );
  }

  /// ✅ stream all delivery requests for a specific customer (user)
  Stream<List<Map<String, dynamic>>> streamRequestsForCustomer(
    String customerId,
  ) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) {
                final docData = doc.data();
                return docData['deliveryRequest'] != null;
              })
              .map((doc) {
                final docData = doc.data();
                final deliveryRequest = docData['deliveryRequest'] as Map<String, dynamic>? ?? {};
                return {
                  'id': doc.id,
                  'orderDocumentId': doc.id,
                  ...deliveryRequest,
                };
              })
              .toList(),
        );
  }

  // حذف طلب توصيل بعد معالجته
  Future<void> deleteRequest(String requestId) async {
    final doc = await _firestore.collection('orders').doc(requestId).get();
    if (doc.exists) {
      final docData = doc.data() ?? {};
      final deliveryRequest = docData['deliveryRequest'] as Map<String, dynamic>? ?? {};
      final officeId = deliveryRequest['officeId'] as String?;
      
      final updates = <String, dynamic>{
        'deliveryRequest': FieldValue.delete(),
      };
      if (officeId != null) {
        updates['access.$officeId'] = FieldValue.delete();
      }
      await _firestore.collection('orders').doc(requestId).update(updates);
    }
  }

  // تحديث حالة طلب التوصيل
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    await _firestore.collection('orders').doc(requestId).update({
      'deliveryRequest.status': newStatus,
      'deliveryRequest.updatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
