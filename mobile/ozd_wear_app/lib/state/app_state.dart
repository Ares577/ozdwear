import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import '../models/product.dart';

class AppState extends ChangeNotifier {
  final SessionStore session = SessionStore();
  late final ApiClient api = ApiClient(session);
  List<Product> products = [];
  bool loading = false;
  bool signedIn = false;
  List<dynamic> favorites = [];

  Future<void> hydrateSession() async {
    try {
      final token = await session.accessToken;
      if (token != null && token.isNotEmpty) { await api.get('auth/me'); signedIn = true; notifyListeners(); }
    } catch (_) { await session.clear(); }
  }

  Future<void> loadProducts() async {
    loading = true; notifyListeners();
    try { final result = await api.get('products', query: {'page': '1', 'limit': '24'}); products = ((result['data'] as List?) ?? []).whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList(); } finally { loading = false; notifyListeners(); }
  }

  Future<void> searchProducts(String query) async {
    final result = await api.get('products', query: {'q': query, 'page': '1', 'limit': '50'});
    products = ((result['data'] as List?) ?? []).whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
  }

  Future<String?> login(String login, String password) async {
    try { final result = await api.post('auth/login', body: {'login': login, 'password': password}); await session.save(access: result['data']['access_token'], refresh: result['data']['refresh_token']); signedIn = true; notifyListeners(); return null; } catch (e) { return e.toString(); }
  }
  Future<String?> register(String name, String phone, String email, String password) async {
    try {
      final result = await api.post('auth/register', body: {'full_name': name, 'phone': phone, 'email': email, 'password': password});
      final data = result['data'];
      if (data is Map && data['access_token'] != null) {
        await session.save(access: data['access_token'], refresh: data['refresh_token']);
        signedIn = true;
        notifyListeners();
      }
      return null;
    } catch (e) { return e.toString(); }
  }
  Future<void> logout() async { try { await api.post('auth/logout'); } catch (_) {} await session.clear(); signedIn = false; notifyListeners(); }
  Future<void> addToCart(Product product, {int variationId = 0}) async { await api.post('cart/add', body: {'product_id': product.id, 'quantity': 1, 'variation_id': variationId}); }
  Future<void> loadFavorites() async { final result = await api.get('favorites'); favorites = (result['data'] as List?) ?? []; notifyListeners(); }
  Future<void> toggleFavorite(int productId) async { await api.post('favorites/$productId'); await loadFavorites(); }
}
