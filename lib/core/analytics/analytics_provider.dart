import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_tracker.dart';
import 'firebase_analytics_tracker.dart';

/// Firebase 没初始化(单测、widgetbook)时退回 no-op。
final analyticsTrackerProvider = Provider<AnalyticsTracker>((ref) {
  if (Firebase.apps.isEmpty) {
    return const NoopAnalyticsTracker();
  }
  return FirebaseAnalyticsTracker();
});
