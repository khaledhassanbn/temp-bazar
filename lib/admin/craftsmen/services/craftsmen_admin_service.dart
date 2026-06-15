import 'package:cloud_firestore/cloud_firestore.dart';

import '../../activity_logs/models/admin_action_type.dart';
import '../../activity_logs/services/admin_log_service.dart';
import '../models/craftsman_admin_model.dart';

class CraftsmenAdminService {
  CraftsmenAdminService({
    FirebaseFirestore? firestore,
    AdminLogService? logService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logService = logService ?? AdminLogService();

  final FirebaseFirestore _firestore;
  final AdminLogService _logService;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('craftsmen');

  Stream<List<CraftsmanAdminModel>> watchCraftsmen({
    String? accountStatus,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> q =
        _col.orderBy('createdAt', descending: true).limit(limit);

    if (accountStatus != null && accountStatus.isNotEmpty) {
      q = _col
          .where('accountStatus', isEqualTo: accountStatus)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    return q.snapshots().map(
          (snap) => snap.docs
              .where((d) => d.data()['isDeleted'] != true)
              .map((d) => CraftsmanAdminModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<CraftsmanAdminModel>> searchByNameOrPhone(String query) async {
    if (query.trim().isEmpty) {
      final snap = await _col.orderBy('createdAt', descending: true).limit(50).get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => CraftsmanAdminModel.fromFirestore(d.id, d.data()))
          .toList();
    }

    final snap = await _col.limit(200).get();
    final q = query.trim().toLowerCase();
    return snap.docs
        .where((d) {
          if (d.data()['isDeleted'] == true) return false;
          final name = (d.data()['name'] as String? ?? '').toLowerCase();
          final phone = (d.data()['phone'] as String? ?? '').toLowerCase();
          return name.contains(q) || phone.contains(q);
        })
        .map((d) => CraftsmanAdminModel.fromFirestore(d.id, d.data()))
        .toList();
  }

  Future<CraftsmanAdminModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CraftsmanAdminModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> suspend({
    required String craftsmanId,
    required String reason,
    required String adminUid,
    required String adminName,
  }) async {
    final prev = await getById(craftsmanId);
    await _col.doc(craftsmanId).set({
      'accountStatus': 'suspended',
      'visibility': 'hidden',
      'suspendedAt': FieldValue.serverTimestamp(),
      'suspendedBy': adminUid,
      'suspendedReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.suspendAccount,
      targetType: 'craftsman',
      targetId: craftsmanId,
      targetName: prev?.name,
      description: reason,
      previousState: {'accountStatus': prev?.accountStatus},
      newState: {'accountStatus': 'suspended'},
    );
  }

  Future<void> ban({
    required String craftsmanId,
    required String reason,
    required String adminUid,
    required String adminName,
  }) async {
    final prev = await getById(craftsmanId);
    await _col.doc(craftsmanId).set({
      'accountStatus': 'banned',
      'visibility': 'banned',
      'bannedAt': FieldValue.serverTimestamp(),
      'bannedBy': adminUid,
      'bannedReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.banAccount,
      targetType: 'craftsman',
      targetId: craftsmanId,
      targetName: prev?.name,
      description: reason,
      previousState: {'accountStatus': prev?.accountStatus},
      newState: {'accountStatus': 'banned'},
    );
  }

  Future<void> reactivate({
    required String craftsmanId,
    required String adminUid,
    required String adminName,
  }) async {
    final prev = await getById(craftsmanId);
    await _col.doc(craftsmanId).set({
      'accountStatus': 'active',
      'visibility': 'public',
      'suspendedAt': FieldValue.delete(),
      'suspendedBy': FieldValue.delete(),
      'suspendedReason': FieldValue.delete(),
      'bannedAt': FieldValue.delete(),
      'bannedBy': FieldValue.delete(),
      'bannedReason': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.reactivateAccount,
      targetType: 'craftsman',
      targetId: craftsmanId,
      targetName: prev?.name,
      previousState: {'accountStatus': prev?.accountStatus},
      newState: {'accountStatus': 'active'},
    );
  }

  Future<void> softDelete({
    required String craftsmanId,
    required String adminUid,
    required String adminName,
  }) async {
    final prev = await getById(craftsmanId);
    final batch = _firestore.batch();

    batch.set(
      _col.doc(craftsmanId),
      {
        'isDeleted': true,
        'accountStatus': 'deleted',
        'visibility': 'hidden',
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection('users').doc(craftsmanId),
      {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': adminUid,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.deleteAccount,
      targetType: 'craftsman',
      targetId: craftsmanId,
      targetName: prev?.name,
      description: 'حذف ناعم للحساب',
      previousState: {'accountStatus': prev?.accountStatus, 'isDeleted': false},
      newState: {'accountStatus': 'deleted', 'isDeleted': true},
    );
  }

  Future<void> removePortfolioImage({
    required String craftsmanId,
    required String imageUrl,
    required String adminUid,
    required String adminName,
  }) async {
    final prev = await getById(craftsmanId);
    await _col.doc(craftsmanId).update({
      'portfolioUrls': FieldValue.arrayRemove([imageUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.deleteMedia,
      targetType: 'craftsman',
      targetId: craftsmanId,
      targetName: prev?.name,
      description: 'حذف صورة من معرض الأعمال',
      metadata: {'imageUrl': imageUrl},
    );
  }
}
