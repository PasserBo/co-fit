import 'dart:convert';

import '../domain/coach_session_log.dart';
import 'jsonl_coach_session_log.dart';

/// 测试用:事件留在内存([events]),不可导出。
class InMemoryCoachSessionLog implements CoachSessionLog {
  final List<Map<String, Object?>> events = [];
  int _seq = 0;

  /// 某类事件,按写入顺序。
  List<Map<String, Object?>> of(String event) =>
      events.where((e) => e['event'] == event).toList();

  @override
  String? get filePath => null;

  @override
  void write(String event, [Map<String, Object?> fields = const {}]) {
    events.add(
      jsonDecode(
            encodeCoachLogEvent(
              seq: _seq++,
              tMs: 0,
              event: event,
              fields: fields,
            ),
          )
          as Map<String, Object?>,
    );
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}
}
