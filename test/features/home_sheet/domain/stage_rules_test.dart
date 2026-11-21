import 'package:cofit/core/theme/cofit_dimens.dart';
import 'package:cofit/features/home_sheet/domain/stage_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StageRules.onStageWhileDragging', () {
    test('拖一小段:小人还在台上', () {
      expect(
        StageRules.onStageWhileDragging(onStage: true, extent: 0.8),
        isTrue,
      );
    });

    test('拖过下台阈值:小人下台', () {
      expect(
        StageRules.onStageWhileDragging(
          onStage: true,
          extent: CoFitDecor.stageDragLeave - 0.01,
        ),
        isFalse,
      );
    });

    test('下台后拖回两个阈值之间:保持不在台上(回差)', () {
      expect(
        StageRules.onStageWhileDragging(onStage: false, extent: 0.5),
        isFalse,
      );
      expect(
        StageRules.onStageWhileDragging(onStage: true, extent: 0.5),
        isTrue,
      );
    });

    test('拖回上台阈值以上:小人回到台上', () {
      expect(
        StageRules.onStageWhileDragging(
          onStage: false,
          extent: CoFitDecor.stageDragBoard + 0.01,
        ),
        isTrue,
      );
    });
  });

  group('StageRules.expandedAfterRelease', () {
    test('慢速松手:小人在台上 → 展开;不在 → 收起', () {
      expect(
        StageRules.expandedAfterRelease(onStage: true, velocityDy: 50),
        isTrue,
      );
      expect(
        StageRules.expandedAfterRelease(onStage: false, velocityDy: -50),
        isFalse,
      );
    });

    test('快速向下甩:即使小人还在台上也收起', () {
      expect(
        StageRules.expandedAfterRelease(
          onStage: true,
          velocityDy: CoFitDecor.stageFlingVelocity + 1,
        ),
        isFalse,
      );
    });

    test('快速向上甩:即使小人已下台也展开', () {
      expect(
        StageRules.expandedAfterRelease(
          onStage: false,
          velocityDy: -CoFitDecor.stageFlingVelocity - 1,
        ),
        isTrue,
      );
    });
  });

  group('StageRules 几何', () {
    test('面板高度不超过屏幕高度的上限比例', () {
      expect(
        StageRules.sheetHeight(contentHeight: 200, screenHeight: 800),
        200,
      );
      expect(
        StageRules.sheetHeight(contentHeight: 900, screenHeight: 800),
        800 * CoFitDecor.sheetMaxHeightFraction,
      );
    });

    test('好友区域下边距随展开程度从手牌过渡到面板', () {
      double inset(double extent) => StageRules.sceneBottomInset(
        collapsedInset: 248,
        sheetHeight: 348,
        extent: extent,
      );
      expect(inset(0), 248);
      expect(inset(0.5), 298);
      expect(inset(1), 348);
    });

    test('面板比手牌区矮时好友区域不收缩', () {
      expect(
        StageRules.sceneBottomInset(
          collapsedInset: 248,
          sheetHeight: 180,
          extent: 1,
        ),
        248,
      );
    });
  });

  group('StageHop', () {
    HopPose pose(double progress, {double toY = 300, double crouch = 0.25}) =>
        StageHop.pose(
          progress: progress,
          crouchFraction: crouch,
          fromX: 100,
          fromY: 200,
          fromScale: 1,
          toX: 100,
          toY: toY,
          toScale: 1.15,
          arc: 16,
        );

    test('蓄力阶段原地不动', () {
      expect(pose(0).y, 200);
      expect(pose(0.25).y, 200);
      expect(pose(0.2).scale, 1);
    });

    test('结束时精确落在落点并达到目标大小', () {
      final end = pose(1);
      expect(end.y, 300);
      expect(end.scale, 1.15);
      expect(end.opacity, 1);
    });

    test('腾空中点高出直线一个弧高', () {
      // 蓄力 0.25,腾空中点 = 0.625
      final mid = pose(0.625);
      expect(mid.y, closeTo(250 - 16, 0.001));
    });

    test('落点每帧取实时值:台面移动后仍精确落在新位置', () {
      expect(pose(1, toY: 340).y, 340);
      // 途中落点变化,轨迹连续指向新落点
      expect(pose(0.9, toY: 340).y, greaterThan(pose(0.9, toY: 300).y));
    });

    test('无蓄力时从第一帧开始移动', () {
      expect(pose(0.1, crouch: 0).y, isNot(200));
    });

    test('减弱动态效果:不位移,先淡出后在落点淡入', () {
      HopPose reduced(double progress) => StageHop.reducedPose(
        progress: progress,
        fromX: 100,
        fromY: 200,
        fromScale: 1,
        toX: 100,
        toY: 300,
        toScale: 1.15,
      );
      expect(reduced(0).y, 200);
      expect(reduced(0).opacity, 1);
      expect(reduced(0.25).y, 200);
      expect(reduced(0.5).opacity, 0);
      expect(reduced(0.75).y, 300);
      expect(reduced(1).y, 300);
      expect(reduced(1).opacity, 1);
    });

    test('弧高按起跳距离等比缩小', () {
      expect(StageHop.arcFor(distance: 200), CoFitDecor.stageHopArc);
      expect(StageHop.arcFor(distance: 40), CoFitDecor.stageHopArc / 2);
      expect(StageHop.arcFor(distance: 0), 0);
    });
  });
}
