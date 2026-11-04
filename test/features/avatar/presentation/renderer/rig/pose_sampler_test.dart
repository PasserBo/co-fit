import 'package:cofit/features/avatar/presentation/renderer/clips/core_states.dart';
import 'package:cofit/features/avatar/presentation/renderer/motion_clip_library.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/bone.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/bone_transform.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/pose_sampler.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/rig.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

Matcher _closeToMatrix(Matrix4 expected) => predicate<Matrix4>((m) {
  for (var i = 0; i < 16; i++) {
    if ((m.storage[i] - expected.storage[i]).abs() > 1e-6) {
      return false;
    }
  }
  return true;
}, 'matrix ≈ $expected');

void main() {
  group('Track', () {
    test('keyframes interpolate with easing and clamp at both ends', () {
      const track = Track.keys([
        Keyframe(0, BoneTransform(rotDeg: 0)),
        Keyframe(0.5, BoneTransform(rotDeg: 10)),
        Keyframe(1, BoneTransform(rotDeg: 0)),
      ]);
      expect(track.sample(0).rotDeg, 0);
      expect(track.sample(0.5).rotDeg, 10);
      expect(track.sample(1).rotDeg, 0);
      expect(track.sample(0.25).rotDeg, closeTo(5, 1e-9)); // easeInOut 中点
      expect(track.sample(0.1).rotDeg, lessThan(2)); // 缓入
    });

    test('swing is a mirror-symmetric triangle wave', () {
      const track = Track.swing(-32, 32);
      expect(track.sample(0).rotDeg, -32);
      expect(track.sample(0.5).rotDeg, 32);
      expect(track.sample(1).rotDeg, -32);
      expect(
        track.sample(0.2).rotDeg,
        closeTo(-track.sample(0.7).rotDeg, 1e-9),
      );
    });
  });

  group('PoseSampler', () {
    test('mirrored bones are exact negations at every t', () {
      for (var i = 0; i <= 20; i++) {
        final t = i / 20;
        final pose = PoseSampler.sample(CoreStateClips.run, Rig.side, t);
        expect(
          pose.local[Bone.thighR]!.rotDeg,
          closeTo(-pose.local[Bone.thighL]!.rotDeg, 1e-9),
        );
        expect(
          pose.local[Bone.uarmR]!.rotDeg,
          closeTo(-pose.local[Bone.uarmL]!.rotDeg, 1e-9),
        );
      }
    });

    test('loop clips have identical poses at t=0 and t=1', () {
      for (final clip in MotionClipLibrary.all.where((c) => c.loop)) {
        final rig = Rig.of(clip.facing);
        final start = PoseSampler.sample(clip, rig, 0);
        final end = PoseSampler.sample(clip, rig, 1);
        for (final bone in Bone.values) {
          expect(
            end.world[bone],
            _closeToMatrix(start.world[bone]!),
            reason: '${clip.id}.${bone.name} 首尾帧不一致',
          );
        }
      }
    });

    test('child bones follow their parent (spine lean moves the head)', () {
      final rest = PoseSampler.sample(CoreStateClips.idle, Rig.front, 0);
      final leaned = PoseSampler.sample(CoreStateClips.stretch, Rig.front, 0.5);
      final headRest = rest.world[Bone.head]!.transform3(Vector3(40, 29, 0));
      final headLean = leaned.world[Bone.head]!.transform3(Vector3(40, 29, 0));
      expect(headLean.x, lessThan(headRest.x)); // 上身左倾 → 头向左
      expect(headLean.y, greaterThan(headRest.y - 5)); // 绕髋转,不是平移
    });

    test('hold segment keeps the spine at the apex', () {
      final a = PoseSampler.sample(CoreStateClips.stretch, Rig.front, 0.45);
      final b = PoseSampler.sample(CoreStateClips.stretch, Rig.front, 0.55);
      expect(a.local[Bone.spine]!.rotDeg, -16);
      expect(b.local[Bone.spine]!.rotDeg, -16);
    });

    test('stage transform lays the plank figure down', () {
      final pose = PoseSampler.sample(CoreStateClips.plank, Rig.side, 0);
      final crown = pose.world[Bone.head]!.transform3(Vector3(40, 7, 0));
      final foot = pose.world[Bone.shinL]!.transform3(Vector3(40, 89, 0));
      expect(crown.x, greaterThan(foot.x + 60)); // 头在右、脚在左
      expect((crown.y - foot.y).abs(), lessThan(8)); // 几乎水平
    });

    test('base pose composes with tracks', () {
      final pose = PoseSampler.sample(CoreStateClips.run, Rig.side, 0.25);
      expect(pose.local[Bone.spine]!.rotDeg, 8); // basePose 常量
      expect(pose.local[Bone.farmL]!.rotDeg, -70);
    });
  });

  group('MotionClipLibrary', () {
    test('ids are unique and periods positive', () {
      final ids = MotionClipLibrary.all.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final clip in MotionClipLibrary.all) {
        expect(clip.period, greaterThan(Duration.zero));
        for (final mirror in clip.mirrors) {
          expect(mirror.from, isNot(mirror.target));
        }
      }
    });

    test('byId finds clips and ignores unknown ids', () {
      expect(MotionClipLibrary.byId('squat'), CoreStateClips.squat);
      expect(MotionClipLibrary.byId('nope'), isNull);
      expect(MotionClipLibrary.byId(null), isNull);
    });
  });
}
