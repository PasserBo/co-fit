import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../avatar/presentation/renderer/motion_clip_library.dart';
import '../../../avatar/presentation/widget/motion_preview_figure.dart';
import '../../domain/entity/action_type.dart';
import 'action_type_style.dart';

/// 自建卡「动作」选择器:按类型分组的动作网格,每格一个 loop 预览小人。
/// 返回 clip id;返回 [useTypeDefault] 表示「按类型原型」;null = 取消。
class MotionPickerSheet extends StatelessWidget {
  const MotionPickerSheet({
    required this.type,
    required this.selected,
    super.key,
  });

  /// 当前卡片类型(该组排最前)。
  final ActionType type;

  /// 当前选中的 clip id;null = 按类型原型。
  final String? selected;

  static const useTypeDefault = '';

  static Future<String?> show(
    BuildContext context, {
    required ActionType type,
    required String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => MotionPickerSheet(type: type, selected: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final orderedTypes = [type, ...ActionType.values.where((t) => t != type)];
    final exercises = MotionClipLibrary.exercises;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(CoFitDimens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '选择动作',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingSm),
            Text(
              '小人在房间里会做这个动作;不选则按类型默认。',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: '默认',
                      children: [
                        _MotionTile(
                          type: type,
                          motionId: null,
                          label: '按类型原型',
                          selected: selected == null,
                          onTap: () =>
                              Navigator.of(context).pop(useTypeDefault),
                        ),
                      ],
                    ),
                    for (final t in orderedTypes)
                      _Section(
                        title: t.label,
                        children: [
                          for (final clip in exercises)
                            if (MotionClipLibrary.typeOf[clip.id] == t)
                              _MotionTile(
                                type: t,
                                motionId: clip.id,
                                label:
                                    MotionClipLibrary.nameOf[clip.id] ??
                                    clip.id,
                                selected: selected == clip.id,
                                onTap: () => Navigator.of(context).pop(clip.id),
                              ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: CoFitDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textTertiary,
              fontWeight: CoFitFontWeights.label,
            ),
          ),
          const SizedBox(height: CoFitDimens.spacingSm),
          Wrap(
            spacing: CoFitDimens.spacingSm,
            runSpacing: CoFitDimens.spacingSm,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _MotionTile extends StatelessWidget {
  const _MotionTile({
    required this.type,
    required this.motionId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ActionType type;
  final String? motionId;
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
        width: CoFitDimens.sizeCardPreview,
        padding: const EdgeInsets.symmetric(
          vertical: CoFitDimens.spacingSm,
          horizontal: CoFitDimens.spacingXs,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primarySubtle : colors.bgDeep,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          border: Border.all(
            color: selected ? colors.borderFocus : colors.borderStrong,
            width: selected
                ? CoFitDimens.borderWidthFocus
                : CoFitDimens.borderWidthHairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MotionPreviewFigure(
              type: type,
              motionId: motionId,
              figureHeight: CoFitDimens.sizeFigureSelf,
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? colors.primaryMain : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
