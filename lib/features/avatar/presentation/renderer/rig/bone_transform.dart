import 'package:flutter/foundation.dart';

/// 单骨骼的局部变换,全部相对 rest pose,绕骨骼自己的枢轴(spec §0:顺时针为正)。
@immutable
class BoneTransform {
  const BoneTransform({
    this.dx = 0,
    this.dy = 0,
    this.rotDeg = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  /// 体积守恒的挤压拉伸:sy 给定,sx = 1/sy。
  const BoneTransform.squash(double sy) : this(scaleX: 1 / sy, scaleY: sy);

  static const identity = BoneTransform();

  final double dx;
  final double dy;
  final double rotDeg;
  final double scaleX;
  final double scaleY;

  /// 关键帧之间的插值(t 已经过缓动)。
  BoneTransform lerpTo(BoneTransform other, double t) {
    return BoneTransform(
      dx: dx + (other.dx - dx) * t,
      dy: dy + (other.dy - dy) * t,
      rotDeg: rotDeg + (other.rotDeg - rotDeg) * t,
      scaleX: scaleX + (other.scaleX - scaleX) * t,
      scaleY: scaleY + (other.scaleY - scaleY) * t,
    );
  }

  /// 叠加(basePose + 轨道值):位移/角度相加,缩放相乘。
  BoneTransform compose(BoneTransform other) {
    return BoneTransform(
      dx: dx + other.dx,
      dy: dy + other.dy,
      rotDeg: rotDeg + other.rotDeg,
      scaleX: scaleX * other.scaleX,
      scaleY: scaleY * other.scaleY,
    );
  }

  /// 镜像肢体(README 帧同步规范 2):角度/横向位移取反,纵向与缩放照抄。
  BoneTransform mirrored({bool negateRot = true, bool negateDx = false}) {
    return BoneTransform(
      dx: negateDx ? -dx : dx,
      dy: dy,
      rotDeg: negateRot ? -rotDeg : rotDeg,
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }

  bool get isIdentity =>
      dx == 0 && dy == 0 && rotDeg == 0 && scaleX == 1 && scaleY == 1;

  @override
  bool operator ==(Object other) =>
      other is BoneTransform &&
      other.dx == dx &&
      other.dy == dy &&
      other.rotDeg == rotDeg &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY;

  @override
  int get hashCode => Object.hash(dx, dy, rotDeg, scaleX, scaleY);

  @override
  String toString() =>
      'BoneTransform(dx: $dx, dy: $dy, rot: $rotDeg°, sx: $scaleX, sy: $scaleY)';
}
