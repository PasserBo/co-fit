import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_tracker.dart';

class FirebaseAnalyticsTracker implements AnalyticsTracker {
  FirebaseAnalyticsTracker({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params.isEmpty ? null : params,
      );
    } catch (e) {
      debugPrint('analytics: $name failed $e');
    }
  }
}
