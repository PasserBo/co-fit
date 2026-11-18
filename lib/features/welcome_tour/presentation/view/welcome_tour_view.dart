import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../action/domain/entity/action_template_card.dart';
import '../../../action/presentation/widget/card_fan.dart';
import '../../../avatar/provider/avatar_renderer_provider.dart';
import '../../../room/domain/entity/action_session.dart';
import '../../../room/domain/entity/user_activity_status_entity.dart';
import '../../../room/presentation/widget/activity_hud.dart';
import '../../../room/presentation/widget/room_scene.dart';
import '../../domain/entity/welcome_tour_demo.dart';
import '../../provider/welcome_tour_providers.dart';
import '../widget/tour_finish_card.dart';
import '../widget/tour_hint_bubble.dart';

/// 引导步骤(规格「引导文案分步出现」):
/// self →(点引导/场景)→ play →(打出第一张卡)→ friends →(第一张卡倒计时结束)→ done。
/// 直接打牌不经 tap 时从 self 跳到 friends。
enum _TourStep { self, play, friends, done }

/// 登录前的演示房间(规格 `welcome-tour`,design §2–§4)。
///
/// 沉浸式布局沿用 #6b 主界面:场景 + 顶栏 + HUD + 扇形手牌,
/// 只是数据全部来自 [WelcomeTourDemo],会话是页面内的本地 [ActionSession]
/// (不走 OwnActionSessionNotifier:它会写 presence / 本地快照 / 历史)。
/// 自己不做导航:跳过 / 登录都只把「演示已看过」落下去,AuthGate 监听后切页。
class WelcomeTourView extends ConsumerStatefulWidget {
  const WelcomeTourView({this.now = _wallClock, super.key});

  /// 时钟注入:会话到点是「endsAt vs now」的派生判定,测试里换成可推进的假钟。
  final DateTime Function() now;

  static DateTime _wallClock() => DateTime.now();

  static const String titleLabel = '演示房间';
  static const String skipLabel = '跳过';
  static const String focusTitle = '选择下一项';
  static const String hintSelf = '这个发光的小人就是你';
  static const String hintPlay = '点底部手牌,上滑中间那张开始运动';
  static const String hintFriends = '好友会以小人形式出现在同一房间,实时看到彼此在练什么';
  static const String shortenedNote =
      '演示已缩短到 ${WelcomeTourDemo.sessionDurationSec} 秒,正式房间按卡面时长计时';
  static const String finishTitle = '这就是 CoFit 里的一次运动';
  static const String finishBody = '登录后建一间房,把好友叫进来,在同一个房间里一起练。';
  static const String finishCta = '登录,把好友叫进来';

  @override
  ConsumerState<WelcomeTourView> createState() => _WelcomeTourViewState();
}

class _WelcomeTourViewState extends ConsumerState<WelcomeTourView> {
  ActionSession? _session;
  Timer? _ticker;
  int _sessionCount = 0;
  bool _fanFocused = false;
  int _fanCenterIndex = 0;
  _TourStep _step = _TourStep.self;
  bool _finished = false;
  bool _isLeaving = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// 跳过 / 登录共用:幂等,连点不重复落盘。
  void _leave() {
    if (_isLeaving) {
      return;
    }
    _isLeaving = true;
    _ticker?.cancel();
    unawaited(ref.read(welcomeTourSeenProvider.notifier).markSeen());
  }

  bool _isActiveAt(DateTime now) {
    final session = _session;
    return session != null &&
        session.status == ActionSessionStatus.active &&
        !session.isExpiredAt(now);
  }

  void _advanceFromSelf() {
    if (_step == _TourStep.self) {
      setState(() => _step = _TourStep.play);
    }
  }

  void _openFan() {
    setState(() {
      _fanFocused = true;
      if (_step == _TourStep.self) {
        _step = _TourStep.play;
      }
    });
  }

  void _closeOverlays() {
    setState(() => _fanFocused = false);
  }

