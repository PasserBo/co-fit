import 'package:flutter/widgets.dart';

import '../../../../core/theme/cofit_dimens.dart';
import '../stage/home_stage_controller.dart';

/// 自己小人的位置层(design.md §2–§3):独立于各房间页面,铺满房间页。
///
/// 漂浮时位于 [floatRect] 内的 [floatAnchor] 处(与原场景里的位置一致);
/// 在台上时水平居中、脚底比面板上沿高 `stageFootInset`,并随面板一起移动。
/// 两者之间的起跳轨迹由 [HomeStageController] 给出。
///
/// 这一层应画在面板**后面**:名字行和光圈下半会被面板自然挡住。
class StageAvatarLayer extends StatelessWidget {
  const StageAvatarLayer({
    required this.controller,
    required this.floatRect,
    required this.floatAnchor,
    required this.sheetHeight,
    required this.feetY,
    required this.onTap,
    required this.builder,
    super.key,
  });

  final HomeStageController controller;

  /// 收起态的场景范围(房间页坐标)。按收起态计算,不随面板展开变化。
  final Rect floatRect;
  final FractionalOffset floatAnchor;

  /// 面板当前高度(含底部安全区)。
  final double sheetHeight;

  /// 脚底在小人气泡内的纵向位置(从气泡顶部算起)。
  final double feetY;

  final VoidCallback onTap;

  /// 构建小人气泡;随 [controller] 每帧重建(用于名字行透明度等)。
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return CustomSingleChildLayout(
      delegate: _StageAvatarDelegate(
        controller: controller,
        floatRect: floatRect,
        floatAnchor: floatAnchor,
        sheetHeight: sheetHeight,
        feetY: feetY,
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Opacity(
            opacity: controller.opacity,
            child: Transform.scale(
              scale: controller.scale,
              // 以脚底为原点缩放:顶部居中 + 向下偏移到脚底
              alignment: Alignment.topCenter,
              origin: Offset(0, feetY),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: builder(context),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StageAvatarDelegate extends SingleChildLayoutDelegate {
  _StageAvatarDelegate({
    required this.controller,
    required this.floatRect,
    required this.floatAnchor,
    required this.sheetHeight,
    required this.feetY,
  }) : super(relayout: controller);

  final HomeStageController controller;
  final Rect floatRect;
  final FractionalOffset floatAnchor;
  final double sheetHeight;
  final double feetY;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final floatX =
        floatRect.left + floatAnchor.dx * (floatRect.width - childSize.width);
    final floatY =
        floatRect.top + floatAnchor.dy * (floatRect.height - childSize.height);
    final stageTop =
        size.height - sheetHeight * controller.extent + controller.dipOffset;
    final pose = controller.resolvePose(
      floatX: floatX,
      floatY: floatY,
      stageX: (size.width - childSize.width) / 2,
      stageY: stageTop - CoFitDimens.sizeStageFootInset - feetY,
    );
    return Offset(pose.x, pose.y);
  }

  @override
  bool shouldRelayout(_StageAvatarDelegate oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.floatRect != floatRect ||
      oldDelegate.floatAnchor != floatAnchor ||
      oldDelegate.sheetHeight != sheetHeight ||
      oldDelegate.feetY != feetY;
}
