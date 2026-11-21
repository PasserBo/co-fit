// 汇总 AI 教练(beta)的会话日志(change add-ai-coach-beta)。
//
//   fvm dart run tool/summarize_ai_coach_log.dart coach_*.jsonl
//
// Prints one row per model turn (latency, size, A2UI messages, errors) and a
// total per log, so runs (models, formats, prompts) can be compared.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: fvm dart run tool/summarize_ai_coach_log.dart <log.jsonl>...',
    );
    exitCode = 64;
    return;
  }
  for (final String path in args) {
    _summarize(File(path));
  }
}

void _summarize(File file) {
  final List<Map<String, Object?>> events = [
    for (final String line in file.readAsLinesSync())
      if (line.trim().isNotEmpty) jsonDecode(line) as Map<String, Object?>,
  ];
  Map<String, Object?>? first(String name) =>
      events.where((e) => e['event'] == name).firstOrNull;
  final Map<String, Object?>? start = first('session_start');
  final Map<String, Object?>? prompt = first('system_prompt');

  stdout
    ..writeln('== ${file.path}')
    ..writeln(
      'model=${start?['model']}  records=${start?['records']}  format=${start?['format']}  '
      'protocol=${start?['protocol']}  system_prompt=${prompt?['chars']} chars',
    );

  final Map<int, String> kinds = {
    for (final e in events.where((e) => e['event'] == 'user_turn'))
      e['turn']! as int: '${e['kind']}',
  };
  final Map<int, String> userText = {
    for (final e in events.where((e) => e['event'] == 'user_turn'))
      e['turn']! as int: '${e['text']}',
  };
  final Map<int, int> errors = {};
  for (final e in events.where((e) => e['event'] == 'renderer_error')) {
    errors.update(e['turn']! as int, (n) => n + 1, ifAbsent: () => 1);
  }

  stdout.writeln(
    '${'turn'.padRight(5)}${'kind'.padRight(8)}${'ok'.padRight(4)}'
    '${'ttfb'.padLeft(7)}${'1st_ui'.padLeft(8)}${'total'.padLeft(8)}'
    '${'chars'.padLeft(7)}${'a2ui'.padLeft(6)}${'err'.padLeft(5)}  request',
  );
  var turns = 0, okTurns = 0, totalMs = 0, totalChars = 0, totalErrors = 0;
  for (final e in events.where((e) => e['event'] == 'model_reply')) {
    final int turn = e['turn']! as int;
    final int err = errors[turn] ?? 0;
    turns++;
    if (e['ok'] == true) okTurns++;
    totalMs += (e['total_ms'] as int?) ?? 0;
    totalChars += (e['chars'] as int?) ?? 0;
    totalErrors += err;
    final String request = (userText[turn] ?? '').replaceAll('\n', ' ');
    stdout.writeln(
      '${'$turn'.padRight(5)}${(kinds[turn] ?? '?').padRight(8)}'
      '${(e['ok'] == true ? 'y' : 'N').padRight(4)}'
      '${_ms(e['ttfb_ms']).padLeft(7)}${_ms(e['first_a2ui_ms']).padLeft(8)}'
      '${_ms(e['total_ms']).padLeft(8)}${'${e['chars']}'.padLeft(7)}'
      '${'${e['a2ui_messages']}'.padLeft(6)}${'$err'.padLeft(5)}  '
      '${request.length > 50 ? '${request.substring(0, 50)}…' : request}',
    );
  }
  final int surfaces = events
      .where((e) => e['event'] == 'surface_created')
      .length;
  final int actions = events
      .where((e) => e['event'] == 'outbound' && e['type'] == 'ActionMessage')
      .length;
  stdout
    ..writeln(
      'turns=$turns ok=$okTurns surfaces=$surfaces actions=$actions '
      'renderer_errors=$totalErrors model_ms=$totalMs reply_chars=$totalChars',
    )
    ..writeln();
  for (final e in events.where((e) => e['event'] == 'renderer_error')) {
    stdout.writeln(
      '  ! turn ${e['turn']} ${e['code']} on "${e['surface']}" '
      '${e['path'] ?? ''}: ${e['message']}',
    );
  }
}

String _ms(Object? value) => value == null ? '-' : '${value}ms';
