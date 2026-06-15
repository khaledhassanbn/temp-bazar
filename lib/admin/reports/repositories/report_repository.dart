import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_model.dart';
import '../models/report_status.dart';

class ReportRepository {
  ReportRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('reports');

  Stream<List<ReportModel>> watchReports({
    ReportStatus? status,
    String? targetType,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q =
        _col.orderBy('createdAt', descending: true).limit(limit);

    if (status != null && targetType != null) {
      q = _col
          .where('targetType', isEqualTo: targetType)
          .where('status', isEqualTo: status.firestoreKey)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    } else if (status != null) {
      q = _col
          .where('status', isEqualTo: status.firestoreKey)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }

    return q.snapshots().map(
          (snap) => snap.docs
              .map((d) => ReportModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<ReportModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReportModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> updateStatus({
    required String reportId,
    required ReportStatus status,
    required String reviewedBy,
    required String reviewedByName,
    String? reviewNote,
    String? actionTaken,
  }) async {
    final payload = <String, dynamic>{
      'status': status.firestoreKey,
      'reviewedBy': reviewedBy,
      'reviewedByName': reviewedByName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reviewNote != null) payload['reviewNote'] = reviewNote;
    if (actionTaken != null) payload['actionTaken'] = actionTaken;
    if (status == ReportStatus.resolved || status == ReportStatus.dismissed) {
      payload['resolvedAt'] = FieldValue.serverTimestamp();
    }
    await _col.doc(reportId).update(payload);
  }
}
