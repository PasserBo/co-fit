import 'package:cofit/core/theme/cofit_dimens.dart';
import 'package:cofit/core/theme/cofit_theme.dart';
import 'package:cofit/features/home_sheet/presentation/stage/home_stage_controller.dart';
import 'package:cofit/features/home_sheet/presentation/widget/home_sheet_panel.dart';
import 'package:cofit/features/home_sheet/presentation/widget/stage_avatar_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _screen = Size(390, 844);
const _sheetHeight = 300.0;
const _avatarSize = Size(60, 100);
const _feetY = 80.0;
const _floatRect = Rect.fromLTRB(0, 100, 390, 600);
const _anchor = FractionalOffset(0.5, 0.55);

/// 台上时小人气泡左上角的 y。
const _stageY = 844 - _sheetHeight - CoFitDimens.sizeStageFootInset - _feetY;

/// 漂浮时小人气泡左上角的 y。
final _floatY = 100 + 0.55 * (500 - _avatarSize.height);

class _Harness extends StatefulWidget {
  const _Harness({required this.onController, this.expanded = true});

  final ValueChanged<HomeStageController> onController;
  final bool expanded;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with TickerProviderStateMixin {
  late final HomeStageController controller = HomeStageController(
    vsync: this,
    expanded: widget.expanded,
    onLand: () => landed++,
  );
  int landed = 0;

  @override
  void initState() {
    super.initState();
    widget.onController(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: StageAvatarLayer(
            controller: controller,
            floatRect: _floatRect,
            floatAnchor: _anchor,
            sheetHeight: _sheetHeight,
            feetY: _feetY,
            onTap: controller.toggle,
            builder: (context) => SizedBox.fromSize(
              key: const ValueKey('self'),
              size: _avatarSize,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _sheetHeight,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => FractionalTranslation(
              translation: Offset(0, 1 - controller.extent),
              child: HomeSheetPanel(
                modules: const [SizedBox(height: 80, child: Text('模块'))],
                revealed: controller.modulesRevealed,
                bottomPadding: 0,
                onHandleTap: controller.toggle,
                onHandleDragStart: controller.dragStart,
                onHandleDragUpdate: (dy) =>
                    controller.dragUpdate(-dy / _sheetHeight),
                onHandleDragEnd: controller.dragEnd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<HomeStageController> _pump(
  WidgetTester tester, {
  bool expanded = true,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late HomeStageController controller;
  await tester.pumpWidget(
    MaterialApp(
      theme: CoFitTheme.dark,
      home: Scaffold(
        body: _Harness(expanded: expanded, onController: (c) => controller = c),
      ),
    ),
  );
  controller.reduceMotion = reduceMotion;
  return controller;
}

double _selfTop(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey('self'))).dy;

Future<void> _tapSelf(WidgetTester tester) =>
    tester.tap(find.byKey(const ValueKey('self')), warnIfMissed: false);

void main() {
  testWidgets('默认展开:小人站在面板上沿正中,不播上台动画', (tester) async {
    final controller = await _pump(tester);

    expect(controller.extent, 1);
    expect(controller.onStage, isTrue);
    expect(controller.isHopping, isFalse);
    expect(controller.scale, CoFitDecor.stageFigureScale);
    expect(controller.labelOpacity, 0);
    final pose = controller.resolvePose(
      floatX: 165,
      floatY: _floatY,
      stageX: 165,
      stageY: _stageY,
    );
    expect(pose.y, _stageY);
    expect(pose.x, 165);
  });

  testWidgets('点小人收起:小人回到漂浮点,面板降到底;再点展开', (tester) async {
    final controller = await _pump(tester);

    await _tapSelf(tester);
    await tester.pumpAndSettle();
    expect(controller.onStage, isFalse);
    expect(controller.extent, 0);
    expect(controller.scale, 1);
    expect(controller.labelOpacity, 1);
    expect(_selfTop(tester), closeTo(_floatY, 0.01));

    await _tapSelf(tester);
    await tester.pumpAndSettle();
    expect(controller.onStage, isTrue);
    expect(controller.extent, 1);
    expect(controller.scale, CoFitDecor.stageFigureScale);
  });

  testWidgets('下台:蓄力期间台子不动,起跳时才开始降', (tester) async {
    final controller = await _pump(tester);

    await _tapSelf(tester);
    await tester.pump();
    expect(controller.reactToLastChange, isTrue);
    await tester.pump(CoFitMotion.stageCrouch ~/ 2);
    expect(controller.extent, 1);

    await tester.pump(CoFitMotion.stageCrouch);
    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.extent, lessThan(1));
    await tester.pumpAndSettle();
  });

  testWidgets('上台:点下去台子立即开始升;落地触发一次回调', (tester) async {
    final controller = await _pump(tester, expanded: false);
    final state = tester.state<_HarnessState>(find.byType(_Harness));

    await _tapSelf(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(controller.extent, greaterThan(0));
    expect(state.landed, 0);

    await tester.pumpAndSettle();
    expect(state.landed, 1);
    expect(controller.extent, 1);
  });

  testWidgets('动画进行中再点:不响应,等播完才接受下一个操作', (tester) async {
    final controller = await _pump(tester);

    await _tapSelf(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.isBusy, isTrue);

    // 动画中的点击、把手拖动都被忽略
    controller.toggle();
    controller
      ..dragStart()
      ..dragUpdate(0.5)
      ..dragEnd(0);
    await tester.pumpAndSettle();
    expect(controller.onStage, isFalse);
    expect(controller.extent, 0);
    expect(controller.isBusy, isFalse);

    // 播完后可以继续操作
    controller.toggle();
    await tester.pumpAndSettle();
    expect(controller.onStage, isTrue);
    expect(controller.extent, 1);
  });

  testWidgets('连续快速点击:只有第一下生效', (tester) async {
    final controller = await _pump(tester);

    for (var i = 0; i < 4; i++) {
      controller.toggle();
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();
    expect(controller.onStage, isFalse);
    expect(controller.extent, 0);
  });

  testWidgets('拖一小段就松手:面板回到展开,小人仍在上沿', (tester) async {
    final controller = await _pump(tester);
    final handle = find.byKey(const ValueKey('home_sheet_handle'));

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(controller.extent, lessThan(1));
    expect(controller.onStage, isTrue);
    // 小人跟着台面下降
    expect(_selfTop(tester), greaterThan(_stageY));

    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.extent, 1);
    expect(controller.onStage, isTrue);
  });

  testWidgets('拖过头:小人自己下台;拖回来又上台;松手结果跟随小人', (tester) async {
    final controller = await _pump(tester);
    final handle = find.byKey(const ValueKey('home_sheet_handle'));

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    expect(controller.extent, lessThan(CoFitDecor.stageDragLeave));
    expect(controller.onStage, isFalse);

    // 拖回接近展开
    await gesture.moveBy(const Offset(0, -170));
    await tester.pump();
    expect(controller.extent, greaterThan(CoFitDecor.stageDragBoard));
    expect(controller.onStage, isTrue);

    // 再拖过头后慢速松手 → 收起
    await gesture.moveBy(const Offset(0, 190));
    await tester.pump();
    expect(controller.onStage, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.extent, 0);
    expect(_selfTop(tester), closeTo(_floatY, 0.01));
  });

  testWidgets('快速向下甩:拖动距离很短也收起', (tester) async {
    final controller = await _pump(tester);
    final handle = find.byKey(const ValueKey('home_sheet_handle'));

    await tester.fling(handle, const Offset(0, 60), 2000);
    await tester.pumpAndSettle();
    expect(controller.onStage, isFalse);
    expect(controller.extent, 0);
  });

  testWidgets('点把手:收起', (tester) async {
    final controller = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('home_sheet_handle')));
    await tester.pumpAndSettle();
    expect(controller.extent, 0);
  });

  testWidgets('减弱动态效果:不位移,小人淡出后在落点淡入', (tester) async {
    final controller = await _pump(tester, reduceMotion: true);

    controller.collapse();
    await tester.pump();
    expect(controller.reactToLastChange, isFalse);
    await tester.pump(const Duration(milliseconds: 40));
    // 前半段:仍在台上的位置,正在淡出
    expect(_selfTop(tester), greaterThan(_floatY));
    expect(controller.opacity, lessThan(1));
    expect(controller.scale, CoFitDecor.stageFigureScale);

    await tester.pumpAndSettle();
    expect(_selfTop(tester), closeTo(_floatY, 0.01));
    expect(controller.opacity, 1);
    expect(controller.extent, 0);
  });

  testWidgets('面板不存在时:收起且点小人无法展开', (tester) async {
    final controller = await _pump(tester);

    controller.setAvailable(false);
    await tester.pump();
    expect(controller.extent, 0);
    expect(controller.onStage, isFalse);

    controller.expand();
    await tester.pumpAndSettle();
    expect(controller.extent, 0);
    expect(controller.onStage, isFalse);
  });

  testWidgets('往下拖到一半:模块不消失,跟着面板一起移动', (tester) async {
    final controller = await _pump(tester);
    await tester.pumpAndSettle();
    final handle = find.byKey(const ValueKey('home_sheet_handle'));

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump();
    expect(controller.extent, lessThan(CoFitDecor.sheetModuleRevealAt));
    expect(controller.modulesRevealed, isTrue);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1,
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('模块在展开后可见,收起后不可见', (tester) async {
    final controller = await _pump(tester);
    await tester.pumpAndSettle();

    AnimatedOpacity opacity() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity().opacity, 1);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(opacity().opacity, 0);
  });
}
