import 'package:flutter/material.dart';

/// 全局 navigator key:深链(邀请预览 sheet)等无 context 场景使用。
/// 挂在 MaterialApp.navigatorKey(main.dart)。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
