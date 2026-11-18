import 'package:cofit/features/welcome_tour/data/in_memory_welcome_tour_seen_repository.dart';
import 'package:cofit/features/welcome_tour/data/shared_preferences_welcome_tour_seen_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesWelcomeTourSeenRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to not seen', () async {
      final repo = SharedPreferencesWelcomeTourSeenRepository();
      expect(await repo.isSeen(), isFalse);
    });

    test('markSeen flips to seen', () async {
      final repo = SharedPreferencesWelcomeTourSeenRepository();
      await repo.markSeen();
      expect(await repo.isSeen(), isTrue);
    });

    test('a fresh instance still reads seen (persisted)', () async {
      await SharedPreferencesWelcomeTourSeenRepository().markSeen();
      expect(
        await SharedPreferencesWelcomeTourSeenRepository().isSeen(),
        isTrue,
      );
    });

    test('markSeen is idempotent', () async {
      final repo = SharedPreferencesWelcomeTourSeenRepository();
      await repo.markSeen();
      await repo.markSeen();
      expect(await repo.isSeen(), isTrue);
    });
  });

  group('InMemoryWelcomeTourSeenRepository', () {
    test('defaults to not seen and can be preset', () async {
      expect(await InMemoryWelcomeTourSeenRepository().isSeen(), isFalse);
      expect(
        await InMemoryWelcomeTourSeenRepository(seen: true).isSeen(),
        isTrue,
      );
    });

    test('markSeen flips to seen', () async {
      final repo = InMemoryWelcomeTourSeenRepository();
      await repo.markSeen();
      expect(repo.seen, isTrue);
      expect(await repo.isSeen(), isTrue);
    });
  });
}
