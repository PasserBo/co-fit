import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../usecase/create_deck_usecase.dart';

/// 牌组命名 dialog(#15c 命名态,新建/重命名共用):
/// 1–20 字校验:空/超限 → coral 描边 + 内联红字 + CTA 禁用(lime@30%)。
/// 返回合法名称或 null(取消)。
Future<String?> showDeckNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DeckNameDialog(
      title: title,
      confirmLabel: confirmLabel,
      initialName: initialName,
    ),
  );
}

class _DeckNameDialog extends StatefulWidget {
  const _DeckNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_DeckNameDialog> createState() => _DeckNameDialogState();
}

class _DeckNameDialogState extends State<_DeckNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _trimmed => _controller.text.trim();

  bool get _isOverLimit =>
      _trimmed.length > CreateDeckUsecase.nameMaxLength;

  bool get _isValid => _trimmed.isNotEmpty && !_isOverLimit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '牌组名',
              border: const OutlineInputBorder(),
              enabledBorder: _isOverLimit
                  ? OutlineInputBorder(
                      borderSide: BorderSide(
                        color: colors.statusDanger,
                        width: CoFitDimens.borderWidthHairline,
                      ),
                    )
                  : null,
              counterText:
                  '${_trimmed.length}/${CreateDeckUsecase.nameMaxLength}',
              counterStyle: textTheme.labelSmall?.copyWith(
                color: _isOverLimit
                    ? colors.statusDanger
                    : colors.textDisabled,
              ),
            ),
          ),
          if (!_isValid && _controller.text.isNotEmpty) ...[
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              '名称需为 1–${CreateDeckUsecase.nameMaxLength} 字',
              style: textTheme.labelSmall?.copyWith(
                color: colors.statusDanger,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        FilledButton(
          onPressed:
              _isValid ? () => Navigator.of(context).pop(_trimmed) : null,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: colors.primaryMain
                .withValues(alpha: CoFitOpacities.disabledFill),
            disabledForegroundColor: colors.primaryOn
                .withValues(alpha: CoFitOpacities.disabledOn),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
