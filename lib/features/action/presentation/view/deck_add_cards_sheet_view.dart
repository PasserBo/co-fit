import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_source.dart';
import '../../domain/entity/action_template_card.dart';
import '../../domain/entity/action_type.dart';
import '../action_template_usecase_provider.dart';
import '../widget/action_type_style.dart';

/// 加卡 sheet(#15c):类型 chip 筛选 + 卡格多选;同卡可多次加入(×N 计数)。
/// 返回选中的卡 id 列表(含重复,按点选顺序),取消返回 null。
class DeckAddCardsSheetView extends ConsumerStatefulWidget {
  const DeckAddCardsSheetView({super.key});

  static Future<List<String>?> show(BuildContext context) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => const DeckAddCardsSheetView(),
    );
  }

  @override
  ConsumerState<DeckAddCardsSheetView> createState() =>
      _DeckAddCardsSheetViewState();
}

class _DeckAddCardsSheetViewState extends ConsumerState<DeckAddCardsSheetView> {
  ActionType? _filter;
  final List<String> _picked = [];

  int _countOf(String cardId) => _picked.where((id) => id == cardId).length;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final cardsAsync = ref.watch(templateCardsProvider);
    final cards = (cardsAsync.value ?? const <ActionTemplateCard>[])
        .where((card) => _filter == null || card.type == _filter)
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '加入卡片',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
                Text(
                  '同一张卡可多次加入',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: CoFitDimens.spacingSm,
                children: [
                  _FilterChip(
                    label: '全部',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final type in ActionType.values)
                    _FilterChip(
                      label: type.label,
                      selected: _filter == type,
                      onTap: () => setState(() => _filter = type),
                    ),
                ],
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            Flexible(
              child: cardsAsync.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(CoFitDimens.spacing2xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildGrid(cards, colors),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            SizedBox(
              height: CoFitDimens.sizeMinTapTarget,
              child: FilledButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.of(context)
                        .pop(List<String>.unmodifiable(_picked)),
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: colors.primaryMain
                      .withValues(alpha: CoFitOpacities.disabledFill),
                  disabledForegroundColor: colors.primaryOn
                      .withValues(alpha: CoFitOpacities.disabledOn),
                ),
                child: Text(
                  _picked.isEmpty ? '选择卡片' : '加入 ${_picked.length} 张',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<ActionTemplateCard> cards, CoFitColors colors) {
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacing2xl),
        child: Text(
          '该类型下暂无卡片',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.textTertiary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 小屏 3 → 2 列(#15c 附注)
        final columns =
            constraints.maxWidth <= CoFitDimens.sizeAuthFormMaxWidth ? 2 : 3;
        return GridView.builder(
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: CoFitDimens.spacingSm,
            crossAxisSpacing: CoFitDimens.spacingSm,
            mainAxisExtent: CoFitDimens.sizeCardPreview,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _PickableCardTile(
              card: card,
              count: _countOf(card.id),
              onTap: () => setState(() => _picked.add(card.id)),
              onRemoveOne: () => setState(() => _picked.remove(card.id)),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CoFitDimens.spacingMd,
          vertical: CoFitDimens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primaryMain : colors.bgDeep,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? colors.primaryOn : colors.textSecondary,
                fontWeight: selected
                    ? CoFitFontWeights.heading
                    : CoFitFontWeights.label,
              ),
        ),
      ),
    );
  }
}

class _PickableCardTile extends StatelessWidget {
  const _PickableCardTile({
    required this.card,
    required this.count,
    required this.onTap,
    required this.onRemoveOne,
  });

  final ActionTemplateCard card;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onRemoveOne;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final selected = count > 0;
    final typeColor = card.type.mainOf(colors);

    return GestureDetector(
      onTap: onTap,
      onLongPress: selected ? onRemoveOne : null,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.bgDeep,
              borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
              border: Border.all(
                color: selected ? colors.borderFocus : colors.borderStrong,
                width: selected
                    ? CoFitDimens.borderWidthFocus
                    : CoFitDimens.borderWidthHairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: CoFitDimens.sizeCardTypeBar,
                  color: typeColor,
                ),
                Padding(
                  padding: const EdgeInsets.all(CoFitDimens.spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: CoFitFontWeights.heading,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: CoFitDimens.spacingXs),
                      Text(
                        '${(card.defaultDurationSec / 60).round().clamp(1, 999)} min',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      if (card.source == ActionSource.custom) ...[
                        const SizedBox(height: CoFitDimens.spacingXs),
                        Text(
                          '自建',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.primaryMain,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: -CoFitDimens.sizeRemoveBadgeOffset,
              right: -CoFitDimens.sizeRemoveBadgeOffset,
              child: Container(
                height: CoFitDimens.sizeCheckBadge,
                constraints: const BoxConstraints(
                  minWidth: CoFitDimens.sizeCheckBadge,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: CoFitDimens.spacingXs,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryMain,
                  borderRadius:
                      BorderRadius.circular(CoFitDimens.radiusSm),
                ),
                child: Text(
                  count == 1 ? '✓' : '×$count',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.primaryOn,
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
