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
/// 不依赖 Flutter —— 动画实现层(vector / 将来 Rive)只消费 [current]。
class AvatarMotionSequencer {
  AvatarMotionSequencer({AvatarMotion? initial})
      : _current = initial ?? AvatarMotion.idle();

  AvatarMotion _current;
  UserActivityState _logical = UserActivityState.idle;
  ActionType? _actionType;
  AvatarTempo _tempo = AvatarTempo.standard;
  bool _pendingResolve = false;

  AvatarMotion get current => _current;

  /// 业务状态更新。返回 true 表示视觉状态发生了变化(需要重启动画)。
  bool onLogicalState(
    UserActivityState state, {
    ActionType? actionType,
    AvatarTempo tempo = AvatarTempo.standard,
  }) {
    final changed = state != _logical ||
        actionType != _actionType ||
        tempo != _tempo;
    _logical = state;
    _actionType = actionType ?? _actionType;
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
        return _resolveAfterOneShot(
          fallback: AvatarMotionState.exercise,
        );
      case AvatarMotionState.finish:
        _pendingResolve = false;
        return _resolveAfterOneShot(fallback: AvatarMotionState.idle);
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
          tempo: _tempo,
        );
      case UserActivityState.paused:
        _current = AvatarMotion(
          state: AvatarMotionState.paused,
          actionType: _actionType,
          tempo: _tempo,
        );
      case UserActivityState.idle:
        _current = fallback == AvatarMotionState.exercise
            // 起手播完但业务已回 idle:直接收尾
            ? const AvatarMotion(state: AvatarMotionState.finish)
            : AvatarMotion.idle();
    }
    return true;
  }

  bool _resolve() {
    final from = _current.state;
    switch (_logical) {
      case UserActivityState.active:
        if (from == AvatarMotionState.idle) {
          _current = AvatarMotion(
            state: AvatarMotionState.windup,
            actionType: _actionType,
            tempo: _tempo,
          );
        } else {
          // paused → active 或 exercise 参数变化:直接进 loop
          _current = AvatarMotion(
            state: AvatarMotionState.exercise,
            actionType: _actionType,
            tempo: _tempo,
          );
        }
      case UserActivityState.paused:
        _current = AvatarMotion(
          state: AvatarMotionState.paused,
          actionType: _actionType,
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
          _current = AvatarMotion.idle();
        }
    }
    return true;
  }
}
