CREATE TABLE IF NOT EXISTS `mobile_access_tokens` (
  `id_token` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_user` int unsigned NOT NULL,
  `token_hash` char(64) NOT NULL,
  `token_type` enum('access','refresh') NOT NULL DEFAULT 'access',
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `ip_hash` char(64) NOT NULL DEFAULT '',
  `user_agent` varchar(255) NOT NULL DEFAULT '',
  `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_token`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `user_type` (`id_user`,`token_type`,`revoked_at`),
  KEY `expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mobile_devices` (
  `id_device` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_user` int unsigned NOT NULL,
  `device_id` varchar(128) NOT NULL,
  `platform` enum('android','ios','unknown') NOT NULL DEFAULT 'unknown',
  `push_token` varchar(512) NOT NULL DEFAULT '',
  `marketing_opt_in` tinyint(1) NOT NULL DEFAULT 0,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `last_seen_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_device`),
  UNIQUE KEY `user_device` (`id_user`,`device_id`),
  KEY `push_active` (`active`,`push_token`(128))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mobile_api_logs` (
  `id_log` bigint unsigned NOT NULL AUTO_INCREMENT,
  `id_user` int unsigned NOT NULL DEFAULT 0,
  `route` varchar(120) NOT NULL,
  `method` varchar(8) NOT NULL,
  `status_code` smallint unsigned NOT NULL DEFAULT 200,
  `ip_hash` char(64) NOT NULL DEFAULT '',
  `date_add` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_log`),
  KEY `route_date` (`route`,`date_add`),
  KEY `user_date` (`id_user`,`date_add`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `settings` (`title`, `value`)
VALUES ('OZD_MOBILE_API_ENABLED', '1')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);

INSERT INTO `settings` (`title`, `value`)
VALUES ('OZD_MOBILE_API_VERSION', '1.0.0')
ON DUPLICATE KEY UPDATE `value` = VALUES(`value`);
