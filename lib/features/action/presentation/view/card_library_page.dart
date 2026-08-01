import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_deck.dart';
import '../../domain/entity/action_template_card.dart';
import '../../provider/action_decks_provider.dart';
import '../action_template_usecase_provider.dart';
import '../widget/deck_list_body.dart';
import '../widget/library_segmented_control.dart';
import '../widget/library_tab_body.dart';

/// 牌库主页(#12b 定稿)。
/// 创建卡片/卡片详情/分享/加卡 均为 stub(SnackBar「开发中」),见 STATUS.md Stub 登记表。
/// 顶部布局预留:P3 悬浮 dock 会浮在左上,届时再校 padding。
class CardLibraryPage extends ConsumerStatefulWidget {
  const CardLibraryPage({super.key});

  @override
  ConsumerState<CardLibraryPage> createState() => _CardLibraryPageState();
}

class _CardLibraryPageState extends ConsumerState<CardLibraryPage> {
  static const _tabLibrary = 0;

  int _tabIndex = _tabLibrary;
  String? _expandedDeckId;

  void _stub(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what:开发中')));
  }

  void _toggleDeck(ActionDeck deck) {
    setState(() {
      _expandedDeckId = _expandedDeckId == deck.id ? null : deck.id;
    });
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
              padding: const EdgeInsets.symmetric(
                horizontal: CoFitDimens.spacingLg,
                vertical: CoFitDimens.spacingSm,
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
        onCreateCard: () => _stub('创建卡片'),
        onCardTap: (card) => _stub('卡片详情「${card.name}」'),
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
    final cardsById = {
      for (final card in cardsAsync.value ?? <ActionTemplateCard>[])
        card.id: card,
    };

    return decksAsync.when(
      data: (decks) => DeckListBody(
        decks: decks,
        cardsById: cardsById,
        expandedDeckId: _expandedDeckId,
        onDeckTap: _toggleDeck,
        onAddCard: (deck) => _stub('向「${deck.name}」添加卡片'),
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
