import 'package:cofit/features/action/domain/entity/action_type.dart';
import 'package:cofit/features/avatar/domain/entity/avatar_motion.dart';
import 'package:cofit/features/avatar/presentation/motion/avatar_motion_sequencer.dart';
import 'package:cofit/features/room/domain/entity/user_activity_status_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _motionIdTests();
  _groundedTests();
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
      ..onLogicalState(
        UserActivityState.active,
        actionType: ActionType.strength,
      )
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

    seq.onLogicalState(UserActivityState.paused, actionType: ActionType.core);
    expect(seq.current.state, AvatarMotionState.paused);

    seq.onLogicalState(UserActivityState.active, actionType: ActionType.core);
    expect(seq.current.state, AvatarMotionState.exercise);
  });

  test('logical change during windup is deferred until one-shot completes', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(UserActivityState.active, actionType: ActionType.cardio);
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
      ..onLogicalState(
        UserActivityState.active,
        actionType: ActionType.strength,
      )
      ..onOneShotComplete();

    final changed = seq.onLogicalState(
      UserActivityState.active,
      actionType: ActionType.strength,
    );
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

void _motionIdTests() {
  test('same state with a different motionId restarts the exercise loop', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(
        UserActivityState.active,
        actionType: ActionType.strength,
        motionId: 'squat',
      )
      ..onOneShotComplete();
    expect(seq.current.motionId, 'squat');

    final changed = seq.onLogicalState(
      UserActivityState.active,
      actionType: ActionType.strength,
      motionId: 'lunge',
    );
    expect(changed, isTrue);
    expect(seq.current.state, AvatarMotionState.exercise);
    expect(seq.current.motionId, 'lunge');
  });

  test('motionId survives pause and resume', () {
    final seq = AvatarMotionSequencer()
      ..onLogicalState(
        UserActivityState.active,
        actionType: ActionType.core,
        motionId: 'crunch',
      )
      ..onOneShotComplete()
      ..onLogicalState(
        UserActivityState.paused,
        actionType: ActionType.core,
        motionId: 'crunch',
      );
    expect(seq.current.motionId, 'crunch');
    seq.onLogicalState(
      UserActivityState.active,
      actionType: ActionType.core,
      motionId: 'crunch',
    );
    expect(seq.current.state, AvatarMotionState.exercise);
    expect(seq.current.motionId, 'crunch');
  });
}

void _groundedTests() {
  group('今日面板:上台 / 下台(grounded)', () {
    test('待机上台:board ×1 → 站立待机;下台:leave ×1 → 漂浮待机', () {
      final seq = AvatarMotionSequencer();

      expect(seq.onGrounded(true), isTrue);
      expect(seq.current.state, AvatarMotionState.board);
      expect(seq.onOneShotComplete(), isTrue);
      expect(seq.current.state, AvatarMotionState.idle);
      expect(seq.current.grounded, isTrue);

      expect(seq.onGrounded(false), isTrue);
      expect(seq.current.state, AvatarMotionState.leave);
      seq.onOneShotComplete();
      expect(seq.current, AvatarMotion.idle());
    });

    test('react: false 不播反应,直接换待机', () {
      final seq = AvatarMotionSequencer();
      expect(seq.onGrounded(true, react: false), isTrue);
      expect(seq.current.state, AvatarMotionState.idle);
      expect(seq.current.grounded, isTrue);
    });

    test('同值重复调用不产生变化', () {
      final seq = AvatarMotionSequencer();
      expect(seq.onGrounded(false), isFalse);
      seq.onGrounded(true, react: false);
      expect(seq.onGrounded(true), isFalse);
    });

    test('反应进行中掉头:立即到目的地的待机', () {
      final seq = AvatarMotionSequencer()..onGrounded(true);
      expect(seq.current.state, AvatarMotionState.board);

      expect(seq.onGrounded(false), isTrue);
      expect(seq.current, AvatarMotion.idle());
    });

    test('运动中上台不换 clip;做完后回到站立待机', () {
      final seq = AvatarMotionSequencer()
        ..onLogicalState(
          UserActivityState.active,
          actionType: ActionType.strength,
        )
        ..onOneShotComplete();
      final exercising = seq.current;

      expect(seq.onGrounded(true), isFalse);
      expect(seq.current, exercising);

      seq.onLogicalState(UserActivityState.idle);
      expect(seq.current.state, AvatarMotionState.finish);
      seq.onOneShotComplete();
      expect(seq.current.state, AvatarMotionState.idle);
      expect(seq.current.grounded, isTrue);
    });

    test('暂停中下台不换 clip', () {
      final seq = AvatarMotionSequencer()
        ..onGrounded(true, react: false)
        ..onLogicalState(UserActivityState.active, actionType: ActionType.core)
        ..onOneShotComplete()
        ..onLogicalState(UserActivityState.paused, actionType: ActionType.core);
      final paused = seq.current;

      expect(seq.onGrounded(false), isFalse);
      expect(seq.current, paused);
    });

    test('上台反应进行中打出卡:立即进起手,不等反应播完', () {
      final seq = AvatarMotionSequencer()..onGrounded(true);

      expect(
        seq.onLogicalState(
          UserActivityState.active,
          actionType: ActionType.cardio,
        ),
        isTrue,
      );
      expect(seq.current.state, AvatarMotionState.windup);
    });
  });
}
