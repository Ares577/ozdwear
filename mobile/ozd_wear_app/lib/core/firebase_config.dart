import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static FirebaseOptions? get options {
    final apiKey = const String.fromEnvironment('OZD_FIREBASE_API_KEY');
    final projectId = const String.fromEnvironment('OZD_FIREBASE_PROJECT_ID');
    final senderId = const String.fromEnvironment('OZD_FIREBASE_MESSAGING_SENDER_ID');
    final appId = Platform.isIOS
        ? const String.fromEnvironment('OZD_FIREBASE_IOS_APP_ID')
        : const String.fromEnvironment('OZD_FIREBASE_ANDROID_APP_ID');
    if ([apiKey, projectId, senderId, appId].any((value) => value.isEmpty)) return null;
    return FirebaseOptions(apiKey: apiKey, appId: appId, messagingSenderId: senderId, projectId: projectId, iosBundleId: Platform.isIOS ? 'com.ozdwear.app' : null);
  }
}
