import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../invite/domain/invite_link_format.dart';
import '../../domain/entity/room_info_entity.dart';
import '../create_room_provider.dart';
import '../room_navigation.dart';
import '../widget/room_created_sheet.dart';
import '../widget/room_visibility_option.dart';
import '../../../notification/provider/push_offer_request_provider.dart';

/// 新建房间整页(change add-room-create-and-discovery,无定稿设计,沿用 #20 系文字语言):
/// 房名(必填)/ 简介 / 可见性(默认公开)→「创建并进入」→ 收起所有工具页、
/// 回到房间 tab 并聚焦新房间,再在房间页上弹 #20b「已就绪」分享卡。
class RoomCreatePageView extends ConsumerStatefulWidget {
  const RoomCreatePageView({required this.userId, super.key});

  final String userId;

  static Future<void> push(BuildContext context, {required String userId}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomCreatePageView(userId: userId),
      ),
    );
  }

  @override
  ConsumerState<RoomCreatePageView> createState() => _RoomCreatePageViewState();
}

class _RoomCreatePageViewState extends ConsumerState<RoomCreatePageView> {
  @override
  void initState() {
    super.initState();
    // Notifier 是 app 级单例,每次进页先复位(否则带着上次的输入/结果)。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createRoomProvider.notifier).reset();
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(createRoomProvider.notifier);
    await notifier.submit(ownerId: widget.userId);
    if (!mounted) {
      return;
    }
    final state = ref.read(createRoomProvider);
    final roomId = state.createdRoomId;
    final hash = state.createdShareLinkHash;
    if (roomId == null || hash == null) {
      return; // 失败:错误文案在页面上,输入保留
    }
    final navigator = Navigator.of(context);
    final roomName = state.name.trim();
    // enterJoinedRoom 会关掉本页,之后不能再用 ref:先拿到 notifier
    final pushOffer = ref.read(pushOfferRequestProvider.notifier);
    await enterJoinedRoom(ref, navigator, roomId: roomId, refreshJoined: true);
    if (!navigator.mounted) {
      return;
    }
    await RoomCreatedSheet.show(
      navigator.context,
      roomName: roomName,
      link: InviteLinkFormat.build(roomId: roomId, hash: hash),
    );
    // 邀请卡收起后询问通知(spec: 首次请求通知权限)
    pushOffer.requestAfterCreate(roomName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(createRoomProvider);
    final notifier = ref.read(createRoomProvider.notifier);
    final busy = state.isSubmitting;
    final canSubmit = !busy && state.name.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('新建房间')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CoFitDimens.spacingLg,
                  CoFitDimens.spacingSm,
                  CoFitDimens.spacingLg,
                  CoFitDimens.spacingLg,
                ),
                children: [
                  Text(
                    '房间是你和朋友一起运动的地方。建好后你就是房主,可以随时修改这些信息。',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacingXl),
                  TextField(
                    key: const Key('room-create-name'),
                    enabled: !busy,
                    autofocus: true,
                    maxLength: RoomInfoLimits.nameMaxLength,
                    textInputAction: TextInputAction.next,
                    onChanged: notifier.updateName,
                    decoration: const InputDecoration(
                      labelText: '房间名(必填)',
                      hintText: '例如:早起拉伸小队',
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  TextField(
                    key: const Key('room-create-description'),
                    enabled: !busy,
                    maxLength: RoomInfoLimits.descriptionMaxLength,
                    minLines: 2,
                    maxLines: 4,
                    onChanged: notifier.updateDescription,
                    decoration: const InputDecoration(
                      labelText: '简介(可选)',
                      hintText: '一起练什么、什么时候练',
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacingLg),
                  Text(
                    '谁能找到这个房间',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  RoomVisibilityOption(
                    icon: Icons.public_rounded,
                    title: '公开',
                    subtitle: '出现在「发现房间」里,任何人都能搜到并直接加入',
                    selected: state.visibility == RoomVisibility.public,
                    onTap: busy
                        ? null
                        : () =>
                              notifier.updateVisibility(RoomVisibility.public),
                  ),
                  const SizedBox(height: CoFitDimens.spacingSm),
                  RoomVisibilityOption(
                    icon: Icons.link_rounded,
                    title: '仅邀请',
                    subtitle: '不出现在列表里,只有拿到邀请链接或房间 ID 的人能加入',
                    selected: state.visibility == RoomVisibility.unlisted,
                    onTap: busy
                        ? null
                        : () => notifier.updateVisibility(
                            RoomVisibility.unlisted,
                          ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: CoFitDimens.spacingLg),
                    Text(
                      '创建失败:${state.errorMessage}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.statusDanger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CoFitDimens.spacingLg,
                CoFitDimens.spacingSm,
                CoFitDimens.spacingLg,
                CoFitDimens.spacingLg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: CoFitDimens.sizeMinTapTarget,
                child: FilledButton(
                  key: const Key('room-create-submit'),
                  onPressed: canSubmit ? _submit : null,
                  child: busy
                      ? SizedBox(
                          width: CoFitDimens.spacingLg,
                          height: CoFitDimens.spacingLg,
                          child: CircularProgressIndicator(
                            strokeWidth: CoFitDimens.borderWidthFocus,
                            color: colors.primaryOn,
                          ),
                        )
                      : const Text('创建并进入'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
