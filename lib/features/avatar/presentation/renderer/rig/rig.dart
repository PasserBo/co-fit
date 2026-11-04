import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../avatar_renderer.dart' show avatarFigureFraction;
import 'bone.dart';

/// 一根骨骼的静态定义:父骨骼、枢轴、rest 几何(圆角矩形,r = 短边/2)。
/// 几何属于渲染内容(与 #14a 关键帧同性质),不是设计 token。
@immutable
class BoneDef {
  const BoneDef({
    required this.parent,
    required this.pivot,
    this.capsules = const [],
  });

  final Bone? parent;
  final Offset pivot;

  /// rest 姿势下该骨骼画的胶囊(视框坐标)。spine/head 的几何由 painter 专门处理。
  final List<Rect> capsules;
}

/// 豆豆骨架(docs/avatar_bean_spec.md §1–3)。视框 80×100,地面 y=90。
@immutable
class Rig {
  const Rig._({
    required this.facing,
    required this.bones,
    required this.drawOrder,
    required this.sockets,
    required this.eyes,
  });

  /// 视框尺寸与地面。
  static const double viewWidth = 80;
  static const double viewHeight = 100;
  static const double groundY = 90;

  /// 形体(头顶 y7 → 脚底 y89)占视框高的比例:token `sizeFigure*` 定义形体高,
  /// 调用方用 figureHeight / figureFraction 换算视框高。
  static const double figureFraction = avatarFigureFraction;

  /// 蛋体 path(spec §1.1),三次贝塞尔,lazy 缓存。
  static final Path eggPath = Path()
    ..moveTo(40, 7)
    ..cubicTo(59, 7, 61, 29, 60, 48)
    ..cubicTo(59, 63, 50, 68, 40, 68)
    ..cubicTo(30, 68, 21, 63, 20, 48)
    ..cubicTo(19, 29, 21, 7, 40, 7)
    ..close();

  /// 悬浮分段的「缝」:四肢胶囊外圈背景色描边宽(spec §1.2)。
  static const double limbGapStroke = 1.4;

  /// 状态描边宽(spec §4,替代 #6b 头环)。
  static const double outlineStroke = 2.4;

  /// 两点眼半径(spec §4)。
  static const double eyeRadius = 1.7;

  final Facing facing;
  final Map<Bone, BoneDef> bones;

  /// 绘制顺序(后画在前)。
  final List<Bone> drawOrder;
  final Map<Socket, Offset> sockets;

  /// 眼睛位置(正面两只,侧面一只)。
  final List<Offset> eyes;

  static Rig of(Facing facing) => switch (facing) {
    Facing.front => front,
    Facing.side => side,
  };

  static const Rig front = Rig._(
    facing: Facing.front,
    bones: {
      Bone.root: BoneDef(parent: null, pivot: Offset(40, 88)),
      Bone.pelvis: BoneDef(parent: Bone.root, pivot: Offset(40, 70.5)),
      Bone.spine: BoneDef(parent: Bone.pelvis, pivot: Offset(40, 68)),
      Bone.head: BoneDef(parent: Bone.spine, pivot: Offset(40, 31)),
      Bone.uarmL: BoneDef(
        parent: Bone.spine,
        pivot: Offset(15.25, 39),
        capsules: [Rect.fromLTWH(12.5, 39, 5.5, 10)],
      ),
      Bone.farmL: BoneDef(
        parent: Bone.uarmL,
        pivot: Offset(15.25, 50),
        capsules: [Rect.fromLTWH(12.5, 51, 5.5, 9)],
      ),
      Bone.uarmR: BoneDef(
        parent: Bone.spine,
        pivot: Offset(64.75, 39),
        capsules: [Rect.fromLTWH(62, 39, 5.5, 10)],
      ),
      Bone.farmR: BoneDef(
        parent: Bone.uarmR,
        pivot: Offset(64.75, 50),
        capsules: [Rect.fromLTWH(62, 51, 5.5, 9)],
      ),
      Bone.thighL: BoneDef(
        parent: Bone.pelvis,
        pivot: Offset(33, 70.5),
        capsules: [Rect.fromLTWH(30, 70.5, 6, 8)],
      ),
      Bone.shinL: BoneDef(
        parent: Bone.thighL,
        pivot: Offset(33, 79),
        capsules: [Rect.fromLTWH(30, 79.5, 6, 7), Rect.fromLTWH(28, 86, 10, 3)],
      ),
      Bone.thighR: BoneDef(
        parent: Bone.pelvis,
        pivot: Offset(47, 70.5),
        capsules: [Rect.fromLTWH(44, 70.5, 6, 8)],
      ),
      Bone.shinR: BoneDef(
        parent: Bone.thighR,
        pivot: Offset(47, 79),
        capsules: [Rect.fromLTWH(44, 79.5, 6, 7), Rect.fromLTWH(42, 86, 10, 3)],
      ),
    },
    drawOrder: [
      Bone.thighL,
      Bone.shinL,
      Bone.thighR,
      Bone.shinR,
      Bone.spine,
      Bone.uarmL,
      Bone.farmL,
      Bone.uarmR,
      Bone.farmR,
      Bone.head,
    ],
    sockets: {
      Socket.crown: Offset(40, 7),
      Socket.face: Offset(40, 29),
      Socket.chest: Offset(40, 50),
      Socket.back: Offset(40, 40),
      Socket.handL: Offset(15.25, 60),
      Socket.handR: Offset(64.75, 60),
      Socket.footL: Offset(33, 88),
      Socket.footR: Offset(47, 88),
      Socket.ground: Offset(40, 90),
    },
    eyes: [Offset(34, 29), Offset(46, 29)],
  );

