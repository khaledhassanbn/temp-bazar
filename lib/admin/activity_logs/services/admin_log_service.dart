import '../models/admin_action_type.dart';
import '../repositories/admin_log_repository.dart';

class AdminLogService {
  AdminLogService({AdminLogRepository? repository})
      : _repository = repository ?? AdminLogRepository();

  final AdminLogRepository _repository;

  Future<void> logAction({
    required String adminUid,
    required String adminName,
    required AdminActionType actionType,
    required String targetType,
    required String targetId,
    String? targetName,
    String? description,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
  }) {
    return _repository.create(
      adminUid: adminUid,
      adminName: adminName,
      actionType: actionType,
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
      description: description,
      metadata: metadata,
      previousState: previousState,
      newState: newState,
    );
  }
}
