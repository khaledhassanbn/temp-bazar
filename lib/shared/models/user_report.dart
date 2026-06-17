import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport {
  final String id;
  final String reporterId;
  final String targetId;
  final String targetType; // 'craftsman' | 'store' | 'courier'
  final String reason;
  final String status; // 'pending' | 'resolved' | 'dismissed'
  final Timestamp createdAt;
  final Timestamp? resolvedAt;
  final String? resolvedBy;
  final String? resolution;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? 'craftsman',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      resolvedAt: data['resolvedAt'],
      resolvedBy: data['resolvedBy'],
      resolution: data['resolution'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
      if (resolvedAt != null) 'resolvedAt': resolvedAt,
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolution != null) 'resolution': resolution,
    };
  }

  UserReport copyWith({
    String? id,
    String? reporterId,
    String? targetId,
    String? targetType,
    String? reason,
    String? status,
    Timestamp? createdAt,
    Timestamp? resolvedAt,
    String? resolvedBy,
    String? resolution,
  }) {
    return UserReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolution: resolution ?? this.resolution,
    );
  }

  String get targetTypeDisplayName {
    switch (targetType) {
      case 'craftsman':
        return 'صنايعي';
      case 'store':
        return 'متجر';
      case 'courier':
        return 'كورير';
      default:
        return targetType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'معلق';
      case 'resolved':
        return 'تم الحل';
      case 'dismissed':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
