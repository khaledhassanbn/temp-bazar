import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime? licenseStartAt;
  final DateTime? licenseEndAt;
  final int? totalProducts;
  final Map<String, dynamic>? userData;

  StoreModel({
    required this.id,
    required this.name,
    this.phone,
    required this.isActive,
    this.licenseStartAt,
    this.licenseEndAt,
    this.totalProducts,
    this.userData,
  });

  factory StoreModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime? _readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final subscription = data['subscription'] as Map<String, dynamic>?;

    return StoreModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'بدون اسم',
      phone: data['phone']?.toString(),
      isActive: data['isActive'] == true,
      licenseStartAt: _readDate(data['licenseStartAt']),
      licenseEndAt: _readDate(data['licenseEndAt']),
      totalProducts: data['totalProducts'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isActive': isActive,
      'licenseStartAt': licenseStartAt != null ? Timestamp.fromDate(licenseStartAt!) : null,
      'licenseEndAt': licenseEndAt != null ? Timestamp.fromDate(licenseEndAt!) : null,
      'totalProducts': totalProducts,
    };
  }

  // حساب الأيام المتبقية
  int get daysRemaining {
    if (licenseEndAt == null) return 0;
    final now = DateTime.now();
    if (licenseEndAt!.isAfter(now)) {
      return licenseEndAt!.difference(now).inDays;
    }
    return 0;
  }

  // الحصول على اسم المستخدم
  String get userName {
    if (userData == null) return 'غير محدد';
    if (userData!['firstName'] != null && userData!['lastName'] != null) {
      return '${userData!['firstName']} ${userData!['lastName']}';
    }
    return userData!['email']?.toString() ?? 'غير محدد';
  }
}
