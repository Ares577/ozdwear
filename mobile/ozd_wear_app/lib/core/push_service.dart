import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../state/app_state.dart';
import 'firebase_config.dart';
import 'app_keys.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: FirebaseConfig.options);
  } catch (_) {
    // Firebase can be configured later through build-time defines.
  }
}

class PushService {
  static FirebaseMessaging? _messaging;
  static String? _token;
  static bool _initialized = false;

  static Future<void> initialize(AppState state) async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await Firebase.initializeApp(options: FirebaseConfig.options);
      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      _token = await messaging.getToken();
      if (!_initialized) {
        FirebaseMessaging.onMessage.listen((message) {
          final notification = message.notification;
          final title = notification?.title ?? message.data['title']?.toString() ?? 'OZD WEAR';
          final body = notification?.body ?? message.data['body']?.toString() ?? '';
          if (body.isEmpty) return;
          appMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('$title: $body')));
        });
        messaging.onTokenRefresh.listen((token) async {
          _token = token;
          if (state.signedIn) await register(state);
        });
        _initialized = true;
      }
      if (state.signedIn) await register(state);
    } catch (_) {
      // Firebase configuration is optional during local development.
    }
  }

  static Future<void> register(AppState state) async {
    final token = _token ?? await _messaging?.getToken();
    if (token == null || token.isEmpty || !state.signedIn) return;
    final deviceId = await state.session.getOrCreateDeviceId();
    try {
      await state.api.post('devices', body: {
        'device_id': deviceId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'push_token': token,
        'marketing_opt_in': false,
      });
    } catch (_) {
      // Registration is retried on the next token refresh/app launch.
    }
  }
}
