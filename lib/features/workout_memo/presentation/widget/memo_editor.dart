import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/workout_memo.dart';
import '../../domain/entity/workout_memo_config.dart';

/// memo 的一行摘要(「🙂 刚好 · 腿还酸」);没有内容返回 null。
String? memoSummaryText(WorkoutMemo? memo, WorkoutMemoConfig config) {
  if (memo == null || memo.isEmpty) {
    return null;
  }
  return [
    if (memo.feel != null) config.feelText(memo.feel!),
    if (memo.note != null) memo.note!,
  ].join(' · ');
}

/// memo 编辑器(纯展示;今日面板模块与详情面板共用,design.md §6):
/// 感受档位一排 + 「写一句」一行。
/// 每个操作立即回调,没有保存按钮。
class MemoEditor extends StatelessWidget {
  const MemoEditor({
    required this.config,
    required this.feel,
    required this.note,
    required this.onFeelChanged,
    required this.onEditNote,
    super.key,
  });

  final WorkoutMemoConfig config;
  final String? feel;
  final String? note;

  /// 点档位:选中它;再点已选中的 = 取消(null)。
  final ValueChanged<String?> onFeelChanged;

  final VoidCallback onEditNote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (config.feels.isNotEmpty)
          Row(
            spacing: CoFitDimens.spacingSm,
            children: [
              for (final option in config.feels)
                Expanded(
                  child: _FeelChip(
                    key: ValueKey('memo_feel_${option.key}'),
                    text: config.feelText(option.key),
                    selected: option.key == feel,
                    onTap: () =>
                        onFeelChanged(option.key == feel ? null : option.key),
                  ),
                ),
            ],
          ),
        GestureDetector(
          key: const ValueKey('memo_note'),
          behavior: HitTestBehavior.opaque,
          onTap: onEditNote,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CoFitDimens.sizeMinTapTarget,
            ),
            child: Row(
              spacing: CoFitDimens.spacingSm,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: CoFitDimens.spacingLg,
                  color: colors.textTertiary,
                ),
                Expanded(
                  child: Text(
                    note ?? '写一句…',
                    style: textTheme.bodySmall?.copyWith(
                      color: note == null
                          ? colors.textTertiary
                          : colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeelChip extends StatelessWidget {
  const _FeelChip({
    required this.text,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: CoFitDimens.sizeMinTapTarget,
          padding: const EdgeInsets.symmetric(
            horizontal: CoFitDimens.spacingSm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primarySubtle : colors.bgSurface,
            borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
            border: Border.all(
              color: selected ? colors.primaryBorder : colors.borderSubtle,
              width: selected
                  ? CoFitDimens.borderWidthFocus
                  : CoFitDimens.borderWidthHairline,
            ),
          ),
          child: Center(
            // 大字号时缩小而不是溢出
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? colors.primaryMain : colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
