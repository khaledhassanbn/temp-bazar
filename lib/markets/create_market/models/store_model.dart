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
  final int completedOrderCount;
  final String? fcmToken; // FCM token for push notifications
  final double? deliveryFee; // Calculated delivery fee
  final int? deliveryTime; // Calculated delivery time in minutes
  final bool showAddress; // Show address/map icon on store page
  final bool available; // Store availability (active/busy)
  final bool? isOpenNow; // Set by Cloud Function based on working hours
  final bool whatsappOrdersEnabled; // Open WhatsApp after successful checkout

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
    this.licenseAutoRenew = true,
    this.currentPackageId,
    this.workingHours,
    required this.numberOfProducts,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.completedOrderCount = 0,
    this.fcmToken,
    this.deliveryFee,
    this.deliveryTime,
    this.showAddress = false,
    this.available = true,
    this.isOpenNow,
    this.whatsappOrdersEnabled = false,
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
      licenseAutoRenew: map['licenseAutoRenew'] != false,
      currentPackageId: map['currentPackageId'] as String?,
      workingHours: workingHours,
      numberOfProducts: map['numberOfProducts'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      completedOrderCount: (map['completedOrderCount'] as num?)?.toInt() ?? 0,
      fcmToken: map['fcmToken'] as String?,
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      deliveryTime: map['deliveryTime'] as int?,
      showAddress: map['show_adress'] == true || map['showAddress'] == true,
      available: map['available'] is bool
          ? map['available'] as bool
          : (map['storeStatus'] is bool ? map['storeStatus'] as bool : true),
      isOpenNow: map['isOpenNow'] as bool?,
      whatsappOrdersEnabled: map['whatsappOrdersEnabled'] == true,
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
      'licenseStartAt': licenseStartAt != null
          ? Timestamp.fromDate(licenseStartAt!)
          : null,
      'licenseEndAt': licenseEndAt != null
          ? Timestamp.fromDate(licenseEndAt!)
          : null,
      'licenseDurationDays': licenseDurationDays,
      'licenseAutoRenew': licenseAutoRenew,
      'currentPackageId': currentPackageId,
      'workingHours': workingHours?.toMap(),
      'numberOfProducts': numberOfProducts,
      'createdAt': Timestamp.fromDate(createdAt),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'completedOrderCount': completedOrderCount,
      'deliveryFee': deliveryFee,
      'deliveryTime': deliveryTime,
      'show_adress': showAddress,
      'available': available,
      if (isOpenNow != null) 'isOpenNow': isOpenNow,
      'whatsappOrdersEnabled': whatsappOrdersEnabled,
    };
  }

  StoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? link,
    String? phone,
    String? email,
    GeoPoint? location,
    String? facebook,
    String? instagram,
    String? logoUrl,
    String? coverUrl,
    String? storeType,
    bool? storeStatus,
    StoreStatus? status,
    bool? isVisible,
    DateTime? licenseStartAt,
    DateTime? licenseEndAt,
    int? licenseDurationDays,
    bool? licenseAutoRenew,
    String? currentPackageId,
    WeeklyWorkingHours? workingHours,
    int? numberOfProducts,
    DateTime? createdAt,
    double? averageRating,
    int? totalReviews,
    int? completedOrderCount,
    String? fcmToken,
    double? deliveryFee,
    int? deliveryTime,
    bool? showAddress,
    bool? available,
    bool? isOpenNow,
    bool? whatsappOrdersEnabled,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      link: link ?? this.link,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      logoUrl: logoUrl ?? this.logoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      storeType: storeType ?? this.storeType,
      storeStatus: storeStatus ?? this.storeStatus,
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      licenseStartAt: licenseStartAt ?? this.licenseStartAt,
      licenseEndAt: licenseEndAt ?? this.licenseEndAt,
      licenseDurationDays: licenseDurationDays ?? this.licenseDurationDays,
      licenseAutoRenew: licenseAutoRenew ?? this.licenseAutoRenew,
      currentPackageId: currentPackageId ?? this.currentPackageId,
      workingHours: workingHours ?? this.workingHours,
      numberOfProducts: numberOfProducts ?? this.numberOfProducts,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      completedOrderCount: completedOrderCount ?? this.completedOrderCount,
      fcmToken: fcmToken ?? this.fcmToken,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      showAddress: showAddress ?? this.showAddress,
      available: available ?? this.available,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      whatsappOrdersEnabled:
          whatsappOrdersEnabled ?? this.whatsappOrdersEnabled,
    );
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

  /// Returns true when store is currently closed by configured working hours.
  /// Prioritises the server-side `isOpenNow` field set by the Cloud Function.
  /// Falls back to local calculation only when `isOpenNow` hasn't been set.
  bool get isClosedByWorkingHours {
    // Server-side value (from Cloud Function)
    if (isOpenNow != null) return !isOpenNow!;
    // Fallback: local calculation
    if (workingHours == null) return false;
    return !workingHours!.isOpenAt(DateTime.now());
  }
}
