import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../state/app_state.dart';

class PushService {
  static Future<void> initialize(AppState state) async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty && state.signedIn) {
        await state.api.post('devices', body: {'device_id': '${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}', 'platform': Platform.isIOS ? 'ios' : 'android', 'push_token': token, 'marketing_opt_in': false});
      }
      FirebaseMessaging.onMessage.listen((_) {});
    } catch (_) {
      // Firebase configuration is optional during local development.
    }
  }
}
