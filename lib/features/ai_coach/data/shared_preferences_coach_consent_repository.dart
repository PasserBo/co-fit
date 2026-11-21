import 'package:shared_preferences/shared_preferences.dart';

import '../domain/coach_consent_repository.dart';

/// shared_preferences 单布尔键;缺省视为未同意。说明文案有实质变化时升版本号。
class SharedPreferencesCoachConsentRepository
    implements CoachConsentRepository {
  static const _key = 'cofit.ai_coach_consent.v1';

  @override
  Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markConsented() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
