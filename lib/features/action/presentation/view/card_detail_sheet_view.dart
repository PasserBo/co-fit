import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_source.dart';
import '../../domain/entity/action_template_card.dart';
import '../../provider/action_deck_repository_provider.dart';
import '../../provider/action_decks_provider.dart';
import '../../provider/custom_card_providers.dart';
import '../action_template_usecase_provider.dart';
import '../widget/card_face_preview.dart';
import 'custom_card_form_sheet_view.dart';

/// 卡片详情 sheet(#16b):大卡预览 + 「已加入 N 个牌组」+
/// 加入牌组(主 CTA)/ 编辑 / 删除(后两项仅自建卡;官方卡无此区)。
class CardDetailSheetView extends ConsumerWidget {
  const CardDetailSheetView({required this.card, super.key});

  final ActionTemplateCard card;

  static Future<void> show(BuildContext context,
      {required ActionTemplateCard card}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => CardDetailSheetView(card: card),
    );
  }

  List<ActionDeck> _decksContaining(List<ActionDeck> decks) {
    return [
      for (final deck in decks)
        if (deck.cardIds.contains(card.id)) deck,
    ];
  }

  Future<void> _addToDeck(BuildContext context, WidgetRef ref) async {
    final decks =
        ref.read(actionDecksProvider).value ?? const <ActionDeck>[];
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('还没有牌组,先去「我的卡组」新建一组')),
        );
      return;
    }
    final deck = await showModalBottomSheet<ActionDeck>(
      context: context,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => _DeckPickerSheet(decks: decks, cardId: card.id),
    );
    if (deck == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(updateDeckUsecaseProvider)
          .execute(deck.copyWith(cardIds: [...deck.cardIds, card.id]));
      ref.invalidate(actionDecksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('已加入「${deck.name}」')),
          );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('加入失败:$error')));
      }
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final saved = await CustomCardFormSheetView.show(context, editing: card);
    if (saved == true && context.mounted) {
      // 详情里的旧数据已过期,直接收起。
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final decks =
        ref.read(actionDecksProvider).value ?? const <ActionDeck>[];
    final affected = _decksContaining(decks);
    final affectedLabel = affected.isEmpty
        ? '该卡未加入任何牌组。'
        : '该卡将同时从 ${affected.length} 个牌组'
            '(${affected.map((d) => d.name).join('、')})中移除全部引用。';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除「${card.name}」?'),
        content: Text('$affectedLabel此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('取消', style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('删除', style: TextStyle(color: colors.statusDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(deleteCustomCardUsecaseProvider)
          .execute(cardId: card.id);
      ref
        ..invalidate(templateCardsProvider)
        ..invalidate(actionDecksProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('已删除「${card.name}」')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('删除失败:$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final decks =
        ref.watch(actionDecksProvider).value ?? const <ActionDeck>[];
    final containing = _decksContaining(decks);
    final isCustom = card.source == ActionSource.custom;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CardFacePreview(
                name: card.name,
                type: card.type,
                durationSec: card.defaultDurationSec,
                intensityLabel:
                    card.intensityLabel.isEmpty ? null : card.intensityLabel,
                source: card.source,
                large: true,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            Text(
              containing.isEmpty
                  ? '尚未加入任何牌组'
                  : '已加入 ${containing.length} 个牌组:'
                      '${containing.map((d) => d.name).join(' · ')}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.bodySmall?.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            SizedBox(
              height: CoFitDimens.sizeMinTapTarget,
              child: FilledButton(
                onPressed: () => _addToDeck(context, ref),
                child: const Text('加入牌组'),
              ),
            ),
            if (isCustom) ...[
              const SizedBox(height: CoFitDimens.spacingSm),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: OutlinedButton(
                  onPressed: () => _edit(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(
                      color: colors.borderStrong,
                      width: CoFitDimens.borderWidthHairline,
                    ),
                  ),
                  child: const Text('编辑卡片'),
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingSm),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: TextButton(
                  onPressed: () => _delete(context, ref),
                  style: TextButton.styleFrom(
                    backgroundColor: colors.statusDanger
                        .withValues(alpha: CoFitOpacities.dangerFaint),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(CoFitDimens.radiusMd),
                      side: BorderSide(
                        color: colors.statusDanger
                            .withValues(alpha: CoFitOpacities.dangerBorder),
                        width: CoFitDimens.borderWidthHairline,
                      ),
                    ),
                  ),
                  child: Text(
                    '删除该卡',
                    style: TextStyle(
                      color: colors.statusDanger,
                      fontWeight: CoFitFontWeights.label,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeckPickerSheet extends StatelessWidget {
  const _DeckPickerSheet({required this.decks, required this.cardId});

  final List<ActionDeck> decks;
  final String cardId;

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
            Text(
              '加入哪个牌组?',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decks.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: CoFitDimens.spacingSm),
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final alreadyCount =
                      deck.cardIds.where((id) => id == cardId).length;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(deck),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(CoFitDimens.spacingMd),
                      decoration: BoxDecoration(
                        color: colors.bgDeep,
                        borderRadius:
                            BorderRadius.circular(CoFitDimens.radiusMd),
                        border: Border.all(
                          color: colors.borderSubtle,
                          width: CoFitDimens.borderWidthHairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              deck.name,
                              style: textTheme.labelLarge?.copyWith(
                                fontWeight: CoFitFontWeights.heading,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            alreadyCount > 0
                                ? '已有 ×$alreadyCount · 再加一张'
                                : '${deck.cardIds.length} 张',
                            style: textTheme.labelSmall?.copyWith(
                              color: alreadyCount > 0
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
