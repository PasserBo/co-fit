import '../domain/welcome_tour_seen_repository.dart';

class InMemoryWelcomeTourSeenRepository implements WelcomeTourSeenRepository {
  InMemoryWelcomeTourSeenRepository({bool seen = false}) : _seen = seen;

  bool _seen;

  /// 测试断言用。
  bool get seen => _seen;

  @override
  Future<bool> isSeen() async => _seen;

  @override
  Future<void> markSeen() async {
    _seen = true;
  }
}
