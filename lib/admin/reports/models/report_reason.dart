enum ReportReason {
  wrongInfo('wrong_info', 'بيانات خاطئة'),
  inappropriateContent('inappropriate_content', 'محتوى مخالف'),
  impersonation('impersonation', 'انتحال شخصية'),
  inappropriateImages('inappropriate_images', 'صور غير مناسبة'),
  spam('spam', 'سبام'),
  other('other', 'أخرى');

  const ReportReason(this.firestoreKey, this.labelAr);
  final String firestoreKey;
  final String labelAr;

  static ReportReason? fromKey(String key) {
    for (final r in ReportReason.values) {
      if (r.firestoreKey == key) return r;
    }
    return null;
  }
}
