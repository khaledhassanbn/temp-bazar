import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_action_type.dart';
import '../models/admin_log_model.dart';

class AdminLogRepository {
  AdminLogRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('admin_activity_logs');

  Future<void> create({
    required String adminUid,
    required String adminName,
    required AdminActionType actionType,
    required String targetType,
    required String targetId,
    String? targetName,
    String? description,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
  }) async {
    await _col.add({
      'adminUid': adminUid,
      'adminName': adminName,
      'actionType': actionType.firestoreKey,
      'targetType': targetType,
      'targetId': targetId,
      if (targetName != null) 'targetName': targetName,
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
      if (previousState != null) 'previousState': previousState,
      if (newState != null) 'newState': newState,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AdminLogModel>> fetchRecent({
    int limit = 50,
    AdminActionType? actionType,
    String? adminUid,
  }) async {
    Query<Map<String, dynamic>> q =
        _col.orderBy('createdAt', descending: true).limit(limit);

    if (actionType != null) {
      q = _col
          .where('actionType', isEqualTo: actionType.firestoreKey)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else if (adminUid != null) {
      q = _col
          .where('adminUid', isEqualTo: adminUid)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }

    final snap = await q.get();
    return snap.docs
        .map((d) => AdminLogModel.fromFirestore(d.id, d.data()))
        .toList();
  }

  Stream<List<AdminLogModel>> watchRecent({int limit = 50}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdminLogModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }
}
