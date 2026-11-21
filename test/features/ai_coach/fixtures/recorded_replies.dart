import 'dart:convert';
import 'dart:io';

/// a2ui_flutter 官方 example 录下的一轮表单往返(Apache-2.0, Google LLC):
/// 第 1 个回答是带邮箱输入框与「Subscribe」按钮的卡片,第 2 个回答是提交后的更新。
/// 内容与健身无关,只用来验证渲染、操作回传与日志,不验证教练回答质量。
final Map<String, Object?> recordedFormRoundTrip =
    jsonDecode(
          File(
            'test/features/ai_coach/fixtures/newsletter_replies.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>;

List<List<String>> get recordedReplies => [
  for (final Object? reply
      in recordedFormRoundTrip['replies']! as List<Object?>)
    (reply! as List<Object?>).cast<String>(),
];

String get recordedRequest => recordedFormRoundTrip['request']! as String;
