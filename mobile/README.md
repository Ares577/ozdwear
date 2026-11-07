# OZD WEAR mobil uygulaması

Bu klasör, web sitesinin veritabanını kullanan native Flutter Android/iOS uygulamasını içerir. WebView veya ayrı bir ürün veritabanı kullanılmaz.

## Sunucu kurulumu

1. `modules/ozd-mobile-api` klasörünü mevcut sunucudaki `modules/` dizinine yükleyin.
2. Yönetim panelinde **Modüller → OZD WEAR Mobile API** modülünü kurup etkinleştirin.
3. API adresi şu yapıda olmalıdır: `https://ozdwear.com/api/module.php?m=ozd-mobile-api&action=api`.

## Yerel geliştirme

Flutter 3.24.x, Android SDK ve Xcode gereklidir. `mobile/ozd_wear_app` içinde `flutter pub get`, ardından `flutter analyze` ve `flutter test` çalıştırılır.

## GitHub Actions

Android workflow'u debug APK, release APK ve AAB üretir. iOS workflow'u Apple imzası olmadan teknik unsigned IPA üretir. App Store veya normal iPhone kurulumu için Apple sertifikası ve provisioning profile gereklidir; bu bilgiler kaynak koda konulmamalıdır.

Firebase push bildirimleri için Android `google-services.json`, iOS `GoogleService-Info.plist`, APNs anahtarı ve GitHub secret yapılandırması ayrıca yapılmalıdır. Bu dosyalar güvenlik nedeniyle pakete dahil edilmemiştir.
