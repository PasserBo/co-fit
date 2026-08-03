import 'package:flutter/widgets.dart';

import '../../domain/entity/avatar_motion.dart';

/// 小人外观(由主题层解析后注入,渲染实现不读主题):
/// - 自己:body = gray-50 白,headRing = lime@90 常亮(#6b 定稿);
/// - 好友:body = 状态色 hue,无头环(#6b 定稿);
/// - 远侧肢体 = body @80%(#14a 派生规则)由实现层推导。
@immutable
class AvatarAppearance {
  const AvatarAppearance({
    required this.body,
    required this.aura,
    required this.auraOpacity,
    this.headRing,
  });

  final Color body;
  final Color aura;
  final double auraOpacity;
  final Color? headRing;

  @override
  bool operator ==(Object other) =>
      other is AvatarAppearance &&
      other.body == body &&
      other.aura == aura &&
      other.auraOpacity == auraOpacity &&
      other.headRing == headRing;

  @override
  int get hashCode => Object.hash(body, aura, auraOpacity, headRing);
}

/// 动画实现的模块化边界(用户要求 1):场景层只依赖本接口 +
/// [AvatarMotion]/[AvatarAppearance] 两个值对象。将来把 Flutter 原生实现
/// 换成 Rive/Lottie 时,只需提供新的 AvatarRenderer 实现并替换 provider 绑定。
abstract class AvatarRenderer {
  const AvatarRenderer();

  /// 构建一个持续播放 [motion] 的小人。
  /// - [height]:小人总高(含地面光圈),宽度由实现按形体比例决定;
  /// - [phaseSeed]:0–1 相位偏移(hash(userId) 派生),避免全房间齐步走;
  /// - [onOneShotComplete]:windup/finish 等 ×1 动画播完的回调(驱动编排器)。
  Widget build({
    required AvatarMotion motion,
    required AvatarAppearance appearance,
    required double height,
    double phaseSeed = 0,
    VoidCallback? onOneShotComplete,
    Key? key,
  });
}
