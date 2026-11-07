<?php
if (!defined('IN_SCRIPT')) exit;
OzdMobileApiService::request((string) Tools::getValue('route', 'bootstrap'));
