import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pending_payment_model.dart';
import '../../wallet/services/wallet_service.dart';

class PendingPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  // إنشاء دفع معلق بعد خصم المبلغ من المحفظة
  Future<String> createPendingPayment({
    required String userId,
    required String packageId,
    required String packageName,
    required double amount,
    required int days,
  }) async {
    try {
      // فحص الرصيد
      final balance = await _walletService.getWalletBalance(userId);
      if (balance < amount) {
        throw Exception('رصيدك غير كافٍ');
      }

      // خصم المبلغ من المحفظة
      final deducted = await _walletService.deductFromWallet(userId, amount);
      if (!deducted) {
        throw Exception('رصيدك غير كافٍ');
      }

      // إنشاء الدفع المعلق
      final paymentId = _firestore.collection('pending_payments').doc().id;
      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      final payment = PendingPayment(
        id: paymentId,
        userId: userId,
        packageId: packageId,
        packageName: packageName,
        amount: amount,
        days: days,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        status: 'pending',
      );

      await _firestore
          .collection('pending_payments')
          .doc(paymentId)
          .set(payment.toJson());

      return paymentId;
    } catch (e) {
      throw Exception('فشل إنشاء الدفع المعلق: ${e.toString()}');
    }
  }

  // الحصول على الدفع المعلق للمستخدم
  Future<PendingPayment?> getPendingPayment(String userId) async {
    try {
      // محاولة الاستعلام مع orderBy أولاً
      QueryDocumentSnapshot? doc;
      try {
        final snapshot = await _firestore
            .collection('pending_payments')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          doc = snapshot.docs.first;
        }
      } catch (e) {
        // إذا فشل الاستعلام (مثلاً بسبب عدم وجود index)، جرب بدون orderBy
        print('خطأ في الاستعلام مع orderBy، جاري المحاولة بدون orderBy: $e');
        final tempSnapshot = await _firestore
            .collection('pending_payments')
            .where('userId', isEqualTo: userId)
            .where('status', isEqualTo: 'pending')
            .get();

        // ترتيب النتائج يدوياً حسب createdAt
        if (tempSnapshot.docs.isNotEmpty) {
          final docsList = tempSnapshot.docs.toList();
          docsList.sort((a, b) {
            final aData = a.data();
            final bData = b.data();
            final aCreated = aData['createdAt'] as Timestamp?;
            final bCreated = bData['createdAt'] as Timestamp?;
            if (aCreated == null || bCreated == null) return 0;
            return bCreated.compareTo(aCreated); // descending
          });
          // استخدام أول document بعد الترتيب
          doc = docsList.first;
        }
      }

      if (doc == null) {
        print('لا يوجد pending payment للمستخدم: $userId');
        return null;
      }
      final data = doc.data() as Map<String, dynamic>;
      final payment = PendingPayment.fromJson({'id': doc.id, ...data});

      print(
        'تم العثور على pending payment: ${payment.id}, isValid: ${payment.isValid}, isExpired: ${payment.isExpired}',
      );

      // التحقق من انتهاء الصلاحية
      if (payment.isExpired) {
        print('Pending payment منتهي الصلاحية، جاري إلغاؤه');
        await _expirePayment(doc.id, userId, payment.amount);
        return null;
      }

      return payment;
    } catch (e) {
      print('خطأ في getPendingPayment: $e');
      return null;
    }
  }

  // ربط الدفع بالمتجر عند الإنشاء
  Future<void> linkPaymentToStore(String paymentId, String storeId) async {
    try {
      await _firestore.collection('pending_payments').doc(paymentId).update({
        'storeId': storeId,
        'status': 'completed',
      });
    } catch (e) {
      throw Exception('فشل ربط الدفع بالمتجر: ${e.toString()}');
    }
  }

  // إلغاء الدفع المعلق وإعادة المبلغ
  Future<void> cancelPendingPayment(String paymentId, String userId) async {
    try {
      final doc = await _firestore
          .collection('pending_payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) {
        return;
      }

      final data = doc.data()!;
      final amount = (data['amount'] ?? 0.0).toDouble();
      final status = data['status'] as String? ?? '';

      if (status == 'completed') {
        return; // لا يمكن إلغاء دفع مكتمل
      }

      // إعادة المبلغ للمستخدم
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      // تحديث حالة الدفع
      await _firestore.collection('pending_payments').doc(paymentId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      throw Exception('فشل إلغاء الدفع: ${e.toString()}');
    }
  }

  // انتهاء صلاحية الدفع تلقائياً
  Future<void> _expirePayment(
    String paymentId,
    String userId,
    double amount,
  ) async {
    try {
      // إعادة المبلغ للمستخدم
      await _firestore.collection('users').doc(userId).update({
        'walletBalance': FieldValue.increment(amount),
      });

      // تحديث حالة الدفع
      await _firestore.collection('pending_payments').doc(paymentId).update({
        'status': 'expired',
      });
    } catch (e) {
      print('خطأ في انتهاء صلاحية الدفع: $e');
    }
  }

  // التحقق من وجود دفع معلق نشط
  Future<bool> hasActivePendingPayment(String userId) async {
    final payment = await getPendingPayment(userId);
    return payment != null && payment.isValid;
  }
}
