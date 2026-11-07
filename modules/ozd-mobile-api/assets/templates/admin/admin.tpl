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
      <div class="mt-3 small text-muted">API adresi: {$mobileApiUrl|escape}</div>
    </div></div>
    <button class="btn btn-primary" name="saveMobileApi" value="1">Kaydet</button>
  </form>
  <div class="card mt-4"><div class="card-body"><h2 class="h5">API kapsamı</h2><p class="mb-0">Kimlik doğrulama, ürünler, kategoriler, sepet, favoriler, adresler, siparişler, cihazlar ve uygulama ayarları.</p></div></div>
</div>
