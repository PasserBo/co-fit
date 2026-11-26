import 'package:shared_preferences/shared_preferences.dart';

import '../domain/push_offer_store.dart';

class SharedPreferencesPushOfferStore implements PushOfferStore {
  static const _key = 'cofit.push_offer_declined_at.v1';

  @override
  Future<DateTime?> lastDeclinedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> markDeclined(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, at.millisecondsSinceEpoch);
  }
}
