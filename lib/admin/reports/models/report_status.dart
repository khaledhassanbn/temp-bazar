enum ReportStatus {
  pending('pending', 'قيد الانتظار'),
  underReview('under_review', 'قيد المراجعة'),
  resolved('resolved', 'تم الحل'),
  dismissed('dismissed', 'مرفوض');

  const ReportStatus(this.firestoreKey, this.labelAr);
  final String firestoreKey;
  final String labelAr;

  static ReportStatus? fromKey(String key) {
    for (final s in ReportStatus.values) {
      if (s.firestoreKey == key) return s;
    }
    return null;
  }
}
