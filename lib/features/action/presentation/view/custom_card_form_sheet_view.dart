import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/action_template_card.dart';
import '../../domain/entity/action_type.dart';
import '../../provider/custom_card_providers.dart';
import '../../usecase/create_custom_card_usecase.dart';
import '../action_template_usecase_provider.dart';
import '../widget/action_type_style.dart';
import '../widget/card_face_preview.dart';

/// 创建/编辑自建卡 sheet(#16a):
/// 顶部实时卡面预览(选类型即换色条/图标底);
/// 字段:名称(1–20,计数)/ 类型四选一 / 时长档位 + 自定义 / 强度标签可选。
class CustomCardFormSheetView extends ConsumerStatefulWidget {
  const CustomCardFormSheetView({this.editing, super.key});

  /// 非 null = 编辑模式(仅自建卡,#16b 入口)。
  final ActionTemplateCard? editing;

  static Future<bool?> show(BuildContext context,
      {ActionTemplateCard? editing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => CustomCardFormSheetView(editing: editing),
    );
  }

  @override
  ConsumerState<CustomCardFormSheetView> createState() =>
      _CustomCardFormSheetViewState();
}

class _CustomCardFormSheetViewState
    extends ConsumerState<CustomCardFormSheetView> {
  static const _durationPresets = [30, 45, 60, 90, 120];
  static const _intensityLabels = ['轻松', '中等', '挑战'];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _customDurationController =
      TextEditingController();

  late ActionType _type = widget.editing?.type ?? ActionType.strength;
  late int? _presetDurationSec = widget.editing == null
      ? _durationPresets.first
      : (_durationPresets.contains(widget.editing!.defaultDurationSec)
          ? widget.editing!.defaultDurationSec
          : null);
  late String? _intensity = widget.editing?.intensityLabel.isNotEmpty == true
      ? widget.editing!.intensityLabel
      : null;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null && _presetDurationSec == null) {
      _customDurationController.text = '${editing.defaultDurationSec}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  String get _trimmedName => _nameController.text.trim();

  bool get _isNameValid =>
      _trimmedName.isNotEmpty &&
      _trimmedName.length <= CreateCustomCardUsecase.nameMaxLength;

  bool get _isCustomDuration => _presetDurationSec == null;

  int get _durationSec {
    if (!_isCustomDuration) {
      return _presetDurationSec!;
    }
    return int.tryParse(_customDurationController.text.trim()) ?? 0;
  }

  bool get _canSubmit => _isNameValid && _durationSec > 0 && !_isSubmitting;

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final editing = widget.editing;
      if (editing == null) {
        await ref.read(createCustomCardUsecaseProvider).execute(
              name: _trimmedName,
              rawType: _type.name,
              durationSec: _durationSec,
              intensityBaseline:
                  _intensity == null ? const {} : {'label': _intensity},
            );
      } else {
        await ref.read(updateCustomCardUsecaseProvider).execute(
              card: editing,
              name: _trimmedName,
              rawType: _type.name,
              durationSec: _durationSec,
              intensityBaseline:
                  _intensity == null ? const {} : {'label': _intensity},
            );
      }
      ref.invalidate(templateCardsProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = '保存失败,请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.editing != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: CoFitDimens.spacingLg,
          right: CoFitDimens.spacingLg,
          top: CoFitDimens.spacingLg,
          bottom:
              CoFitDimens.spacingLg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? '编辑卡片' : '创建卡片',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: CoFitFontWeights.heading,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
              Center(
                child: CardFacePreview(
                  name: _trimmedName,
                  type: _type,
                  durationSec: _durationSec,
                  intensityLabel: _intensity,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingLg),
              _FieldLabel('名称'),
              TextField(
                controller: _nameController,
                enabled: !_isSubmitting,
                maxLength: CreateCustomCardUsecase.nameMaxLength,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '如:壶铃摆荡',
                  border: const OutlineInputBorder(),
                  enabledBorder: !_isNameValid &&
                          _nameController.text.isNotEmpty
                      ? OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.statusDanger,
                            width: CoFitDimens.borderWidthHairline,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
              _FieldLabel('类型'),
              Row(
                spacing: CoFitDimens.spacingSm,
                children: [
                  for (final type in ActionType.values)
                    Expanded(
                      child: _TypeChip(
                        type: type,
                        selected: _type == type,
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() => _type = type),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CoFitDimens.spacingLg),
              _FieldLabel('时长'),
              Wrap(
                spacing: CoFitDimens.spacingSm,
                runSpacing: CoFitDimens.spacingSm,
                children: [
                  for (final preset in _durationPresets)
                    _SelectChip(
                      label: preset < 60 ? '${preset}s' : '${preset ~/ 60}min',
                      selected: _presetDurationSec == preset,
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _presetDurationSec = preset),
                    ),
                  _SelectChip(
                    label: '自定义',
                    selected: _isCustomDuration,
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() => _presetDurationSec = null),
                  ),
                ],
              ),
              if (_isCustomDuration) ...[
                const SizedBox(height: CoFitDimens.spacingSm),
                TextField(
                  controller: _customDurationController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: '自定义时长(秒)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: CoFitDimens.spacingLg),
              _FieldLabel('强度标签(可选)'),
              Wrap(
                spacing: CoFitDimens.spacingSm,
                children: [
                  for (final label in _intensityLabels)
                    _SelectChip(
                      label: label,
                      selected: _intensity == label,
                      onTap: _isSubmitting
                          ? null
                          : () => setState(
                                () => _intensity =
                                    _intensity == label ? null : label,
                              ),
                    ),
                ],
              ),
              const SizedBox(height: CoFitDimens.spacingXl),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: colors.primaryMain
                        .withValues(alpha: CoFitOpacities.disabledFill),
                    disabledForegroundColor: colors.primaryOn
                        .withValues(alpha: CoFitOpacities.disabledOn),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: CoFitDimens.spacingLg,
                          height: CoFitDimens.spacingLg,
                          child: CircularProgressIndicator(
                            strokeWidth: CoFitDimens.borderWidthFocus,
                            color: colors.primaryOn,
                          ),
                        )
                      : Text(isEditing ? '保存修改' : '创建卡片'),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: CoFitDimens.spacingMd),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.statusDanger),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: CoFitDimens.spacingSm),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textTertiary,
              fontWeight: CoFitFontWeights.label,
            ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    this.onTap,
  });

  final ActionType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final typeColor = type.mainOf(colors);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: CoFitDimens.spacingSm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? type.subtleOf(colors) : colors.bgDeep,
          borderRadius: BorderRadius.circular(CoFitDimens.radiusMd),
          border: Border.all(
            color: selected ? typeColor : colors.borderStrong,
            width: selected
                ? CoFitDimens.borderWidthFocus
                : CoFitDimens.borderWidthHairline,
          ),
        ),
        child: Text(
          type.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? typeColor : colors.textSecondary,
                fontWeight: selected
                    ? CoFitFontWeights.heading
                    : CoFitFontWeights.label,
              ),
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CoFitDimens.spacingMd,
          vertical: CoFitDimens.spacingXs,
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
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color:
                    selected ? colors.primaryMain : colors.textSecondary,
                fontWeight: selected
                    ? CoFitFontWeights.heading
                    : CoFitFontWeights.label,
              ),
        ),
      ),
    );
  }
}
