import 'package:cloud_firestore/cloud_firestore.dart';

class CraftsmanAdminModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String phone;
  final String professionName;
  final String areaName;
  final double averageRating;
  final int totalReviews;
  final int reportCount;
  final String accountStatus;
  final String visibility;
  final String adminStatus;
  final String verificationStatus;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final List<String> portfolioUrls;

  const CraftsmanAdminModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.phone,
    required this.professionName,
    required this.areaName,
    required this.averageRating,
    required this.totalReviews,
    required this.reportCount,
    required this.accountStatus,
    required this.visibility,
    required this.adminStatus,
    required this.verificationStatus,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.portfolioUrls = const [],
  });

  factory CraftsmanAdminModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final accountStatus = data['accountStatus'] as String? ??
        _legacyAccountStatus(data);
    final portfolio = data['portfolioUrls'];
    final portfolioUrls = portfolio is List
        ? portfolio.map((e) => e.toString()).toList()
        : <String>[];
    return CraftsmanAdminModel(
      id: id,
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String? ?? '',
      professionName: data['professionName'] as String? ?? '',
      areaName: data['areaName'] as String? ?? '',
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (data['totalReviews'] as num?)?.toInt() ?? 0,
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      accountStatus: accountStatus,
      visibility: data['visibility'] as String? ?? 'public',
      adminStatus: data['adminStatus'] as String? ?? 'none',
      verificationStatus:
          data['verificationStatus'] as String? ?? 'unverified',
      isDeleted: data['isDeleted'] == true,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      portfolioUrls: portfolioUrls,
    );
  }

  static String _legacyAccountStatus(Map<String, dynamic> data) {
    if (data['isDeleted'] == true) return 'deleted';
    if (data['visibility'] == 'banned') return 'banned';
    if (data['visibility'] == 'hidden') return 'suspended';
    return 'active';
  }

  String get statusLabel {
    switch (accountStatus) {
      case 'active':
        return 'نشط';
      case 'suspended':
        return 'موقوف';
      case 'banned':
        return 'محظور';
      case 'deleted':
        return 'محذوف';
      default:
        return accountStatus;
    }
  }
}
