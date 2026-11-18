import 'package:cofit/features/welcome_tour/data/in_memory_welcome_tour_seen_repository.dart';
import 'package:cofit/features/welcome_tour/domain/welcome_tour_seen_repository.dart';
import 'package:cofit/features/welcome_tour/provider/welcome_tour_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingSeenRepository implements WelcomeTourSeenRepository {
  @override
  Future<bool> isSeen() async => false;

  @override
  Future<void> markSeen() async => throw StateError('disk full');
}

ProviderContainer _container(WelcomeTourSeenRepository repo) {
  final container = ProviderContainer(
    overrides: [welcomeTourSeenRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts loading, then reflects the repository', () async {
    final container = _container(InMemoryWelcomeTourSeenRepository());

    expect(container.read(welcomeTourSeenProvider).isLoading, isTrue);
    expect(await container.read(welcomeTourSeenProvider.future), isFalse);

    final preset = _container(InMemoryWelcomeTourSeenRepository(seen: true));
    expect(await preset.read(welcomeTourSeenProvider.future), isTrue);
  });

  test('markSeen flips state at once and persists', () async {
    final repo = InMemoryWelcomeTourSeenRepository();
    final container = _container(repo);
    await container.read(welcomeTourSeenProvider.future);

    final pending = container.read(welcomeTourSeenProvider.notifier).markSeen();
    // 内存态先于落盘翻转,门控才能立刻切页。
    expect(container.read(welcomeTourSeenProvider).value, isTrue);

    await pending;
    expect(repo.seen, isTrue);
  });

  test('a failed write keeps the in-memory state and does not throw', () async {
    final container = _container(_ThrowingSeenRepository());
    await container.read(welcomeTourSeenProvider.future);

    await container.read(welcomeTourSeenProvider.notifier).markSeen();

    final state = container.read(welcomeTourSeenProvider);
    expect(state.hasError, isFalse);
    expect(state.value, isTrue);
  });
}
