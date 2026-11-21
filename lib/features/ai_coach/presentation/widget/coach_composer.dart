import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_dimens.dart';

/// 预置问题(横向滚动)+ 输入框。[enabled] 为 false 时两者都不可用(回答进行中)。
class CoachComposer extends StatefulWidget {
  const CoachComposer({
    required this.presets,
    required this.enabled,
    required this.onSend,
    super.key,
  });

  final List<String> presets;
  final bool enabled;

  /// (文本, 是否预置问题)
  final void Function(String text, bool preset) onSend;

  @override
  State<CoachComposer> createState() => _CoachComposerState();
}

class _CoachComposerState extends State<CoachComposer> {
  final TextEditingController _input = TextEditingController();

  void _sendTyped() {
    final String text = _input.text.trim();
    if (!widget.enabled || text.isEmpty) {
      return;
    }
    _input.clear();
    widget.onSend(text, false);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: CoFitDimens.spacingLg,
          ),
          child: Row(
            spacing: CoFitDimens.spacingSm,
            children: [
              for (final String preset in widget.presets)
                ActionChip(
                  label: Text(preset),
                  onPressed: widget.enabled
                      ? () => widget.onSend(preset, true)
                      : null,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CoFitDimens.spacingLg,
            CoFitDimens.spacingSm,
            CoFitDimens.spacingSm,
            CoFitDimens.spacingSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: widget.enabled,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTyped(),
                  decoration: const InputDecoration(hintText: '问问你的运动记录'),
                ),
              ),
              IconButton(
                tooltip: '发送',
                constraints: const BoxConstraints(
                  minWidth: CoFitDimens.sizeMinTapTarget,
                  minHeight: CoFitDimens.sizeMinTapTarget,
                ),
                icon: const Icon(Icons.send_rounded),
                onPressed: widget.enabled ? _sendTyped : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
