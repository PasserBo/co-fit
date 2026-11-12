import 'package:cofit/features/auth/presentation/user_bootstrap_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only ready/failed are settled (gate may open on them)', () {
    for (final phase in UserBootstrapPhase.values) {
      expect(
        phase.isSettled,
        phase == UserBootstrapPhase.ready || phase == UserBootstrapPhase.failed,
        reason: '$phase',
      );
    }
  });

  test('every phase has a splash label', () {
    for (final phase in UserBootstrapPhase.values) {
      expect(phase.splashLabel, isNotEmpty, reason: '$phase');
    }
  });

  test('initial state keeps the gate closed; copyWith can open it', () {
    final initial = UserBootstrapState.initial();
    expect(initial.isGateOpen, isFalse);
    expect(initial.phase, UserBootstrapPhase.idle);

    final ready = initial.copyWith(
      phase: UserBootstrapPhase.ready,
      isGateOpen: true,
    );
    expect(ready.isGateOpen, isTrue);
    expect(ready.phase.isSettled, isTrue);
  });
}
