import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  static const String endpoint = 'https://ozdwear.com/api/module.php';
  final SessionStore session;
  ApiClient(this.session);

  Future<dynamic> get(String route, {Map<String, String>? query}) => _request('GET', route, query: query);
  Future<dynamic> post(String route, {Map<String, dynamic>? body}) => _request('POST', route, body: body);
  Future<dynamic> patch(String route, {Map<String, dynamic>? body}) => _request('PATCH', route, body: body);
  Future<dynamic> put(String route, {Map<String, dynamic>? body}) => _request('PUT', route, body: body);
  Future<dynamic> delete(String route, {Map<String, dynamic>? body}) => _request('DELETE', route, body: body);

  Future<dynamic> _request(String method, String route, {Map<String, String>? query, Map<String, dynamic>? body, bool retry = true, String? bearerOverride}) async {
    final params = <String, String>{'m': 'ozd-mobile-api', 'action': 'api', 'route': route, ...?query};
    final headers = <String, String>{'Accept': 'application/json'};
    final token = bearerOverride ?? await session.accessToken;
    if (token != null && token.isNotEmpty) {
      // X-Authorization is a compatibility fallback for Apache/PHP-FPM hosts
      // that do not forward the standard Authorization header.
      headers['Authorization'] = 'Bearer $token';
      headers['X-Authorization'] = 'Bearer $token';
    }
    if (body != null) headers['Content-Type'] = 'application/json';
    final uri = Uri.parse(endpoint).replace(queryParameters: params);
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final client = http.Client();
    late final http.StreamedResponse response;
    try {
      response = await client.send(request).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      client.close();
      throw const ApiException('Sunucu yanıt vermedi. İnternet bağlantınızı kontrol edin.', 408);
    } catch (_) {
      client.close();
      rethrow;
    }
    final text = await response.stream.bytesToString().timeout(const Duration(seconds: 25), onTimeout: () => throw const ApiException('Sunucu verisi zamanında alınamadı.', 408));
    client.close();
    dynamic decoded;
    try {
      decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    } on FormatException {
      throw ApiException('Sunucudan geçersiz yanıt geldi.', response.statusCode);
    }
    if (response.statusCode == 401 && retry && route != 'auth/refresh') {
      final refresh = await session.refreshToken;
      if (refresh != null && refresh.isNotEmpty) {
        final refreshed = await _request('POST', 'auth/refresh', retry: false, bearerOverride: refresh);
        await session.save(access: refreshed['data']['access_token'], refresh: refreshed['data']['refresh_token']);
        return _request(method, route, query: query, body: body, retry: false);
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? (decoded['message'] ?? 'İstek başarısız') : 'İstek başarısız';
      throw ApiException(message.toString(), response.statusCode);
    }
    if (decoded is Map && decoded['success'] == false) throw ApiException((decoded['message'] ?? 'İşlem başarısız').toString(), response.statusCode);
    return decoded;
  }
}
