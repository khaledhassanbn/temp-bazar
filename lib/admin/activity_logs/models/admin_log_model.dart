import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_action_type.dart';

class AdminLogModel {
  final String id;
  final String adminUid;
  final String adminName;
  final AdminActionType actionType;
  final String targetType;
  final String targetId;
  final String? targetName;
  final String? description;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final DateTime? createdAt;

  const AdminLogModel({
    required this.id,
    required this.adminUid,
    required this.adminName,
    required this.actionType,
    required this.targetType,
    required this.targetId,
    this.targetName,
    this.description,
    this.metadata,
    this.previousState,
    this.newState,
    this.createdAt,
  });

  factory AdminLogModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final actionKey = data['actionType'] as String? ?? 'other';
    return AdminLogModel(
      id: id,
      adminUid: data['adminUid'] as String? ?? '',
      adminName: data['adminName'] as String? ?? '',
      actionType:
          AdminActionType.fromKey(actionKey) ?? AdminActionType.other,
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetName: data['targetName'] as String?,
      description: data['description'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      previousState: data['previousState'] as Map<String, dynamic>?,
      newState: data['newState'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
