import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../domain/entity/room_presence_member.dart';
import '../../provider/member_nickname_provider.dart';
import '../../provider/room_info_provider.dart';
import '../../usecase/submit_report_usecase.dart';
import '../join_room_provider.dart';
import '../room_browser_provider.dart';
import '../widget/room_scene.dart';
import 'room_members_sheet_view.dart';

/// 举报 sheet(stub 协议:无定稿设计,功能优先;UGC 合规必需)。
/// 举报对象:房间本身,或房间内某位成员(不含自己);原因必填 ≤ 500 字。
/// 提交后落 `reports` 集合,客户端不可读;处理走 Firebase console。
class ReportSheetView extends ConsumerStatefulWidget {
  const ReportSheetView({
    required this.roomId,
    required this.roomName,
    required this.reporterId,
    super.key,
  });

  final String roomId;
  final String roomName;
  final String reporterId;

  /// 返回 true 表示已提交。
  static Future<bool?> show(
    BuildContext context, {
    required String roomId,
    required String roomName,
    required String reporterId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).extension<CoFitColors>()!.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CoFitDimens.radiusLg),
        ),
      ),
      builder: (_) => ReportSheetView(
        roomId: roomId,
        roomName: roomName,
        reporterId: reporterId,
      ),
    );
  }

  @override
  ConsumerState<ReportSheetView> createState() => _ReportSheetViewState();
}

class _ReportSheetViewState extends ConsumerState<ReportSheetView> {
  final _reasonController = TextEditingController();

  /// null = 举报房间本身。
  String? _targetUserId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorMessage = '请填写举报原因');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(submitReportUsecaseProvider)
          .execute(
            reporterId: widget.reporterId,
            roomId: widget.roomId,
            targetUserId: _targetUserId,
            reason: reason,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = '提交失败:$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final roomInfo = ref.watch(roomInfoProvider(widget.roomId)).value;
    final presence = ref.watch(roomPresenceByIdProvider(widget.roomId));
    final presenceByUid = {for (final m in presence) m.userId: m};
    final candidates = roomMemberIdsOf(
      roomInfo,
      presence,
    ).where((uid) => uid != widget.reporterId).toList(growable: false);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: CoFitDimens.spacingXl,
          right: CoFitDimens.spacingXl,
          top: CoFitDimens.spacingXl,
          bottom:
              CoFitDimens.spacingXl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '举报',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: CoFitFontWeights.heading,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingXs),
            Text(
              '来自「${widget.roomName}」· 我们会尽快处理,举报内容不会告知对方',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(color: colors.textTertiary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            Text(
              '举报对象',
              style: textTheme.labelSmall?.copyWith(color: colors.textDisabled),
            ),
            const SizedBox(height: CoFitDimens.spacingSm),
            Wrap(
                spacing: CoFitDimens.spacingSm,
                runSpacing: CoFitDimens.spacingSm,
                children: [
                  ChoiceChip(
                    label: const Text('房间内容'),
                    selected: _targetUserId == null,
                    onSelected: _isSubmitting
                        ? null
                        : (_) => setState(() => _targetUserId = null),
                  ),
                  for (final uid in candidates)
                    _MemberChip(
                      uid: uid,
                      presenceMember: presenceByUid[uid],
                      selected: _targetUserId == uid,
                      onSelected: _isSubmitting
                          ? null
                          : () => setState(() => _targetUserId = uid),
                    ),
                ],
            ),
            const SizedBox(height: CoFitDimens.spacingLg),
            TextField(
              controller: _reasonController,
              enabled: !_isSubmitting,
              maxLength: SubmitReportUsecase.reasonMaxLength,
              maxLines: 4,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: '原因',
                hintText: '发生了什么?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: CoFitDimens.spacingMd),
            SizedBox(
              height: CoFitDimens.sizeMinTapTarget,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        width: CoFitDimens.spacingLg,
                        height: CoFitDimens.spacingLg,
                        child: CircularProgressIndicator(
                          strokeWidth: CoFitDimens.borderWidthFocus,
                          color: colors.primaryOn,
                        ),
                      )
                    : const Text('提交举报'),
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
    );
  }
}

class _MemberChip extends ConsumerWidget {
  const _MemberChip({
    required this.uid,
    required this.presenceMember,
    required this.selected,
    required this.onSelected,
  });

  final String uid;
  final RoomPresenceMember? presenceMember;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceName = presenceMember?.nickname?.trim();
    final name = (presenceName != null && presenceName.isNotEmpty)
        ? presenceName
        : (ref.watch(memberNicknameProvider(uid)).value ??
              RoomScene.displayName(
                RoomPresenceMember(clientId: uid, userId: uid),
              ));
    return ChoiceChip(
      label: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
    );
  }
}
