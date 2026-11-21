import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/flags/feature_flags_provider.dart';
import '../../action/provider/action_session_history_providers.dart';
import '../data/firebase_ai_coach_model_client.dart';
import '../data/jsonl_coach_session_log.dart';
import '../data/shared_preferences_coach_consent_repository.dart';
import '../domain/coach_consent_repository.dart';
import '../domain/coach_model_client.dart';
import '../domain/coach_session_log.dart';
import '../usecase/build_coach_context_usecase.dart';
import 'coach_chat_controller.dart';

/// 可用 --dart-define 覆盖,便于对比模型与格式(结果都写进日志 session_start)。
const _modelName = String.fromEnvironment(
  'AI_COACH_MODEL',
  defaultValue: 'gemini-3.6-flash',
);
const _format = String.fromEnvironment('AI_COACH_FORMAT');

/// debug 构建无视远程开关始终展示入口(测试里覆盖为 false 以验证开关)。
final aiCoachDebugOverrideProvider = Provider<bool>((ref) => kDebugMode);

/// 运动历史页是否展示「AI 教练 Beta」入口。
final aiCoachEntryVisibleProvider = Provider<bool>((ref) {
  return ref.watch(aiCoachDebugOverrideProvider) ||
      ref.watch(featureFlagsValueProvider).betaAiCoachEnabled;
});

final coachConsentRepositoryProvider = Provider<CoachConsentRepository>((ref) {
  return SharedPreferencesCoachConsentRepository();
});

final coachModelClientProvider = Provider<CoachModelClient>((ref) {
  return FirebaseAiCoachModelClient(modelName: _modelName);
});

final coachFormatProvider = Provider<CoachFormat>((ref) {
  return CoachFormat.parse(_format);
});

/// 每次进入教练页开一个新日志文件。
final coachSessionLogFactoryProvider =
    Provider<Future<CoachSessionLog> Function()>((ref) {
      return () async {
        final Directory docs = await getApplicationDocumentsDirectory();
        return JsonlCoachSessionLog.open(
          Directory('${docs.path}/ai_coach_logs'),
        );
      };
    });

/// 组装一次新会话:读最近运动记录 → 上下文 → 开日志 → 控制器。
/// 由页面持有并在离开时 dispose(规格:对话不保存)。
final createCoachChatProvider =
    Provider<Future<CoachChatController> Function()>((ref) {
      return () async {
        final records = await ref.read(recentSessionsProvider.future);
        final CoachSessionLog log = await ref.read(
          coachSessionLogFactoryProvider,
        )();
        return CoachChatController(
          client: ref.read(coachModelClientProvider),
          log: log,
          format: ref.read(coachFormatProvider),
          recordCount: records.length,
          recordsContext: const BuildCoachContextUsecase().execute(
            records,
            now: DateTime.now(),
          ),
        );
      };
    });
