/// 「最近运动记录会发送给 AI 服务」说明的设备级同意标记。
/// 实现:data/shared_preferences_coach_consent_repository.dart(线上)、
/// data/in_memory_coach_consent_repository.dart(测试)。
abstract class CoachConsentRepository {
  Future<bool> hasConsented();
  Future<void> markConsented();
}
