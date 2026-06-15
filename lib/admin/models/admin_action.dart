import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAction {
  final String action; // 'approved' | 'rejected' | 'suspended' | 'banned' | 'deleted' | 'restored'
  final String by; // adminId
  final Timestamp at;
  final String reason;

  AdminAction({
    required this.action,
    required this.by,
    required this.at,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'by': by,
      'at': at,
      'reason': reason,
    };
  }

  factory AdminAction.fromMap(Map<String, dynamic> map) {
    return AdminAction(
      action: map['action'] ?? '',
      by: map['by'] ?? '',
      at: map['at'] ?? Timestamp.now(),
      reason: map['reason'] ?? '',
    );
  }

  String get actionDisplayName {
    switch (action) {
      case 'approved':
        return 'تم القبول';
      case 'rejected':
        return 'تم الرفض';
      case 'suspended':
        return 'تم التعليق';
      case 'banned':
        return 'تم الحظر';
      case 'deleted':
        return 'تم الحذف';
      case 'restored':
        return 'تم الاستعادة';
      case 'converted':
        return 'تم التحويل';
      default:
        return action;
    }
  }

  AdminAction copyWith({
    String? action,
    String? by,
    Timestamp? at,
    String? reason,
  }) {
    return AdminAction(
      action: action ?? this.action,
      by: by ?? this.by,
      at: at ?? this.at,
      reason: reason ?? this.reason,
    );
  }
}
