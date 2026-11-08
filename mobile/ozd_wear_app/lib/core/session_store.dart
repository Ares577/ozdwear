import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

class SessionStore {
  static const _accessKey = 'ozd_access_token';
  static const _refreshKey = 'ozd_refresh_token';
  static const _deviceIdKey = 'ozd_device_id';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(18, (_) => Random.secure().nextInt(256));
    final id = 'ozd-${base64UrlEncode(bytes).replaceAll('=', '')}';
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
