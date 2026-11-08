# OZD WEAR Mobile API server patch

The web bootstrap currently enforces browser-session CSRF before dispatching `/api/module.php`.
Native clients authenticate with `Authorization: Bearer ...`, so that request must be exempted from browser CSRF validation.

Apply the following logic inside `Security::isCsrfExemptRequest()` in `core/Security.php`, within the `/api/module.php` branch and before webhook checks:

```php
$queryModule = strtolower(trim((string) ($_GET['m'] ?? '')));
if ($queryModule === 'ozd-mobile-api' && $queryAction === 'api') {
    return true;
}
```

This exemption is limited to the OZD mobile API dispatcher. Authorization and ownership checks remain enforced by `OzdMobileApiService` for protected routes.
