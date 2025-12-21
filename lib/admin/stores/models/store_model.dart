import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? phone;
  final bool isActive;
  final DateTime? expiryDate;
  final Map<String, dynamic>? subscription;
  final int? totalProducts;
  final Map<String, dynamic>? userData;

  StoreModel({
    required this.id,
    required this.name,
    this.phone,
    required this.isActive,
    this.expiryDate,
    this.subscription,
    this.totalProducts,
    this.userData,
  });

  factory StoreModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'بدون اسم',
      phone: data['phone']?.toString(),
      isActive: data['isActive'] == true,
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      subscription: data['subscription'] as Map<String, dynamic>?,
      totalProducts: data['totalProducts'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isActive': isActive,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'subscription': subscription,
      'totalProducts': totalProducts,
    };
  }

  // حساب الأيام المتبقية
  int get daysRemaining {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    if (expiryDate!.isAfter(now)) {
      return expiryDate!.difference(now).inDays;
    }
    return 0;
  }

  // الحصول على اسم الباقة
  String get planName {
    if (subscription == null) return 'غير محدد';
    return subscription?['packageName']?.toString() ?? 'غير محدد';
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
