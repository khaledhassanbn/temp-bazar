import 'package:cloud_firestore/cloud_firestore.dart';

import 'report_reason.dart';
import 'report_status.dart';

class ReportModel {
  final String id;
  final String reporterUid;
  final String reporterName;
  final String targetType;
  final String targetId;
  final String targetName;
  final ReportReason reason;
  final String reasonText;
  final String? additionalDetails;
  final String? mediaUrl;
  final ReportStatus status;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? reviewNote;
  final String? actionTaken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const ReportModel({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.reasonText,
    this.additionalDetails,
    this.mediaUrl,
    required this.status,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewNote,
    this.actionTaken,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory ReportModel.fromFirestore(String id, Map<String, dynamic> data) {
    final reasonKey = data['reason'] as String? ?? 'other';
    final statusKey = data['status'] as String? ?? 'pending';
    return ReportModel(
      id: id,
      reporterUid: data['reporterUid'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetName: data['targetName'] as String? ?? '',
      reason: ReportReason.fromKey(reasonKey) ?? ReportReason.other,
      reasonText: data['reasonText'] as String? ?? '',
      additionalDetails: data['additionalDetails'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      status: ReportStatus.fromKey(statusKey) ?? ReportStatus.pending,
      reviewedBy: data['reviewedBy'] as String?,
      reviewedByName: data['reviewedByName'] as String?,
      reviewNote: data['reviewNote'] as String?,
      actionTaken: data['actionTaken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
