import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import '../domain/coach_session_log.dart';

/// 一会话一个 JSONL 文件:`<dir>/coach_<timestamp>.jsonl`,只存设备本地。
/// 每个事件同时镜像到 `dart:developer`(name: `ai_coach`),`flutter run` / DevTools 可见。
class JsonlCoachSessionLog implements CoachSessionLog {
  JsonlCoachSessionLog._(this._file, this._sink);

  static Future<JsonlCoachSessionLog> open(Directory dir) async {
    await dir.create(recursive: true);
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '_');
    final file = File('${dir.path}/coach_$stamp.jsonl');
    return JsonlCoachSessionLog._(file, file.openWrite(mode: FileMode.append));
  }

  final File _file;
  final IOSink _sink;
  final Stopwatch _clock = Stopwatch()..start();
  int _seq = 0;
  bool _closed = false;

  @override
  String get filePath => _file.path;

  @override
  void write(String event, [Map<String, Object?> fields = const {}]) {
    if (_closed) {
      return;
    }
    final String line = encodeCoachLogEvent(
      seq: _seq++,
      tMs: _clock.elapsedMilliseconds,
      event: event,
      fields: fields,
    );
    _sink.writeln(line);
    developer.log(line, name: 'ai_coach');
  }

  @override
  Future<void> flush() => _closed ? Future.value() : _sink.flush();

  /// 幂等:重复调用拿到同一个 Future,保证所有调用方都等到写盘完成
  /// (页面 dispose 与导出可能同时关闭)。
  @override
  Future<void> close() => _closing ??= _close();

  Future<void>? _closing;

  Future<void> _close() async {
    _closed = true;
    await _sink.flush();
    await _sink.close();
  }
}

/// 一行日志的 JSON。无法 JSON 化的值退化为 `toString()`,保证日志永不因内容抛错。
String encodeCoachLogEvent({
  required int seq,
  required int tMs,
  required String event,
  required Map<String, Object?> fields,
}) {
  return jsonEncode({
    'seq': seq,
    'ts': DateTime.now().toIso8601String(),
    't_ms': tMs,
    'event': event,
    ...fields,
  }, toEncodable: (Object? value) => value.toString());
}
