import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// Thin wrapper around Firebase Analytics for Picme product events.
final class AppAnalytics {
  AppAnalytics._();

  static final AppAnalytics instance = AppAnalytics._();

  FirebaseAnalytics? _analytics;
  bool _enabled = false;

  Future<void> initialize({required bool firebaseReady}) async {
    if (!firebaseReady) return;
    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _enabled = true;
    } catch (error, stack) {
      debugPrint('Analytics initialization skipped: $error\n$stack');
    }
  }

  Future<void> logPermissionResult(PermissionState state) {
    return _log('permission_result', {'status': _permissionStatus(state)});
  }

  Future<void> logSwipeSessionStart({
    required String category,
    required bool hasFolder,
  }) {
    return _log('swipe_session_start', {
      'category': category,
      'has_folder': hasFolder ? 1 : 0,
    });
  }

  Future<void> logSwipeSessionEnd({
    required int swipeCount,
    required int queueCount,
    required String category,
  }) {
    return _log('swipe_session_end', {
      'swipe_count': swipeCount,
      'queue_count': queueCount,
      'category': category,
    });
  }

  Future<void> logQueueOpened({required int itemCount}) {
    return _log('queue_opened', {'item_count': itemCount});
  }

  Future<void> logQueueDeleteConfirmed({
    required int itemCount,
    required int totalBytes,
  }) {
    return _log('queue_delete_confirmed', {
      'item_count': itemCount,
      'total_bytes': totalBytes,
    });
  }

  Future<void> logSponsoredAdShown({required int serial}) {
    return _log('sponsored_ad_shown', {'serial': serial});
  }

  Future<void> logSponsoredAdLoaded({required int serial}) {
    return _log('sponsored_ad_loaded', {'serial': serial});
  }

  Future<void> logSponsoredAdFailed({required int serial}) {
    return _log('sponsored_ad_failed', {'serial': serial});
  }

  Future<void> logSponsoredAdDismissed({
    required int serial,
    required bool wasUnlocked,
  }) {
    return _log('sponsored_ad_dismissed', {
      'serial': serial,
      'was_unlocked': wasUnlocked ? 1 : 0,
    });
  }

  static String _permissionStatus(PermissionState state) {
    if (state.isAuth) return 'authorized';
    if (state.hasAccess) return 'limited';
    return 'denied';
  }

  Future<void> _log(String name, Map<String, Object> parameters) async {
    if (!_enabled || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event "$name" failed: $error');
    }
  }
}
