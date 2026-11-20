import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../../../core/theme/cofit_dimens.dart';
import '../../../../core/widget/app_bar_filled_action.dart';
import '../../domain/entity/room_info_entity.dart';
import '../../provider/public_rooms_provider.dart';
import '../../usecase/fetch_public_rooms_usecase.dart';
import '../room_browser_provider.dart';
import '../room_navigation.dart';
import '../widget/public_room_tile.dart';
import 'public_room_preview_sheet_view.dart';
import 'room_create_page_view.dart';

/// 发现房间(change add-room-create-and-discovery,无定稿设计,沿用 #20c 卡片语言):
/// 公开房间列表(成员数多→少)+ 顶部搜索(房名/简介)+ 下拉刷新;
/// 未加入 → 预览 sheet →「加入并进入」;已加入 → 直接回房间 tab 聚焦该房间。
class RoomDiscoverPageView extends ConsumerStatefulWidget {
  const RoomDiscoverPageView({required this.userId, super.key});

  final String userId;

  static Future<void> push(BuildContext context, {required String userId}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoomDiscoverPageView(userId: userId),
      ),
    );
  }

  @override
  ConsumerState<RoomDiscoverPageView> createState() =>
      _RoomDiscoverPageViewState();
}

class _RoomDiscoverPageViewState extends ConsumerState<RoomDiscoverPageView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      ref.invalidate(publicRoomsProvider);
      await ref.read(publicRoomsProvider.future);
    } catch (_) {
      // 失败态由 provider 的 AsyncError 渲染
    }
  }

  Future<void> _openRoom(RoomInfoEntity room, {required bool joined}) async {
    final navigator = Navigator.of(context);
    if (joined) {
      await enterJoinedRoom(ref, navigator, roomId: room.roomId);
      return;
    }
    final didJoin = await PublicRoomPreviewSheetView.show(
      context,
      room: room,
      userId: widget.userId,
    );
    if (didJoin != true || !mounted) {
      return;
    }
    await enterJoinedRoom(
      ref,
      navigator,
      roomId: room.roomId,
      refreshJoined: true,
    );
    if (navigator.mounted) {
      ScaffoldMessenger.of(navigator.context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('已加入「${room.name}」')));
    }
  }

  void _create() {
    RoomCreatePageView.push(context, userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(publicRoomsProvider);
    final joinedIds = ref
        .watch(roomBrowserProvider.select((s) => s.joinedRoomIds))
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('发现房间'),
        actions: [
          AppBarFilledAction(icon: Icons.add, label: '新建', onPressed: _create),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CoFitDimens.spacingLg,
                CoFitDimens.spacingXs,
                CoFitDimens.spacingLg,
                CoFitDimens.spacingSm,
              ),
              child: TextField(
                key: const Key('room-discover-search'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '搜索房间名或简介',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: roomsAsync.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _MessageState(
                  title: '加载失败',
                  body: '请检查网络后重试',
                  actionLabel: '重试',
                  onAction: () => ref.invalidate(publicRoomsProvider),
                ),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return _RefreshableMessage(
                      onRefresh: _refresh,
                      child: _MessageState(
                        title: '暂时还没有公开房间',
                        body: '新建一间公开房间,让大家来一起练',
                        actionLabel: '新建房间',
                        onAction: _create,
                      ),
                    );
                  }
                  final visible = filterRoomsByQuery(rooms, _query);
                  if (visible.isEmpty) {
                    return _RefreshableMessage(
                      onRefresh: _refresh,
                      child: _MessageState(
                        title: '没有找到匹配的房间',
                        body: '换个关键词,或者自己建一间',
                        actionLabel: '新建房间',
                        onAction: _create,
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        CoFitDimens.spacingLg,
                        CoFitDimens.spacingXs,
                        CoFitDimens.spacingLg,
                        CoFitDimens.spacingLg,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: CoFitDimens.spacingSm),
                      itemBuilder: (context, index) {
                        final room = visible[index];
                        final joined = joinedIds.contains(room.roomId);
                        return PublicRoomTile(
                          key: ValueKey(room.roomId),
                          name: room.name,
                          description: room.description,
                          memberCount: room.memberIds.length,
                          joined: joined,
                          onTap: () => _openRoom(room, joined: joined),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空态也允许下拉刷新(滚动容器撑满高度)。
class _RefreshableMessage extends StatelessWidget {
  const _RefreshableMessage({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CoFitColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(CoFitDimens.spacing3xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoFitDimens.spacingSm,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: CoFitFontWeights.heading,
            ),
          ),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(height: CoFitDimens.spacingSm),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
