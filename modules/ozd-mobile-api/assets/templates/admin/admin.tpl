<div class="container-fluid py-3">
  <h1 class="h3 mb-3">OZD WEAR Mobil Uygulama</h1>
  {if $flash}<div class="alert alert-success">{$flash|escape}</div>{/if}
  <form method="post">
    <input type="hidden" name="token" value="{$adminToken|escape}">
    <input type="hidden" name="adminToken" value="{$adminToken|escape}">
    <div class="card mb-3"><div class="card-body">
      <label class="form-label">Mobil API durumu</label>
      <select class="form-select" name="enabled"><option value="1" {if $mobileApiEnabled}selected{/if}>Aktif</option><option value="0" {if !$mobileApiEnabled}selected{/if}>Pasif</option></select>
      <label class="form-label mt-3">Minimum uygulama sürümü</label>
      <input class="form-control" name="app_version" value="{$mobileAppVersion|escape}">
      <label class="form-label mt-3">Android yayın / APK bağlantısı</label>
      <input class="form-control" type="url" name="android_url" value="{$androidDownloadUrl|escape}" placeholder="https://...">
      <label class="form-label mt-3">iOS yayın bağlantısı</label>
      <input class="form-control" type="url" name="ios_url" value="{$iosDownloadUrl|escape}" placeholder="https://...">
      <div class="mt-3 small text-muted">API adresi: {$mobileApiUrl|escape}</div>
    </div></div>
    <button class="btn btn-primary" name="saveMobileApi" value="1">Kaydet</button>
  </form>
  <div class="row g-3 mt-1">
    <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted small">Aktif cihaz</div><div class="h3 mb-0">{$deviceCount|escape}</div></div></div></div>
    <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted small">Android / iOS</div><div class="h3 mb-0">{$androidDeviceCount|escape} / {$iosDeviceCount|escape}</div></div></div></div>
    <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted small">Son 24 saat API isteği</div><div class="h3 mb-0">{$apiLogCount|escape}</div></div></div></div>
    <div class="col-md-3"><div class="card"><div class="card-body"><div class="text-muted small">Geçerli erişim oturumu</div><div class="h3 mb-0">{$activeTokenCount|escape}</div></div></div></div>
  </div>
  <div class="card mt-4"><div class="card-body"><h2 class="h5">API kapsamı</h2><p class="mb-0">Kimlik doğrulama, ürünler, kategori/marka, arama, varyasyon, sepet, favoriler, adresler, kupon, ödeme yönlendirmesi, sipariş, kargo takibi, blog, bildirim cihazları, tema ve görsel varlıklar.</p></div></div>
</div>
