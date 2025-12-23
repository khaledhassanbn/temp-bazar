import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../planes/models/package.dart';
import '../../wallet/services/wallet_service.dart';
import '../models/license_status.dart';

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
    final ok = await _walletService.deductFromWallet(userId, package.price);
    if (!ok) {
      throw Exception('رصيدك غير كافٍ');
    }

    await _firestore.runTransaction((txn) async {
      final ref = _firestore.collection('markets').doc(marketId);
      final snap = await txn.get(ref);
      final data = snap.data() ?? {};
      final now = DateTime.now();

      DateTime _readDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return now;
      }

      final currentEnd = _readDate(data['licenseEndAt'] ?? data['expiryDate']);
      final base = currentEnd.isAfter(now) ? currentEnd : now;
      final newEnd = base.add(Duration(days: package.days));

      txn.update(ref, {
        'licenseEndAt': Timestamp.fromDate(newEnd),
        'expiryDate': Timestamp.fromDate(newEnd),
        'licenseDurationDays': package.days,
        'licenseLastRenewedAt': Timestamp.fromDate(now),
        'currentPackageId': package.id,
        'currentPackageName': package.name,
        'subscription': {
          'packageName': package.name,
          'packageId': package.id,
          'startDate': Timestamp.fromDate(now),
          'endDate': Timestamp.fromDate(newEnd),
          'durationDays': package.days,
        },
        'isActive': true,
        'canAddProducts': true,
        'canReceiveOrders': true,
        'status': 'active',
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

