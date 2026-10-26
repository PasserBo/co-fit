import 'package:cofit/core/flags/feature_flags.dart';
import 'package:cofit/core/flags/feature_flags_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults keep Google login off', () {
    expect(FeatureFlags.defaults.authGoogleEnabled, isFalse);
    expect(
      FeatureFlags.defaultsMap()[FeatureFlags.keyAuthGoogleEnabled],
      false,
    );
  });

  test('fromReader maps remote keys', () {
    final flags = FeatureFlags.fromReader(
      (key) => key == FeatureFlags.keyAuthGoogleEnabled,
    );
    expect(flags.authGoogleEnabled, isTrue);
  });

  test('in-memory repository returns what it was given', () async {
    final repo = InMemoryFeatureFlagsRepository(
      const FeatureFlags(authGoogleEnabled: true),
    );
    expect((await repo.load()).authGoogleEnabled, isTrue);
  });
}
