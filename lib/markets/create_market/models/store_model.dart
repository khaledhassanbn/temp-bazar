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
  final DateTime? expiredAt; // تاريخ انتهاء الصلاحية
  final DateTime? renewedAt; // تاريخ التجديد
  final WeeklyWorkingHours? workingHours; // مواعيد العمل
  final int numberOfProducts; // عدد المنتجات المسموح بها
  final DateTime createdAt;
  final double averageRating;
  final int totalReviews;

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
    this.expiredAt,
    this.renewedAt,
    this.workingHours,
    required this.numberOfProducts,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
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
      expiredAt: map['expiredAt'] != null
          ? (map['expiredAt'] as Timestamp).toDate()
          : null,
      renewedAt: map['renewedAt'] != null
          ? (map['renewedAt'] as Timestamp).toDate()
          : null,
      workingHours: workingHours,
      numberOfProducts: map['numberOfProducts'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
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
      'expiredAt': expiredAt != null ? Timestamp.fromDate(expiredAt!) : null,
      'renewedAt': renewedAt != null ? Timestamp.fromDate(renewedAt!) : null,
      'workingHours': workingHours?.toMap(),
      'numberOfProducts': numberOfProducts,
      'createdAt': Timestamp.fromDate(createdAt),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }
}
