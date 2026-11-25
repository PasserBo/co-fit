// DRAFT MODEL: 卡片上「做多少」的一项(change add-card-prescription);
// 保存在卡片 intensityBaseline.amounts 与运动记录的 amounts 里。暂定结构,可调整。
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_amount.freezed.dart';

/// 量的种类:决定叫什么、默认用什么单位。这份清单是内容,增减不影响已有数据
/// (数据里存的是 key + 数值 + 单位,不认识的 key 照样能显示)。
class CardAmountKind {
  const CardAmountKind({
    required this.key,
    required this.label,
    required this.unit,
  });

  final String key;
  final String label;
  final String unit;

  static const reps = CardAmountKind(key: 'reps', label: '次数', unit: '个');
  static const weight = CardAmountKind(key: 'weight', label: '重量', unit: 'kg');
  static const distance = CardAmountKind(
    key: 'distance',
    label: '距离',
    unit: 'm',
  );

  /// 表单里可选的种类,按显示顺序。没有「组数」:一张卡就是一组
  /// (2026-11-25 用户决议),想做几组就打几次。
  static const all = [reps, weight, distance];

  static CardAmountKind? byKey(String key) {
    for (final kind in all) {
      if (kind.key == key) {
        return kind;
      }
    }
    return null;
  }
}

/// 一项量:种类 + 数值 + 单位(如 15 个 / 5 kg / 400 m)。全部可选,一张卡可以有几项。
@freezed
abstract class CardAmount with _$CardAmount {
  const CardAmount._();

  const factory CardAmount({
    required String kind,
    required num value,
    required String unit,
  }) = _CardAmount;

  /// 用某个种类的默认单位。
  factory CardAmount.of(CardAmountKind kind, num value) =>
      CardAmount(kind: kind.key, value: value, unit: kind.unit);

  /// 一张卡最多带几项(服务端规则里也是这个上限)。
  static const maxPerCard = 8;
  static const maxValue = 100000;

  /// 「15 个」「2.5 kg」:整数不带小数点。
  String get text {
    final number = value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
    return unit.isEmpty ? number : '$number $unit';
  }

  Map<String, dynamic> toMap() => {'kind': kind, 'value': value, 'unit': unit};

  /// 从保存的列表里读;不合法的项被丢掉,同一种类只留第一项。永不抛出。
  static List<CardAmount> listFrom(Object? source) {
    if (source is! List) {
      return const [];
    }
    final seen = <String>{};
    final result = <CardAmount>[];
    for (final item in source) {
      if (item is! Map) {
        continue;
      }
      final kind = item['kind'];
      final value = item['value'];
      final unit = item['unit'];
      if (kind is! String ||
          kind.isEmpty ||
          value is! num ||
          value <= 0 ||
          value > maxValue ||
          !seen.add(kind)) {
        continue;
      }
      result.add(
        CardAmount(
          kind: kind,
          value: value,
          unit: unit is String
              ? unit
              : (CardAmountKind.byKey(kind)?.unit ?? ''),
        ),
      );
      if (result.length == maxPerCard) {
        break;
      }
    }
    return result;
  }

  /// 「15 个 · 5 kg」;没有返回空串。
  static String textOf(List<CardAmount> amounts) =>
      amounts.map((amount) => amount.text).join(' · ');

  /// 组装卡片的强度基线:强度标签与量都可选,都没有就是空表。
  static Map<String, dynamic> baseline({
    String? label,
    List<CardAmount> amounts = const [],
  }) => {
    if (label != null && label.isNotEmpty) 'label': label,
    if (amounts.isNotEmpty) 'amounts': [for (final a in amounts) a.toMap()],
  };
}
