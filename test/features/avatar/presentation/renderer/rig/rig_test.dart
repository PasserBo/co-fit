import 'package:cofit/features/avatar/presentation/renderer/rig/bone.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig/rig.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final rig in [Rig.front, Rig.side]) {
    group('Rig.${rig.facing.name}', () {
      test('defines every bone exactly once with a valid parent', () {
        expect(rig.bones.keys.toSet(), Bone.values.toSet());
        for (final entry in rig.bones.entries) {
          final parent = entry.value.parent;
          if (entry.key == Bone.root) {
            expect(parent, isNull);
          } else {
            expect(parent, isNotNull, reason: '${entry.key} 需要父骨骼');
            expect(
              parent!.index,
              lessThan(entry.key.index),
              reason: '父骨骼必须排在子骨骼之前(采样按枚举顺序合成)',
            );
          }
        }
      });

      test('draw order covers every drawable bone once', () {
        final drawable = Bone.values.where(
          (b) => b != Bone.root && b != Bone.pelvis,
        );
        expect(rig.drawOrder.toSet(), drawable.toSet());
        expect(rig.drawOrder.length, drawable.length);
      });

      test('defines all sockets inside the viewbox', () {
        expect(rig.sockets.keys.toSet(), Socket.values.toSet());
        for (final offset in rig.sockets.values) {
          expect(offset.dx, inInclusiveRange(0, Rig.viewWidth));
          expect(offset.dy, inInclusiveRange(0, Rig.viewHeight));
        }
      });

      test('limb capsules hang below their pivot', () {
        for (final entry in rig.bones.entries) {
          for (final rect in entry.value.capsules) {
            expect(
              rect.top,
              greaterThanOrEqualTo(entry.value.pivot.dy - 0.01),
              reason: '${entry.key} 的 rest 几何应从枢轴向下',
            );
          }
        }
      });
    });
  }

  test('side rig puts far leg slightly behind near leg', () {
    final near = Rig.side.bones[Bone.thighL]!.pivot;
    final far = Rig.side.bones[Bone.thighR]!.pivot;
    expect(far.dx, lessThan(near.dx));
  });
}
