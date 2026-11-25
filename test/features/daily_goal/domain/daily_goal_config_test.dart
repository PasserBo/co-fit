import 'package:cofit/features/daily_goal/domain/entity/daily_goal_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('空串 / 非法 JSON / 不是对象 → 内置默认值', () {
    for (final raw in [null, '', '  ', '{oops', '[1,2]', '"cards"']) {
      expect(DailyGoalConfig.parse(raw), DailyGoalConfig.defaults);
    }
  });

  test('完整配置', () {
    final config = DailyGoalConfig.parse(
      '{"metric":"minutes","defaultTarget":10,"choices":[20,5,10,10]}',
    );
    expect(config.metric, 'minutes');
    expect(config.defaultTarget, 10);
    expect(config.choices, [5, 10, 20]); // 去重并排序
  });

  test('单个字段不对 → 只有那个字段用默认值', () {
    final config = DailyGoalConfig.parse(
      '{"metric":"steps","defaultTarget":0,"choices":[3,"x",-1]}',
    );
    expect(config.metric, DailyGoalConfig.defaults.metric);
    expect(config.defaultTarget, DailyGoalConfig.defaults.defaultTarget);
    expect(config.choices, [3]);
  });

  test('choices 全部无效 → 默认清单', () {
    final config = DailyGoalConfig.parse('{"choices":[0,"a"]}');
    expect(config.choices, DailyGoalConfig.defaults.choices);
  });
}
