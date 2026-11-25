import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widget/cofit_confirm_sheet.dart';
import '../../../action/domain/entity/action_session_record.dart';
import '../../provider/workout_memo_providers.dart';
import '../widget/memo_editor.dart';

/// 一条运动记录的 memo 编辑器(接好数据的版本):每个操作立即保存;
/// 保存失败时界面回到之前的值并提示。
class MemoEditorView extends ConsumerWidget {
  const MemoEditorView({required this.record, super.key});

  final ActionSessionRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(workoutMemoConfigProvider);
    final memo = ref.watch(workoutMemoMapProvider)[record.sessionId];

    // 每次操作都按最新保存的 memo 合并(不用 build 时的快照,连点不会丢步)
    Future<void> change({
      String? Function(String? old)? feel,
      String? Function(String? old)? note,
    }) async {
      final latest = ref.read(workoutMemoMapProvider)[record.sessionId];
      final messenger = ScaffoldMessenger.maybeOf(context);
      try {
        await ref
            .read(workoutMemosProvider.notifier)
            .put(
              record,
              feel: feel == null ? latest?.feel : feel(latest?.feel),
              note: note == null ? latest?.note : note(latest?.note),
            );
      } catch (_) {
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('没有保存成功,请稍后再试')));
      }
    }

    return MemoEditor(
      config: config,
      feel: memo?.feel,
      note: memo?.note,
      onFeelChanged: (feel) => change(feel: (_) => feel),
      onEditNote: () async {
        final typed = await showCoFitTextInputSheet(
          context,
          title: '写一句',
          label: '这次感觉怎么样',
          initialValue: memo?.note ?? '',
          maxLength: config.noteMaxLength,
          validator: (value) =>
              value.length > config.noteMaxLength ? '太长了' : null,
        );
        if (typed != null) {
          await change(note: (_) => typed);
        }
      },
    );
  }
}
