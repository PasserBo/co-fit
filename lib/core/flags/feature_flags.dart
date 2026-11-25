/// 远程功能开关(Firebase Remote Config)。
/// 字段默认值 = 远端未配置时的行为;新开关先在这里加字段与默认值,
/// 再到 Firebase console 建同名参数。
class FeatureFlags {
  const FeatureFlags({
    this.authGoogleEnabled = false,
    this.betaAiCoachEnabled = false,
    this.homeSheetLayout = '',
    this.dailyGoalConfig = '',
    this.workoutMemoConfig = '',
  });

  /// 登录页是否展示「通过 Google 登录」(2026-10-26 决议:默认关,
  /// Apple/Google uid 不互通问题解决前不开放)。参数名 `auth_google_enabled`。
  final bool authGoogleEnabled;

  /// 运动历史页是否展示 beta「AI 教练」入口(2026-11-18,change
  /// add-ai-coach-beta:默认关;debug 构建无视此开关始终展示)。
  /// 参数名 `beta_ai_coach_enabled`。
  final bool betaAiCoachEnabled;

  /// 今日面板的布局配置(JSON 字符串,change add-home-sheet,形状见其
  /// design.md §12)。空串 = 用 App 内置默认布局;解析与回退在
  /// `HomeSheetLayout.parse`。参数名 `home_sheet_layout`。
  final String homeSheetLayout;

  /// 今日进度的内容配置(JSON 字符串,change add-daily-card-goal,形状见其
  /// design.md §2:计量方式、默认目标、可选目标)。空串 = App 内置默认值;
  /// 解析与回退在 `DailyGoalConfig.parse`。参数名 `daily_goal_config`。
  final String dailyGoalConfig;

  /// 运动 memo 的内容配置(JSON 字符串,change add-workout-memo,形状见其
  /// design.md §3:感受档位、可补记时长、文字上限)。
  /// 空串 = App 内置默认值;解析与回退在 `WorkoutMemoConfig.parse`。
  /// 参数名 `workout_memo_config`。
  final String workoutMemoConfig;

  static const defaults = FeatureFlags();

  static const keyAuthGoogleEnabled = 'auth_google_enabled';
  static const keyBetaAiCoachEnabled = 'beta_ai_coach_enabled';
  static const keyHomeSheetLayout = 'home_sheet_layout';
  static const keyDailyGoalConfig = 'daily_goal_config';
  static const keyWorkoutMemoConfig = 'workout_memo_config';

  /// 与 Remote Config 的 `setDefaults` 形状一致。
  static Map<String, Object> defaultsMap() => {
    keyAuthGoogleEnabled: defaults.authGoogleEnabled,
    keyBetaAiCoachEnabled: defaults.betaAiCoachEnabled,
    keyHomeSheetLayout: defaults.homeSheetLayout,
    keyDailyGoalConfig: defaults.dailyGoalConfig,
    keyWorkoutMemoConfig: defaults.workoutMemoConfig,
  };

  factory FeatureFlags.fromReader(
    bool Function(String key) readBool, {
    String Function(String key)? readString,
  }) {
    return FeatureFlags(
      authGoogleEnabled: readBool(keyAuthGoogleEnabled),
      betaAiCoachEnabled: readBool(keyBetaAiCoachEnabled),
      homeSheetLayout:
          readString?.call(keyHomeSheetLayout) ?? defaults.homeSheetLayout,
      dailyGoalConfig:
          readString?.call(keyDailyGoalConfig) ?? defaults.dailyGoalConfig,
      workoutMemoConfig:
          readString?.call(keyWorkoutMemoConfig) ?? defaults.workoutMemoConfig,
    );
  }
}
