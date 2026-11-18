import 'package:shared_preferences/shared_preferences.dart';

import '../domain/welcome_tour_seen_repository.dart';

/// shared_preferences 单布尔键;缺省(从未写过)视为未看过。
class SharedPreferencesWelcomeTourSeenRepository
    implements WelcomeTourSeenRepository {
  static const _key = 'cofit.welcome_tour_seen.v1';

  @override
  Future<bool> isSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
