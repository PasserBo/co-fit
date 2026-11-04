import 'package:cofit/features/avatar/presentation/renderer/avatar_renderer.dart';
import 'package:cofit/features/avatar/presentation/renderer/motion_clip_library.dart';
import 'package:cofit/features/avatar/presentation/renderer/rig_avatar_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// P1 验收样张:8 个基础状态 × 4 个定帧,100px 高。
/// 画面纯几何无字体;基线由新实现生成(`flutter test --update-goldens`),
/// 与 docs/avatar_bean_sheet.html 人工对照过。
void main() {
  const appearance = AvatarAppearance(
    body: Color(0xFFF4F3EF),
    aura: Color(0xFFC8F24B),
    auraOpacity: 0.28,
    headRing: Color(0xE6C8F24B),
    ink: Color(0xFF181B22),
  );
  const frames = [0.0, 0.25, 0.5, 0.75];

  for (final clip in MotionClipLibrary.all) {
    testWidgets('${clip.id} frames', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ColoredBox(
            color: const Color(0xFF181B22),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final t in frames)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: StaticAvatarFrame(
                        clip: clip,
                        appearance: appearance,
                        height: 100,
                        t: t,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(Row),
        matchesGoldenFile('goldens/${clip.id}.png'),
      );
    });
  }
}
