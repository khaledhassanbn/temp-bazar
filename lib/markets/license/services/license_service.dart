import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../planes/models/package.dart';
import '../../wallet/services/wallet_service.dart';
import '../models/license_status.dart';
import '../../create_market/models/store_model.dart';

class LicenseService {
  final FirebaseFirestore _firestore;
  final WalletService _walletService;

  LicenseService({
    FirebaseFirestore? firestore,
    WalletService? walletService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _walletService = walletService ?? WalletService();

  Future<void> deleteStore(String marketId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    // نستخدم batch لحذف إشارات بسيطة، مع إبقاء الحذف الكامل يدوياً لو حجم البيانات كبير
    final userRef = _firestore.collection('users').doc(user.uid);
    final storeRef = _firestore.collection('markets').doc(marketId);

    await _firestore.runTransaction((txn) async {
      txn.update(userRef, {
        'market_id': FieldValue.delete(),
        'marketId': FieldValue.delete(),
        'market': FieldValue.delete(),
        'status': 'user',
      });
      txn.delete(storeRef);
    });
  }

  Future<LicenseStatus> fetchStatus(String marketId) async {
    final doc = await _firestore.collection('markets').doc(marketId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('المتجر غير موجود');
    }
    return LicenseStatus.fromDoc(marketId, data);
  }

  Future<StoreModel> fetchStore(String marketId) async {
    final doc = await _firestore.collection('markets').doc(marketId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw Exception('المتجر غير موجود');
    }
    return StoreModel.fromMap(marketId, data);
  }

  Future<double> fetchBalance(String userId) {
    return _walletService.getWalletBalance(userId);
  }

  Future<void> toggleAutoRenew({
    required String marketId,
    required bool enabled,
  }) async {
    await _firestore.collection('markets').doc(marketId).update({
      'licenseAutoRenew': enabled,
    });
  }

  Future<LicenseStatus> renewWithPackage({
    required String marketId,
    required Package package,
    required String userId,
  }) async {
    // كل العملية داخل Transaction واحدة: خصم الرصيد + تمديد الترخيص + كتابة سجل
    // wallet_ledger من النوع subscription_payment (رصيد قبل/بعد).
    await _firestore.runTransaction((txn) async {
      final marketRef = _firestore.collection('markets').doc(marketId);
      final userRef = _firestore.collection('users').doc(userId);

      final marketSnap = await txn.get(marketRef);
      final userSnap = await txn.get(userRef);

      final data = marketSnap.data() ?? {};
      final now = DateTime.now();

      final balanceBefore =
          ((userSnap.data()?['walletBalance'] ?? 0.0) as num).toDouble();
      if (balanceBefore < package.price) {
        throw Exception('رصيدك غير كافٍ');
      }
      final balanceAfter = balanceBefore - package.price;

      DateTime readDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return now;
      }

      final currentEnd = readDate(data['licenseEndAt']);
      final base = currentEnd.isAfter(now) ? currentEnd : now;
      final newEnd = base.add(Duration(days: package.days));
      final newEndTs = Timestamp.fromDate(newEnd);

      // خصم الرصيد
      txn.update(userRef, {'walletBalance': balanceAfter});

      txn.update(marketRef, {
        // الحقول الرئيسية للترخيص فقط
        'licenseStartAt': Timestamp.fromDate(now),
        'licenseEndAt': newEndTs,
        // ضبط expiryDate لمواءمة التجديد التلقائي (Cloud Function)
        'expiryDate': newEndTs,
        'licenseDurationDays': package.days,
        'licenseAutoRenew': data['licenseAutoRenew'] ?? false,
        // معلومات الباقة
        'currentPackageId': package.id,
        'currentPackageName': package.name,
        // حالة المتجر
        'isActive': true,
        'canAddProducts': true,
        'canReceiveOrders': true,
        'status': 'active',
      });

      // كتابة سجل العملية المالية
      final ledgerRef = _firestore.collection('wallet_ledger').doc();
      txn.set(ledgerRef, {
        'id': ledgerRef.id,
        'storeId': marketId,
        'userId': userId,
        'type': 'subscription_payment',
        'amount': -package.price,
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
        'referenceId': package.id,
        'referenceType': 'subscription',
        'description': 'تجديد اشتراك - ${package.name}',
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'packageId': package.id,
          'packageName': package.name,
          'durationDays': package.days,
        },
      });
    });

    return fetchStatus(marketId);
  }

  Future<String?> resolveCurrentUserMarketId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final snap =
        await _firestore.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};
    return data['market_id'] as String? ??
        data['marketId'] as String? ??
        (data['market'] is Map ? data['market']['id'] as String? : null);
  }
}

