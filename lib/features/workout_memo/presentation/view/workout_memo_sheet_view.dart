import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/cofit_confirm_sheet.dart';
import '../../../action/domain/entity/action_session_record.dart';
import '../../provider/workout_memo_providers.dart';
import 'memo_editor_view.dart';

/// 一条运动记录的详情面板:看完整 memo,改感受 / 文字,删除 memo。
/// 运动记录本身不能在这里删除。
Future<void> showWorkoutMemoSheet(
  BuildContext context, {
  required ActionSessionRecord record,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WorkoutMemoSheetView(record: record),
  );
}

class WorkoutMemoSheetView extends ConsumerWidget {
  const WorkoutMemoSheetView({required this.record, super.key});

  final ActionSessionRecord record;

  String _when(DateTime time) {
    final t = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.month}月${t.day}日 ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final memo = ref.watch(workoutMemoMapProvider)[record.sessionId];
    final minutes = (record.durationSec / Duration.secondsPerMinute)
        .round()
        .clamp(1, 999);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CoFitDimens.spacingXl,
          CoFitDimens.spacingSm,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              record.templateName.isEmpty
                  ? record.actionKey
                  : record.templateName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              [
                _when(record.completedAt),
                '$minutes min',
                if (record.prescriptionText.isNotEmpty) record.prescriptionText,
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            MemoEditorView(record: record),
            if (memo?.note != null) ...[
              const SizedBox(height: CoFitDimens.spacingSm),
              // 完整文字(编辑器里只露出一行)
              Text(
                memo!.note!,
                key: const ValueKey('memo_sheet_full_note'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (memo != null) ...[
              const SizedBox(height: CoFitDimens.spacingLg),
              TextButton(
                key: const ValueKey('memo_sheet_delete'),
                onPressed: () async {
                  final confirmed = await showCoFitConfirmSheet(
                    context,
                    title: '删除这条 memo?',
                    message: '运动记录会保留,只删除你记下的感受和文字。',
                    confirmLabel: '删除',
                    danger: true,
                  );
                  if (confirmed != true || !context.mounted) {
                    return;
                  }
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  try {
                    await ref
                        .read(workoutMemosProvider.notifier)
                        .remove(record);
                  } catch (_) {
                    messenger?.showSnackBar(
                      const SnackBar(content: Text('没有删除成功,请稍后再试')),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.statusDanger,
                ),
                child: const Text('删除 memo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
