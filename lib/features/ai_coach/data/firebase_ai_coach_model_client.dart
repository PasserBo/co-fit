import 'package:firebase_ai/firebase_ai.dart' as fai;

import '../domain/coach_model_client.dart';

/// Firebase AI Logic(Gemini Developer API)。模型密钥不在 App 内。
///
/// 需在 Firebase console 启用 AI Logic(见 add-ai-coach-beta tasks T6),
/// 否则首个请求即失败,错误会进对话与日志。
class FirebaseAiCoachModelClient implements CoachModelClient {
  FirebaseAiCoachModelClient({required this.modelName});

  final String modelName;

  @override
  String get name => 'firebase_ai:$modelName';

  @override
  Stream<String> generate(String systemPrompt, List<CoachTurn> turns) async* {
    final fai.GenerativeModel model = fai.FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: fai.Content.system(systemPrompt),
    );
    final List<fai.Content> contents = [
      for (final CoachTurn turn in turns)
        turn.fromUser
            ? fai.Content.text(turn.text)
            : fai.Content.model([fai.TextPart(turn.text)]),
    ];
    await for (final fai.GenerateContentResponse response
        in model.generateContentStream(contents)) {
      final String? text = response.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }
}
