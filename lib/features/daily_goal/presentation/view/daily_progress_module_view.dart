import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../action/presentation/view/workout_history_page_view.dart';
import '../../../home_sheet/domain/entity/home_sheet_layout.dart';
import '../../../home_sheet/presentation/module/home_sheet_module.dart';
import '../../../home_sheet/presentation/widget/home_sheet_panel.dart';
import '../../../home_sheet/provider/home_sheet_providers.dart';
import '../../domain/entity/daily_progress.dart';
import '../../provider/daily_goal_providers.dart';
import '../widget/daily_progress_summary.dart';
import '../widget/daily_target_sheet.dart';

/// 「今日进度」模块(今日面板)。显示的进度与算出来的进度分开维护:
/// 完成一张卡时等小人完成动作落地的节拍再滚到新值(design.md §5)。
class DailyProgressModuleView extends ConsumerStatefulWidget {
  const DailyProgressModuleView({required this.host, super.key});

  final HomeSheetHost host;

  @override
  ConsumerState<DailyProgressModuleView> createState() =>
      _DailyProgressModuleViewState();
}

class _DailyProgressModuleViewState
    extends ConsumerState<DailyProgressModuleView> {
  /// 正在显示的进度。
  DailyProgress? _shown;

  /// 已经算出来、还在等节拍的新进度。
  DailyProgress? _pending;
  Timer? _applyTimer;

  /// 最近一次还没用掉的节拍(节拍先于新记录到达时用)。
  DateTime? _unusedBeatAt;
  bool _animateNext = false;
  int _pulseTick = 0;

  late ValueListenable<int> _celebrations;

  @override
  void initState() {
    super.initState();
    _celebrations = widget.host.celebrations..addListener(_onBeat);
  }

  @override
  void didUpdateWidget(DailyProgressModuleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.host.celebrations, _celebrations)) {
      _celebrations.removeListener(_onBeat);
      _celebrations = widget.host.celebrations..addListener(_onBeat);
    }
  }

  @override
  void dispose() {
    _celebrations.removeListener(_onBeat);
    _applyTimer?.cancel();
    super.dispose();
  }

  void _onBeat() {
    if (_pending == null) {
      _unusedBeatAt = DateTime.now();
      return;
    }
    _applyAfter(widget.host.celebrationDelay(HomeSheetModuleIds.dailyProgress));
  }

  void _applyAfter(Duration delay) {
    _applyTimer?.cancel();
    _applyTimer = Timer(delay, _applyPending);
  }

  void _applyPending() {
    final next = _pending;
    final shown = _shown;
    if (!mounted || next == null) {
      return;
    }
    final reachedNow = shown != null && !shown.reached && next.reached;
    setState(() {
      _shown = next;
      _pending = null;
      _animateNext = true;
      if (reachedNow) {
        _pulseTick++;
      }
    });
    if (reachedNow) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  /// 把算出来的进度同步到显示(在 build 里调用,只改字段不 setState)。
  void _sync(DailyProgress computed) {
    final shown = _shown;
    if (shown == null) {
      _shown = computed;
      return;
    }
    final target = _pending ?? shown;
    if (computed == target) {
      return;
    }
    final grew =
        computed.current > shown.current &&
        computed.target == shown.target &&
        computed.unit == shown.unit;
    if (!grew) {
      // 过零点、改目标、换计量方式:直接套用,不播动画
      _applyTimer?.cancel();
      _pending = null;
      _shown = computed;
      _animateNext = false;
      return;
    }
    _pending = computed;
    final beatAt = _unusedBeatAt;
    _unusedBeatAt = null;
    final beatIsFresh =
        beatAt != null &&
        DateTime.now().difference(beatAt) <
            CoFitMotion.dailyProgressBeatTimeout;
    if (beatIsFresh) {
      // 节拍已经过去(记录比动画晚到):立即滚
      _applyAfter(Duration.zero);
    } else if (_applyTimer?.isActive != true) {
      // 等节拍;等不到就直接更新
      _applyAfter(CoFitMotion.dailyProgressBeatTimeout);
    }
  }

  Future<void> _pickTarget(DailyProgress progress) async {
    final picked = await showDailyTargetSheet(
      context,
      choices: ref.read(dailyTargetChoicesProvider),
      current: progress.target,
      unit: progress.unit,
    );
    if (picked != null && picked != progress.target) {
      await ref.read(savedDailyTargetProvider.notifier).setTarget(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dailyProgressProvider);
    final computed = async.value;
    if (computed == null) {
      if (async.hasError) {
        return const SizedBox.shrink();
      }
      return const HomeSheetModuleFrame(
        key: ValueKey('home_sheet_daily_progress'),
        child: DailyProgressSummary(progress: null),
      );
    }
    _sync(computed);
    final shown = _shown!;
    final animate = _animateNext && !MediaQuery.disableAnimationsOf(context);
    final colors = Theme.of(context).extension<CoFitColors>()!;

    // 今天还没开始:引导到今日推荐,点模块 = 点今日推荐
    final recommended = shown.current == 0
        ? ref.watch(recommendedCardProvider)
        : null;

    return HomeSheetModuleFrame(
      key: const ValueKey('home_sheet_daily_progress'),
      // 今天做过:点正文直达运动历史(add-workout-memo)
      onTap: recommended == null
          ? (shown.current > 0
                ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WorkoutHistoryPageView(),
                    ),
                  )
                : null)
          : () {
              widget.host
                ..focusFanOnCard(recommended.id)
                ..collapseSheet();
            },
      child: DailyProgressSummary(
        progress: shown,
        hint: recommended == null ? null : '从今日推荐开始',
        animate: animate,
        pulseTick: animate ? _pulseTick : 0,
        trailing: IconButton(
          key: const ValueKey('daily_progress_edit_target'),
          tooltip: '调整今日目标',
          onPressed: () => _pickTarget(shown),
          icon: Icon(Icons.tune, color: colors.textTertiary),
          constraints: const BoxConstraints(
            minWidth: CoFitDimens.sizeMinTapTarget,
            minHeight: CoFitDimens.sizeMinTapTarget,
          ),
        ),
      ),
    );
  }
}
