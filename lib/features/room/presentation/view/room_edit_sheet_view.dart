import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/room_info_entity.dart';
import '../../provider/room_info_provider.dart';
import '../join_room_provider.dart';

/// 编辑房间信息 sheet(#17b,布局复用建房表单):
/// 房间名(非空)/ 描述(可空)/ 可见性 segmented。仅房主入口可达。
class RoomEditSheetView extends ConsumerStatefulWidget {
  const RoomEditSheetView({required this.room, super.key});

  final RoomInfoEntity room;

  static Future<void> show(BuildContext context,
      {required RoomInfoEntity room}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => RoomEditSheetView(room: room),
    );
  }

  @override
  ConsumerState<RoomEditSheetView> createState() => _RoomEditSheetViewState();
}

class _RoomEditSheetViewState extends ConsumerState<RoomEditSheetView> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.room.name);
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.room.description);
  late String _visibility = widget.room.visibility;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(updateRoomInfoUsecaseProvider).execute(
            roomId: widget.room.roomId,
            name: _nameController.text,
            description: _descriptionController.text,
            visibility: _visibility,
          );
      ref.invalidate(roomInfoProvider(widget.room.roomId));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已保存')));
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
    final nameValid = _nameController.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: CoFitDimens.spacingXl,
          right: CoFitDimens.spacingXl,
          top: CoFitDimens.spacingXl,
          bottom:
              CoFitDimens.spacingXl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '编辑房间信息',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: CoFitFontWeights.heading,
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingXl),
              TextField(
                controller: _nameController,
                enabled: !_isSubmitting,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '房间名(必填)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
              TextField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '描述(可空)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: CoFitDimens.spacingMd),
              Row(
                spacing: CoFitDimens.spacingSm,
                children: [
                  for (final visibility in RoomVisibility.allowed)
                    Expanded(
                      child: _VisibilityChip(
                        label: visibility == RoomVisibility.public
                            ? '公开'
                            : '仅邀请',
                        selected: _visibility == visibility,
                        onTap: _isSubmitting
                            ? null
                            : () => setState(() => _visibility = visibility),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: CoFitDimens.spacingLg),
              SizedBox(
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  onPressed: _isSubmitting || !nameValid ? null : _save,
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
                      : const Text('保存'),
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

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
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
        padding:
            const EdgeInsets.symmetric(vertical: CoFitDimens.spacingSm),
        alignment: Alignment.center,
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
                color: selected ? colors.primaryMain : colors.textSecondary,
                fontWeight: selected
                    ? CoFitFontWeights.heading
                    : CoFitFontWeights.label,
              ),
        ),
      ),
    );
  }
}
