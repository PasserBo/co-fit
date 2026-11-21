import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 首次使用前的数据去向说明(规格:同意前不能提问)。
class CoachConsentPanel extends StatelessWidget {
  const CoachConsentPanel({
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CoFitDimens.spacing2xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: CoFitDimens.spacingLg,
          children: [
            Text(
              'AI 教练(Beta)',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            Text(
              '为了回答你的问题,你最近的运动记录(时间、动作卡名称、时长,最多 100 条)'
              '和你输入的内容会发送给 AI 服务(Google Gemini)用于生成回答。\n\n'
              '这是试验功能:回答可能不准确,对话不会保存;'
              '为改进功能,本次对话会记录在你的设备上,只有你主动「导出日志」时才会发出。',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            FilledButton(onPressed: onAccept, child: const Text('同意并继续')),
            TextButton(onPressed: onDecline, child: const Text('返回')),
          ],
        ),
      ),
    );
  }
}
