import 'package:cloud_firestore/cloud_firestore.dart';

class AdRequestOwnerType {
  static const String merchant = 'merchant';
  static const String craftsman = 'craftsman';
}

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
  final String status;
  final String? adminNotes;
  final String? ownerType;
  final String? craftsmanId;
  final String? rejectionReason;
  final bool refunded;
  final DateTime? reviewedAt;
  final String? reviewedBy;

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
    this.ownerType,
    this.craftsmanId,
    this.rejectionReason,
    this.refunded = false,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isCraftsmanRequest => ownerType == AdRequestOwnerType.craftsman;

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
      ownerType: map['ownerType'] ?? AdRequestOwnerType.merchant,
      craftsmanId: map['craftsmanId'],
      rejectionReason: map['rejectionReason'],
      refunded: map['refunded'] ?? false,
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'],
    );
  }

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
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (ownerType != null) 'ownerType': ownerType,
      if (craftsmanId != null) 'craftsmanId': craftsmanId,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'refunded': refunded,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
    };
  }

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
    String? ownerType,
    String? craftsmanId,
    String? rejectionReason,
    bool? refunded,
    DateTime? reviewedAt,
    String? reviewedBy,
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
      ownerType: ownerType ?? this.ownerType,
      craftsmanId: craftsmanId ?? this.craftsmanId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      refunded: refunded ?? this.refunded,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}
