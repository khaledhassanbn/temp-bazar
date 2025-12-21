import 'package:cloud_firestore/cloud_firestore.dart';

class OfficeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role; // يجب أن يكون "office"
  final String status; // "active" أو "blocked"
  final DateTime createdAt;
  final DateTime? updatedAt;

  OfficeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.role = "office",
    this.status = "active",
    required this.createdAt,
    this.updatedAt,
  });

  factory OfficeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficeModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      role: data['role']?.toString() ?? 'office',
      status: data['status']?.toString() ?? 'active',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  OfficeModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    String? status,
    DateTime? updatedAt,
  }) {
    return OfficeModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';
}
