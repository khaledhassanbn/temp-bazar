import '../models/admin_permission.dart';
import '../models/admin_role.dart';
import '../models/admin_role_model.dart';
import '../repositories/admin_role_repository.dart';

class AdminPermissionService {
  AdminPermissionService({AdminRoleRepository? repository})
      : _repository = repository ?? AdminRoleRepository();

  final AdminRoleRepository _repository;
  AdminRoleModel? _cachedRole;

  AdminRoleModel? get currentRole => _cachedRole;

  Future<void> loadForUid(String uid) async {
    _cachedRole = await _repository.getByUid(uid);
  }

  void clear() {
    _cachedRole = null;
  }

  bool hasPermission(AdminPermission permission) {
    if (_cachedRole == null) {
      // Legacy admins without role doc — full access
      return true;
    }
    return _cachedRole!.hasPermission(permission.firestoreKey);
  }

  bool get isSuperAdmin =>
      _cachedRole == null ||
      _cachedRole!.role == AdminRoleType.superAdmin;

  bool get canManageAdmins =>
      isSuperAdmin || hasPermission(AdminPermission.manageAdmins);

  bool get canDeleteAccounts => hasPermission(AdminPermission.deleteAccounts);

  bool get canViewLogs => hasPermission(AdminPermission.viewLogs);
}
