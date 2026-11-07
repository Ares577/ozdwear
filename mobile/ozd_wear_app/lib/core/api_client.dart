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
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    if (body != null) headers['Content-Type'] = 'application/json';
    final uri = Uri.parse(endpoint).replace(queryParameters: params);
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Client().send(request);
    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
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
