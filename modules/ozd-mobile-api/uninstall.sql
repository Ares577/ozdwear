DROP TABLE IF EXISTS `mobile_api_logs`;
DROP TABLE IF EXISTS `mobile_devices`;
DROP TABLE IF EXISTS `mobile_access_tokens`;
DELETE FROM `settings` WHERE `setting_key` IN ('OZD_MOBILE_API_ENABLED', 'OZD_MOBILE_API_VERSION');
