import 'package:cloud_firestore/cloud_firestore.dart';

class AdRequestModel {
  final String id;
  final String? imageUrl;
  final String? storeId;
  final String? storeName;
  final int days;
  final double totalPrice;
  final String phoneNumber;
  final String ownerEmail;
  final String ownerUid;
  final DateTime createdAt;
  final String status; // pending, approved, rejected
  final String? adminNotes;

  AdRequestModel({
    required this.id,
    this.imageUrl,
    this.storeId,
    this.storeName,
    required this.days,
    required this.totalPrice,
    required this.phoneNumber,
    required this.ownerEmail,
    required this.ownerUid,
    required this.createdAt,
    this.status = 'pending',
    this.adminNotes,
  });

  // تحويل من Firestore
  factory AdRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return AdRequestModel(
      id: id,
      imageUrl: map['imageUrl'],
      storeId: map['storeId'],
      storeName: map['storeName'],
      days: map['days'] ?? 0,
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      phoneNumber: map['phoneNumber'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'storeId': storeId,
      'storeName': storeName,
      'days': days,
      'totalPrice': totalPrice,
      'phoneNumber': phoneNumber,
      'ownerEmail': ownerEmail,
      'ownerUid': ownerUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'adminNotes': adminNotes,
    };
  }

  // نسخ مع تعديل
  AdRequestModel copyWith({
    String? id,
    String? imageUrl,
    String? storeId,
    String? storeName,
    int? days,
    double? totalPrice,
    String? phoneNumber,
    String? ownerEmail,
    String? ownerUid,
    DateTime? createdAt,
    String? status,
    String? adminNotes,
  }) {
    return AdRequestModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      days: days ?? this.days,
      totalPrice: totalPrice ?? this.totalPrice,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
