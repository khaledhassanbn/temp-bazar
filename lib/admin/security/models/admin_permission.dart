enum AdminPermission {
  manageCraftsmen('manage_craftsmen', 'إدارة الصنايعية'),
  manageStores('manage_stores', 'إدارة المتاجر'),
  manageCouriers('manage_couriers', 'إدارة المناديب'),
  manageReports('manage_reports', 'إدارة البلاغات'),
  manageMedia('manage_media', 'إدارة الصور'),
  manageVerification('manage_verification', 'إدارة التوثيق'),
  viewAnalytics('view_analytics', 'عرض الإحصائيات'),
  manageAdmins('manage_admins', 'إدارة المسؤولين'),
  deleteAccounts('delete_accounts', 'حذف الحسابات'),
  banAccounts('ban_accounts', 'حظر الحسابات'),
  viewLogs('view_logs', 'عرض سجلات النشاط');

  const AdminPermission(this.firestoreKey, this.labelAr);
  final String firestoreKey;
  final String labelAr;

  static AdminPermission? fromKey(String key) {
    for (final p in AdminPermission.values) {
      if (p.firestoreKey == key) return p;
    }
    return null;
  }
}
