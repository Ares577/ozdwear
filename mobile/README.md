# OZD WEAR native mobil uygulaması

Bu teslimat, OZD WEAR veritabanını ve mevcut PHP iş mantığını kullanan native Flutter Android/iOS mağazasıdır. Mağaza ekranlarında WebView, iframe, PWA veya ayrı ürün veritabanı kullanılmaz. Ürünler, varyasyonlar, galeriler, logolar, bannerlar, sepet, favoriler, adresler, kuponlar, siparişler, ödeme yönlendirmesi, bildirimler, sipariş takibi, iptal/iade talepleri ve CMS sayfaları mevcut API üzerinden gelir.

## Sunucu modülü kurulumu

PHP modülünü sunucuya ben kurmadım; kurulum işlemi sunucu sahibine aittir.

1. `ozd-mobile-api-module-final-*.zip` arşivini açın.
2. İçindeki `ozd-mobile-api` klasörünü mevcut sunucudaki `modules/` klasörüne yükleyin.
3. Yönetim panelinde **Modüller → OZD WEAR Mobile API** bölümünden kurup etkinleştirin.
4. Uygulamanın API adresi şu biçimde olmalıdır:
   `https://ozdwear.com/api/module.php?m=ozd-mobile-api&action=api`
5. Modül kurulumu `mobile_access_tokens`, `mobile_devices` ve `mobile_api_logs` tablolarını otomatik oluşturur. SQL dosyasını ayrıca çalıştırmak zorunlu değildir; istenirse `install.sql` yalnızca bu tabloları oluşturur.

## Yerel çalışma

`ozd_wear_app` klasöründe Flutter 3.24 veya üzeri ile:

```text
flutter pub get
flutter analyze
flutter test
flutter run
```

`lib/core/api_client.dart` içindeki API adresini kendi test sunucunuza göre değiştirin. Canlı ödeme veya gerçek müşteri siparişiyle test yapmayın.

## Görsel ve logo akışı

Header/footer/admin logoları, favicon, hero/promo bannerları, kategori kapakları ve ürün galerisindeki tüm URL’ler API’nin `bootstrap`, `categories` ve `products/{id}` cevaplarından alınır. Ürün detayında sunucudaki bütün galeri görselleri korunur. API erişilemezse yalnızca paket içindeki `assets/branding/ozdwear-logo.png` logo yedeği kullanılır.

## Kimlik doğrulama ve ödeme

E-posta/şifre, kayıt, parola sıfırlama, profil/parola güncelleme ve yapılandırılmışsa Google ile giriş desteklenir. Google girişi için sunucudaki mevcut Google Login modülü ve istemci kimliği yapılandırılmış olmalıdır. Checkout toplamı ve stok sunucuda doğrulanır; PayTR gibi mevcut ödeme sağlayıcısının güvenli yönlendirmesi sistem tarayıcısında açılır ve ödeme callback’i sunucuda doğrulanır.

## Push bildirimleri

Firebase üretim ayarları güvenlik nedeniyle arşive konulmamıştır. Android için `google-services.json`, iOS için `GoogleService-Info.plist`, APNs anahtarı ve gerekli GitHub secret’ları eklenmelidir. Uygulama cihaz kimliğini ve FCM token’ını API’ye kaydeder.

## GitHub Actions çıktıları

Android workflow’u debug APK, release APK ve Play Store AAB üretir. iOS workflow’u Apple imzası olmadan teknik unsigned IPA üretir. Apple sertifikası ve provisioning profile olmadan unsigned IPA normal iPhone kurulumu veya App Store yayını değildir. İmzalı iOS çıktılarını üretmek için sertifikalar GitHub Secrets üzerinden ayrıca tanımlanmalıdır.
