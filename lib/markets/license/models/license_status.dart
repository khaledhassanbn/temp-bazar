import 'package:cloud_firestore/cloud_firestore.dart';

class LicenseStatus {
  final String marketId;
  final DateTime? startAt;
  final DateTime? endAt;
  final int durationDays;
  final bool autoRenewEnabled;
  final String? currentPackageId;
  final String? currentPackageName;

  const LicenseStatus({
    required this.marketId,
    required this.startAt,
    required this.endAt,
    required this.durationDays,
    required this.autoRenewEnabled,
    required this.currentPackageId,
    required this.currentPackageName,
  });

  int get remainingDays {
    if (endAt == null) return 0;
    final diff = endAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get fallbackPackageName =>
      currentPackageName ?? 'باقة غير معروفة';

  static LicenseStatus fromDoc(String marketId, Map<String, dynamic> data) {
    DateTime? _readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final subscription = data['subscription'] as Map<String, dynamic>? ?? {};

    return LicenseStatus(
      marketId: marketId,
      startAt: _readDate(data['licenseStartAt']),
      endAt: _readDate(data['licenseEndAt']),
      durationDays: (data['licenseDurationDays'] ?? 0) as int,
      autoRenewEnabled: data['licenseAutoRenew'] == true,
      currentPackageId: data['currentPackageId'] as String?,
      currentPackageName: data['currentPackageName'] as String?,
    );
  }
}