  /// 侧面(朝右):肩前移到 x46,髋在 x40;远侧腿整体 x −1.5(spec §3)。
  static const Rig side = Rig._(
    facing: Facing.side,
    bones: {
      Bone.root: BoneDef(parent: null, pivot: Offset(40, 88)),
      Bone.pelvis: BoneDef(parent: Bone.root, pivot: Offset(40, 70.5)),
      Bone.spine: BoneDef(parent: Bone.pelvis, pivot: Offset(40, 68)),
      Bone.head: BoneDef(parent: Bone.spine, pivot: Offset(40, 31)),
      Bone.uarmL: BoneDef(
        parent: Bone.spine,
        pivot: Offset(46, 39),
        capsules: [Rect.fromLTWH(43.25, 39, 5.5, 10)],
      ),
      Bone.farmL: BoneDef(
        parent: Bone.uarmL,
        pivot: Offset(46, 50),
        capsules: [Rect.fromLTWH(43.25, 51, 5.5, 9)],
      ),
      Bone.uarmR: BoneDef(
        parent: Bone.spine,
        pivot: Offset(46, 39),
        capsules: [Rect.fromLTWH(43.25, 39, 5.5, 10)],
      ),
      Bone.farmR: BoneDef(
        parent: Bone.uarmR,
        pivot: Offset(46, 50),
        capsules: [Rect.fromLTWH(43.25, 51, 5.5, 9)],
      ),
      Bone.thighL: BoneDef(
        parent: Bone.pelvis,
        pivot: Offset(40, 70.5),
        capsules: [Rect.fromLTWH(37, 70.5, 6, 8)],
      ),
      Bone.shinL: BoneDef(
        parent: Bone.thighL,
        pivot: Offset(40, 79),
        capsules: [Rect.fromLTWH(37, 79.5, 6, 7), Rect.fromLTWH(36, 86, 11, 3)],
      ),
      Bone.thighR: BoneDef(
        parent: Bone.pelvis,
        pivot: Offset(38.5, 70.5),
        capsules: [Rect.fromLTWH(35.5, 70.5, 6, 8)],
      ),
      Bone.shinR: BoneDef(
        parent: Bone.thighR,
        pivot: Offset(38.5, 79),
        capsules: [
          Rect.fromLTWH(35.5, 79.5, 6, 7),
          Rect.fromLTWH(34.5, 86, 11, 3),
        ],
      ),
    },
    // 远侧(R)先画,蛋体夹在远臂与近臂之间。
    drawOrder: [
      Bone.thighR,
      Bone.shinR,
      Bone.thighL,
      Bone.shinL,
      Bone.uarmR,
      Bone.farmR,
      Bone.spine,
      Bone.uarmL,
      Bone.farmL,
      Bone.head,
    ],
    sockets: {
      Socket.crown: Offset(40, 7),
      Socket.face: Offset(48, 29),
      Socket.chest: Offset(44, 50),
      Socket.back: Offset(28, 40),
      Socket.handL: Offset(46, 60),
      Socket.handR: Offset(46, 60),
      Socket.footL: Offset(40, 88),
      Socket.footR: Offset(40, 88),
      Socket.ground: Offset(40, 90),
    },
    eyes: [Offset(48, 29)],
  );
}
