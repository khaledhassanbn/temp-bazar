import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _collection(String type) {
    switch (type) {
      case 'craftsman':
        return 'craftsmen';
      case 'store':
        return 'markets';
      case 'courier':
        return 'courier_requests';
      default:
        return 'craftsmen';
    }
  }

  /// Approve user account
  Future<void> approveUser({
    required String accountId,
    required String accountType,
    required String adminId,
  }) async {
    try {
      final collection = _collection(accountType);
      await _firestore
          .collection(collection)
          .doc(accountId)
          .update({
            'adminStatus': 'active',
            'lastAdminAction': {
              'action': 'approved',
              'by': adminId,
              'at': FieldValue.serverTimestamp(),
              'reason': '',
            },
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'قبول');
    }
  }

  /// Reject user account
  Future<void> rejectUser({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        throw Exception('يجب إدخال سبب الرفض');
      }

      final collection = _collection(accountType);
      await _firestore
          .collection(collection)
          .doc(accountId)
          .update({
            'adminStatus': 'rejected',
            'lastAdminAction': {
              'action': 'rejected',
              'by': adminId,
              'at': FieldValue.serverTimestamp(),
              'reason': reason.trim(),
            },
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'رفض');
    }
  }

  /// Suspend user account
  Future<void> suspendAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        throw Exception('يجب إدخال سبب التعليق');
      }

      final collection = _collection(accountType);
      await _firestore
          .collection(collection)
          .doc(accountId)
          .update({
            'adminStatus': 'suspended',
            'lastAdminAction': {
              'action': 'suspended',
              'by': adminId,
              'at': FieldValue.serverTimestamp(),
              'reason': reason.trim(),
            },
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'تعليق');
    }
  }

  /// Ban user account permanently
  Future<void> banAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        throw Exception('يجب إدخال سبب الحظر');
      }

      final collection = _collection(accountType);
      await _firestore
          .collection(collection)
          .doc(accountId)
          .update({
            'adminStatus': 'banned',
            'lastAdminAction': {
              'action': 'banned',
              'by': adminId,
              'at': FieldValue.serverTimestamp(),
              'reason': reason.trim(),
            },
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'حظر');
    }
  }

  /// Delete account (soft delete) and convert to regular user
  Future<void> deleteAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    try {
      final collection = _collection(accountType);
      final batch = _firestore.batch();

      // 1. Soft delete in sub-collections (craftsmen/markets/courier_requests)
      final lastAction = {
        'action': 'deleted',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': reason.trim(),
      };

      if (accountType == 'store') {
        final marketsQuery = await _firestore
            .collection('markets')
            .where('ownerUid', isEqualTo: accountId)
            .get();
        for (var doc in marketsQuery.docs) {
          batch.update(doc.reference, {
            'adminStatus': 'deleted',
            'accountStatus': 'deleted',
            'isDeleted': true,
            'isVisible': false,
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': adminId,
            'lastAdminAction': lastAction,
          });
        }
      } else {
        final accountRef = _firestore.collection(collection).doc(accountId);
        final Map<String, dynamic> updateData = {
          'adminStatus': 'deleted',
          'accountStatus': 'deleted',
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
          'deletedBy': adminId,
          'lastAdminAction': lastAction,
        };
        if (accountType == 'craftsman') {
          updateData['visibility'] = 'hidden';
        } else if (accountType == 'courier') {
          updateData['status'] = 'deleted';
        }
        batch.update(accountRef, updateData);
      }

      // 2. Convert role in users collection
      final userRef = _firestore.collection('users').doc(accountId);
      batch.update(userRef, {
        'role': 'user',
        'previousAccountType': accountType == 'craftsman'
            ? 'craftsman'
            : (accountType == 'store' ? 'store_owner' : 'courier'),
        'convertedAt': FieldValue.serverTimestamp(),
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': adminId,
      });

      await batch.commit().timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'حذف');
    }
  }

  /// Restore deleted account
  Future<void> restoreAccount({
    required String accountId,
    required String accountType,
    required String adminId,
  }) async {
    try {
      final collection = _collection(accountType);
      final batch = _firestore.batch();

      // 1. Get previous account type from users collection
      final userDoc = await _firestore.collection('users').doc(accountId).get();
      final userData = userDoc.data();
      final previousType = userData?['previousAccountType'];

      // Determine restored role
      String restoredRole;
      if (previousType != null) {
        restoredRole = previousType == 'craftsman'
            ? 'craftsman'
            : (previousType == 'courier' ? 'courier' : 'store_owner');
      } else {
        if (accountType == 'craftsman') {
          restoredRole = 'craftsman';
        } else if (accountType == 'store') {
          restoredRole = 'store_owner';
        } else if (accountType == 'courier') {
          restoredRole = 'courier';
        } else {
          restoredRole = userData?['role'] as String? ?? 'user';
        }
      }

      final lastAction = {
        'action': 'restored',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': 'تم استعادة الحساب',
      };

      // 2. Restore account status in sub-collections
      if (accountType == 'store') {
        final marketsQuery = await _firestore
            .collection('markets')
            .where('ownerUid', isEqualTo: accountId)
            .get();
        for (var doc in marketsQuery.docs) {
          batch.update(doc.reference, {
            'adminStatus': 'active',
            'accountStatus': 'active',
            'isDeleted': false,
            'isVisible': true,
            'isActive': true,
            'deletedAt': FieldValue.delete(),
            'deletedBy': FieldValue.delete(),
            'lastAdminAction': lastAction,
          });
        }
      } else {
        final accountRef = _firestore.collection(collection).doc(accountId);
        final Map<String, dynamic> updateData = {
          'adminStatus': 'active',
          'accountStatus': 'active',
          'isDeleted': false,
          'deletedAt': FieldValue.delete(),
          'deletedBy': FieldValue.delete(),
          'lastAdminAction': lastAction,
        };
        if (accountType == 'craftsman') {
          updateData['visibility'] = 'public';
        } else if (accountType == 'courier') {
          updateData['status'] = 'approved';
        }
        batch.update(accountRef, updateData);
      }

      // 3. Restore role in users collection
      final userRef = _firestore.collection('users').doc(accountId);
      batch.update(userRef, {
        'role': restoredRole,
        'previousAccountType': FieldValue.delete(),
        'convertedAt': FieldValue.delete(),
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
      });

      await batch.commit().timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'استعادة');
    }
  }

  /// Activate account (remove suspension)
  Future<void> activateAccount({
    required String accountId,
    required String accountType,
    required String adminId,
  }) async {
    try {
      final collection = _collection(accountType);
      await _firestore
          .collection(collection)
          .doc(accountId)
          .update({
            'adminStatus': 'active',
            'lastAdminAction': {
              'action': 'activated',
              'by': adminId,
              'at': FieldValue.serverTimestamp(),
              'reason': 'تم تفعيل الحساب',
            },
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      _handleError(e, 'تفعيل');
    }
  }

  /// Watch accounts by status
  Stream<List<Map<String, dynamic>>> watchAccountsByStatus({
    required String accountType,
    required String status,
  }) {
    try {
      final collection = _collection(accountType);

      // If status is 'all', don't filter by adminStatus
      if (status == 'all') {
        return _firestore
            .collection(collection)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots()
            .map(
              (snapshot) =>
                  snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
            );
      }

      return _firestore
          .collection(collection)
          .where('adminStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
          );
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض المستخدمين');
      }
      rethrow;
    }
  }

  /// Get account details
  Future<Map<String, dynamic>?> getAccountDetails({
    required String accountId,
    required String accountType,
  }) async {
    try {
      final collection = _collection(accountType);
      final doc = await _firestore
          .collection(collection)
          .doc(accountId)
          .get()
          .timeout(Duration(seconds: 30));

      if (!doc.exists) {
        throw Exception('المستخدم غير موجود');
      }

      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      _handleError(e, 'جلب بيانات');
    }
  }

  /// Watch account details in real-time
  Stream<Map<String, dynamic>?> watchAccountDetails({
    required String accountId,
    required String accountType,
  }) {
    try {
      final collection = _collection(accountType);
      return _firestore.collection(collection).doc(accountId).snapshots().map((
        doc,
      ) {
        if (!doc.exists) return null;
        return {'id': doc.id, ...doc.data()!};
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض بيانات المستخدم');
      }
      rethrow;
    }
  }

  /// Get current admin user ID
  String? getCurrentAdminId() {
    return _auth.currentUser?.uid;
  }

  /// Error handler
  void _handleError(dynamic e, String action) {
    if (e.toString().contains('permission-denied')) {
      throw Exception('ليس لديك صلاحيات $action الحساب');
    } else if (e.toString().contains('not-found')) {
      throw Exception('المستخدم غير موجود');
    } else if (e.toString().contains('timeout')) {
      throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
    } else if (e is Exception) {
      throw e;
    } else {
      throw Exception('حدث خطأ أثناء $action الحساب');
    }
  }
}
