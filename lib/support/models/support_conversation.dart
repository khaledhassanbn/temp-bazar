import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum IssueType {
  storeIssue,      // مشكلة خاصة بمتجر
  craftsmanIssue,  // مشكلة خاصة بصنايعي
  driverIssue,     // مشكلة خاصة بمندوب
  appIssue,        // مشكلة بالتطبيق
  generalInquiry,  // استفسار عام
}

enum ConversationStatus {
  open,        // مفتوحة
  inProgress,  // جارى المتابعة
  resolved,    // تم الحل
  closed,      // مغلقة
}

class SupportConversation {
  final String id;
  final String userId;
  final String userName;
  final String userType; // customer | merchant | craftsman
  final IssueType issueType;
  final String? relatedMerchantId;
  final String? relatedMerchantName;
  final String? relatedCraftsmanId;
  final String? relatedCraftsmanName;
  final String? relatedDriverId;
  final String? relatedDriverName;
  final String? relatedOrderId;
  final ConversationStatus status;
  final String lastMessage;
  final int unreadAdminCount;
  final int unreadUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userType,
    required this.issueType,
    this.relatedMerchantId,
    this.relatedMerchantName,
    this.relatedCraftsmanId,
    this.relatedCraftsmanName,
    this.relatedDriverId,
    this.relatedDriverName,
    this.relatedOrderId,
    required this.status,
    required this.lastMessage,
    required this.unreadAdminCount,
    required this.unreadUserCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// تحويل IssueType لنص عربي للعرض
  String get issueTypeDisplayName {
    switch (issueType) {
      case IssueType.storeIssue: return 'مشكلة خاصة بمتجر';
      case IssueType.craftsmanIssue: return 'مشكلة خاصة بصنايعي';
      case IssueType.driverIssue: return 'مشكلة خاصة بمندوب';
      case IssueType.appIssue: return 'مشكلة بالتطبيق';
      case IssueType.generalInquiry: return 'استفسار عام';
    }
  }

  /// تحويل الحالة لنص عربي
  String get statusDisplayName {
    switch (status) {
      case ConversationStatus.open: return 'مفتوحة';
      case ConversationStatus.inProgress: return 'جارى المتابعة';
      case ConversationStatus.resolved: return 'تم الحل';
      case ConversationStatus.closed: return 'مغلقة';
    }
  }

  /// لون الحالة
  Color get statusColor {
    switch (status) {
      case ConversationStatus.open: return Colors.blue;
      case ConversationStatus.inProgress: return Colors.orange;
      case ConversationStatus.resolved: return Colors.green;
      case ConversationStatus.closed: return Colors.grey;
    }
  }

  factory SupportConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse IssueType
    final issueTypeStr = data['issueType']?.toString() ?? 'generalInquiry';
    final issueType = IssueType.values.firstWhere(
      (e) => e.name == issueTypeStr,
      orElse: () => IssueType.generalInquiry,
    );

    // Parse ConversationStatus
    final statusStr = data['status']?.toString() ?? 'open';
    final status = ConversationStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => ConversationStatus.open,
    );

    // Parse timestamps safely
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final updatedAtTimestamp = data['updatedAt'] as Timestamp?;
    
    final createdAt = createdAtTimestamp != null ? createdAtTimestamp.toDate() : DateTime.now();
    final updatedAt = updatedAtTimestamp != null ? updatedAtTimestamp.toDate() : DateTime.now();

    return SupportConversation(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userType: data['userType']?.toString() ?? 'customer',
      issueType: issueType,
      relatedMerchantId: data['relatedMerchantId']?.toString(),
      relatedMerchantName: data['relatedMerchantName']?.toString(),
      relatedCraftsmanId: data['relatedCraftsmanId']?.toString(),
      relatedCraftsmanName: data['relatedCraftsmanName']?.toString(),
      relatedDriverId: data['relatedDriverId']?.toString(),
      relatedDriverName: data['relatedDriverName']?.toString(),
      relatedOrderId: data['relatedOrderId']?.toString(),
      status: status,
      lastMessage: data['lastMessage']?.toString() ?? '',
      unreadAdminCount: (data['unreadAdminCount'] as num?)?.toInt() ?? 0,
      unreadUserCount: (data['unreadUserCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'issueType': issueType.name,
      'relatedMerchantId': relatedMerchantId ?? '',
      'relatedMerchantName': relatedMerchantName ?? '',
      'relatedCraftsmanId': relatedCraftsmanId ?? '',
      'relatedCraftsmanName': relatedCraftsmanName ?? '',
      'relatedDriverId': relatedDriverId ?? '',
      'relatedDriverName': relatedDriverName ?? '',
      'relatedOrderId': relatedOrderId ?? '',
      'status': status.name,
      'lastMessage': lastMessage,
      'unreadAdminCount': unreadAdminCount,
      'unreadUserCount': unreadUserCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SupportConversation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userType,
    IssueType? issueType,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedOrderId,
    ConversationStatus? status,
    String? lastMessage,
    int? unreadAdminCount,
    int? unreadUserCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      issueType: issueType ?? this.issueType,
      relatedMerchantId: relatedMerchantId ?? this.relatedMerchantId,
      relatedMerchantName: relatedMerchantName ?? this.relatedMerchantName,
      relatedCraftsmanId: relatedCraftsmanId ?? this.relatedCraftsmanId,
      relatedCraftsmanName: relatedCraftsmanName ?? this.relatedCraftsmanName,
      relatedDriverId: relatedDriverId ?? this.relatedDriverId,
      relatedDriverName: relatedDriverName ?? this.relatedDriverName,
      relatedOrderId: relatedOrderId ?? this.relatedOrderId,
      status: status ?? this.status,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadAdminCount: unreadAdminCount ?? this.unreadAdminCount,
      unreadUserCount: unreadUserCount ?? this.unreadUserCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
