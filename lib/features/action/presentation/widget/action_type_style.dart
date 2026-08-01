import 'package:flutter/material.dart';

import '../../../../core/theme/cofit_colors.dart';
import '../../domain/entity/action_type.dart';

/// [ActionType] 的展示层映射(文案/图标/语义色)。
/// 颜色取 CoFitColors 的 type.* token;牌库分区标题等场景可复用。
extension ActionTypeStyle on ActionType {
  String get label => switch (this) {
        ActionType.strength => '力量',
        ActionType.cardio => '有氧',
        ActionType.core => '核心',
        ActionType.flexibility => '柔韧',
      };

  /// 牌库分区标题(#12b mock:力量训练/有氧训练/核心)
  String get sectionTitle => switch (this) {
        ActionType.strength => '力量训练',
        ActionType.cardio => '有氧训练',
        ActionType.core => '核心',
        ActionType.flexibility => '柔韧',
      };

  IconData get icon => switch (this) {
        ActionType.strength => Icons.fitness_center,
        ActionType.cardio => Icons.directions_run,
        ActionType.core => Icons.self_improvement,
        ActionType.flexibility => Icons.accessibility_new,
      };

  Color mainOf(CoFitColors colors) => switch (this) {
        ActionType.strength => colors.typeStrength,
        ActionType.cardio => colors.typeCardio,
        ActionType.core => colors.typeCore,
        ActionType.flexibility => colors.typeFlexibility,
      };

  Color subtleOf(CoFitColors colors) => switch (this) {
        ActionType.strength => colors.typeStrengthSubtle,
        ActionType.cardio => colors.typeCardioSubtle,
        ActionType.core => colors.typeCoreSubtle,
        ActionType.flexibility => colors.typeFlexibilitySubtle,
      };
}
