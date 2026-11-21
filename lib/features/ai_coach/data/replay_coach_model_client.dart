import 'dart:convert';
import 'dart:io';

import '../domain/coach_model_client.dart';

/// 依次回放录好的模型回答(每个回答是若干流式分段),不调用模型。
///
/// 用于测试,以及把导出的会话日志(`model_chunk` 事件)重新喂给渲染器,
/// 在不花模型调用的情况下复现一次会话。
class ReplayCoachModelClient implements CoachModelClient {
  ReplayCoachModelClient(this.replies, {this.source = 'memory'});

  /// 读取会话日志里的 `model_chunk` 事件,按 turn 分组。
  factory ReplayCoachModelClient.fromLog(File log) {
    final Map<int, List<String>> byTurn = {};
    for (final String line in log.readAsLinesSync()) {
      if (line.trim().isEmpty) {
        continue;
      }
      final Map<String, Object?> event =
          jsonDecode(line) as Map<String, Object?>;
      if (event['event'] != 'model_chunk') {
        continue;
      }
      byTurn
          .putIfAbsent(event['turn']! as int, () => [])
          .add(event['text']! as String);
    }
    final List<int> turns = byTurn.keys.toList()..sort();
    return ReplayCoachModelClient([
      for (final int turn in turns) byTurn[turn]!,
    ], source: log.path);
  }

  final List<List<String>> replies;
  final String source;

  /// 每次请求收到的 system prompt 与对话(测试断言用)。
  final List<String> systemPrompts = [];
  final List<List<CoachTurn>> requests = [];

  @override
  String get name => 'replay:$source';

  @override
  Stream<String> generate(String systemPrompt, List<CoachTurn> turns) async* {
    systemPrompts.add(systemPrompt);
    requests.add(List.of(turns));
    final int index = requests.length - 1;
    if (index >= replies.length) {
      throw StateError('回放没有第 ${index + 1} 个回答(共 ${replies.length} 个)');
    }
    yield* Stream.fromIterable(replies[index]);
  }
}
