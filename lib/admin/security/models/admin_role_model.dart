import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_role.dart';

class AdminRoleModel {
  final String uid;
  final AdminRoleType role;
  final String name;
  final String email;
  final Map<String, bool> permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  const AdminRoleModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    required this.permissions,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  bool hasPermission(String key) =>
      role == AdminRoleType.superAdmin || permissions[key] == true;

  factory AdminRoleModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final roleKey = data['role'] as String? ?? 'admin';
    return AdminRoleModel(
      uid: uid,
      role: AdminRoleType.fromKey(roleKey) ?? AdminRoleType.admin,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      permissions: Map<String, bool>.from(
        (data['permissions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v == true),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }
}
