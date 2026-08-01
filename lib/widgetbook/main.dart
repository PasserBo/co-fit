import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import '../core/theme/cofit_theme.dart';
import '../features/action/domain/entity/action_source.dart';
import '../features/action/domain/entity/action_template_card.dart';
import '../features/action/domain/entity/action_type.dart';
import '../features/action/presentation/widget/action_card.dart';
import '../features/action/presentation/widget/action_type_style.dart';

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
          ],
        ),
      ],
    );
  }
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
    id: 'preview_${type.name}',
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
