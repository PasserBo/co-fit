import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/floating_dock.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_template_card.dart';
import '../../provider/action_deck_repository_provider.dart';
import '../../provider/action_decks_provider.dart';
import '../action_template_usecase_provider.dart';
import '../widget/deck_list_body.dart';
import '../widget/deck_name_dialog.dart';
import '../widget/library_segmented_control.dart';
import '../widget/library_tab_body.dart';
import 'card_detail_sheet_view.dart';
import 'custom_card_form_sheet_view.dart';
import 'deck_detail_page_view.dart';

/// 牌库主页(#12b 定稿 + 阶段三 #15/#16 接线)。
/// 分享给好友仍为 stub(G4 social 未实现)。
class CardLibraryPage extends ConsumerStatefulWidget {
  const CardLibraryPage({super.key});

  @override
  ConsumerState<CardLibraryPage> createState() => _CardLibraryPageState();
}

class _CardLibraryPageState extends ConsumerState<CardLibraryPage> {
  static const _tabLibrary = 0;

  int _tabIndex = _tabLibrary;

  void _stub(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what:开发中')));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createCard() async {
    final created = await CustomCardFormSheetView.show(context);
    if (created == true && mounted) {
      _toast('已创建');
    }
  }

  void _openCardDetail(ActionTemplateCard card) {
    CardDetailSheetView.show(context, card: card);
  }

  void _openDeckDetail(ActionDeck deck) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeckDetailPageView(deckId: deck.id),
      ),
    );
  }

  Future<void> _createDeck() async {
    final name = await showDeckNameDialog(
      context,
      title: '新建牌组',
      confirmLabel: '创建',
    );
    if (name == null || !mounted) {
      return;
    }
    try {
      final deck =
          await ref.read(createDeckUsecaseProvider).execute(name: name);
      ref.invalidate(actionDecksProvider);
      if (mounted) {
        _openDeckDetail(deck);
      }
    } catch (error) {
      if (mounted) {
        _toast('创建失败:$error');
      }
    }
  }

  Future<void> _handleDeckMenu(ActionDeck deck, DeckMenuAction action) async {
    switch (action) {
      case DeckMenuAction.setActive:
        await ref.read(actionDeckRepositoryProvider).setActiveDeckId(deck.id);
        ref.invalidate(activeDeckIdProvider);
        if (mounted) {
          _toast('「${deck.name}」已设为当前使用');
        }
      case DeckMenuAction.rename:
        final name = await showDeckNameDialog(
          context,
          title: '重命名牌组',
          confirmLabel: '保存',
          initialName: deck.name,
        );
        if (name == null || name == deck.name || !mounted) {
          return;
        }
        try {
          await ref
              .read(updateDeckUsecaseProvider)
              .execute(deck.copyWith(name: name));
          ref.invalidate(actionDecksProvider);
        } catch (error) {
          if (mounted) {
            _toast('重命名失败:$error');
          }
        }
      case DeckMenuAction.delete:
        await _deleteDeck(deck);
    }
  }

  Future<void> _deleteDeck(ActionDeck deck) async {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final activeDeckId = ref.read(activeDeckIdProvider).value;
    final decks = ref.read(actionDecksProvider).value ?? const <ActionDeck>[];
    final isActive = deck.id == activeDeckId;
    ActionDeck? successor;
    if (isActive) {
      for (final candidate in decks) {
        if (candidate.id != deck.id) {
          successor = candidate;
          break;
        }
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('删除牌组「${deck.name}」?'),
        content: Text(
          isActive
              ? '该组正在使用中,删除后当前使用将切换为'
                  '${successor == null ? '空' : '「${successor.name}」'}。'
                  '此操作不可撤销。'
              : '此操作不可撤销。',
        ),
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
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(deleteDeckUsecaseProvider).execute(deckId: deck.id);
      ref
        ..invalidate(actionDecksProvider)
        ..invalidate(activeDeckIdProvider);
      if (mounted) {
        _toast(
          isActive && successor != null
              ? '已删除「${deck.name}」· 当前使用切换为 ${successor.name}'
              : '已删除「${deck.name}」',
        );
      }
    } catch (error) {
      if (mounted) {
        _toast('删除失败:$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(templateCardsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // 左侧为悬浮 dock 让位(#12b mock 顶栏左缩进)
              padding: const EdgeInsets.fromLTRB(
                CoFitDimens.spacingLg +
                    FloatingDock.collapsedWidth +
                    CoFitDimens.spacingSm,
                CoFitDimens.spacingSm,
                CoFitDimens.spacingLg,
                CoFitDimens.spacingSm,
              ),
              child: LibrarySegmentedControl(
                labels: const ['牌库', '我的卡组'],
                index: _tabIndex,
                onChanged: (index) => setState(() => _tabIndex = index),
              ),
            ),
            Expanded(
              child: _tabIndex == _tabLibrary
                  ? _buildLibraryTab(cardsAsync)
                  : _buildDeckTab(cardsAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab(AsyncValue<List<ActionTemplateCard>> cardsAsync) {
    return cardsAsync.when(
      data: (cards) => LibraryTabBody(
        cards: cards,
        onCreateCard: _createCard,
        onCardTap: _openCardDetail,
        onShareCard: (card) => _stub('分享「${card.name}」'),
        onSeeAll: (type) => _stub('查看全部'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorRetry(
        message: '$error',
        onRetry: () => ref.invalidate(templateCardsProvider),
      ),
    );
  }

  Widget _buildDeckTab(AsyncValue<List<ActionTemplateCard>> cardsAsync) {
    final decksAsync = ref.watch(actionDecksProvider);
    final activeDeckId = ref.watch(activeDeckIdProvider).value;
    final cardsById = {
      for (final card in cardsAsync.value ?? <ActionTemplateCard>[])
        card.id: card,
    };

    return decksAsync.when(
      data: (decks) => DeckListBody(
        decks: decks,
        cardsById: cardsById,
        activeDeckId: activeDeckId,
        onDeckTap: _openDeckDetail,
        onDeckMenuAction: _handleDeckMenu,
        onCreateDeck: _createDeck,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorRetry(
        message: '$error',
        onRetry: () => ref.invalidate(actionDecksProvider),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textTertiary),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
