import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';

/// 解散房间确认 dialog(#17b):说明不可逆 + 输入房间名才解锁红色 CTA。
/// 返回 true = 确认解散。
Future<bool?> showDissolveRoomDialog(
  BuildContext context, {
  required String roomName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _DissolveRoomDialog(roomName: roomName),
  );
}

class _DissolveRoomDialog extends StatefulWidget {
  const _DissolveRoomDialog({required this.roomName});

  final String roomName;

  @override
  State<_DissolveRoomDialog> createState() => _DissolveRoomDialogState();
}

class _DissolveRoomDialogState extends State<_DissolveRoomDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == widget.roomName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('解散「${widget.roomName}」?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: '房间将被删除,全部成员失去访问。此操作',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '不可撤销',
                  style: TextStyle(
                    color: colors.statusDanger,
                    fontWeight: CoFitFontWeights.heading,
                  ),
                ),
                const TextSpan(text: '。输入房间名以确认:'),
              ],
            ),
          ),
          const SizedBox(height: CoFitDimens.spacingMd),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.roomName,
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: colors.statusDanger
                      .withValues(alpha: CoFitOpacities.border),
                  width: CoFitDimens.borderWidthHairline,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(
            backgroundColor: _matches
                ? null
                : colors.statusDanger
                    .withValues(alpha: CoFitOpacities.dangerDisabled),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CoFitDimens.radiusSm),
            ),
          ),
          child: Text(
            '解散',
            style: TextStyle(
              color: _matches ? colors.statusDanger : colors.textDisabled,
              fontWeight: CoFitFontWeights.heading,
            ),
          ),
        ),
      ],
    );
  }
}
