import 'package:cofit/features/workout_memo/data/in_memory_workout_memo_repository.dart';
import 'package:cofit/features/workout_memo/domain/entity/workout_memo.dart';
import 'package:cofit/features/workout_memo/domain/entity/workout_memo_config.dart';
import 'package:cofit/features/workout_memo/presentation/widget/memo_editor.dart';
import 'package:cofit/features/workout_memo/usecase/memo_prompt.dart';
import 'package:cofit/features/workout_memo/usecase/save_workout_memo_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  final at = DateTime(2026, 11, 25, 12);

  WorkoutMemo memo({String? feel, String? note}) => WorkoutMemo(
    sessionId: 's1',
    templateId: 'squat',
    completedAt: at,
    updatedAt: at,
    feel: feel,
    note: note,
  );

  group('WorkoutMemoConfig.parse', () {
    test('空串 / 非法 JSON / 不是对象 → 内置默认值', () {
      for (final raw in [null, '', '{oops', '[]', '1']) {
        expect(WorkoutMemoConfig.parse(raw), WorkoutMemoConfig.defaults);
      }
    });

    test('完整配置', () {
      final config = WorkoutMemoConfig.parse('''
        {"feels":[{"key":"a","label":"甲","emoji":"🅰"},{"key":"b","label":"乙"}],
         "promptWindowMinutes":10,"noteMaxLength":40}''');
      expect(config.feels.map((f) => f.key), ['a', 'b']);
      expect(config.feelText('a'), '🅰 甲');
      expect(config.feelText('b'), '乙');
      expect(config.promptWindow, const Duration(minutes: 10));
      expect(config.noteMaxLength, 40);
    });

    test('单个字段不合法 → 只有那个字段用默认值', () {
      final config = WorkoutMemoConfig.parse(
        '{"feels":"x","promptWindowMinutes":-1,"noteMaxLength":9999}',
      );
      expect(config.feels, WorkoutMemoConfig.defaults.feels);
      expect(config.promptWindowMinutes, 30);
      expect(config.noteMaxLength, 100);
    });

    test('档位:丢掉缺字段与重复 key 的;空数组 = 不问感受', () {
      final config = WorkoutMemoConfig.parse(
        '{"feels":[{"key":"a","label":"甲"},{"key":"a","label":"重复"},'
        '{"key":"","label":"x"},{"label":"y"},7]}',
      );
      expect(config.feels.map((f) => f.label), ['甲']);
      expect(WorkoutMemoConfig.parse('{"feels":[]}').feels, isEmpty);
    });

    test('配置里已经没有的档位 key 显示 key 本身', () {
      expect(WorkoutMemoConfig.defaults.feelText('gone'), 'gone');
    });
  });

  group('memoPromptTarget', () {
    const window = Duration(minutes: 30);

    test('最新的一条,且在时长之内', () {
      final older = record(at.subtract(const Duration(minutes: 20)));
      final latest = record(at.subtract(const Duration(minutes: 5)));
      expect(
        memoPromptTarget(records: [older, latest], now: at, window: window),
        latest,
      );
    });

    test('超过时长 / 没有记录 / 时长为 0 → 没有', () {
      final old = record(at.subtract(const Duration(minutes: 30)));
      expect(memoPromptTarget(records: [old], now: at, window: window), isNull);
      expect(memoPromptTarget(records: [], now: at, window: window), isNull);
      expect(
        memoPromptTarget(records: [record(at)], now: at, window: Duration.zero),
        isNull,
      );
    });
  });

  group('WorkoutMemo', () {
    test('内容字段都没有 = 空', () {
      expect(memo().isEmpty, isTrue);
      expect(memo(note: '  ').isEmpty, isTrue);
      expect(memo(feel: 'ok').isEmpty, isFalse);
    });

    test('toMap 不写空字段;fromMap 往返', () {
      final map = memo(feel: 'ok', note: ' 腿酸 ').toMap();
      expect(map.keys, isNot(contains('reps')));
      expect(map['note'], '腿酸');
      final back = WorkoutMemo.fromMap(map)!;
      expect(back.feel, 'ok');
      expect(back.note, '腿酸');
    });

    test('fromMap 缺必填字段返回 null', () {
      expect(WorkoutMemo.fromMap({'sessionId': 's1'}), isNull);
      expect(WorkoutMemo.fromMap({'completedAt': at}), isNull);
    });

    test('摘要:感受 · 文字', () {
      const config = WorkoutMemoConfig.defaults;
      expect(
        memoSummaryText(memo(feel: 'hard', note: '腿酸'), config),
        '😮‍💨 吃力 · 腿酸',
      );
      expect(memoSummaryText(memo(note: '只有文字'), config), '只有文字');
      expect(memoSummaryText(memo(), config), isNull);
      expect(memoSummaryText(null, config), isNull);
    });
  });

  test('保存:有内容写入;全空改为删除', () async {
    final repository = InMemoryWorkoutMemoRepository();
    final usecase = SaveWorkoutMemoUsecase(repository);

    await usecase.execute(
      userId: 'me',
      memo: memo(feel: 'ok'),
    );
    expect(repository.of('me').keys, ['s1']);

    await usecase.execute(userId: 'me', memo: memo());
    expect(repository.of('me'), isEmpty);
  });
}
