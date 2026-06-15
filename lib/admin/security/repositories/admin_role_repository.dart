import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_role_model.dart';

class AdminRoleRepository {
  AdminRoleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('admin_roles');

  Future<AdminRoleModel?> getByUid(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AdminRoleModel.fromFirestore(doc.id, doc.data()!);
  }

  Stream<List<AdminRoleModel>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => AdminRoleModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<AdminRoleModel>> fetchAll({int limit = 50}) async {
    final snap =
        await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs
        .map((d) => AdminRoleModel.fromFirestore(d.id, d.data()))
        .toList();
  }
}
