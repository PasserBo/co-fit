import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entity/pending_session_snapshot.dart';
import '../domain/pending_session_repository.dart';

/// shared_preferences 单键存 JSON;解析失败视为无快照并清掉。
class SharedPreferencesPendingSessionRepository
    implements PendingSessionRepository {
  static const _key = 'cofit.pending_session.v1';

  @override
  Future<PendingSessionSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final snapshot = PendingSessionSnapshot.fromMap(jsonDecode(raw));
      if (snapshot == null) {
        await prefs.remove(_key);
      }
      return snapshot;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(PendingSessionSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toMap()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
