import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:a2ui_flutter/basic_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../provider/coach_chat_controller.dart';

/// 对话里的一条:用户气泡 / 教练文字 / A2UI 卡片 / 已发送的操作 / 错误。
class CoachChatEntry extends StatelessWidget {
  const CoachChatEntry({required this.entry, super.key});

  final CoachEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    if (entry.surface
        case final SurfaceModel<ComponentImplementation> surface) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: CoFitDimens.spacingSm),
        padding: const EdgeInsets.all(CoFitDimens.spacingMd),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusLg),
          border: Border.all(
            color: colors.borderSubtle,
            width: CoFitDimens.borderWidthHairline,
          ),
        ),
        child: A2uiMarkdown(
          builder: _markdown,
          child: A2uiSurface(surface: surface),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoFitDimens.spacingXs),
      child: switch (entry.kind) {
        CoachEntryKind.user => Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CoFitDimens.spacingMd,
              vertical: CoFitDimens.spacingSm,
            ),
            decoration: BoxDecoration(
              color: colors.primarySubtle,
              borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
            ),
            child: Text(
              entry.text,
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
          ),
        ),
        CoachEntryKind.sent => Text(
          '已发送:${entry.text}',
          style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
        ),
        CoachEntryKind.error => Text(
          entry.text,
          style: textTheme.bodySmall?.copyWith(color: colors.statusDanger),
        ),
        CoachEntryKind.model || CoachEntryKind.surface => MarkdownBody(
          data: entry.text,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      },
    );
  }

  static Widget _markdown(
    BuildContext context,
    String markdown,
    TextStyle style,
  ) {
    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(p: style),
    );
  }
}
