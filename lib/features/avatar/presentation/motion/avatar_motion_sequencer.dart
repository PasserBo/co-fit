import '../../../action/domain/entity/action_type.dart';
import '../../../room/domain/entity/user_activity_status_entity.dart';
import '../../domain/entity/avatar_motion.dart';

/// 纯逻辑的动画编排器:把「业务状态变化」(idle/active/paused)翻译成
/// 「视觉状态序列」(起手/完成 ×1 过渡 + loop),保证切换丝滑:
///
/// - idle → active:先播 windup ×1,完成后进 exercise loop;
/// - active → idle:先播 finish ×1,完成后回 idle;
/// - active ⇄ paused:直接切(设计如此,摇摆/loop 自带缓动);
/// - 过渡进行中收到新变化:记入 pending,×1 播完后按最新目标继续。
///
/// 今日面板的「在台上」([onGrounded])与业务状态相互独立:
/// - 待机时上台 / 下台:可选播 board / leave ×1 反应,再进对应的待机;
/// - 运动 / 暂停 / 起手 / 完成中:只记下标记,不换 clip(上台不打断动作);
/// - 反应进行中再次切换,或业务状态变化:立即切到最新目标,不等反应播完。
///
/// 不依赖 Flutter —— 动画实现层(vector / 将来 Rive)只消费 [current]。
class AvatarMotionSequencer {
  AvatarMotionSequencer({AvatarMotion? initial})
    : _current = initial ?? AvatarMotion.idle();

  AvatarMotion _current;
  UserActivityState _logical = UserActivityState.idle;
  ActionType? _actionType;
  String? _motionId;
  AvatarTempo _tempo = AvatarTempo.standard;
  bool _pendingResolve = false;
  bool _grounded = false;

  AvatarMotion get current => _current;

  bool get grounded => _grounded;

  AvatarMotion _idle() =>
      AvatarMotion(state: AvatarMotionState.idle, grounded: _grounded);

  bool get _inReaction =>
      _current.state == AvatarMotionState.board ||
      _current.state == AvatarMotionState.leave;

  /// 上台 / 下台。[react] = 待机时是否播蓄力-腾空-落地的 ×1 反应
  /// (拖动触发、被打断、减弱动态效果时为 false)。
  /// 返回 true 表示视觉状态发生了变化。
  bool onGrounded(bool grounded, {bool react = true}) {
    if (grounded == _grounded) {
      return false;
    }
    _grounded = grounded;
    switch (_current.state) {
      case AvatarMotionState.idle:
        _current = react
            ? AvatarMotion(
                state: grounded
                    ? AvatarMotionState.board
                    : AvatarMotionState.leave,
                grounded: grounded,
              )
            : _idle();
        return true;
      case AvatarMotionState.board:
      case AvatarMotionState.leave:
        // 反应进行中掉头:直接到目的地的待机
        _current = _idle();
        return true;
      case AvatarMotionState.windup:
      case AvatarMotionState.exercise:
      case AvatarMotionState.paused:
      case AvatarMotionState.finish:
        return false;
    }
  }

  /// 业务状态更新。返回 true 表示视觉状态发生了变化(需要重启动画)。
  bool onLogicalState(
    UserActivityState state, {
    ActionType? actionType,
    String? motionId,
    AvatarTempo tempo = AvatarTempo.standard,
  }) {
    final changed =
        state != _logical ||
        actionType != _actionType ||
        motionId != _motionId ||
        tempo != _tempo;
    _logical = state;
    _actionType = actionType ?? _actionType;
    _motionId = motionId;
    _tempo = tempo;
    if (!changed) {
      return false;
    }

    // ×1 过渡进行中:不打断,播完后 onOneShotComplete 会按最新目标续接。
    if (_current.state == AvatarMotionState.windup ||
        _current.state == AvatarMotionState.finish) {
      _pendingResolve = true;
      return false;
    }

    return _resolve();
  }

  /// windup/finish ×1 播放完毕。返回 true 表示进入了新的视觉状态。
  bool onOneShotComplete() {
    switch (_current.state) {
      case AvatarMotionState.windup:
        // 起手完成 → 按当前业务状态进 loop(期间若已变化则跟随最新)
        _pendingResolve = false;
        return _resolveAfterOneShot(fallback: AvatarMotionState.exercise);
      case AvatarMotionState.finish:
        _pendingResolve = false;
        return _resolveAfterOneShot(fallback: AvatarMotionState.idle);
      case AvatarMotionState.board:
      case AvatarMotionState.leave:
        _current = _idle();
        return true;
      default:
        if (_pendingResolve) {
          _pendingResolve = false;
          return _resolve();
        }
        return false;
    }
  }

  bool _resolveAfterOneShot({required AvatarMotionState fallback}) {
    switch (_logical) {
      case UserActivityState.active:
        _current = AvatarMotion(
          state: AvatarMotionState.exercise,
          actionType: _actionType,
          motionId: _motionId,
          tempo: _tempo,
        );
      case UserActivityState.paused:
        _current = AvatarMotion(
          state: AvatarMotionState.paused,
          actionType: _actionType,
          motionId: _motionId,
          tempo: _tempo,
        );
      case UserActivityState.idle:
        _current = fallback == AvatarMotionState.exercise
            // 起手播完但业务已回 idle:直接收尾
            ? const AvatarMotion(state: AvatarMotionState.finish)
            : _idle();
    }
    return true;
  }

  bool _resolve() {
    final from = _current.state;
    switch (_logical) {
      case UserActivityState.active:
        if (from == AvatarMotionState.idle || _inReaction) {
          _current = AvatarMotion(
            state: AvatarMotionState.windup,
            actionType: _actionType,
            motionId: _motionId,
            tempo: _tempo,
          );
        } else {
          // paused → active 或 exercise 参数变化:直接进 loop
          _current = AvatarMotion(
            state: AvatarMotionState.exercise,
            actionType: _actionType,
            motionId: _motionId,
            tempo: _tempo,
          );
        }
      case UserActivityState.paused:
        _current = AvatarMotion(
          state: AvatarMotionState.paused,
          actionType: _actionType,
          motionId: _motionId,
          tempo: _tempo,
        );
      case UserActivityState.idle:
        if (from == AvatarMotionState.exercise ||
            from == AvatarMotionState.paused) {
          _current = AvatarMotion(
            state: AvatarMotionState.finish,
            actionType: _actionType,
          );
        } else {
          _current = _idle();
        }
    }
    return true;
  }
}
