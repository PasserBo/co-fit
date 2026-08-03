import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/avatar/domain/entity/avatar_motion.dart';
import 'package:cofit/features/avatar/presentation/motion/avatar_motion_sequencer.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idle → active plays windup first, then enters exercise loop', () {
    final seq = AvatarMotionSequencer();

    final changed = seq.onLogicalState(
      UserActivityState.active,
      actionType: ActionType.cardio,
    );
    expect(changed, isTrue);
    expect(seq.current.state, AvatarMotionState.windup);

    expect(seq.onOneShotComplete(), isTrue);
    expect(seq.current.state, AvatarMotionState.exercise);
    expect(seq.current.actionType, ActionType.cardio);
  });

  test('active → idle plays finish before returning to idle', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(UserActivityState.active,
          actionType: ActionType.strength)
      ..onOneShotComplete();

    seq.onLogicalState(UserActivityState.idle);
    expect(seq.current.state, AvatarMotionState.finish);

    seq.onOneShotComplete();
    expect(seq.current.state, AvatarMotionState.idle);
  });

  test('pause and resume switch directly without one-shots', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(UserActivityState.active, actionType: ActionType.core)
      ..onOneShotComplete();

    seq.onLogicalState(UserActivityState.paused,
        actionType: ActionType.core);
    expect(seq.current.state, AvatarMotionState.paused);

    seq.onLogicalState(UserActivityState.active, actionType: ActionType.core);
    expect(seq.current.state, AvatarMotionState.exercise);
  });

  test('logical change during windup is deferred until one-shot completes',
      () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(UserActivityState.active,
          actionType: ActionType.cardio);
    expect(seq.current.state, AvatarMotionState.windup);

    // 起手未播完就已回 idle(极短会话)—— 不打断 ×1
    final changed = seq.onLogicalState(UserActivityState.idle);
    expect(changed, isFalse);
    expect(seq.current.state, AvatarMotionState.windup);

    // 起手播完 → 业务已 idle → 直接收尾 finish → idle
    seq.onOneShotComplete();
    expect(seq.current.state, AvatarMotionState.finish);
    seq.onOneShotComplete();
    expect(seq.current.state, AvatarMotionState.idle);
  });

  test('repeated identical logical states do not restart the loop', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(UserActivityState.active,
          actionType: ActionType.strength)
      ..onOneShotComplete();

    final changed = seq.onLogicalState(UserActivityState.active,
        actionType: ActionType.strength);
    expect(changed, isFalse);
    expect(seq.current.state, AvatarMotionState.exercise);
  });

  test('tempo derives from intensity label', () {
    expect(AvatarTempo.fromIntensityLabel('慢速'), AvatarTempo.slow);
    expect(AvatarTempo.fromIntensityLabel('高强度'), AvatarTempo.fast);
    expect(AvatarTempo.fromIntensityLabel('标准'), AvatarTempo.standard);
    expect(AvatarTempo.fromIntensityLabel(null), AvatarTempo.standard);
  });
}
