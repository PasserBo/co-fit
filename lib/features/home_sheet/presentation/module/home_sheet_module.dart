import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../action/provider/action_decks_provider.dart';
import '../../../daily_goal/presentation/view/daily_progress_module_view.dart';
import '../../../daily_goal/provider/daily_goal_providers.dart';
import '../../../workout_memo/presentation/view/last_session_memo_module_view.dart';
import '../../../workout_memo/provider/workout_memo_providers.dart';
import '../../domain/entity/home_sheet_layout.dart';
import '../../provider/home_sheet_providers.dart';
import '../view/recommendation_module_view.dart';

/// 模块此刻有没有东西可显示。全部模块都是 [empty] 时今日面板不出现。
enum HomeSheetModuleStatus { loading, content, empty }

/// 模块能对房间页做的全部事情(design.md §11)。模块不引用房间页的其他东西。
abstract interface class HomeSheetHost {
  /// 收起今日面板。
  void collapseSheet();

  /// 让手牌进入选卡状态并停在 [cardId] 这张卡上。
  /// 卡不在手牌里时返回 false,手牌进入普通选卡状态。
  bool focusFanOnCard(String cardId);

  /// 完成庆祝的节拍:每播一次庆祝数值 +1(在小人完成动作第一次落地时)。
  /// 关心数字的模块监听它,在 [celebrationDelay] 之后把数字从旧值滚到新值;
  /// 不关心的模块忽略。
  ValueListenable<int> get celebrations;

  /// 模块 [moduleId] 相对节拍应延后多久(按模块在面板里的顺序依次错开)。
  Duration celebrationDelay(String moduleId);
}

/// 一个模块 = id + 状态 + 页面级组件。模块自己读数据、自己画;
/// 没有内容或出错时状态为 empty 并画空,不影响其他模块。
class HomeSheetModuleSpec {
  const HomeSheetModuleSpec({
    required this.id,
    required this.status,
    required this.build,
  });

  final String id;
  final ProviderListenable<HomeSheetModuleStatus> status;
  final Widget Function(HomeSheetHost host) build;
}

final _recommendationStatusProvider = Provider<HomeSheetModuleStatus>((ref) {
  if (ref.watch(recommendedCardProvider) != null) {
    return HomeSheetModuleStatus.content;
  }
  return ref.watch(activeHandLoadingProvider)
      ? HomeSheetModuleStatus.loading
      : HomeSheetModuleStatus.empty;
});

/// 今日进度:记录加载中显示占位;加载失败时不出现。
final _dailyProgressStatusProvider = Provider<HomeSheetModuleStatus>((ref) {
  final progress = ref.watch(dailyProgressProvider);
  if (progress.hasValue) {
    return HomeSheetModuleStatus.content;
  }
  return progress.hasError
      ? HomeSheetModuleStatus.empty
      : HomeSheetModuleStatus.loading;
});

/// 刚才这张:有可补记的记录时才出现。
final _lastSessionMemoStatusProvider = Provider<HomeSheetModuleStatus>((ref) {
  return ref.watch(memoPromptTargetProvider) == null
      ? HomeSheetModuleStatus.empty
      : HomeSheetModuleStatus.content;
});

/// 内置模块注册表:id → 模块。新增模块只需在这里登记。
final Map<String, HomeSheetModuleSpec> homeSheetModuleRegistry = {
  HomeSheetModuleIds.lastSessionMemo: HomeSheetModuleSpec(
    id: HomeSheetModuleIds.lastSessionMemo,
    status: _lastSessionMemoStatusProvider,
    build: (host) => const LastSessionMemoModuleView(),
  ),
  HomeSheetModuleIds.dailyProgress: HomeSheetModuleSpec(
    id: HomeSheetModuleIds.dailyProgress,
    status: _dailyProgressStatusProvider,
    build: (host) => DailyProgressModuleView(host: host),
  ),
  HomeSheetModuleIds.recommendation: HomeSheetModuleSpec(
    id: HomeSheetModuleIds.recommendation,
    status: _recommendationStatusProvider,
    build: (host) => RecommendationModuleView(host: host),
  ),
};

/// 按布局配置取出模块:保持配置顺序,跳过这个版本不认识的 id 与重复的 id。
List<HomeSheetModuleSpec> resolveHomeSheetModules(
  HomeSheetLayout layout, {
  Map<String, HomeSheetModuleSpec>? registry,
}) {
  final source = registry ?? homeSheetModuleRegistry;
  final seen = <String>{};
  return [
    for (final id in layout.modules)
      if (source[id] != null && seen.add(id)) source[id]!,
  ];
}
