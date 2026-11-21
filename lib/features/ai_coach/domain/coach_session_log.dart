/// 一次 AI 教练会话的事件日志(beta 试用的效果评估依据)。
///
/// 每个事件是 `{seq, ts, t_ms, event, ...fields}`;事件表见
/// docs/spec/changes/add-ai-coach-beta/design.md。实现:
/// data/jsonl_coach_session_log.dart(设备文件)、data/in_memory_coach_session_log.dart(测试)。
abstract class CoachSessionLog {
  void write(String event, [Map<String, Object?> fields = const {}]);

  /// 日志文件路径;仅内存时为 null(不可导出)。
  String? get filePath;

  Future<void> flush();

  Future<void> close();
}
