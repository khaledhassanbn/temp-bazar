import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double fallbackCommissionRate = 5.0;
  static const String fallbackCommissionType = 'fixed';

  /// حساب رسوم الخدمة (= العمولة) المعروضة للعميل في الفاتورة
  Future<double> calculateServiceFee({
    required String storeId,
    required double subtotal,
  }) async {
    try {
      final config = await getCommissionConfig();
      final defaultRate =
          (config['defaultCommissionRate'] ?? fallbackCommissionRate).toDouble();
      final defaultType =
          config['defaultCommissionType'] ?? fallbackCommissionType;

      final storeDoc =
          await _firestore.collection('markets').doc(storeId).get();
      final storeData = storeDoc.data() ?? {};
      final rate = (storeData['commissionRate'] ?? defaultRate).toDouble();
      final type = storeData['commissionType'] ?? defaultType;

      return computeCommissionAmount(rate: rate, type: type, subtotal: subtotal);
    } catch (e) {
      print('Error calculating service fee: $e');
      return fallbackCommissionRate;
    }
  }

  /// نفس منطق العمولة — رسوم الخدمة والعمولة قيمة واحدة
  static double computeCommissionAmount({
    required double rate,
    required String type,
    required double subtotal,
  }) {
    if (type == 'percentage') {
      return subtotal * (rate / 100);
    }
    return rate;
  }

  /// خصم العمولة عند اكتمال الطلب — داخل Firestore Transaction
  Future<bool> deductOrderCommission({
    required String orderId,
    required String storeId,
    required String ownerId,
    required double orderTotal,
  }) async {
    try {
      return await _firestore.runTransaction((txn) async {
        // 1. قراءة الطلب
        final orderRef = _firestore.collection('orders').doc(orderId);
        final orderSnap = await txn.get(orderRef);
        if (!orderSnap.exists) {
          throw Exception('الطلب غير موجود');
        }
        final orderData = orderSnap.data() ?? {};

        // 2. فحص Idempotency
        if (orderData['commissionDeducted'] == true) {
          return false;
        }

        // 3. قراءة الإعدادات الافتراضية
        final configRef = _firestore
            .collection('commission_config')
            .doc('default');
        final configSnap = await txn.get(configRef);
        final configData = configSnap.data() ?? {};
        final defaultRate = (configData['defaultCommissionRate'] ?? 5.0)
            .toDouble();
        final defaultType = configData['defaultCommissionType'] ?? 'fixed';

        // 4. قراءة إعدادات المتجر
        final storeRef = _firestore.collection('markets').doc(storeId);
        final storeSnap = await txn.get(storeRef);
        final storeData = storeSnap.data() ?? {};

        // 5. قراءة رصيد المستخدم
        final userRef = _firestore.collection('users').doc(ownerId);
        final userSnap = await txn.get(userRef);
        final currentBalance = (userSnap.data()?['walletBalance'] ?? 0.0)
            .toDouble();

        // 6. العمولة = serviceFee المحفوظ في الطلب (نفس ما دفعه الزبون)
        final savedServiceFee = (orderData['serviceFee'] as num?)?.toDouble();
        double commission;
        if (savedServiceFee != null && savedServiceFee > 0) {
          commission = savedServiceFee;
        } else {
          // طلبات قديمة بدون serviceFee — إعادة حساب من الإعدادات
          final rate = (storeData['commissionRate'] ?? defaultRate).toDouble();
          final type = storeData['commissionType'] ?? defaultType;
          final subtotal =
              (orderData['subtotal'] as num?)?.toDouble() ?? orderTotal;
          commission = computeCommissionAmount(
            rate: rate,
            type: type,
            subtotal: subtotal,
          );
        }

        if (commission <= 0) {
          return false;
        }

        final rate = (storeData['commissionRate'] ?? defaultRate).toDouble();
        final type = storeData['commissionType'] ?? defaultType;

        // 7. الخصم (يُسمح بالسالب)
        final newBalance = currentBalance - commission;

        // 8. كتابة التحديثات
        txn.update(orderRef, {
          'commissionDeducted': true,
          'commissionAmount': commission,
          'commissionDeductedAt': FieldValue.serverTimestamp(),
        });

        txn.update(userRef, {'walletBalance': newBalance});

        txn.update(storeRef, {
          'totalCommissionsPaid':
              (storeData['totalCommissionsPaid'] ?? 0.0) + commission,
          'lastCommissionAt': FieldValue.serverTimestamp(),
        });

        // 9. إنشاء سجل المحفظة
        final ledgerRef = _firestore.collection('wallet_ledger').doc();
        txn.set(ledgerRef, {
          'id': ledgerRef.id,
          'storeId': storeId,
          'userId': ownerId,
          'type': 'order_commission',
          'amount': -commission,
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'referenceId': orderId,
          'referenceType': 'order',
          'description': 'عمولة طلب #$orderId',
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'orderId': orderId,
            'commissionType': type,
            'commissionRate': rate,
            'serviceFee': commission,
            'orderTotal': orderTotal,
          },
        });

        return true;
      });
    } catch (e) {
      print('Error in deductOrderCommission: $e');
      return false;
    }
  }

  /// فحص هل المتجر يمكنه استقبال طلبات جديدة بناءً على الحد الائتماني
  Future<bool> canStoreReceiveNewOrders(String storeId) async {
    try {
      final storeDoc = await _firestore
          .collection('markets')
          .doc(storeId)
          .get();
      if (!storeDoc.exists) return false;

      final storeData = storeDoc.data() ?? {};
      final ownerId = storeData['ownerId'] as String?;
      if (ownerId == null) return false;

      // فحص الحقل الأساسي للمتجر إن كان مغلق يدوياً أولاً
      final canReceiveOrders = storeData['canReceiveOrders'] ?? true;
      if (canReceiveOrders == false) return false;

      // قراءة الإعدادات الافتراضية
      double creditLimit = -50.0;
      try {
        final configDoc = await _firestore
            .collection('commission_config')
            .doc('default')
            .get();
        if (configDoc.exists) {
          creditLimit = (configDoc.data()?['defaultCreditLimit'] ?? -50.0)
              .toDouble();
        }
      } catch (_) {}

      // قراءة الحد الائتماني الخاص بالمتجر إن وجد
      if (storeData['creditLimit'] != null) {
        creditLimit = (storeData['creditLimit'] as num).toDouble();
      }

      // قراءة رصيد محفظة صاحب المتجر
      final userDoc = await _firestore.collection('users').doc(ownerId).get();
      if (!userDoc.exists) return false;

      final walletBalance = (userDoc.data()?['walletBalance'] ?? 0.0)
          .toDouble();

      return walletBalance > creditLimit;
    } catch (e) {
      print('Error in canStoreReceiveNewOrders: $e');
      return false; // في حالة وجود خطأ نفضل الأمان ونمنع استقبال الطلبات، أو نسمح بها؟ خطوة الأمان تمنع.
    }
  }

  /// جلب إعدادات العمولة العامة
  Future<Map<String, dynamic>> getCommissionConfig() async {
    try {
      final doc = await _firestore
          .collection('commission_config')
          .doc('default')
          .get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting commission config: $e');
      return {};
    }
  }
}
