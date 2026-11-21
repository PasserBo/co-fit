import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/flags/feature_flags_provider.dart';
import '../../action/domain/entity/action_session_record.dart';
import '../../action/domain/entity/action_template_card.dart';
import '../../action/provider/action_decks_provider.dart';
import '../../action/provider/action_session_history_providers.dart';
import '../domain/entity/home_sheet_layout.dart';
import '../domain/recommend_card_strategy.dart';

/// 今日面板的布局配置:远程值解析后的结果,读不到或无法识别时是内置默认值。
final homeSheetLayoutProvider = Provider<HomeSheetLayout>((ref) {
  return HomeSheetLayout.parse(
    ref.watch(featureFlagsValueProvider).homeSheetLayout,
  );
});

/// 「今日推荐」的推荐规则。换规则 = 覆盖这个 provider。
final recommendCardStrategyProvider = Provider<RecommendCardStrategy>((ref) {
  return const LeastRecentlyDoneStrategy();
});

/// 今日推荐的卡(一定在当前手牌里);没有可推荐的为 null。
/// 运动记录还没加载完时按「没有记录」推荐,加载完后自动更新。
final recommendedCardProvider = Provider<ActionTemplateCard?>((ref) {
  return ref
      .watch(recommendCardStrategyProvider)
      .recommend(
        hand: ref.watch(activeHandProvider),
        history:
            ref.watch(recentSessionsProvider).value ??
            const <ActionSessionRecord>[],
      );
});
