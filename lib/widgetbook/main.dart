import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import '../core/navigation/app_shell.dart';
import '../core/theme/cofit_theme.dart';
import '../core/widget/floating_dock.dart';
import '../features/action/domain/entity/action_deck.dart';
import '../features/action/domain/entity/action_source.dart';
import '../features/action/domain/entity/action_template_card.dart';
import '../features/action/domain/entity/action_type.dart';
import '../features/action/presentation/action_template_usecase_provider.dart';
import '../features/action/presentation/view/card_library_page.dart';
import '../features/action/presentation/widget/action_card.dart';
import '../features/action/presentation/widget/action_type_style.dart';
import '../features/action/presentation/widget/card_fan.dart';
import '../features/action/presentation/widget/deck_list_body.dart';
import '../features/action/presentation/widget/deck_switcher.dart';
import '../features/action/presentation/widget/library_tab_body.dart';
import '../features/room/domain/entity/room_presence_member.dart';
import '../features/room/domain/entity/user_activity_status_entity.dart';
import '../features/room/presentation/widget/room_scene.dart';
import '../features/room/presentation/widget/room_top_bar.dart';

/// CoFit 组件画廊(Widgetbook)。
/// 独立入口,不初始化 Firebase/Ably:
///   flutter run -t lib/widgetbook/main.dart
/// 新增纯展示组件时,在这里注册对应 use-case(ui-implementation skill 第 7 步)。
void main() => runApp(const CoFitWidgetbook());

/// 画廊内示例卡片的预览宽度(仅供 Widgetbook 摆放,组件本身宽度由父级决定)。
const _previewCardWidth = 140.0;

class CoFitWidgetbook extends StatelessWidget {
  const CoFitWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        MaterialThemeAddon(
          themes: [WidgetbookTheme(name: 'CoFit Dark', data: CoFitTheme.dark)],
        ),
        TextScaleAddon(min: 1, max: 1.6, initialScale: 1),
        ViewportAddon([
          IosViewports.iPhoneSE,
          IosViewports.iPhone13,
          IosViewports.iPhone13ProMax,
        ]),
      ],
      directories: [
        WidgetbookFolder(
          name: 'action',
          children: [
            WidgetbookComponent(
              name: 'ActionCard',
              useCases: [
                WidgetbookUseCase(name: 'Playground', builder: _playground),
                WidgetbookUseCase(name: '全部状态一览', builder: _allStates),
              ],
            ),
            WidgetbookComponent(
              name: 'LibraryTabBody',
              useCases: [
                WidgetbookUseCase(name: '牌库 tab', builder: _libraryTab),
              ],
            ),
            WidgetbookComponent(
              name: 'DeckListBody',
              useCases: [
                WidgetbookUseCase(name: '我的卡组 tab', builder: _deckList),
              ],
            ),
            WidgetbookComponent(
              name: 'CardLibraryPage(完整页)',
              useCases: [
                WidgetbookUseCase(name: '默认', builder: _cardLibraryPage),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'room',
          children: [
            WidgetbookComponent(
              name: 'RoomScene',
              useCases: [
                WidgetbookUseCase(name: '6 人房间', builder: _roomScene),
              ],
            ),
            WidgetbookComponent(
              name: 'CardFan',
              useCases: [
                WidgetbookUseCase(name: 'Playground', builder: _cardFan),
              ],
            ),
            WidgetbookComponent(
              name: 'RoomTopBar + DeckChip',
              useCases: [
                WidgetbookUseCase(name: '默认', builder: _roomChrome),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'core',
          children: [
            WidgetbookComponent(
              name: 'FloatingDock',
              useCases: [
                WidgetbookUseCase(name: '点击展开/收起', builder: _dock),
              ],
            ),
            WidgetbookComponent(
              name: 'AppShell',
              useCases: [
                WidgetbookUseCase(name: '导航壳演示', builder: _appShell),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

Widget _dock(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: FloatingDock(
        destinations: AppShell.destinations,
        currentIndex: 1,
        onSelect: (_) {},
      ),
    ),
  );
}

Widget _appShell(BuildContext context) {
  Widget page(String label) => Scaffold(
        body: Center(child: Text(label)),
      );
  return ProviderScope(
    overrides: [
      templateCardsProvider.overrideWith((ref) async => _sampleLibrary()),
    ],
    child: AppShell(
      initialIndex: 1,
      pages: [
        page('房间(RoomMainView,需真实 presence)'),
        const CardLibraryPage(),
        page('我的(P5 重做)'),
      ],
    ),
  );
}

List<RoomPresenceMember> _sampleMembers() {
  RoomPresenceMember member(
    String id,
    UserActivityState state, {
    String? action,
    int? remaining,
  }) {
    return RoomPresenceMember(
      clientId: id,
      userId: id,
      activityStatus: UserActivityStatusEntity(
        activityState: state,
        templateName: action,
        remainingSec: remaining,
        durationSec: remaining == null ? null : remaining * 2,
      ),
    );
  }

  return [
    member('user_a', UserActivityState.active, action: '深蹲', remaining: 300),
    member('user_b', UserActivityState.active, action: '开合跳', remaining: 120),
    member('user_c', UserActivityState.paused, action: '平板支撑'),
    member('user_d', UserActivityState.idle),
    member('user_e', UserActivityState.active, action: '硬拉', remaining: 500),
    member('me', UserActivityState.active, action: '波比跳', remaining: 90),
  ];
}

Widget _roomScene(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: RoomScene(members: _sampleMembers(), selfUserId: 'me'),
    ),
  );
}

Widget _cardFan(BuildContext context) {
  final focused = context.knobs.boolean(label: '聚焦模式');
  final center = context.knobs.double
      .slider(label: '中心卡下标', initialValue: 2, min: 0, max: 4)
      .round();
  final cards = _sampleLibrary().take(5).toList();
  return Scaffold(
    body: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CardFan(
            cards: cards,
            focused: focused,
            centerIndex: center,
            onPlay: (_) {},
          ),
        ),
      ],
    ),
  );
}

Widget _roomChrome(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RoomTopBar(
              roomName: '考研自习室',
              memberCount: 6,
              activeCount: 4,
              roomIndex: 3,
              roomTotal: 3,
            ),
            const Spacer(),
            DeckChip(deckName: '考研自习室', open: false, onTap: () {}),
          ],
        ),
      ),
    ),
  );
}

