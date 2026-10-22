import '../data/firebase_report_repository.dart';

/// 提交举报(UGC 合规:App Store 指南 1.2 要求有举报机制)。
/// 举报对象 = 房间本身(targetUserId 为 null)或房间内某成员。
class SubmitReportUsecase {
  SubmitReportUsecase(this._repository);

  static const reasonMaxLength = 500;

  final FirebaseReportRepository _repository;

  Future<void> execute({
    required String reporterId,
    required String roomId,
    String? targetUserId,
    required String reason,
  }) {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'Reason must not be empty.');
    }
    if (trimmedReason.length > reasonMaxLength) {
      throw ArgumentError.value(
        reason,
        'reason',
        'Reason must be at most $reasonMaxLength characters.',
      );
    }
    final trimmedTarget = targetUserId?.trim();
    return _repository.submit(
      reporterId: reporterId.trim(),
      roomId: roomId.trim(),
      targetUserId: (trimmedTarget == null || trimmedTarget.isEmpty)
          ? null
          : trimmedTarget,
      reason: trimmedReason,
    );
  }
}
