import 'package:cofit/features/auth/presentation/unauthenticated_stage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UnauthenticatedStage resolve({
    bool invite = false,
    required AsyncValue<bool> seen,
  }) {
    return resolveUnauthenticatedStage(
      hasPendingInvite: invite,
      tourSeen: seen,
    );
  }

  test('seen flag still loading → splash (never flash the login page)', () {
    expect(resolve(seen: const AsyncLoading()), UnauthenticatedStage.splash);
  });

  test('not seen → welcome tour', () {
    expect(
      resolve(seen: const AsyncData(false)),
      UnauthenticatedStage.welcomeTour,
    );
  });

  test('seen → login', () {
    expect(resolve(seen: const AsyncData(true)), UnauthenticatedStage.login);
  });

  test('flag unreadable → login (treat as a returning user)', () {
    expect(
      resolve(seen: AsyncError(StateError('boom'), StackTrace.empty)),
      UnauthenticatedStage.login,
    );
  });

  test('a pending invite wins over everything', () {
    for (final seen in <AsyncValue<bool>>[
      const AsyncLoading(),
      const AsyncData(false),
      const AsyncData(true),
    ]) {
      expect(
        resolve(invite: true, seen: seen),
        UnauthenticatedStage.login,
        reason: '$seen',
      );
    }
  });
}
