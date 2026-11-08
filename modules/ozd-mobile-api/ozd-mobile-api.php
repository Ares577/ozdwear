<?php

if (!defined('IN_SCRIPT') && !defined('IN_ADMIN')) {
	exit;
}

require_once dirname(__DIR__, 2) . '/core/ModuleBase.php';
require_once __DIR__ . '/lib/OzdMobileApiService.php';

class OzdMobileApiModule extends ModuleBase
{
	public string $name = 'ozd-mobile-api';
	public string $title = 'OZD WEAR Mobile API';
	public string $version = '1.0.0';
	public string $description = 'Flutter Android/iOS uygulaması için güvenli mobil API ve cihaz kayıt altyapısı.';
	public string $author = 'OZD WEAR';

	public array $apiActions = [
		'api' => 'api/api.php',
	];

	public function install(): bool
	{
		if (!$this->runSqlFile('install.sql')) {
			return false;
		}
		Settings::set('OZD_MOBILE_API_ENABLED', '1');
		Settings::set('OZD_MOBILE_API_VERSION', '1.0.0');
		OzdMobileApiService::ensureSchema();
		return true;
	}

	public function uninstall(): bool
	{
		return $this->runSqlFile('uninstall.sql');
	}

	public function boot(): void
	{
		OzdMobileApiService::ensureSchema();
		$this->registerAdminMenuLink('Mobil Uygulama', 'system', 18);
	}

	public function adminPage(): void
	{
		global $smarty, $adminToken, $domain;
		$flash = '';
		if (Tools::isSubmit('saveMobileApi') && hash_equals($adminToken, (string) Tools::getValue('token'))) {
			Settings::set('OZD_MOBILE_API_ENABLED', Tools::getValue('enabled') === '1' ? '1' : '0');
			Settings::set('OZD_MOBILE_API_VERSION', trim((string) Tools::getValue('app_version')));
			Settings::set('OZD_MOBILE_ANDROID_URL', trim((string) Tools::getValue('android_url')));
			Settings::set('OZD_MOBILE_IOS_URL', trim((string) Tools::getValue('ios_url')));
			$flash = 'Mobil API ayarları kaydedildi.';
		}
		$deviceCount = (int) DB::getValue('SELECT COUNT(*) FROM mobile_devices WHERE active = 1');
		$androidCount = (int) DB::getValue("SELECT COUNT(*) FROM mobile_devices WHERE active = 1 AND platform = 'android'");
		$iosCount = (int) DB::getValue("SELECT COUNT(*) FROM mobile_devices WHERE active = 1 AND platform = 'ios'");
		$logCount = (int) DB::getValue('SELECT COUNT(*) FROM mobile_api_logs WHERE date_add >= DATE_SUB(NOW(), INTERVAL 24 HOUR)');
		$tokenCount = (int) DB::getValue("SELECT COUNT(*) FROM mobile_access_tokens WHERE token_type = 'access' AND revoked_at IS NULL AND expires_at > NOW()");
		$smarty->assign([
			'mobileApiEnabled' => Settings::get('OZD_MOBILE_API_ENABLED') !== '0',
			'mobileAppVersion' => Settings::get('OZD_MOBILE_API_VERSION') ?: '1.0.0',
			'androidDownloadUrl' => (string) Settings::get('OZD_MOBILE_ANDROID_URL'),
			'iosDownloadUrl' => (string) Settings::get('OZD_MOBILE_IOS_URL'),
			'deviceCount' => $deviceCount,
			'androidDeviceCount' => $androidCount,
			'iosDeviceCount' => $iosCount,
			'apiLogCount' => $logCount,
			'activeTokenCount' => $tokenCount,
			'mobileApiUrl' => rtrim((string) $domain, '/') . '/api/module.php?m=ozd-mobile-api&action=api',
			'flash' => $flash,
		]);
	}
}
