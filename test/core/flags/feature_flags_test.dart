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

  test('home sheet layout: 默认空串;有字符串读取器时取远程值', () {
    expect(FeatureFlags.defaults.homeSheetLayout, '');
    expect(FeatureFlags.defaultsMap()[FeatureFlags.keyHomeSheetLayout], '');
    expect(FeatureFlags.fromReader((_) => false).homeSheetLayout, '');
    final flags = FeatureFlags.fromReader(
      (_) => false,
      readString: (key) =>
          key == FeatureFlags.keyHomeSheetLayout ? '{"modules":[]}' : '',
    );
    expect(flags.homeSheetLayout, '{"modules":[]}');
  });

  test('in-memory repository returns what it was given', () async {
    final repo = InMemoryFeatureFlagsRepository(
      const FeatureFlags(authGoogleEnabled: true),
    );
    expect((await repo.load()).authGoogleEnabled, isTrue);
  });
}
