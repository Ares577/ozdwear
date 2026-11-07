<?php

class OzdMobileApiService
{
	private static bool $schemaReady = false;

	public static function ensureSchema(): void
	{
		if (self::$schemaReady) return;
		self::$schemaReady = true;
		DB::execute("CREATE TABLE IF NOT EXISTS `mobile_access_tokens` (`id_token` bigint unsigned NOT NULL AUTO_INCREMENT, `id_user` int unsigned NOT NULL, `token_hash` char(64) NOT NULL, `token_type` enum('access','refresh') NOT NULL DEFAULT 'access', `expires_at` datetime NOT NULL, `revoked_at` datetime DEFAULT NULL, `ip_hash` char(64) NOT NULL DEFAULT '', `user_agent` varchar(255) NOT NULL DEFAULT '', `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id_token`), UNIQUE KEY `token_hash` (`token_hash`), KEY `user_type` (`id_user`,`token_type`,`revoked_at`), KEY `expires_at` (`expires_at`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
		DB::execute("CREATE TABLE IF NOT EXISTS `mobile_devices` (`id_device` bigint unsigned NOT NULL AUTO_INCREMENT, `id_user` int unsigned NOT NULL, `device_id` varchar(128) NOT NULL, `platform` enum('android','ios','unknown') NOT NULL DEFAULT 'unknown', `push_token` varchar(512) NOT NULL DEFAULT '', `marketing_opt_in` tinyint(1) NOT NULL DEFAULT 0, `active` tinyint(1) NOT NULL DEFAULT 1, `last_seen_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP, `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id_device`), UNIQUE KEY `user_device` (`id_user`,`device_id`), KEY `push_active` (`active`,`push_token`(128))) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
		DB::execute("CREATE TABLE IF NOT EXISTS `mobile_api_logs` (`id_log` bigint unsigned NOT NULL AUTO_INCREMENT, `id_user` int unsigned NOT NULL DEFAULT 0, `route` varchar(120) NOT NULL, `method` varchar(8) NOT NULL, `status_code` smallint unsigned NOT NULL DEFAULT 200, `ip_hash` char(64) NOT NULL DEFAULT '', `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id_log`), KEY `route_date` (`route`,`date_add`), KEY `user_date` (`id_user`,`date_add`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
	}

	public static function respond(array $payload, int $status = 200): void
	{
		header('Content-Type: application/json; charset=utf-8');
		header('Cache-Control: no-store');
		http_response_code($status);
		echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
	exit;
	}

	public static function input(): array
	{
		$raw = file_get_contents('php://input');
		$data = json_decode($raw ?: '', true);
		return is_array($data) ? $data : $_POST;
	}

	public static function request(string $route): void
	{
		self::ensureSchema();
		header('X-Content-Type-Options: nosniff');
		header('Referrer-Policy: no-referrer');
		$rateIdentifier = 'mobile|' . RateLimit::clientIp();
		if (RateLimit::isLimited(RateLimit::SCOPE_WEBAPI, $rateIdentifier, 240, 60)) self::respond(['success' => false, 'message' => 'Çok fazla istek. Lütfen kısa süre sonra tekrar deneyin.'], 429);
		RateLimit::record(RateLimit::SCOPE_WEBAPI, $rateIdentifier);
		if (Settings::get('OZD_MOBILE_API_ENABLED') === '0') self::respond(['success' => false, 'message' => 'Mobil API kapalı'], 503);
		$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
		$data = self::input();
		$user = self::authenticate($route, $method);
		$parts = array_values(array_filter(explode('/', trim($route, '/'))));
		$resource = strtolower((string) ($parts[0] ?? 'bootstrap'));
		$id = ctype_digit((string) ($parts[1] ?? '')) ? (int) $parts[1] : 0;

		if ($resource === 'auth') self::auth($parts[1] ?? '', $data, $user);
		if ($resource === 'profile') self::profile($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'bootstrap' && $method === 'GET') self::bootstrap();
		if ($resource === 'products') self::products($method, $id, $data);
		if ($resource === 'categories' && $method === 'GET') self::categories();
		if ($resource === 'favorites') self::favorites($method, $id, $user);
		if ($resource === 'cart') self::cart($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'addresses') self::addresses($method, $id, $data, $user);
		if ($resource === 'coupon') self::coupon($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'checkout') self::checkout($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'orders') self::orders($method, $id, $user);
		if ($resource === 'notifications') self::notifications($method, $id, $parts[2] ?? '', $user);
		if ($resource === 'devices' && $method === 'POST') self::device($data, $user);
		self::respond(['success' => false, 'message' => 'Mobil API rotası bulunamadı'], 404);
	}

	private static function auth(string $action, array $data, ?array $user): void
	{
		if ($action === 'login') {
			$result = Customer::login((string) ($data['login'] ?? $data['email'] ?? ''), (string) ($data['password'] ?? ''), false);
			if (empty($result['success'])) self::respond($result, 401);
			self::respond(['success' => true, 'data' => self::issueTokens(Customer::getId())]);
		}
		if ($action === 'register') {
			$result = Customer::register((string) ($data['full_name'] ?? ''), (string) ($data['phone'] ?? ''), (string) ($data['password'] ?? ''), (string) ($data['email'] ?? ''));
			if (empty($result['success'])) self::respond($result, 422);
			if (Customer::getId() > 0) self::respond(['success' => true, 'data' => self::issueTokens(Customer::getId())]);
			self::respond($result, 201);
		}
		if ($action === 'forgot-password') {
			self::respond(Customer::requestPasswordReset((string) ($data['email'] ?? '')));
		}
		if ($action === 'reset-password') {
			self::respond(Customer::resetPassword((string) ($data['token'] ?? ''), (string) ($data['password'] ?? ''), (string) ($data['password_confirmation'] ?? $data['password2'] ?? '')));
		}
		if ($action === 'refresh') {
			$raw = self::bearer();
			$row = DB::getRowSafe('mobile_access_tokens', 'token_hash = ? AND token_type = ? AND revoked_at IS NULL AND expires_at > NOW()', [hash('sha256', $raw), 'refresh']);
			if (!$row) self::respond(['success' => false, 'message' => 'Yenileme oturumu geçersiz'], 401);
			DB::execute('UPDATE mobile_access_tokens SET revoked_at = NOW() WHERE id_token = ?', [(int) $row['id_token']]);
			self::respond(['success' => true, 'data' => self::issueTokens((int) $row['id_user'])]);
		}
		if ($action === 'me') {
			if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
			self::respond(['success' => true, 'data' => Customer::publicUser($user)]);
		}
		if ($action === 'logout') {
			$raw = self::bearer();
			if ($raw !== '') {
				DB::execute('UPDATE mobile_access_tokens SET revoked_at = NOW() WHERE token_hash = ?', [hash('sha256', $raw)]);
			}
			self::respond(['success' => true]);
		}
		self::respond(['success' => false, 'message' => 'Geçersiz kimlik doğrulama işlemi'], 400);
	}

	private static function profile(string $method, string $action, array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		if ($method === 'GET' && $action === '') self::respond(['success' => true, 'data' => Customer::publicUser($user)]);
		if ($method === 'PUT' && $action === '') {
			$result = Customer::updateProfile((string) ($data['full_name'] ?? ''), (string) ($data['phone'] ?? ''), (string) ($data['email'] ?? ''));
			self::respond(['success' => !empty($result['success']), 'data' => Customer::publicUser(Customer::getCurrent()), 'message' => $result['message'] ?? '']);
		}
		if ($method === 'POST' && $action === 'password') self::respond(Customer::updatePassword((string) ($data['current_password'] ?? ''), (string) ($data['new_password'] ?? '')));
		self::respond(['success' => false, 'message' => 'Profil işlemi geçersiz'], 405);
	}

	private static function bootstrap(): void
	{
		$logos = class_exists('SiteAssets', false) ? SiteAssets::getLogos() : [];
		$slides = [];
		if (class_exists('SliderModule', false) && method_exists('SliderModule', 'getList')) {
			$slides = [
				'hero' => SliderModule::getList('hero', true),
				'promo' => SliderModule::getList('promo', true),
			];
		}
		self::respond(['success' => true, 'data' => [
			'app_name' => Settings::get('SITE_NAME') ?: 'OZD WEAR',
			'version' => Settings::get('OZD_MOBILE_API_VERSION') ?: '1.0.0',
			'logos' => $logos,
			'slides' => $slides,
			'theme' => ['background' => '#f7f7f5', 'ink' => '#111111', 'muted' => '#767676', 'accent' => '#111111'],
		]]);
	}

	private static function products(string $method, int $id, array $data): void
	{
		if ($method !== 'GET') self::respond(['success' => false, 'message' => 'Bu ürün işlemi yalnızca okunabilir'], 405);
		if ($id > 0) {
			$product = Product::getById($id);
			if (!$product) self::respond(['success' => false, 'message' => 'Ürün bulunamadı'], 404);
			$product['images'] = Product::getImages($id);
			$basePrice = (float) ($product['price'] ?? $product['price_tax_inc'] ?? 0);
			$product['variations'] = ProductVariation::getForStorefront($id, $basePrice);
			self::respond(['success' => true, 'data' => $product]);
		}
		$page = max(1, (int) ($_GET['page'] ?? 1));
		$limit = min(50, max(1, (int) ($_GET['limit'] ?? 20)));
		$query = trim((string) ($_GET['q'] ?? ''));
		$sort = (string) ($_GET['sort'] ?? 'newest');
		$categoryId = max(0, (int) ($_GET['category_id'] ?? 0));
		$brandId = max(0, (int) ($_GET['brand_id'] ?? 0));
		$filter = (string) ($_GET['filter'] ?? '');
		if ($query !== '') {
			$rows = Product::search($query, $limit, ($page - 1) * $limit, $sort);
		} elseif ($filter === 'discounted') {
			$rows = Product::getDiscountedList($limit, ($page - 1) * $limit, $sort);
		} elseif ($filter === 'top-rated') {
			$rows = Product::getTopRatedList($limit, ($page - 1) * $limit);
		} else {
			$rows = Product::getActiveList($categoryId > 0 ? $categoryId : null, $limit, ($page - 1) * $limit, $sort, $brandId > 0 ? $brandId : null);
		}
		$countSql = 'SELECT COUNT(*) FROM products WHERE active = 1';
		$countParams = [];
		if ($query !== '') { $countSql .= ' AND (product_name LIKE ? OR reference LIKE ?)'; $countParams = ['%' . $query . '%', '%' . $query . '%']; }
		if ($categoryId > 0 && $query === '' && $filter === '') { $countSql .= ' AND id_category = ?'; $countParams[] = $categoryId; }
		if ($brandId > 0 && $query === '' && $filter === '') { $countSql .= ' AND id_brand = ?'; $countParams[] = $brandId; }
		if ($filter === 'discounted') $countSql .= ' AND old_price > price';
		$total = (int) DB::getValue($countSql, $countParams);
		self::respond(['success' => true, 'data' => $rows, 'meta' => ['page' => $page, 'limit' => $limit, 'total' => $total, 'query' => $query]]);
	}

	private static function categories(): void
	{
		$rows = DB::execute('SELECT id_category AS id, category_name AS name, category_link AS slug, id_parent AS parent_id FROM categories WHERE active = 1 ORDER BY position ASC, category_name ASC') ?: [];
		self::respond(['success' => true, 'data' => $rows]);
	}

	private static function favorites(string $method, int $id, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		if ($method === 'POST' && $id > 0) self::respond(Favorite::toggle($id));
		if ($method === 'DELETE' && $id > 0) self::respond(Favorite::remove($id));
		self::respond(['success' => true, 'data' => Favorite::getList((int) $user['id_user'])]);
	}

	private static function cart(string $method, string $action, array $data, ?array $user): void
	{
		if ($method === 'POST' && $action === 'add') self::respond(Cart::add((int) ($data['product_id'] ?? 0), (float) ($data['quantity'] ?? 1), (int) ($data['variation_id'] ?? 0), (array) ($data['options'] ?? [])));
		if ($method === 'PATCH' && $action === 'update') self::respond(Cart::update((int) ($data['product_id'] ?? 0), (float) ($data['quantity'] ?? 1), (int) ($data['variation_id'] ?? 0), (string) ($data['cart_key'] ?? '')));
		if ($method === 'DELETE' && $action === 'remove') self::respond(Cart::remove((int) ($data['product_id'] ?? 0), (int) ($data['variation_id'] ?? 0), (string) ($data['cart_key'] ?? '')));
		if ($method === 'DELETE' && $action === 'clear') self::respond(Cart::clear());
		self::respond(['success' => true, 'data' => Cart::getSummary()]);
	}

	private static function coupon(string $method, string $action, array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		$cart = Cart::getSummary();
		if ($method === 'POST' && $action === 'apply') self::respond(Coupon::apply((string) ($data['code'] ?? ''), (float) ($cart['total'] ?? 0)));
		if ($method === 'DELETE' && $action === 'remove') self::respond(Coupon::remove());
		self::respond(['success' => true, 'data' => Coupon::getCheckoutSummary((float) ($cart['total'] ?? 0), $cart)]);
	}

	private static function checkout(string $method, string $action, array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		if ($method === 'GET' && $action === 'summary') {
			$cart = Cart::getSummary();
			self::respond(['success' => true, 'data' => ['cart' => $cart, 'addresses' => Address::getListForUser((int) $user['id_user']), 'cargo' => class_exists('Cargo', false) ? Cargo::getList(true) : [], 'payments' => array_keys(Module::getPaymentMethods())]]);
		}
		if ($method === 'POST' && $action === 'order') {
			$allowed = ['id_address','customer_name','customer_phone','customer_email','address_city','address_district','address_text','note','company_name','tax_office','tax_number','payment_method','id_cargo','accept_terms','save_address','address_label','set_default_address','gift_wrap'];
			$orderData = [];
			foreach ($allowed as $key) if (array_key_exists($key, $data)) $orderData[$key] = $data[$key];
			$orderData['_stored_id_user'] = (int) $user['id_user'];
			self::respond(Order::place($orderData), 201);
		}
		self::respond(['success' => false, 'message' => 'Checkout işlemi geçersiz'], 405);
	}

	private static function addresses(string $method, int $id, array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		$uid = (int) $user['id_user'];
		if ($method === 'GET') self::respond(['success' => true, 'data' => Address::getListForUser($uid)]);
		if ($method === 'POST') self::respond(Address::save($uid, $data, $id), 201);
		if ($method === 'DELETE') self::respond(Address::delete($id, $uid));
		self::respond(['success' => false, 'message' => 'Adres işlemi geçersiz'], 405);
	}

	private static function orders(string $method, int $id, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		$uid = (int) $user['id_user'];
		if ($method === 'GET' && $id > 0) self::respond(['success' => true, 'data' => Order::getByIdForUser($id, $uid)]);
		self::respond(['success' => true, 'data' => Order::getUserOrders($uid)]);
	}

	private static function notifications(string $method, int $id, string $action, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		$idUser = (int) $user['id_user'];
		if ($method === 'GET') self::respond(['success' => true, 'data' => Notification::getListForUser($idUser, 100), 'unread' => Notification::getUnreadCount($idUser)]);
		if ($method === 'POST' && $action === 'read-all') { Notification::markAllRead($idUser); self::respond(['success' => true, 'unread' => 0]); }
		if ($method === 'POST' && $action === 'read' && $id > 0) self::respond(['success' => Notification::markRead($id, $idUser), 'unread' => Notification::getUnreadCount($idUser)]);
		self::respond(['success' => false, 'message' => 'Bildirim işlemi geçersiz'], 405);
	}

	private static function device(array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		DB::execute('INSERT INTO mobile_devices (id_user,device_id,platform,push_token,marketing_opt_in,last_seen_at) VALUES (?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE platform=VALUES(platform),push_token=VALUES(push_token),marketing_opt_in=VALUES(marketing_opt_in),active=1,last_seen_at=NOW()', [(int) $user['id_user'], substr((string) ($data['device_id'] ?? ''), 0, 128), in_array(($data['platform'] ?? ''), ['android','ios'], true) ? $data['platform'] : 'unknown', substr((string) ($data['push_token'] ?? ''), 0, 512), !empty($data['marketing_opt_in']) ? 1 : 0]);
		self::respond(['success' => true]);
	}

	private static function authenticate(string $route, string $method): ?array
	{
		if (in_array($route, ['auth/login', 'auth/register', 'auth/refresh', 'auth/forgot-password', 'auth/reset-password'], true) || $route === 'bootstrap' || $route === 'products' || strpos($route, 'products/') === 0 || $route === 'categories') return null;
		$raw = self::bearer();
		if ($raw === '') self::respond(['success' => false, 'message' => 'Bearer token gerekli'], 401);
		$row = DB::getRowSafe('mobile_access_tokens', 'token_hash = ? AND token_type = ? AND revoked_at IS NULL AND expires_at > NOW()', [hash('sha256', $raw), 'access']);
		if (!$row) self::respond(['success' => false, 'message' => 'Oturum geçersiz veya süresi dolmuş'], 401);
		$_SESSION['id_user'] = (int) $row['id_user'];
		$user = Customer::getCurrent();
		if (!$user) self::respond(['success' => false, 'message' => 'Kullanıcı bulunamadı'], 401);
		return $user;
	}

	private static function bearer(): string
	{
		$header = trim((string) ($_SERVER['HTTP_AUTHORIZATION'] ?? ''));
		return preg_match('/^Bearer\s+(.+)$/i', $header, $m) ? trim($m[1]) : '';
	}

	private static function issueTokens(int $idUser): array
	{
		$tokens = [];
		foreach ([['access', 3600], ['refresh', 7776000]] as [$type, $ttl]) {
			$raw = bin2hex(random_bytes(32));
			DB::insert('mobile_access_tokens', ['id_user' => $idUser, 'token_hash' => hash('sha256', $raw), 'token_type' => $type, 'expires_at' => date('Y-m-d H:i:s', time() + $ttl), 'ip_hash' => hash('sha256', (string) ($_SERVER['REMOTE_ADDR'] ?? '')), 'user_agent' => substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255)]);
			$tokens[$type . '_token'] = $raw;
		}
		return ['user' => Customer::publicUser(Customer::getCurrent()), 'access_token' => $tokens['access_token'], 'refresh_token' => $tokens['refresh_token'], 'expires_in' => 3600];
	}
}
