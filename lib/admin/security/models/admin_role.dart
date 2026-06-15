import 'admin_permission.dart';

enum AdminRoleType {
  superAdmin('super_admin', 'مسؤول أعلى'),
  admin('admin', 'مسؤول'),
  moderator('moderator', 'مشرف'),
  supportAgent('support_agent', 'دعم فني');

  const AdminRoleType(this.firestoreKey, this.labelAr);
  final String firestoreKey;
  final String labelAr;

  static AdminRoleType? fromKey(String? key) {
    if (key == null) return null;
    for (final r in AdminRoleType.values) {
      if (r.firestoreKey == key) return r;
    }
    return null;
  }

  static Map<String, bool> defaultPermissions(AdminRoleType role) {
    switch (role) {
      case AdminRoleType.superAdmin:
        return {
          for (final p in AdminPermission.values) p.firestoreKey: true,
        };
      case AdminRoleType.admin:
        return {
          for (final p in AdminPermission.values)
            p.firestoreKey: p != AdminPermission.manageAdmins,
        };
      case AdminRoleType.moderator:
        return {
          AdminPermission.manageReports.firestoreKey: true,
          AdminPermission.manageMedia.firestoreKey: true,
          AdminPermission.viewAnalytics.firestoreKey: true,
        };
      case AdminRoleType.supportAgent:
        return {
          AdminPermission.manageReports.firestoreKey: true,
          AdminPermission.viewAnalytics.firestoreKey: true,
        };
    }
  }
}
