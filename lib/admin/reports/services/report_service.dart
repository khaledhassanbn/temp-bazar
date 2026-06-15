import '../models/report_model.dart';
import '../models/report_status.dart';
import '../repositories/report_repository.dart';

class ReportService {
  ReportService({ReportRepository? repository})
      : _repository = repository ?? ReportRepository();

  final ReportRepository _repository;

  Stream<List<ReportModel>> watchReports({
    ReportStatus? status,
    String? targetType,
  }) {
    return _repository.watchReports(status: status, targetType: targetType);
  }

  Future<void> resolveReport({
    required String reportId,
    required String adminUid,
    required String adminName,
    String? note,
    String actionTaken = 'none',
  }) {
    return _repository.updateStatus(
      reportId: reportId,
      status: ReportStatus.resolved,
      reviewedBy: adminUid,
      reviewedByName: adminName,
      reviewNote: note,
      actionTaken: actionTaken,
    );
  }

  Future<void> dismissReport({
    required String reportId,
    required String adminUid,
    required String adminName,
    String? note,
  }) {
    return _repository.updateStatus(
      reportId: reportId,
      status: ReportStatus.dismissed,
      reviewedBy: adminUid,
      reviewedByName: adminName,
      reviewNote: note,
      actionTaken: 'none',
    );
  }

  Future<void> markUnderReview({
    required String reportId,
    required String adminUid,
    required String adminName,
  }) {
    return _repository.updateStatus(
      reportId: reportId,
      status: ReportStatus.underReview,
      reviewedBy: adminUid,
      reviewedByName: adminName,
    );
  }
}
