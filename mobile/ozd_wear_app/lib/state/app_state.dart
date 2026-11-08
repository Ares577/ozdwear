import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import '../models/product.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/push_service.dart';

class AppState extends ChangeNotifier {
  final SessionStore session = SessionStore();
  late final ApiClient api = ApiClient(session);
  List<Product> products = [];
  bool loading = false;
  bool signedIn = false;
  List<dynamic> favorites = [];
  List<dynamic> categories = [];
  Map<String, dynamic> bootstrap = {};
  Map<String, dynamic> cart = {};
  Map<String, dynamic> profile = {};
  List<dynamic> notifications = [];
  int unreadNotifications = 0;
  bool googleLoginEnabled = false;
  String googleServerClientId = '';
  String? lastError;

  Future<void> hydrateSession() async {
    try {
      final token = await session.accessToken;
      if (token != null && token.isNotEmpty) { await api.get('auth/me'); signedIn = true; await Future.wait([loadProfile(), loadNotifications(), loadFavorites(), loadCart()]); await PushService.register(this); notifyListeners(); }
    } catch (_) { await session.clear(); }
  }

  Future<void> loadBootstrap() async {
    try {
      final result = await api.get('bootstrap');
      bootstrap = Map<String, dynamic>.from((result['data'] as Map?) ?? const {});
      final google = (bootstrap['google_login'] as Map?) ?? const {};
      googleLoginEnabled = google['enabled'] == true;
      googleServerClientId = '${google['server_client_id'] ?? ''}';
      final categoryResult = await api.get('categories');
      categories = (categoryResult['data'] as List?) ?? const [];
      notifyListeners();
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> loadProducts({int categoryId = 0, String filter = '', String sort = 'newest'}) async {
    loading = true; notifyListeners();
    try { final result = await api.get('products', query: {'page': '1', 'limit': '24', if (categoryId > 0) 'category_id': '$categoryId', if (filter.isNotEmpty) 'filter': filter, 'sort': sort}); products = ((result['data'] as List?) ?? []).whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (error) { lastError = error.toString(); } finally { loading = false; notifyListeners(); }
  }

  Future<void> searchProducts(String query) async {
    final result = await api.get('products', query: {'q': query, 'page': '1', 'limit': '50'});
    products = ((result['data'] as List?) ?? []).whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
  }

  Future<Product> loadProductDetail(Product fallback) async {
    try {
      final result = await api.get('products/${fallback.id}');
      final data = result['data'];
      if (data is Map) return Product.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      // Keep the cached list item usable while offline or during a transient error.
    }
    return fallback;
  }

  Future<String?> login(String login, String password) async {
    try { final result = await api.post('auth/login', body: {'login': login, 'password': password}); await session.save(access: result['data']['access_token'], refresh: result['data']['refresh_token']); signedIn = true; await Future.wait([loadProfile(), loadNotifications(), loadFavorites(), loadCart()]); await PushService.register(this); notifyListeners(); return null; } catch (e) { return e.toString(); }
  }
  Future<String?> register(String name, String phone, String email, String password) async {
    try {
      final result = await api.post('auth/register', body: {'full_name': name, 'phone': phone, 'email': email, 'password': password});
      final data = result['data'];
      if (data is Map && data['access_token'] != null) {
        await session.save(access: data['access_token'], refresh: data['refresh_token']);
        signedIn = true;
        await Future.wait([loadProfile(), loadNotifications(), loadFavorites(), loadCart()]);
        await PushService.register(this);
        notifyListeners();
      }
      return null;
    } catch (e) { return e.toString(); }
  }
  Future<String?> forgotPassword(String email) async { try { await api.post('auth/forgot-password', body: {'email': email}); return null; } catch (e) { return e.toString(); } }
  Future<String?> loginWithGoogle() async {
    if (!googleLoginEnabled || googleServerClientId.isEmpty) return 'Google ile giriş yapılandırılmamış';
    try {
      final signIn = GoogleSignIn(scopes: const ['email', 'profile'], serverClientId: googleServerClientId);
      final account = await signIn.signIn();
      if (account == null) return 'Google girişi iptal edildi';
      final code = account.serverAuthCode;
      if (code == null || code.isEmpty) return 'Google yetkilendirme kodu alınamadı';
      final result = await api.post('auth/google', body: {'code': code});
      await session.save(access: result['data']['access_token'], refresh: result['data']['refresh_token']);
      signedIn = true;
      await Future.wait([loadProfile(), loadNotifications(), loadFavorites(), loadCart()]);
      await PushService.register(this);
      notifyListeners();
      return null;
    } catch (e) { return e.toString(); }
  }
  Future<void> logout() async { try { await api.post('auth/logout'); } catch (_) {} await session.clear(); signedIn = false; favorites = []; cart = {}; profile = {}; notifications = []; unreadNotifications = 0; notifyListeners(); }
  Future<void> loadProfile() async { final result = await api.get('profile'); profile = Map<String, dynamic>.from((result['data'] as Map?) ?? const {}); notifyListeners(); }
  Future<String?> saveProfile({required String fullName, required String phone, required String email}) async { try { final result = await api.put('profile', body: {'full_name': fullName, 'phone': phone, 'email': email}); profile = Map<String, dynamic>.from((result['data'] as Map?) ?? const {}); notifyListeners(); return null; } catch (e) { return e.toString(); } }
  Future<String?> changePassword(String current, String next) async { try { await api.post('profile/password', body: {'current_password': current, 'new_password': next}); return null; } catch (e) { return e.toString(); } }
  Future<void> loadNotifications() async { final result = await api.get('notifications'); notifications = (result['data'] as List?) ?? []; unreadNotifications = (result['unread'] as num?)?.toInt() ?? 0; notifyListeners(); }
  Future<void> markNotificationRead(int id) async { if (id > 0) await api.post('notifications/$id/read'); await loadNotifications(); }
  Future<void> markAllNotificationsRead() async { await api.post('notifications/read-all'); await loadNotifications(); }
  Future<void> loadCart() async { final result = await api.get('cart'); cart = Map<String, dynamic>.from((result['data'] as Map?) ?? const {}); notifyListeners(); }
  Future<void> addToCart(Product product, {int variationId = 0}) async { await api.post('cart/add', body: {'product_id': product.id, 'quantity': 1, 'variation_id': variationId}); await loadCart(); }
  Future<void> updateCartItem(Map<String, dynamic> item, double quantity) async { await api.patch('cart/update', body: {'product_id': item['id_product'], 'variation_id': item['id_variation'] ?? 0, 'cart_key': item['cart_key'] ?? '', 'quantity': quantity}); await loadCart(); }
  Future<void> removeCartItem(Map<String, dynamic> item) async { await api.delete('cart/remove', body: {'product_id': item['id_product'], 'variation_id': item['id_variation'] ?? 0, 'cart_key': item['cart_key'] ?? ''}); await loadCart(); }
  Future<void> clearCart() async { await api.delete('cart/clear'); await loadCart(); }
  Future<dynamic> checkoutSummary() => api.get('checkout/summary');
  Future<dynamic> placeOrder(Map<String, dynamic> data) async { final result = await api.post('checkout/order', body: data); await loadCart(); return result; }
  Future<void> loadFavorites() async { final result = await api.get('favorites'); favorites = (result['data'] as List?) ?? []; notifyListeners(); }
  Future<void> toggleFavorite(int productId) async { await api.post('favorites/$productId'); await loadFavorites(); }
}
