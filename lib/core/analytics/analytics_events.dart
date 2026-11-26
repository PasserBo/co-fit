/// 事件名与参数(GA4:小写下划线,事件名 ≤ 40 字符,参数值为字符串或数字)。
/// 只加不改:改名会断开历史数据。
/// ⚠️ 唯一登记处是 docs/analytics/events.md:新增 / 修改事件先改那里,再改这里。
abstract final class AnalyticsEvents {
  // ── 通知询问与权限(add-partner-start-push)──────────────────────
  /// App 内通知提示出现。参数 [pTrigger]。
  static const pushOfferShown = 'push_offer_shown';

  /// App 内通知提示的选择。参数 [pTrigger]、[pAccepted]。
  static const pushOfferResult = 'push_offer_result';

  /// 系统通知权限请求的结果。参数 [pSource]、[pResult]。
  static const pushPermissionResult = 'push_permission_result';

  /// 点开伙伴开始运动的推送。参数 [pEntered](是否切进了房间)。
  static const pushOpened = 'push_opened';

  /// 「我的」里的推送总开关。参数 [pEnabled]。
  static const pushSettingChanged = 'push_setting_changed';

  /// 房间菜单的静音 / 取消静音。参数 [pMuted]。
  static const roomPushMuted = 'room_push_muted';

  // ── 运动 ──────────────────────────────────────────────────────
  /// 开始一张卡。参数 [pDurationSec]。
  static const cardStarted = 'card_started';

  /// 一张卡做完。参数 [pDurationSec]。
  static const cardCompleted = 'card_completed';

  // ── 参数 ──────────────────────────────────────────────────────
  /// 询问出现的时机:[triggerJoin] / [triggerCreate] / [triggerExisting]。
  static const pTrigger = 'trigger';
  static const triggerJoin = 'join';
  static const triggerCreate = 'create';
  static const triggerExisting = 'existing_member';

  /// 1 = 是,0 = 否(GA4 参数不支持布尔)。
  static const pAccepted = 'accepted';
  static const pEnabled = 'enabled';
  static const pMuted = 'muted';
  static const pEntered = 'entered_room';

  /// 系统权限请求来自哪里:[sourceOffer] / [sourceSettings]。
  static const pSource = 'source';
  static const sourceOffer = 'offer';
  static const sourceSettings = 'settings';

  /// 权限结果:[resultGranted] / [resultDenied]。
  static const pResult = 'result';
  static const resultGranted = 'granted';
  static const resultDenied = 'denied';

  static const pDurationSec = 'duration_sec';

  static int flag(bool value) => value ? 1 : 0;
}