  /// 规格「运动中再次打牌」:当前动作未结束时忽略新的一张。
  void _playCard(ActionTemplateCard card) {
    final now = widget.now();
    if (_isActiveAt(now)) {
      return;
    }
    _sessionCount++;
    setState(() {
      _session = ActionSession(
        sessionId: 'demo-$_sessionCount',
        roomId: WelcomeTourDemo.roomId,
        userId: WelcomeTourDemo.selfUserId,
        actionKey: card.rawType,
        templateId: card.id,
        templateName: card.name,
        motionId: card.motionId,
        durationSec: WelcomeTourDemo.sessionDurationSec,
        startedAt: now,
        status: ActionSessionStatus.active,
        endsAt: now.add(
          const Duration(seconds: WelcomeTourDemo.sessionDurationSec),
        ),
        lastEventAt: now,
      );
      _fanFocused = false;
      if (_step.index < _TourStep.friends.index) {
        _step = _TourStep.friends;
      }
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// 会话剩余时间是随 now 的派生值(ActionSession 设计),
  /// 进行中每秒重建一次驱动倒计时;到点 → 回待机 + 收尾卡。
  void _tick() {
    if (!mounted) {
      return;
    }
    final session = _session;
    if (session == null) {
      _ticker?.cancel();
      return;
    }
    if (session.isExpiredAt(widget.now())) {
      _ticker?.cancel();
      setState(() {
        _session = null;
        _finished = true;
        _step = _TourStep.done;
      });
      return;
    }
    setState(() {});
  }

  String? get _hintText => switch (_step) {
    _TourStep.self => WelcomeTourView.hintSelf,
    _TourStep.play => WelcomeTourView.hintPlay,
    _TourStep.friends => WelcomeTourView.hintFriends,
    _TourStep.done => null,
  };

  /// 引导气泡在场景区内的锚点(与 RoomScene 的小人锚点同一套坐标系)。
  /// 自己的小人在 y≈0.55,示例小人占据上半区(含 y≈0.44 的右侧一只),
  /// 所以 self / friends 两条都放在自己小人**下方**、手牌上方的空白带,
  /// play 贴着手牌上沿(模拟器实测:放上方会压到右侧示例小人)。
  static const _hintAnchorSelf = Alignment(0, 0.6);
  static const _hintAnchorPlay = Alignment.bottomCenter;
  static const _hintAnchorFriends = Alignment(0, 0.6);

  Alignment get _hintAlignment => switch (_step) {
    _TourStep.self => _hintAnchorSelf,
    _TourStep.play => _hintAnchorPlay,
    _ => _hintAnchorFriends,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final now = widget.now();
    final selfStatus =
        _session?.toActivityStatus(now) ?? UserActivityStatusEntity.idle();
    final members = withSelfPresent(
      WelcomeTourDemo.sampleMembers,
      selfUserId: WelcomeTourDemo.selfUserId,
      activityStatus: selfStatus,
    );
    final hintText = _hintText;

    final safeTop = MediaQuery.paddingOf(context).top;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // 场景区与主界面一致:顶栏之下、手牌之上。
    final scenePadding = EdgeInsets.only(
      top: safeTop + CoFitDimens.sizeMinTapTarget,
      bottom: safeBottom + CoFitDimens.sizeFanHeight,
    );

    return Scaffold(
      backgroundColor: colors.bgApp,
      body: Stack(
        children: [
          // 场景(点任意处推进第一条引导)
          Positioned.fill(
            child: GestureDetector(
              onTap: _advanceFromSelf,
              behavior: HitTestBehavior.translucent,
              child: Padding(
                padding: scenePadding,
                child: RoomScene(
                  members: members,
                  selfUserId: WelcomeTourDemo.selfUserId,
                  renderer: ref.watch(avatarRendererProvider),
                ),
              ),
            ),
          ),

          // 顶栏:小标 + 跳过
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingLg,
                  vertical: CoFitDimens.spacingSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        WelcomeTourView.titleLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primaryMain,
                          fontWeight: CoFitFontWeights.heading,
                          letterSpacing: CoFitTypography.letterSpacingWide,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _leave,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          CoFitDimens.sizeMinTapTarget,
                          CoFitDimens.sizeMinTapTarget,
                        ),
                        foregroundColor: colors.textTertiary,
                      ),
                      child: const Text(WelcomeTourView.skipLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // HUD + 缩短说明:自己运动中
          if (selfStatus.activityState == UserActivityState.active)
            Positioned(
              top:
                  safeTop +
                  CoFitDimens.sizeMinTapTarget +
                  CoFitDimens.spacingXl,
              left: CoFitDimens.spacingXl,
              right: CoFitDimens.spacingXl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActivityHud(status: selfStatus),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  Text(
                    WelcomeTourView.shortenedNote,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

          // 引导气泡:不拦截手势;聚焦手牌时隐藏(scrim 在上面)
          if (hintText != null && !_fanFocused)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: scenePadding,
                  child: Align(
                    alignment: _hintAlignment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CoFitDimens.spacing2xl,
                      ),
                      child: TourHintBubble(text: hintText),
                    ),
                  ),
                ),
              ),
            ),

          // 收尾卡:第一张卡倒计时结束后常驻,不遮手牌
          if (_finished)
            Positioned(
              left: CoFitDimens.spacingXl,
              right: CoFitDimens.spacingXl,
              bottom: safeBottom + CoFitDimens.sizeFanHeight,
              child: TourFinishCard(
                title: WelcomeTourView.finishTitle,
                body: WelcomeTourView.finishBody,
                ctaLabel: WelcomeTourView.finishCta,
                onCta: _leave,
              ),
            ),

          // 聚焦模式 scrim(盖住场景与顶栏,点击关闭)
          if (_fanFocused)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlays,
                child: ColoredBox(
                  color: colors.bgDeep.withValues(
                    alpha: CoFitOpacities.overlay,
                  ),
                ),
              ),
            ),

          // 聚焦模式顶部标题(#6b;演示没有牌组切换)
          if (_fanFocused)
            Positioned(
              top: safeTop + CoFitDimens.spacingXl,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  WelcomeTourView.focusTitle,
                  style: textTheme.titleMedium,
                ),
              ),
            ),

          // 扇形手牌
          Positioned(
            left: 0,
            right: 0,
            bottom: safeBottom,
            child: CardFan(
              cards: WelcomeTourDemo.cards,
              focused: _fanFocused,
              centerIndex: _fanCenterIndex,
              onTapCollapsed: _openFan,
              onFocusCard: (index) => setState(() => _fanCenterIndex = index),
              onPlay: _playCard,
            ),
          ),
        ],
      ),
    );
  }
}
