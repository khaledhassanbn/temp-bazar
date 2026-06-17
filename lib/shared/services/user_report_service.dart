import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/shared/models/user_report.dart';

class UserReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new report with duplicate validation
  Future<String> createReport({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    try {
      final existing = await _firestore
          .collection('user_reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('targetId', isEqualTo: targetId)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 10));

      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      final recentReports = existing.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(twentyFourHoursAgo);
      }).toList();

      if (recentReports.isNotEmpty) {
        throw Exception('لقد أبلغت عن هذا المستخدم مؤخراً. يرجى الانتظار 24 ساعة.');
      }

      final doc = await _firestore.collection('user_reports').add({
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _handleReportCreated(targetId, targetType);

      return doc.id;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لإنشاء بلاغ');
      } else if (e.toString().contains('not-found')) {
        throw Exception('المستخدم المبلغ عنه غير موجود');
      } else if (e.toString().contains('network')) {
        throw Exception('حدث خطأ في الاتصال، حاول مرة أخرى');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  Future<void> _handleReportCreated(String targetId, String targetType) async {
    try {
      final collection = targetType == 'craftsman'
          ? 'craftsmen'
          : targetType == 'store'
              ? 'markets'
              : 'courier_requests';

      await _firestore.collection(collection).doc(targetId).update({
        'reportCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Don't throw - allow report creation to succeed even if counter update fails
    }
  }

  String? getCurrentUserId() => _auth.currentUser?.uid;
}
