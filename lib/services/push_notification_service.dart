import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notifications_repository.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService(this._ref);
  final Ref _ref;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  bool _initialized = false;

  String? _lastSyncedToken;
  String? _lastSyncedUserId;

  /// Initializes FCM listeners, requests notification permission, and binds token listeners.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (Android 13+ & iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');

      // 2. Foreground message listener: refresh in-app notification state
      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM message received in foreground: ${message.notification?.title}');
        _ref.invalidate(notificationsListProvider);
      });

      // 3. Listen to token refreshes from Firebase
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed by Firebase: $newToken');
        await syncToken(newToken);
      });

      // 4. Perform initial sync if user session is already active
      final currentToken = await messaging.getToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        await syncToken(currentToken);
      }
    } catch (e) {
      debugPrint('PushNotificationService initialization exception: $e');
    }
  }

  /// Sends the current or provided FCM push token to the Saathira backend API.
  Future<void> syncToken([String? token]) async {
    try {
      final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final session = _ref.read(sessionProvider).value;
      if (session == null || !session.registered || session.user == null) {
        debugPrint('Deferring FCM token sync: user is not yet logged in or registered.');
        return;
      }

      // Skip duplicate API call if already synced for this user & token
      if (_lastSyncedToken == fcmToken && _lastSyncedUserId == session.user!.id) {
        return;
      }

      await _ref.read(notificationsRepositoryProvider).updateFcmToken(fcmToken);
      _lastSyncedToken = fcmToken;
      _lastSyncedUserId = session.user!.id;
      debugPrint('✅ FCM Push Token successfully registered with Saathira backend for user ${session.user?.id}');
    } catch (e) {
      debugPrint('⚠️ Failed to sync FCM token with Saathira backend: $e');
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
