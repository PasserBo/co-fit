import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_progress.freezed.dart';

/// 今日进度:界面只认这三个值,不知道计量方式是什么。
@freezed
abstract class DailyProgress with _$DailyProgress {
  const DailyProgress._();

  const factory DailyProgress({
    required int current,
    required int target,
    required String unit,
  }) = _DailyProgress;

  bool get reached => current >= target;

  /// 离目标还差多少;已达成为 0。
  int get remaining => reached ? 0 : target - current;

  /// 进度环的填充比例,0–1。
  double get fraction =>
      target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();
}
