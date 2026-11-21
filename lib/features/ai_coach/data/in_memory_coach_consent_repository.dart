import '../domain/coach_consent_repository.dart';

class InMemoryCoachConsentRepository implements CoachConsentRepository {
  InMemoryCoachConsentRepository({this.consented = false});

  bool consented;

  @override
  Future<bool> hasConsented() async => consented;

  @override
  Future<void> markConsented() async => consented = true;
}
