import 'package:cloud_firestore/cloud_firestore.dart';

class PendingPayment {
  final String id;
  final String userId;
  final String packageId;
  final String packageName;
  final double amount;
  final int days;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'pending', 'completed', 'expired', 'cancelled'
  final String? storeId; // يتم ربطه عند إنشاء المتجر

  PendingPayment({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.packageName,
    required this.amount,
    required this.days,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
    this.storeId,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      packageId: json['packageId'] ?? '',
      packageName: json['packageName'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      days: (json['days'] ?? 0) as int,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),
      status: json['status'] ?? 'pending',
      storeId: json['storeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'packageId': packageId,
      'packageName': packageName,
      'amount': amount,
      'days': days,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
      'storeId': storeId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => status == 'pending' && !isExpired;
}
