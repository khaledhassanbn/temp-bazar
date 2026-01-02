import 'package:cloud_firestore/cloud_firestore.dart';
import 'working_hours.dart';

enum StoreStatus { expired, active }

class StoreModel {
  final String id;
  final String name;
  final String description;
  final String link;
  final String phone;
  final String email;
  final GeoPoint? location; // ← هنستخدمه بدل النص
  final String? facebook;
  final String? instagram;
  final String? logoUrl;
  final String? coverUrl;
  final String storeType; // نوع المتجر (online/physical)
  final bool storeStatus; // حالة المتجر
  final StoreStatus status; // حالة العرض (expired/active)
  final bool isVisible; // إظهار المتجر
  final DateTime? licenseStartAt;
  final DateTime? licenseEndAt;
  final int? licenseDurationDays;
  final bool licenseAutoRenew;
  final String? currentPackageId;
  final WeeklyWorkingHours? workingHours; // مواعيد العمل
  final int numberOfProducts; // عدد المنتجات المسموح بها
  final DateTime createdAt;
  final double averageRating;
  final int totalReviews;
  final String? fcmToken; // FCM token for push notifications

  StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.link,
    required this.phone,
    required this.email,
    this.location,
    this.facebook,
    this.instagram,
    this.logoUrl,
    this.coverUrl,
    required this.storeType,
    required this.storeStatus,
    required this.status,
    required this.isVisible,
    this.licenseStartAt,
    this.licenseEndAt,
    this.licenseDurationDays,
    this.licenseAutoRenew = false,
    this.currentPackageId,
    this.workingHours,
    required this.numberOfProducts,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.fcmToken,
  });

  factory StoreModel.fromMap(String id, Map<String, dynamic> map) {
    WeeklyWorkingHours? workingHours;
    if (map['workingHours'] != null) {
      workingHours = WeeklyWorkingHours.fromMap(map['workingHours']);
    }

    // Handle status enum conversion
    StoreStatus status = StoreStatus.active;
    if (map['status'] != null) {
      if (map['status'] == 'expired') {
        status = StoreStatus.expired;
      } else if (map['status'] == 'active') {
        status = StoreStatus.active;
      }
    }

    DateTime? _readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final subscription = map['subscription'] as Map<String, dynamic>? ?? {};

    return StoreModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      link: map['link'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      location: map['location'],
      facebook: map['facebook'],
      instagram: map['instagram'],
      logoUrl: map['logoUrl'],
      coverUrl: map['coverUrl'],
      storeType: map['storeType'] ?? 'online',
      storeStatus: map['storeStatus'] ?? true,
      status: status,
      isVisible: map['isVisible'] ?? true,
      // قراءة التواريخ من الحقول الموحدة أو من الحقول القديمة كـ Fallback
      licenseStartAt: _readDate(map['licenseStartAt']),
      licenseEndAt: _readDate(map['licenseEndAt']),
      licenseDurationDays: (map['licenseDurationDays'] ?? 0) as int?,
      licenseAutoRenew: map['licenseAutoRenew'] == true,
      currentPackageId: map['currentPackageId'] as String?,
      workingHours: workingHours,
      numberOfProducts: map['numberOfProducts'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'link': link,
      'phone': phone,
      'email': email,
      'location': location,
      'facebook': facebook,
      'instagram': instagram,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'storeType': storeType,
      'storeStatus': storeStatus,
      'status': status.name,
      'isVisible': isVisible,
      // نكتفي فقط بحقلي البداية والنهاية كما طلب المستخدم
      'licenseStartAt':
          licenseStartAt != null ? Timestamp.fromDate(licenseStartAt!) : null,
      'licenseEndAt':
          licenseEndAt != null ? Timestamp.fromDate(licenseEndAt!) : null,
      'licenseDurationDays': licenseDurationDays,
      'licenseAutoRenew': licenseAutoRenew,
      'currentPackageId': currentPackageId,
      'workingHours': workingHours?.toMap(),
      'numberOfProducts': numberOfProducts,
      'createdAt': Timestamp.fromDate(createdAt),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // License Helper Methods
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns true if the store's license has expired
  bool get isLicenseExpired {
    if (licenseEndAt == null) return true;
    return DateTime.now().isAfter(licenseEndAt!);
  }

  /// Returns the number of days until license expiry (negative if already expired)
  int get daysUntilExpiry {
    if (licenseEndAt == null) return 0;
    return licenseEndAt!.difference(DateTime.now()).inDays;
  }

  /// Returns true if license is about to expire (within 7 days) but not yet expired
  bool get isLicenseWarning => daysUntilExpiry <= 7 && daysUntilExpiry >= 0;

  /// Returns true if the store has an active (non-expired) license
  bool get hasActiveLicense => !isLicenseExpired;
}
