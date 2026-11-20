import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_shell_index_provider.dart';
import '../../auth/presentation/user_bootstrap_provider.dart';
import 'room_browser_provider.dart';

/// 「进入某个已加入的房间」的统一收尾:切到房间 tab、聚焦该房间、
/// 收起压在 AppShell 上的所有工具页(我的房间 / 发现 / 新建)。
///
/// [refreshJoined] = true 时先拉一次已加入列表(刚建房 / 刚加入,
/// 本地列表里还没有这个房间,setFocusedRoom 会被忽略)。
Future<void> enterJoinedRoom(
  WidgetRef ref,
  NavigatorState navigator, {
  required String roomId,
  bool refreshJoined = false,
}) async {
  if (refreshJoined) {
    await ref.read(userBootstrapProvider.notifier).refreshJoinedRooms();
  }
  ref.read(roomBrowserProvider.notifier).setFocusedRoom(roomId);
  ref.read(appShellIndexProvider.notifier).set(0);
  navigator.popUntil((route) => route.isFirst);
}
