import 'package:cofit/features/home_sheet/domain/entity/home_sheet_layout.dart';
import 'package:cofit/features/home_sheet/usecase/auto_expand_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 21, 12);
  const layout = HomeSheetLayout.defaults;

  group('AutoExpandPolicy', () {
    bool resumedAfter(Duration away, {HomeSheetLayout l = layout}) =>
        AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.resumed,
          layout: l,
          now: now,
          leftAt: now.subtract(away),
        );

    test('冷启动与完成一张卡:按配置展开', () {
      expect(
        AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.coldStart,
          layout: layout,
          now: now,
        ),
        isTrue,
      );
      expect(
        AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.completed,
          layout: layout.copyWith(expandAfterCompletion: false),
          now: now,
        ),
        isFalse,
      );
    });

    test('短暂离开:保持原状', () {
      expect(resumedAfter(const Duration(minutes: 5)), isFalse);
    });

    test('离开超过设定时长:展开(含刚好等于)', () {
      expect(resumedAfter(const Duration(minutes: 30)), isTrue);
      expect(resumedAfter(const Duration(hours: 3)), isTrue);
    });

    test('关闭按离开时长展开、或不知道何时离开:不展开', () {
      expect(
        resumedAfter(
          const Duration(hours: 3),
          l: layout.copyWith(expandAfterAwayMinutes: null),
        ),
        isFalse,
      );
      expect(
        AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.resumed,
          layout: layout,
          now: now,
        ),
        isFalse,
      );
    });

    test('面板关闭(没有模块)时永不展开', () {
      expect(
        AutoExpandPolicy.shouldExpand(
          trigger: AutoExpandTrigger.coldStart,
          layout: layout.copyWith(modules: const []),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('PendingCelebrationPolicy', () {
    bool replay(int count, Duration? ago) =>
        PendingCelebrationPolicy.shouldReplay(
          pendingCount: count,
          lastCompletedAt: ago == null ? null : now.subtract(ago),
          now: now,
          layout: layout,
        );

    test('有欠的且在有效期内:补播', () {
      expect(replay(1, const Duration(minutes: 20)), isTrue);
      expect(replay(3, const Duration(hours: 12)), isTrue);
    });

    test('超过有效期:不补播', () {
      expect(replay(1, const Duration(hours: 13)), isFalse);
    });

    test('没有欠的:不补播', () {
      expect(replay(0, const Duration(minutes: 1)), isFalse);
      expect(replay(2, null), isFalse);
    });
  });
}
