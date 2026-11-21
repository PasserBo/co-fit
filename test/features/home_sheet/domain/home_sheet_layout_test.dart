import 'package:cofit/features/home_sheet/domain/entity/home_sheet_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeSheetLayout.parse', () {
    test('空、null、非法 JSON、不是对象 → 整份默认值', () {
      for (final raw in [null, '', '   ', '{not json', '[1,2]', '"x"', '3']) {
        expect(
          HomeSheetLayout.parse(raw),
          HomeSheetLayout.defaults,
          reason: '$raw',
        );
      }
    });

    test('完整配置按给定值解析', () {
      final layout = HomeSheetLayout.parse('''
        {"modules": ["progress", "recommendation"],
         "autoExpand": {"coldStart": false, "afterAwayMinutes": 5, "afterCompletion": false},
         "celebrationMaxAgeHours": 2}''');
      expect(layout.modules, ['progress', 'recommendation']);
      expect(layout.expandOnColdStart, isFalse);
      expect(layout.expandAfterAwayMinutes, 5);
      expect(layout.expandAfterCompletion, isFalse);
      expect(layout.celebrationMaxAgeHours, 2);
    });

    test('缺字段:只有缺的那个用默认值', () {
      final layout = HomeSheetLayout.parse(
        '{"autoExpand": {"coldStart": false}}',
      );
      expect(layout.expandOnColdStart, isFalse);
      expect(layout.modules, HomeSheetLayout.defaults.modules);
      expect(
        layout.expandAfterAwayMinutes,
        HomeSheetLayout.defaults.expandAfterAwayMinutes,
      );
      expect(layout.celebrationMaxAgeHours, 12);
    });

    test('类型不对:对应字段回退,其余照常', () {
      final layout = HomeSheetLayout.parse('''
        {"modules": "recommendation",
         "autoExpand": {"coldStart": "yes", "afterAwayMinutes": -3, "afterCompletion": false},
         "celebrationMaxAgeHours": "12"}''');
      expect(layout.modules, HomeSheetLayout.defaults.modules);
      expect(layout.expandOnColdStart, isTrue);
      expect(layout.expandAfterAwayMinutes, 30);
      expect(layout.expandAfterCompletion, isFalse);
      expect(layout.celebrationMaxAgeHours, 12);
    });

    test('autoExpand 不是对象 → 自动展开全部用默认值', () {
      final layout = HomeSheetLayout.parse('{"autoExpand": true}');
      expect(layout, HomeSheetLayout.defaults);
    });

    test('modules 为空数组 = 关闭面板', () {
      final layout = HomeSheetLayout.parse('{"modules": []}');
      expect(layout.modules, isEmpty);
      expect(layout.enabled, isFalse);
    });

    test('modules 里的非字符串与空串被丢弃', () {
      final layout = HomeSheetLayout.parse(
        '{"modules": ["a", 1, null, "", "b"]}',
      );
      expect(layout.modules, ['a', 'b']);
    });

    test('afterAwayMinutes 显式为 null = 不按离开时长展开', () {
      final layout = HomeSheetLayout.parse(
        '{"autoExpand": {"afterAwayMinutes": null}}',
      );
      expect(layout.expandAfterAwayMinutes, isNull);
    });
  });
}
