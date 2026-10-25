import '../domain/entity/pending_session_snapshot.dart';
import '../domain/pending_session_repository.dart';

class InMemoryPendingSessionRepository implements PendingSessionRepository {
  PendingSessionSnapshot? _snapshot;

  @override
  Future<PendingSessionSnapshot?> load() async => _snapshot;

  @override
  Future<void> save(PendingSessionSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    _snapshot = null;
  }
}
