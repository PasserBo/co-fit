import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../home_sheet/presentation/widget/home_sheet_panel.dart';
import '../../provider/workout_memo_providers.dart';
import 'memo_editor_view.dart';

/// 今日面板的「刚才这张」模块:针对最近完成的一张卡记 memo(可补记的
/// 时长之内)。没有目标时画空。
class LastSessionMemoModuleView extends ConsumerWidget {
  const LastSessionMemoModuleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(memoPromptTargetProvider);
    if (record == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final name = record.templateName.isEmpty
        ? record.actionKey
        : record.templateName;

    return HomeSheetModuleFrame(
      key: const ValueKey('home_sheet_last_session_memo'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '刚才 · ',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                TextSpan(
                  text: name,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: CoFitDimens.spacingSm),
          // 换一条记录时重建编辑器
          MemoEditorView(key: ValueKey(record.sessionId), record: record),
        ],
      ),
    );
  }
}
