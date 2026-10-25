import 'package:flutter/material.dart';

import '../theme/cofit_colors.dart';
import '../theme/cofit_dimens.dart';

/// 全 App 统一的「确认」底部 sheet(替代散落各处的原生 AlertDialog)。
/// 结构:可选图标块 → 标题 → 说明 → [取消 | 确认] 双按钮。
/// [danger] = 确认按钮用 coral 实底(删除/退出/移出等不可逆操作)。
/// 返回 true = 确认;null/false = 取消或滑掉。
Future<bool?> showCoFitConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = '取消',
  bool danger = false,
  IconData? icon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (_) => CoFitConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      danger: danger,
      icon: icon,
    ),
  );
}

/// 纯展示;按钮以 Navigator.pop(bool) 返回。
class CoFitConfirmSheet extends StatelessWidget {
  const CoFitConfirmSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = '取消',
    this.danger = false,
    this.icon,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final accent = danger ? colors.statusDanger : colors.primaryMain;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  width: CoFitDimens.sizeMinTapTarget,
                  height: CoFitDimens.sizeMinTapTarget,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(
                      alpha: danger
                          ? CoFitOpacities.dangerFaint
                          : CoFitOpacities.subtle,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                    size: CoFitDimens.sizeCardIcon,
                  ),
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: CoFitDimens.spacingXl),
            Row(
              spacing: CoFitDimens.spacingSm,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: danger
                        ? FilledButton.styleFrom(
                            backgroundColor: colors.statusDanger,
                            foregroundColor: colors.textPrimary,
                          )
                        : null,
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 统一的单字段文本输入 sheet(昵称等简单改名场景)。
/// 返回 trim 后的文本;取消/空值返回 null。[validator] 返回错误文案则禁用确认。
Future<String?> showCoFitTextInputSheet(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
  String confirmLabel = '保存',
  int? maxLength,
  String? Function(String value)? validator,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TextInputSheet(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      maxLength: maxLength,
      validator: validator,
    ),
  );
}

class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet({
    required this.title,
    required this.label,
    required this.initialValue,
    required this.confirmLabel,
    required this.maxLength,
    required this.validator,
  });

  final String title;
  final String label;
  final String initialValue;
  final String confirmLabel;
  final int? maxLength;
  final String? Function(String value)? validator;

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _value => _controller.text.trim();
  String? get _error => _value.isEmpty ? null : widget.validator?.call(_value);
  bool get _canSubmit => _value.isNotEmpty && _error == null;

  void _submit() {
    if (_canSubmit) {
      Navigator.of(context).pop(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingXl,
          CoFitDimens.spacingLg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: widget.maxLength,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: _error,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            Row(
              spacing: CoFitDimens.spacingSm,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
