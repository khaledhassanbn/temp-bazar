import 'package:cloud_functions/cloud_functions.dart';

import '../../activity_logs/models/admin_action_type.dart';
import '../../activity_logs/services/admin_log_service.dart';
import '../models/admin_role.dart';

class AdminManagementService {
  AdminManagementService({
    FirebaseFunctions? functions,
    AdminLogService? logService,
  })  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _logService = logService ?? AdminLogService();

  final FirebaseFunctions _functions;
  final AdminLogService _logService;

  Future<Map<String, dynamic>> assignAdminByEmail({
    required String email,
    required AdminRoleType role,
    required Map<String, bool> permissions,
    required String adminUid,
    required String adminName,
    String? displayName,
  }) async {
    final callable = _functions.httpsCallable('assignAdminByEmail');
    final result = await callable.call<Map<String, dynamic>>({
      'email': email.trim().toLowerCase(),
      'role': role.firestoreKey,
      'permissions': permissions,
      if (displayName != null && displayName.isNotEmpty) 'name': displayName,
    });

    final data = Map<String, dynamic>.from(result.data);
    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.assignAdmin,
      targetType: 'admin',
      targetId: data['targetUid'] as String? ?? email,
      targetName: displayName ?? email,
      description: 'تعيين مسؤول جديد: $email',
      metadata: {'role': role.firestoreKey},
    );
    return data;
  }

  Future<void> removeAdminRole({
    required String targetUid,
    required String adminUid,
    required String adminName,
    String? targetName,
  }) async {
    final callable = _functions.httpsCallable('removeAdminRole');
    await callable.call({'targetUid': targetUid});

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.removeAdmin,
      targetType: 'admin',
      targetId: targetUid,
      targetName: targetName,
      description: 'إزالة صلاحيات المسؤول',
    );
  }

  Future<void> softDeleteAccount({
    required String targetUid,
    required String targetType,
    required String adminUid,
    required String adminName,
    String? targetName,
  }) async {
    final callable = _functions.httpsCallable('softDeleteAccount');
    await callable.call({
      'targetUid': targetUid,
      'targetType': targetType,
    });

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.deleteAccount,
      targetType: targetType,
      targetId: targetUid,
      targetName: targetName,
      description: 'حذف ناعم للحساب',
      newState: {'isDeleted': true},
    );
  }

  Future<void> restoreAccount({
    required String targetUid,
    required String targetType,
    required String adminUid,
    required String adminName,
    String? targetName,
  }) async {
    final callable = _functions.httpsCallable('restoreAccount');
    await callable.call({
      'targetUid': targetUid,
      'targetType': targetType,
    });

    await _logService.logAction(
      adminUid: adminUid,
      adminName: adminName,
      actionType: AdminActionType.restoreAccount,
      targetType: targetType,
      targetId: targetUid,
      targetName: targetName,
      description: 'استعادة حساب محذوف',
      newState: {'isDeleted': false},
    );
  }
}
