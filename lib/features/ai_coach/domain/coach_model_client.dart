/// 对话中的一轮发言。
typedef CoachTurn = ({bool fromUser, String text});

/// 流式回答的语言模型。实现:data/firebase_ai_coach_model_client.dart(线上)、
/// data/replay_coach_model_client.dart(测试 / 按日志回放)。
abstract interface class CoachModelClient {
  /// 写进日志的名字,如 `firebase_ai:gemini-3.6-flash`。
  String get name;

  /// 在 [systemPrompt] 下回答 [turns](最后一条是用户发言),按模型流式输出逐段产出。
  Stream<String> generate(String systemPrompt, List<CoachTurn> turns);
}
