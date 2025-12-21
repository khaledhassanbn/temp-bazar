import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransaction {
  final String id;
  final String userId;
  final double amount;
  final String status; // 'pending', 'approved', 'rejected'
  final String? phoneNumber;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminId; // ID of admin who approved/rejected

  WalletTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    this.phoneNumber,
    this.notes,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.adminId,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      phoneNumber: json['phoneNumber'],
      notes: json['notes'],
      imageUrl: json['imageUrl'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      adminId: json['adminId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'status': status,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminId': adminId,
    };
  }

  WalletTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? status,
    String? phoneNumber,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminId,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminId: adminId ?? this.adminId,
    );
  }
}
