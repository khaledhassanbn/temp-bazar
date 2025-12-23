import 'package:cloud_firestore/cloud_firestore.dart';

/// خدمة جلب طلبات المستخدم
class UserOrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب طلبات المستخدم من /users/{userId}/orders
  Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    print('🔍 جلب طلبات المستخدم من users/$userId/orders');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📦 عدد الطلبات الموجودة: ${snapshot.docs.length}');
          
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            data['documentId'] = doc.id;
            return data;
          }).toList();
          
          return orders;
        });
  }

  /// جلب طلب واحد
  Future<DocumentSnapshot> getOrder(String userId, String orderId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();
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
