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
		if ($resource === 'popup' && $method === 'GET') self::popup();
		if ($resource === 'newsletter' && $method === 'POST') self::newsletter($data);
		if ($resource === 'cms' && $method === 'GET') self::cms((string) ($parts[1] ?? ''));
		if ($resource === 'blog' && $method === 'GET') self::blog($parts[1] ?? '', $id, $parts[2] ?? '');
		if ($resource === 'track' && $method === 'GET') self::track((string) ($_GET['reference'] ?? ''));
		if ($resource === 'recent-viewed' && $method === 'POST') self::recentViewed($id);
		if ($resource === 'price-alert' && $method === 'POST') self::priceAlert($data);
		if ($resource === 'stock-alert' && $method === 'POST') self::stockAlert($data);
		if ($resource === 'products' && ($parts[2] ?? '') === 'questions') self::questions($method, $id, $data, $user);
		if ($resource === 'products') self::products($method, $id, $data);
		if ($resource === 'reviews' && $method === 'POST') self::review($data, $user);
		if ($resource === 'categories' && $method === 'GET') self::categories();
		if ($resource === 'brands' && $method === 'GET') self::brands();
		if ($resource === 'favorites') self::favorites($method, $id, $user);
		if ($resource === 'cart') self::cart($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'addresses') self::addresses($method, $id, $data, $user);
		if ($resource === 'coupon') self::coupon($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'checkout') self::checkout($method, $parts[1] ?? '', $data, $user);
		if ($resource === 'orders') self::orders($method, $id, $data, $parts[2] ?? '', $user);
		if ($resource === 'returns' && $method === 'GET') self::returns($id, $user);
		if ($resource === 'messages') self::messages($method, $id, $data, $user);
		if ($resource === 'contact' && $method === 'POST') self::contact($data);
		if ($resource === 'notifications') self::notifications($method, $id, $parts[2] ?? '', $user);
		if ($resource === 'devices' && $method === 'POST') self::device($data, $user);
		self::respond(['success' => false, 'message' => 'Mobil API rotası bulunamadı'], 404);
	}

	private static function track(string $reference): void
	{
		$reference = strtoupper(trim($reference));
		if ($reference === '' || strlen($reference) > 64) {
			self::respond(['success' => false, 'message' => 'Sipariş numarası gerekli'], 422);
		}
		$idUser = null;
		$bearer = self::bearer();
		if ($bearer !== '') {
			$row = DB::getRowSafe('mobile_access_tokens', 'token_hash = ? AND token_type = ? AND revoked_at IS NULL AND expires_at > NOW()', [hash('sha256', $bearer), 'access']);
			$idUser = $row ? (int) $row['id_user'] : null;
		}
		$order = Order::trackByReference($reference, $idUser);
		if (!$order) self::respond(['success' => false, 'message' => 'Sipariş bulunamadı'], 404);
		self::respond(['success' => true, 'data' => $order]);
	}

	private static function priceAlert(array $data): void
	{
		if (!Module::isEnabled('alert-price')) {
			self::respond(['success' => false, 'message' => 'Fiyat alarmı etkin değil'], 503);
		}
		if (!class_exists('AlertPriceModule', false)) {
			$file = dirname(__DIR__, 2) . '/alert-price/alert-price.php';
			if (is_file($file)) require_once $file;
		}
		if (!class_exists('AlertPriceModule', false)) {
			self::respond(['success' => false, 'message' => 'Fiyat alarmı servisi bulunamadı'], 503);
		}
		$idUser = self::optionalAuthenticatedUserId();
		$result = AlertPriceModule::subscribe(
			(int) ($data['product_id'] ?? 0),
			(string) ($data['email'] ?? ''),
			(float) ($data['target_price'] ?? $data['price'] ?? 0),
			$idUser
		);
		self::respond($result, !empty($result['success']) ? 201 : 422);
	}

	private static function stockAlert(array $data): void
	{
		if (!Module::isEnabled('alert')) {
			self::respond(['success' => false, 'message' => 'Stok alarmı etkin değil'], 503);
		}
		$file = dirname(__DIR__, 2) . '/alert/lib/AlertService.php';
		if (!class_exists('AlertService', false) && is_file($file)) require_once $file;
		if (!class_exists('AlertService', false)) {
			self::respond(['success' => false, 'message' => 'Stok alarmı servisi bulunamadı'], 503);
		}
		$email = trim((string) ($data['email'] ?? ''));
		$idUser = self::optionalAuthenticatedUserId();
		$result = AlertService::subscribeStockAlert(
			(int) ($data['product_id'] ?? 0),
			$email,
			(int) ($data['variation_id'] ?? 0),
			$idUser
		);
		self::respond($result, !empty($result['success']) ? 201 : 422);
	}

	private static function optionalAuthenticatedUserId(): ?int
	{
		$raw = self::bearer();
		if ($raw === '') return null;
		$row = DB::getRowSafe('mobile_access_tokens', 'token_hash = ? AND token_type = ? AND revoked_at IS NULL AND expires_at > NOW()', [hash('sha256', $raw), 'access']);
		if (!$row) return null;
		$_SESSION['id_user'] = (int) $row['id_user'];
		return (int) $row['id_user'];
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
		if ($action === 'google') {
			if (!class_exists('GoogleLoginModule', false) || !Module::isEnabled('google-login')) {
				self::respond(['success' => false, 'message' => 'Google ile giriş şu anda yapılandırılmamış'], 503);
			}
			$code = trim((string) ($data['code'] ?? ''));
			if ($code === '') self::respond(['success' => false, 'message' => 'Google yetkilendirme kodu gerekli'], 422);
			$google = GoogleLoginModule::exchangeCode($code);
			if (empty($google['success'])) self::respond($google, 401);
			$login = Customer::authWithGoogle((string) ($google['google_id'] ?? ''), (string) ($google['email'] ?? ''), (string) ($google['name'] ?? ''), !empty($google['email_verified']));
			if (!empty($login['pending'])) self::respond($login, 403);
			if (empty($login['success'])) self::respond($login, 401);
			self::respond(['success' => true, 'data' => self::issueTokens(Customer::getId())]);
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
		$themeName = class_exists('Theme', false) ? Theme::resolveActive((string) Settings::get('THEME')) : 'theme4';
		$themeColors = class_exists('Theme', false) ? Theme::getColors($themeName) : [];
		$logos = class_exists('SiteAssets', false) ? SiteAssets::getLogos() : [];
		$googleEnabled = class_exists('GoogleLoginModule', false) && Module::isEnabled('google-login') && trim((string) Settings::get('GOOGLE_CLIENT_ID')) !== '';
		$slides = [];
		if (class_exists('SliderModule', false) && method_exists('SliderModule', 'getList')) {
			$slides = [
				'hero' => SliderModule::getList('hero', true),
				'promo' => SliderModule::getList('promo', true),
			];
		}
		$trustBar = self::optionalServiceCall('trust-bar', 'TrustBarService', 'TrustBarService.php', 'getActiveItems');
		$instagram = self::optionalServiceCall('instagram-gallery', 'InstagramGalleryService', 'InstagramGalleryService.php', 'getActiveItems');
		$stories = self::optionalServiceCall('story', 'StoryModule', 'story.php', 'getList', [true]);
		$menu = self::optionalServiceCall('main-menu', 'MenuService', 'MenuService.php', 'getActiveItems', ['mobile']);
		$homeText = '';
		if (Module::isEnabled('home-text')) {
			$homeText = (string) DB::getValue('SELECT detail FROM home_text WHERE id = 1 LIMIT 1');
		}
		self::respond(['success' => true, 'data' => [
			'app_name' => Settings::get('SITE_NAME') ?: 'OZD WEAR',
			'version' => Settings::get('OZD_MOBILE_API_VERSION') ?: '1.0.0',
			'logos' => $logos,
			'contact' => [
				'phone' => (string) Settings::get('CONTACT_PHONE'),
				'email' => (string) Settings::get('CONTACT_EMAIL'),
				'address' => (string) Settings::get('CONTACT_ADDRESS'),
			],
			'google_login' => ['enabled' => $googleEnabled, 'server_client_id' => $googleEnabled ? (string) Settings::get('GOOGLE_CLIENT_ID') : ''],
			'slides' => $slides,
			'trust_bar' => is_array($trustBar) ? $trustBar : [],
			'instagram_gallery' => is_array($instagram) ? $instagram : [],
			'stories' => is_array($stories) ? $stories : [],
			'mobile_menu' => is_array($menu) ? $menu : [],
			'home_text' => $homeText,
			'theme' => [
				'name' => $themeName,
				'background' => (string) ($themeColors['background'] ?? '#f7f7f5'),
				'ink' => (string) ($themeColors['text'] ?? '#111111'),
				'muted' => (string) ($themeColors['text-muted'] ?? '#767676'),
				'accent' => (string) ($themeColors['primary'] ?? '#111111'),
				'surface' => (string) ($themeColors['surface'] ?? '#ffffff'),
				'border' => (string) ($themeColors['border'] ?? '#e5e5e5'),
			],
		]]);
	}

	private static function optionalServiceCall(string $module, string $class, string $fileName, string $method, array $args = [])
	{
		if (!Module::isEnabled($module)) return [];
		if (!class_exists($class, false)) {
			$base = dirname(__DIR__, 2) . '/' . $module . '/';
			$file = is_file($base . 'lib/' . $fileName) ? $base . 'lib/' . $fileName : $base . $fileName;
			if (is_file($file)) require_once $file;
		}
		if (!class_exists($class, false) || !method_exists($class, $method)) return [];
		try { return $class::$method(...$args); } catch (Throwable $e) { return []; }
	}

	private static function popup(): void
	{
		if (!class_exists('SmartPopupService', false) && Module::isEnabled('smart-popup')) {
			$file = dirname(__DIR__, 2) . '/smart-popup/lib/SmartPopupService.php';
			if (is_file($file)) require_once $file;
		}
		if (class_exists('SmartPopupService', false) && Module::isEnabled('smart-popup')) {
			self::respond(SmartPopupService::decide(['page_url' => '/', 'device' => 'mobile', 'visitor_id' => substr(hash('sha256', (string) ($_SERVER['REMOTE_ADDR'] ?? '') . (string) ($_SERVER['HTTP_USER_AGENT'] ?? '')), 0, 32)]));
		}
		self::respond(['success' => true, 'campaign' => null]);
	}

	private static function newsletter(array $data): void
	{
		if (!Module::isEnabled('newsletter')) self::respond(['success' => false, 'message' => 'Bülten servisi etkin değil'], 503);
		if (!class_exists('NewsletterModule', false)) {
			$file = dirname(__DIR__, 2) . '/newsletter/newsletter.php';
			if (is_file($file)) require_once $file;
		}
		if (!class_exists('NewsletterModule', false)) self::respond(['success' => false, 'message' => 'Bülten servisi bulunamadı'], 503);
		self::respond(NewsletterModule::subscribe((string) ($data['email'] ?? '')));
	}

	private static function cms(string $slug): void
	{
		if (!class_exists('Cms', false)) require_once dirname(__DIR__, 2) . '/core/Cms.php';
		$page = Cms::getBySlug($slug);
		if (!$page) self::respond(['success' => false, 'message' => 'Sayfa bulunamadı'], 404);
		self::respond(['success' => true, 'data' => [
			'slug' => (string) ($page['slug'] ?? $slug),
			'title' => (string) ($page['title'] ?? ''),
			'summary' => (string) ($page['summary'] ?? ''),
			'content' => (string) ($page['desc'] ?? $page['content'] ?? ''),
			'meta_title' => (string) ($page['meta_title'] ?? ''),
			'meta_description' => (string) ($page['meta_description'] ?? ''),
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
			$product['option_groups'] = class_exists('ProductOption', false) ? ProductOption::getForStorefront($id) : ['has_options' => false, 'groups' => []];
			$product['reviews'] = class_exists('ReviewsModule', false) ? ReviewsModule::getApprovedForProduct($id, 50) : [];
			$product['product_questions'] = self::optionalProductQuestions($id);
			$product['product_set'] = self::optionalProductSet($id, $product);
			$product['product_tabs'] = self::optionalProductData('product-tabs', 'ProductTabsService', 'ProductTabsService.php', 'getTabsForProduct', $id);
			$product['siblings'] = self::optionalProductData('product-siblings', 'ProductSiblingsService', 'ProductSiblingsService.php', 'getSiblingsForProduct', $id);
			$product['cart_promo_offers'] = class_exists('CartPromotion', false) ? CartPromotion::getProductPageOffers($basePrice) : [];
			$product['quantity_tiers'] = self::optionalServiceCall('quantity-tiers', 'QuantityTiersService', 'QuantityTiersService.php', 'getStorefrontTiers', [$id, $basePrice]);
			$product['discount_timer'] = self::optionalServiceCall('discount-timer', 'DiscountTimerService', 'DiscountTimerService.php', 'getActiveForProduct', [$id, $product]) ?: [];
			$product['extra_text'] = Module::isEnabled('product-extra-text') ? (string) Settings::get('PRODUCT_EXTRA_TEXT_CONTENT') : '';
			$related = Product::getRelatedForProduct($product, 12);
			$product['related_products'] = array_map(static function (array $row): array { return self::normalizeProductAssets($row); }, (array) ($related['products'] ?? []));
			$product = self::normalizeProductAssets($product);
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
		$rows = array_map(static function (array $row): array {
			return self::normalizeProductAssets($row);
		}, $rows);
		self::respond(['success' => true, 'data' => $rows, 'meta' => ['page' => $page, 'limit' => $limit, 'total' => $total, 'query' => $query]]);
	}

	private static function blog(string $part, int $id, string $subPart): void
	{
		if (!Module::isEnabled('blog')) self::respond(['success' => true, 'data' => []]);
		if (!class_exists('BlogService', false)) {
			$file = dirname(__DIR__, 2) . '/blog/lib/BlogService.php';
			if (is_file($file)) require_once $file;
		}
		if (!class_exists('BlogService', false)) self::respond(['success' => false, 'message' => 'Blog servisi bulunamadı'], 503);
		if ($part === 'category' && ctype_digit($subPart) && (int) $subPart > 0) {
			$id = (int) $subPart;
			$page = max(1, (int) ($_GET['page'] ?? 1));
			$limit = min(50, max(1, (int) ($_GET['limit'] ?? 20)));
			self::respond(['success' => true, 'data' => BlogService::getList(true, $limit, ($page - 1) * $limit, $id), 'meta' => ['page' => $page, 'limit' => $limit, 'category_id' => $id]]);
		}
		if ($id > 0 || $part !== '') {
			$post = $id > 0 ? BlogService::getPublishedById($id) : BlogService::getBySlug($part);
			if (!$post) self::respond(['success' => false, 'message' => 'Blog yazısı bulunamadı'], 404);
			self::respond(['success' => true, 'data' => BlogService::enrich($post)]);
		}
		$page = max(1, (int) ($_GET['page'] ?? 1));
		$limit = min(50, max(1, (int) ($_GET['limit'] ?? 20)));
		self::respond(['success' => true, 'data' => BlogService::getList(true, $limit, ($page - 1) * $limit), 'categories' => BlogService::getCategories(true), 'meta' => ['page' => $page, 'limit' => $limit]]);
	}

	private static function recentViewed(int $idProduct): void
	{
		if ($idProduct <= 0 || !Module::isEnabled('recent-viewed')) self::respond(['success' => true]);
		$file = dirname(__DIR__, 2) . '/recent-viewed/lib/RecentViewedService.php';
		if (!class_exists('RecentViewedService', false) && is_file($file)) require_once $file;
		if (class_exists('RecentViewedService', false)) RecentViewedService::track($idProduct);
		self::respond(['success' => true]);
	}

	private static function questions(string $method, int $idProduct, array $data, ?array $user): void
	{
		if ($idProduct <= 0) self::respond(['success' => false, 'message' => 'Ürün bulunamadı'], 404);
		if (!Module::isEnabled('question')) self::respond(['success' => true, 'data' => []]);
		if (!class_exists('QuestionModule', false)) {
			$file = dirname(__DIR__, 2) . '/question/question.php';
			if (is_file($file)) require_once $file;
		}
		if (!class_exists('QuestionModule', false)) self::respond(['success' => true, 'data' => []]);
		if ($method === 'GET') self::respond(['success' => true, 'data' => QuestionModule::getPublishedForProduct($idProduct, 50)]);
		if (!$user && $method === 'POST' && self::optionalAuthenticatedUserId() !== null) $user = Customer::getCurrent();
		if ($method !== 'POST' || !$user) self::respond(['success' => false, 'message' => 'Soru göndermek için giriş yapmalısınız'], 401);
		if (empty($_SESSION['question_form_started'])) $_SESSION['question_form_started'] = time() - 5;
		$result = QuestionModule::submit($idProduct, (string) ($data['question'] ?? $data['message'] ?? ''), (int) $user['id_user'], []);
		self::respond($result, !empty($result['success']) ? 201 : 422);
	}

	private static function optionalProductQuestions(int $idProduct): array
	{
		if (!Module::isEnabled('question')) return [];
		if (!class_exists('QuestionModule', false)) {
			$file = dirname(__DIR__, 2) . '/question/question.php';
			if (is_file($file)) require_once $file;
		}
		return class_exists('QuestionModule', false) ? QuestionModule::getPublishedForProduct($idProduct, 50) : [];
	}

	private static function optionalProductSet(int $idProduct, array $product): array
	{
		if (!Module::isEnabled('product-set') || empty($product['is_pack'])) return [];
		$file = dirname(__DIR__, 2) . '/product-set/lib/ProductSetService.php';
		if (!class_exists('ProductSetService', false) && is_file($file)) require_once $file;
		if (!class_exists('ProductSetService', false)) return [];
		return [
			'items' => ProductSetService::getItems($idProduct),
			'pricing' => ProductSetService::getPricing($idProduct, $product),
			'available_stock' => ProductSetService::getAvailableStock($idProduct),
		];
	}

	private static function categories(): void
	{
		$rows = DB::execute('SELECT id_category AS id, category_name AS name, category_link AS slug, id_parent AS parent_id FROM categories WHERE active = 1 ORDER BY position ASC, category_name ASC') ?: [];
		$rows = array_map(static function (array $row): array {
			$id = (int) ($row['id'] ?? 0);
			$cover = DB::getValue('SELECT i.id_image FROM products p INNER JOIN images i ON i.id_product = p.id_product AND i.cover = 1 LEFT JOIN product_category pc ON pc.id_product = p.id_product AND pc.id_category = ? WHERE p.active = 1 AND (p.id_category = ? OR pc.id_category IS NOT NULL) ORDER BY p.id_product ASC, i.id_image ASC LIMIT 1', [$id, $id]);
			$row['image_url'] = $cover ? Product::getImageUrl((int) $cover) : Category::getImageUrl($id);
			return $row;
		}, $rows);
		self::respond(['success' => true, 'data' => $rows]);
	}

	private static function review(array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		if (!class_exists('ReviewsModule', false)) self::respond(['success' => false, 'message' => 'Yorum modülü etkin değil'], 503);
		$result = ReviewsModule::submit((int) ($data['product_id'] ?? 0), (int) ($data['rating'] ?? 5), (string) ($data['title'] ?? ''), (string) ($data['comment'] ?? ''), (int) $user['id_user']);
		self::respond($result, !empty($result['success']) ? 201 : 422);
	}

	private static function brands(): void
	{
		self::respond(['success' => true, 'data' => Brand::getPublicList(100)]);
	}

	private static function normalizeProductAssets(array $product): array
	{
		if (empty($product['image_url']) && !empty($product['id_image'])) {
			$product['image_url'] = Product::getImageUrl((int) $product['id_image']);
		}
		$images = [];
		foreach ((array) ($product['images'] ?? []) as $image) {
			if (is_array($image)) {
				$url = (string) ($image['url'] ?? $image['image_url'] ?? '');
				if ($url !== '') {
					$image['url'] = $url;
					$images[] = $image;
				}
			} elseif (trim((string) $image) !== '') {
				$images[] = ['url' => (string) $image];
			}
		}
		if ($images === [] && !empty($product['image_url'])) $images[] = ['url' => (string) $product['image_url'], 'cover' => 1];
		$product['images'] = $images;
		$product['image_url'] = (string) ($product['image_url'] ?? ($images[0]['url'] ?? ''));
		return $product;
	}

	private static function optionalProductData(string $module, string $class, string $fileName, string $method, int $id): array
	{
		if (!Module::isEnabled($module)) return [];
		if (!class_exists($class, false)) {
			$file = dirname(__DIR__, 2) . '/' . $module . '/lib/' . $fileName;
			if (is_file($file)) require_once $file;
		}
		return class_exists($class, false) && method_exists($class, $method) ? (array) $class::$method($id) : [];
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

	private static function orders(string $method, int $id, array $data, string $action, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		$uid = (int) $user['id_user'];
		if ($method === 'GET' && $id > 0) self::respond(['success' => true, 'data' => Order::getByIdForUser($id, $uid)]);
		if ($method === 'POST' && $id > 0 && $action === 'cancel') { CancelRequest::ensureSchema(); self::respond(CancelRequest::create($id, $uid, (string) ($data['message'] ?? ''))); }
		if ($method === 'POST' && $id > 0 && $action === 'return') { ReturnRequest::ensureSchema(); self::respond(ReturnRequest::create($id, $uid, (string) ($data['message'] ?? ''), [])); }
		self::respond(['success' => true, 'data' => Order::getUserOrders($uid)]);
	}

	private static function returns(int $id, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		ReturnRequest::ensureSchema();
		if ($id > 0) {
			$row = ReturnRequest::getByIdForUser($id, (int) $user['id_user']);
			if (!$row) self::respond(['success' => false, 'message' => 'İade talebi bulunamadı'], 404);
			self::respond(['success' => true, 'data' => $row]);
		}
		self::respond(['success' => true, 'data' => ReturnRequest::getUserList((int) $user['id_user'])]);
	}

	private static function messages(string $method, int $idOrder, array $data, ?array $user): void
	{
		if (!$user) self::respond(['success' => false, 'message' => 'Giriş yapmalısınız'], 401);
		if ($method !== 'POST' || $idOrder <= 0) self::respond(['success' => false, 'message' => 'Mesaj işlemi geçersiz'], 405);
		if (!Order::getByIdForUser($idOrder, (int) $user['id_user'])) self::respond(['success' => false, 'message' => 'Sipariş bulunamadı'], 404);
		require_once dirname(__DIR__, 2) . '/core/Contact.php';
		self::respond(Contact::submitOrder($idOrder, (int) $user['id_user'], (string) ($data['message'] ?? ''), ['subject' => (string) ($data['subject'] ?? 'Mobil uygulama mesajı')]));
	}

	private static function contact(array $data): void
	{
		if (!class_exists('Contact', false)) require_once dirname(__DIR__, 2) . '/core/Contact.php';
		$result = Contact::submit([
			'full_name' => (string) ($data['full_name'] ?? ''),
			'email' => (string) ($data['email'] ?? ''),
			'phone' => (string) ($data['phone'] ?? ''),
			'subject' => (string) ($data['subject'] ?? ''),
			'message' => (string) ($data['message'] ?? ''),
		]);
		self::respond($result, !empty($result['success']) ? 201 : 422);
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
		if (in_array($route, ['auth/login', 'auth/register', 'auth/refresh', 'auth/forgot-password', 'auth/reset-password', 'contact', 'track', 'popup', 'newsletter', 'price-alert', 'stock-alert'], true) || $route === 'bootstrap' || $route === 'products' || strpos($route, 'products/') === 0 || $route === 'categories' || $route === 'brands' || strpos($route, 'cms/') === 0 || $route === 'blog' || strpos($route, 'blog/') === 0 || strpos($route, 'recent-viewed/') === 0) return null;
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
