import 'dart:convert';
import 'dart:io';

import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/ai_coach/data/in_memory_coach_session_log.dart';
import 'package:cofit/features/ai_coach/data/jsonl_coach_session_log.dart';
import 'package:cofit/features/ai_coach/data/replay_coach_model_client.dart';
import 'package:cofit/features/ai_coach/presentation/widget/coach_chat_entry.dart';
import 'package:cofit/features/ai_coach/provider/coach_chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/recorded_replies.dart';

CoachChatController _controller(
  ReplayCoachModelClient client,
  InMemoryCoachSessionLog log,
) => CoachChatController(
  client: client,
  log: log,
  recordsContext: 'RECORDS-CONTEXT',
  recordCount: 3,
);

void main() {
  testWidgets('表单往返:渲染卡片、提交操作回传给模型、每一步写日志', (tester) async {
    final client = ReplayCoachModelClient(recordedReplies);
    final log = InMemoryCoachSessionLog();
    final controller = _controller(client, log);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: CoFitTheme.dark,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => ListView(
              children: [
                for (final entry in controller.entries)
                  CoachChatEntry(entry: entry),
              ],
            ),
          ),
        ),
      ),
    );

    await controller.send(recordedRequest, preset: true);
    await tester.pumpAndSettle();

    expect(client.systemPrompts.single, startsWith(coachInstructions));
    expect(client.systemPrompts.single, contains('RECORDS-CONTEXT'));
    final Finder surface = find.byType(A2uiSurface);
    expect(surface, findsOne);

    await tester.enterText(
      find.descendant(of: surface, matching: find.byType(TextField)),
      'ada@example.com',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pumpAndSettle();

    // 第二轮发言是 action JSON,带填写内容
    expect(client.requests, hasLength(2));
    expect(client.requests[1].last.text, contains('ada@example.com'));

    // 日志
    expect(log.of('session_start').single['records'], 3);
    expect(log.of('system_prompt').single['chars'], greaterThan(1000));
    expect(log.of('user_turn').map((e) => e['kind']), ['preset', 'action']);
    expect(log.of('surface_created').single['surface'], 'newsletter-signup');
    expect(log.of('renderer_error'), isEmpty);
    expect(log.of('outbound').single['type'], 'ActionMessage');
    final replies = log.of('model_reply');
    expect(replies, hasLength(2));
    for (final reply in replies) {
      expect(reply['ok'], isTrue);
      expect(reply['a2ui_messages'], greaterThan(0));
      expect(reply['first_a2ui_ms'], isNotNull);
      expect(reply['ttfb_ms'], isNotNull);
    }
    expect(
      log.of('model_chunk').where((e) => e['turn'] == 0).length,
      recordedReplies.first.length,
    );
  });

  testWidgets('请求失败:对话出现错误、busy 结束、日志记 ok=false', (tester) async {
    final client = ReplayCoachModelClient(const []); // 第一次请求即抛错
    final log = InMemoryCoachSessionLog();
    final controller = _controller(client, log);
    addTearDown(controller.dispose);

    await controller.send('这周我练得怎么样?');

    expect(controller.busy, isFalse);
    expect(
      controller.entries.map((e) => e.kind),
      contains(CoachEntryKind.error),
    );
    final reply = log.of('model_reply').single;
    expect(reply['ok'], isFalse);
    expect(reply['error'], isNotNull);
  });

  test('JSONL 日志可被回放成同样的模型回答', () async {
    final Directory dir = await Directory.systemTemp.createTemp('coach_log');
    addTearDown(() => dir.delete(recursive: true));
    final log = await JsonlCoachSessionLog.open(dir);
    for (final (int turn, List<String> reply) in recordedReplies.indexed) {
      for (final (int i, String chunk) in reply.indexed) {
        log.write('model_chunk', {'turn': turn, 'i': i, 'text': chunk});
      }
    }
    // 页面 dispose 与调用方可能各关一次:第二次也必须等到写盘完成
    final Future<void> first = log.close();
    await log.close();
    await first;

    final lines = File(log.filePath).readAsLinesSync();
    expect(lines, hasLength(recordedReplies.expand((r) => r).length));
    expect(jsonDecode(lines.first), containsPair('event', 'model_chunk'));
    final replay = ReplayCoachModelClient.fromLog(File(log.filePath));
    expect(replay.replies, recordedReplies);
  });
}
