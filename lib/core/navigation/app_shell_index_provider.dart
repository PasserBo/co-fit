import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AppShell 当前 tab 下标(0 房间 / 1 牌库 / 2 我的)。
/// 提升为 provider 是为了让深链流程(邀请加入后跳回房间 tab)能驱动导航。
class AppShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) {
    state = index;
  }
}

final appShellIndexProvider = NotifierProvider<AppShellIndexNotifier, int>(
  AppShellIndexNotifier.new,
);
