import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/floating_dock.dart';
import '../../../action/domain/entity/action_deck.dart';
import '../../../action/domain/entity/action_template_card.dart';
import '../../../action/presentation/action_template_usecase_provider.dart';
import '../../../action/presentation/widget/card_fan.dart';
import '../../../action/presentation/widget/deck_switcher.dart';
import '../../../action/provider/action_deck_repository_provider.dart';
import '../../../action/provider/action_decks_provider.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../domain/entity/user_activity_status_entity.dart';
import '../../provider/room_info_provider.dart';
import '../room_browse_page.dart';
import '../room_browser_provider.dart';
import '../widget/room_scene.dart';
import '../widget/room_top_bar.dart';

/// 房间主界面(#6b 定稿):全屏沉浸场景,无底部 nav。
/// 漂浮气泡(presence)+ 左右滑切换房间 + 底部扇形手牌(#5d 聚焦/上滑打出)
/// + 牌组切换(#4a)。悬浮层一律覆盖,不挤压布局。
class RoomMainView extends ConsumerStatefulWidget {
  const RoomMainView({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<RoomMainView> createState() => _RoomMainViewState();
}

class _RoomMainViewState extends ConsumerState<RoomMainView> {
  PageController? _pageController;
  bool _fanFocused = false;
  int _fanCenterIndex = 0;
  bool _popoverOpen = false;
  bool _isPlaying = false;

  /// 顶栏/内容给悬浮 dock 让出的左侧空间(与牌库页一致)。
  static const _dockInset = CoFitDimens.spacingLg +
      FloatingDock.collapsedWidth +
      CoFitDimens.spacingSm;

  void _closeOverlays() {
    setState(() {
      _fanFocused = false;
      _popoverOpen = false;
    });
  }

  Future<void> _switchDeck(ActionDeck deck) async {
    await ref.read(actionDeckRepositoryProvider).setActiveDeckId(deck.id);
    ref.invalidate(activeDeckIdProvider);
    if (mounted) {
      setState(() {
        _popoverOpen = false;
        _fanCenterIndex = 0;
      });
    }
  }

  Future<void> _openDeckSheet(List<ActionDeck> decks, String? activeId) async {
    setState(() => _popoverOpen = false);
    final selected = await showModalBottomSheet<ActionDeck>(
      context: context,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (context) => _DeckSheet(decks: decks, activeDeckId: activeId),
    );
    if (selected != null) {
      await _switchDeck(selected);
    }
  }

  Future<void> _playCard(ActionTemplateCard card, String roomId) async {
    if (_isPlaying) {
      return;
    }
    setState(() => _isPlaying = true);
    try {
      await ref
          .read(selectTemplateCardUsecaseProvider)
          .execute(templateId: card.id);
      await ref
          .read(startTemplateCardActionUsecaseProvider)
          .execute(roomId: roomId, userId: widget.userId);
      if (!mounted) {
        return;
      }
      _closeOverlays();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已打出「${card.name}」,开始运动!')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('打出失败:$error')));
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _openBrowse() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('浏览房间')),
          body: RoomBrowsePage(userId: widget.userId),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final browser = ref.watch(roomBrowserProvider);
    final joinedRoomIds = browser.joinedRoomIds;

    if (joinedRoomIds.isEmpty) {
      return _EmptyRooms(onBrowse: _openBrowse);
    }

    final focusedRoomId = browser.focusedRoomId ?? joinedRoomIds.first;
    final roomIndex =
        (joinedRoomIds.indexOf(focusedRoomId)).clamp(0, joinedRoomIds.length - 1);
    _pageController ??= PageController(initialPage: roomIndex);

    final members =
        browser.presenceByRoom[focusedRoomId] ?? const <RoomPresenceMember>[];
    final activeCount = members
        .where((m) => m.activityStatus.activityState == UserActivityState.active)
        .length;
    final roomInfo = ref.watch(roomInfoProvider(focusedRoomId)).value;

    final decks = ref.watch(actionDecksProvider).value ?? const <ActionDeck>[];
    final activeDeckId = ref.watch(activeDeckIdProvider).value;
    final cards =
        ref.watch(templateCardsProvider).value ?? const <ActionTemplateCard>[];
    final cardsById = {for (final card in cards) card.id: card};

    ActionDeck? activeDeck;
    for (final deck in decks) {
      if (deck.id == activeDeckId) {
        activeDeck = deck;
        break;
      }
    }
    activeDeck ??= decks.isEmpty ? null : decks.first;
    final fanCards = [
      for (final id in activeDeck?.cardIds ?? const <String>[])
        if (cardsById[id] != null) cardsById[id]!,
    ];

    RoomPresenceMember? self;
    for (final member in members) {
      if (member.userId == widget.userId) {
        self = member;
        break;
      }
    }

    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          // 场景:左右滑切换房间
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: joinedRoomIds.length,
              onPageChanged: (index) {
                ref
                    .read(roomBrowserProvider.notifier)
                    .setFocusedRoom(joinedRoomIds[index]);
              },
              itemBuilder: (context, index) {
                final roomId = joinedRoomIds[index];
                return Padding(
                  padding: EdgeInsets.only(
                    top: safeTop + CoFitDimens.sizeMinTapTarget,
                    bottom: CoFitDimens.sizeFanHeight,
                  ),
                  child: RoomScene(
                    members: browser.presenceByRoom[roomId] ??
                        const <RoomPresenceMember>[],
                    selfUserId: widget.userId,
                  ),
                );
              },
            ),
          ),

          // 顶栏
          Positioned(
            top: safeTop + CoFitDimens.spacingSm,
            left: _dockInset,
            right: CoFitDimens.spacingLg,
            child: RoomTopBar(
              roomName: roomInfo?.name.isNotEmpty == true
                  ? roomInfo!.name
                  : focusedRoomId,
              memberCount: members.length,
              activeCount: activeCount,
              roomIndex: roomIndex + 1,
              roomTotal: joinedRoomIds.length,
              onBrowseRooms: _openBrowse,
            ),
          ),

          // HUD:自己运动中
          if (self != null &&
              self.activityStatus.activityState == UserActivityState.active)
            Positioned(
              top: safeTop + CoFitDimens.sizeMinTapTarget +
                  CoFitDimens.spacingXl,
              left: 0,
              right: 0,
              child: Center(
                child: _ActivityHud(status: self.activityStatus),
              ),
            ),

          // 聚焦模式 scrim(盖住场景与顶栏,点击关闭)
          if (_fanFocused)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlays,
                child: ColoredBox(
                  color:
                      colors.bgDeep.withValues(alpha: CoFitOpacities.overlay),
                ),
              ),
            ),

          // 聚焦模式顶部标题 + 牌组切换(#6b)
          if (_fanFocused)
            Positioned(
              top: safeTop + CoFitDimens.spacingXl,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('选择下一项',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  DeckChip(
                    deckName: activeDeck?.name ?? '未选择牌组',
                    open: _popoverOpen,
                    onTap: () =>
                        setState(() => _popoverOpen = !_popoverOpen),
                  ),
                ],
              ),
            ),

          // 扇形手牌
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CardFan(
              cards: fanCards,
              focused: _fanFocused,
              centerIndex: _fanCenterIndex,
              onTapCollapsed: () => setState(() => _fanFocused = true),
              onFocusCard: (index) =>
                  setState(() => _fanCenterIndex = index),
              onPlay: (card) => unawaited(_playCard(card, focusedRoomId)),
            ),
          ),

          // 收起态牌组 chip(#6b 左下)
          if (!_fanFocused)
            Positioned(
              left: CoFitDimens.spacingXl,
              bottom: CoFitDimens.sizeDeckChipBottom,
              child: DeckChip(
                deckName: activeDeck?.name ?? '未选择牌组',
                open: _popoverOpen,
                onTap: () => setState(() => _popoverOpen = !_popoverOpen),
              ),
            ),

          // 牌组下拉(悬浮,不挤压布局)
          if (_popoverOpen) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _popoverOpen = false),
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: _fanFocused ? 0 : CoFitDimens.spacingXl,
              right: _fanFocused ? 0 : null,
              top: _fanFocused
                  ? safeTop + CoFitDimens.sizeMinTapTarget * 2
                  : null,
              bottom: _fanFocused
                  ? null
                  : CoFitDimens.sizeDeckChipBottom +
                      CoFitDimens.sizeDockItem +
                      CoFitDimens.spacingSm,
              child: Align(
                alignment:
                    _fanFocused ? Alignment.topCenter : Alignment.bottomLeft,
                child: DeckPopover(
                  decks: decks,
                  activeDeckId: activeDeck?.id,
                  onSelect: (deck) => unawaited(_switchDeck(deck)),
                  onSeeAll: () =>
                      unawaited(_openDeckSheet(decks, activeDeck?.id)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// HUD:当前动作徽章(#6b 简化版,倒计时环用进度环表达)。
class _ActivityHud extends StatelessWidget {
  const _ActivityHud({required this.status});

  final UserActivityStatusEntity status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final name = status.templateName ?? status.actionKey ?? '运动中';
    final duration = status.durationSec;
    final remaining = status.remainingSec;
    final progress = (duration != null && duration > 0 && remaining != null)
        ? (1 - remaining / duration).clamp(0.0, 1.0)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoFitDimens.spacingMd,
        vertical: CoFitDimens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
        border: Border.all(
          color: colors.primaryBorder,
          width: CoFitDimens.borderWidthHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          SizedBox(
            width: CoFitDimens.sizeHudRing,
            height: CoFitDimens.sizeHudRing,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: CoFitDimens.borderWidthFocus * 2,
              color: colors.primaryMain,
              backgroundColor: colors.borderStrong,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前动作',
                style:
                    textTheme.labelSmall?.copyWith(color: colors.textTertiary),
              ),
              Text(name, style: textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoFitDimens.spacingMd,
          children: [
            Text(
              '还没有加入任何房间',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textTertiary),
            ),
            FilledButton(onPressed: onBrowse, child: const Text('浏览房间')),
          ],
        ),
      ),
    );
  }
}

/// #4a「查看全部牌组」底部抽屉。
class _DeckSheet extends StatelessWidget {
  const _DeckSheet({required this.decks, required this.activeDeckId});

  final List<ActionDeck> decks;
  final String? activeDeckId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('选择牌组', style: textTheme.titleMedium),
            const SizedBox(height: CoFitDimens.spacingMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decks.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: CoFitDimens.spacingSm),
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final active = deck.id == activeDeckId;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(deck),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(CoFitDimens.spacingMd),
                      decoration: BoxDecoration(
                        color: active ? colors.primarySubtle : colors.bgDeep,
                        borderRadius:
                            BorderRadius.circular(CoFitDimens.radiusMd),
                        border: Border.all(
                          color: active
                              ? colors.primaryBorder
                              : colors.borderSubtle,
                          width: CoFitDimens.borderWidthHairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              deck.name,
                              style: textTheme.labelLarge?.copyWith(
                                color: active
                                    ? colors.primaryMain
                                    : colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            active ? '使用中 ✓' : '${deck.cardIds.length} 张',
                            style: textTheme.labelSmall?.copyWith(
                              color: active
                                  ? colors.primaryMain
                                  : colors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
