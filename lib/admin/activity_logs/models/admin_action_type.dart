enum AdminActionType {
  deleteAccount('delete_account', 'حذف حساب'),
  restoreAccount('restore_account', 'استعادة حساب'),
  banAccount('ban_account', 'حظر حساب'),
  suspendAccount('suspend_account', 'إيقاف حساب'),
  reactivateAccount('reactivate_account', 'إعادة تفعيل'),
  convertAccount('convert_account', 'تحويل نوع الحساب'),
  deleteMedia('delete_media', 'حذف صورة'),
  reviewReport('review_report', 'مراجعة بلاغ'),
  closeReport('close_report', 'إغلاق بلاغ'),
  approveVerification('approve_verification', 'قبول توثيق'),
  rejectVerification('reject_verification', 'رفض توثيق'),
  deleteReview('delete_review', 'حذف تقييم'),
  assignAdmin('assign_admin', 'تعيين مسؤول'),
  removeAdmin('remove_admin', 'إزالة مسؤول'),
  other('other', 'أخرى');

  const AdminActionType(this.firestoreKey, this.labelAr);
  final String firestoreKey;
  final String labelAr;

  static AdminActionType? fromKey(String key) {
    for (final t in AdminActionType.values) {
      if (t.firestoreKey == key) return t;
    }
    return null;
  }
}