List<ActionTemplateCard> _sampleLibrary() => [
      _sample(),
      _sample(
        type: ActionType.strength,
        source: ActionSource.custom,
        name: '壶铃摆荡',
        durationSec: 480,
      ),
      _sample(type: ActionType.strength, name: '硬拉', durationSec: 720),
      _sample(type: ActionType.cardio, durationSec: 300),
      _sample(
        type: ActionType.cardio,
        source: ActionSource.friendShared,
        name: '高抬腿',
        durationSec: 240,
      ),
      _sample(type: ActionType.core, durationSec: 180),
      _sample(type: ActionType.core, name: '卷腹', durationSec: 360),
      _sample(type: ActionType.flexibility, durationSec: 300),
    ];

Widget _libraryTab(BuildContext context) {
  return Scaffold(body: LibraryTabBody(cards: _sampleLibrary()));
}

Widget _deckList(BuildContext context) {
  final cards = _sampleLibrary();
  final decks = [
    ActionDeck(
      id: 'deck_1',
      name: '考研自习室',
      cardIds: cards.take(5).map((c) => c.id).toList(),
    ),
    ActionDeck(
      id: 'deck_2',
      name: '晨间唤醒',
      cardIds: cards.skip(3).take(4).map((c) => c.id).toList(),
    ),
  ];
  return Scaffold(
    body: DeckListBody(
      decks: decks,
      cardsById: {for (final c in cards) c.id: c},
      expandedDeckId: 'deck_1',
      onAddCard: (_) {},
    ),
  );
}

Widget _cardLibraryPage(BuildContext context) {
  return ProviderScope(
    overrides: [
      templateCardsProvider.overrideWith((ref) async => _sampleLibrary()),
    ],
    child: const CardLibraryPage(),
  );
}

ActionTemplateCard _sample({
  ActionType type = ActionType.strength,
  ActionSource source = ActionSource.official,
  String? name,
  int durationSec = 600,
}) {
  const names = {
    ActionType.strength: '深蹲',
    ActionType.cardio: '开合跳',
    ActionType.core: '平板支撑',
    ActionType.flexibility: '肩颈拉伸',
  };
  return ActionTemplateCard(
    id: 'preview_${type.name}_${name ?? names[type]!}',
    name: name ?? names[type]!,
    type: type,
    rawType: type.name,
    source: source,
    ablyActionId: 'preview',
    defaultDurationSec: durationSec,
  );
}

Widget _playground(BuildContext context) {
  final type = context.knobs.object.dropdown(
    label: '类型',
    options: ActionType.values,
    labelBuilder: (t) => t.label,
  );
  final source = context.knobs.object.dropdown(
    label: '来源',
    options: ActionSource.values,
    labelBuilder: (s) => s.name,
  );
  final selected = context.knobs.boolean(label: '已入组 selected');
  final editing = context.knobs.boolean(label: '编辑态 editing');
  final width = context.knobs.double.slider(
    label: '父级宽度(演示响应式)',
    initialValue: _previewCardWidth,
    min: 100,
    max: 260,
  );

  return Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: ActionCard(
          card: _sample(type: type, source: source),
          selected: selected,
          editing: editing,
          onTap: () {},
          onShare: () {},
          onRemove: () {},
        ),
      ),
    ),
  );
}

Widget _allStates(BuildContext context) {
  Widget item(String caption, Widget card) {
    return SizedBox(
      width: _previewCardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          card,
          const SizedBox(height: 8),
          Text(caption, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  return Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Wrap(
          spacing: 20,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            item('官方 · 力量', ActionCard(card: _sample())),
            item(
              '自建 · 有氧(分享↗)',
              ActionCard(
                card: _sample(
                  type: ActionType.cardio,
                  source: ActionSource.custom,
                  durationSec: 480,
                ),
                onShare: () {},
              ),
            ),
            item(
              '好友分享 · 核心',
              ActionCard(
                card: _sample(
                  type: ActionType.core,
                  source: ActionSource.friendShared,
                ),
              ),
            ),
            item(
              '已入组 ✓ · 柔韧',
              ActionCard(
                card: _sample(type: ActionType.flexibility),
                selected: true,
              ),
            ),
            item(
              '编辑态(移除角标)',
              ActionCard(card: _sample(), editing: true, onRemove: () {}),
            ),
            item(
              '长名称截断',
              ActionCard(
                card: _sample(name: '超长名称的动作卡片应当省略号截断不换行'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
