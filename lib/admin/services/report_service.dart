import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_report.dart';

class ReportService {
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
      // 1. Check for duplicate reports (simplified query to avoid composite index)
      // Get all reports from this reporter to this target, filter locally
      final existing = await _firestore
          .collection('user_reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('targetId', isEqualTo: targetId)
          .limit(5)
          .get()
          .timeout(Duration(seconds: 10));

      // Check if any report was created in the last 24 hours (filter on client side)
      final twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24));
      final recentReports = existing.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(twentyFourHoursAgo);
      }).toList();

      if (recentReports.isNotEmpty) {
        throw Exception('لقد أبلغت عن هذا المستخدم مؤخراً. يرجى الانتظار 24 ساعة.');
      }

      // 2. Create report
      final doc = await _firestore.collection('user_reports').add({
        'reporterId': reporterId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Handle report creation side effects (replaces Cloud Function)
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

  /// Handle report creation (replaces Cloud Function)
  Future<void> _handleReportCreated(
      String targetId, String targetType) async {
    try {
      // Determine collection based on target type
      final collection = targetType == 'craftsman'
          ? 'craftsmen'
          : targetType == 'store'
              ? 'markets'
              : 'courier_requests';

      // Increment reportCount on target entity
      await _firestore.collection(collection).doc(targetId).update({
        'reportCount': FieldValue.increment(1),
      });

      // TODO: Send FCM notification to admins
      // This would require implementing FCM separately
      // For now, we skip this part or implement it later
    } catch (e) {
      print('Error handling report creation: $e');
      // Don't throw - allow report creation to succeed even if counter update fails
    }
  }

  /// Watch pending reports in real-time
  Stream<List<UserReport>> watchPendingReports() {
    try {
      return _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) {
              try {
                return UserReport.fromFirestore(doc);
              } catch (e) {
                print('Error parsing report ${doc.id}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<UserReport>()
            .toList();
        
        // Sort locally instead of using orderBy (to avoid composite index)
        reports.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          return bTime.compareTo(aTime);
        });
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      print('Error in watchPendingReports: $e');
      rethrow;
    }
  }

  /// Get all reports for a specific target
  Future<List<UserReport>> getReportsByTarget(String targetId) async {
    try {
      final snapshot = await _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .get()
          .timeout(Duration(seconds: 30));

      final reports = snapshot.docs
          .map((doc) => UserReport.fromFirestore(doc))
          .toList();
      
      // Sort locally instead of using orderBy (to avoid composite index)
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reports;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Resolve a report
  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String resolution,
  }) async {
    try {
      // Validate resolution text
      if (resolution.trim().length < 10) {
        throw Exception('يجب أن يكون نص الحل 10 أحرف على الأقل');
      }

      await _firestore
          .collection('user_reports')
          .doc(reportId)
          .update({
            'status': 'resolved',
            'resolvedAt': FieldValue.serverTimestamp(),
            'resolvedBy': adminId,
            'resolution': resolution.trim(),
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لحل البلاغ');
      } else if (e.toString().contains('not-found')) {
        throw Exception('البلاغ غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Dismiss a report
  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore
          .collection('user_reports')
          .doc(reportId)
          .update({
            'status': 'dismissed',
            'resolvedAt': FieldValue.serverTimestamp(),
            'resolvedBy': adminId,
            'resolution': reason.trim(),
          })
          .timeout(Duration(seconds: 30));
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لرفض البلاغ');
      } else if (e.toString().contains('not-found')) {
        throw Exception('البلاغ غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Get report count for a specific target
  Future<int> getReportCountForTarget(String targetId) async {
    try {
      final snapshot = await _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .count()
          .get()
          .timeout(Duration(seconds: 30));

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }

  /// Watch all reports (for admin dashboard)
  Stream<List<UserReport>> watchAllReports() {
    try {
      return _firestore
          .collection('user_reports')
          .limit(100)
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) {
              try {
                return UserReport.fromFirestore(doc);
              } catch (e) {
                print('Error parsing report ${doc.id}: $e');
                return null;
              }
            })
            .where((report) => report != null)
            .cast<UserReport>()
            .toList();
        
        // Sort locally instead of using orderBy (to avoid index requirement)
        reports.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          return bTime.compareTo(aTime);
        });
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      print('Error in watchAllReports: $e');
      rethrow;
    }
  }

  /// Watch reports for a specific target in real-time
  Stream<List<UserReport>> watchReportsForTarget(String targetId) {
    try {
      return _firestore
          .collection('user_reports')
          .where('targetId', isEqualTo: targetId)
          .snapshots()
          .map((snapshot) {
        final reports = snapshot.docs
            .map((doc) => UserReport.fromFirestore(doc))
            .toList();
        // Sort locally instead of using orderBy (to avoid composite index)
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reports;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض البلاغات');
      }
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
