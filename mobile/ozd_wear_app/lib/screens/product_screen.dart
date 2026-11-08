import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});
  @override State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Future<Product>? _future;
  Product? _item;
  int _selectedImage = 0;
  int _selectedVariation = 0;
  final Map<String, String> _options = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    final fallback = ModalRoute.of(context)?.settings.arguments as Product?;
    _future = fallback == null ? Future.error(const FormatException('Ürün bulunamadı')) : context.read<AppState>().loadProductDetail(fallback);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ürün'), actions: [IconButton(tooltip: 'Favorilere ekle', onPressed: _item == null ? null : () => _toggleFavorite(_item!), icon: const Icon(Icons.favorite_border))]),
    body: FutureBuilder<Product>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData) return Center(child: Text('${snapshot.error ?? 'Ürün yüklenemedi'}'));
        _item = snapshot.data;
        return _buildProduct(snapshot.data!);
      },
    ),
  );

  Widget _buildProduct(Product product) {
    final gallery = <String>[product.image, ...product.images.map((item) => '${item is Map ? item['url'] ?? '' : item}').where((url) => url.isNotEmpty)].toSet().toList();
    final rawVariation = product.variations.isEmpty ? null : product.variations[_selectedVariation.clamp(0, product.variations.length - 1)];
    final variation = rawVariation is Map ? Map<String, dynamic>.from(rawVariation) : <String, dynamic>{};
    final variationId = int.tryParse('${variation['id_variation'] ?? variation['id'] ?? 0}') ?? 0;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
      AspectRatio(aspectRatio: .86, child: gallery.isEmpty ? const Icon(Icons.image_outlined, size: 80) : CachedNetworkImage(imageUrl: gallery[_selectedImage.clamp(0, gallery.length - 1)], fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined))),
      if (gallery.length > 1) SizedBox(height: 74, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(top: 10), itemCount: gallery.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, index) => GestureDetector(onTap: () => setState(() => _selectedImage = index), child: Container(width: 64, decoration: BoxDecoration(border: Border.all(color: _selectedImage == index ? Colors.black : Colors.transparent, width: 2)), child: CachedNetworkImage(imageUrl: gallery[index], fit: BoxFit.cover))))),
      const SizedBox(height: 20), Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      if (product.brand.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(product.brand.toUpperCase(), style: const TextStyle(letterSpacing: 1.2, color: Colors.grey, fontSize: 12))),
      const SizedBox(height: 10), Row(children: [Text('${product.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), if (product.oldPrice > product.price) ...[const SizedBox(width: 8), Text('${product.oldPrice.toStringAsFixed(2)} ₺', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey))]]),
      if (product.variations.isNotEmpty) ...[
        const SizedBox(height: 20), const Text('Beden / renk seçimi', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
        Wrap(spacing: 8, children: List.generate(product.variations.length, (index) { final raw = product.variations[index]; final item = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{}; final label = '${item['label'] ?? item['name'] ?? item['value'] ?? 'Seçenek'}'; final stock = double.tryParse('${item['stock'] ?? 1}') ?? 1; return ChoiceChip(label: Text(stock <= 0 ? '$label (Tükendi)' : label), selected: _selectedVariation == index, onSelected: stock <= 0 ? null : (_) => setState(() => _selectedVariation = index)); })),
      ],
      ..._optionWidgets(product),
      if (product.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(product.description)),
      if (product.extraText.isNotEmpty) _infoCard('Ürün bilgisi', product.extraText),
      if (product.productSet.isNotEmpty) _infoCard('Set içeriği', ((product.productSet['items'] as List?) ?? const []).map((item) => item is Map ? '${item['product_name'] ?? item['name'] ?? ''} × ${item['qty'] ?? 1}' : '$item').join('\n')),
      if (product.cartPromoOffers.isNotEmpty) _infoCard('Kampanyalar', product.cartPromoOffers.map((offer) => offer is Map ? '${offer['title'] ?? offer['name'] ?? 'Kampanya'}' : '$offer').join('\n')),
      if (product.productTabs.isNotEmpty) ...product.productTabs.map((tab) => tab is Map ? _infoCard('${tab['title'] ?? 'Bilgi'}', '${tab['content'] ?? tab['description'] ?? ''}') : const SizedBox.shrink()),
      _buildReviews(product), _buildQuestions(product),
      if (product.relatedProducts.isNotEmpty) _buildRelated(product.relatedProducts),
      const SizedBox(height: 20),
      FilledButton(onPressed: product.inStock ? () => _addToCart(product, variationId) : null, child: Text(product.inStock ? 'Sepete ekle' : 'Tükendi')),
      if (!product.inStock) ...[const SizedBox(height: 8), OutlinedButton.icon(onPressed: () => _stockAlert(product, variationId), icon: const Icon(Icons.notifications_none), label: const Text('Stoğa girince haber ver'))],
      if (product.oldPrice > product.price) ...[const SizedBox(height: 8), TextButton.icon(onPressed: () => _priceAlert(product), icon: const Icon(Icons.trending_down), label: const Text('Fiyat düşünce haber ver'))],
    ]);
  }

  List<Widget> _optionWidgets(Product product) {
    final widgets = <Widget>[];
    for (final raw in product.optionGroups) {
      if (raw is! Map) continue;
      final group = Map<String, dynamic>.from(raw); final key = '${group['id'] ?? group['key'] ?? group['name'] ?? 'option'}'; final values = (group['values'] as List?) ?? const [];
      if (values.isEmpty) continue;
      widgets.add(Padding(padding: const EdgeInsets.only(top: 14), child: DropdownButtonFormField<String>(value: _options[key], decoration: InputDecoration(labelText: '${group['name'] ?? 'Seçenek'}'), items: values.map((value) { final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{}; final text = '${map['label'] ?? map['value'] ?? value}'; return DropdownMenuItem(value: text, child: Text(text)); }).toList(), onChanged: (value) => setState(() => _options[key] = value ?? ''))));
    }
    return widgets;
  }

  Widget _buildReviews(Product product) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (product.rating > 0 || product.reviews.isNotEmpty) ...[
      const Divider(height: 32), Text('Müşteri değerlendirmeleri${product.reviewCount > 0 ? ' (${product.reviewCount})' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      if (product.rating > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('★ ${product.rating.toStringAsFixed(1)} / 5')),
      ...product.reviews.take(10).map((review) { final item = review is Map ? review : <String, dynamic>{}; return ListTile(contentPadding: EdgeInsets.zero, title: Text('${item['title'] ?? 'Değerlendirme'}'), subtitle: Text('${item['comment'] ?? ''}'), trailing: Text('★ ${item['rating'] ?? ''}')); }),
    ],
  ]);

  Widget _buildQuestions(Product product) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Divider(height: 32), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Ürün soruları${product.questions.isNotEmpty ? ' (${product.questions.length})' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), TextButton(onPressed: () => _askQuestion(product), child: const Text('Soru sor'))]),
    if (product.questions.isEmpty) const Text('Henüz cevaplanmış soru yok.'),
    ...product.questions.take(10).map((raw) { final item = raw is Map ? raw : <String, dynamic>{}; return Card(child: ListTile(title: Text('${item['question'] ?? ''}'), subtitle: Text('${item['answer'] ?? ''}'))); }),
  ]);

  Widget _buildRelated(List<dynamic> related) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Divider(height: 32), const Text('Benzer ürünler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 10), SizedBox(height: 220, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: related.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, index) { final raw = related[index]; if (raw is! Map) return const SizedBox.shrink(); final item = Product.fromJson(Map<String, dynamic>.from(raw)); return SizedBox(width: 150, child: GestureDetector(onTap: () => Navigator.pushReplacementNamed(context, '/product', arguments: item), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover, width: double.infinity)), const SizedBox(height: 6), Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis), Text('${item.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.w700))]))); }))]);

  Widget _infoCard(String title, String body) => Card(margin: const EdgeInsets.only(top: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(body)])));

  Future<void> _toggleFavorite(Product product) async { try { await context.read<AppState>().toggleFavorite(product.id); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoriler güncellendi'))); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } }
  Future<void> _addToCart(Product product, int variationId) async { try { await context.read<AppState>().addToCart(product, variationId: variationId, options: _options); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün sepete eklendi'))); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } }

  Future<void> _askQuestion(Product product) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Ürün hakkında soru sor'), content: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: 'Sorunuzu yazın')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Gönder'))]));
    if (text == null || text.isEmpty || !mounted) return;
    try { final result = await context.read<AppState>().api.post('products/${product.id}/questions', body: {'question': text}); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Sorunuz alındı.'}'))); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  Future<void> _priceAlert(Product product) async {
    final email = TextEditingController(text: '${context.read<AppState>().profile['email'] ?? ''}'); final price = TextEditingController(text: product.price.toStringAsFixed(2));
    final data = await showDialog<Map<String, String>>(context: context, builder: (_) => AlertDialog(title: const Text('Fiyat düşünce haber ver'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')), TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Hedef fiyat'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, {'email': email.text.trim(), 'price': price.text.trim()}), child: const Text('Kaydet'))]));
    if (data == null || !mounted) return;
    try { final result = await context.read<AppState>().api.post('price-alert', body: {'product_id': product.id, 'email': data['email'], 'target_price': data['price']}); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Talebiniz kaydedildi.'}'))); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }

  Future<void> _stockAlert(Product product, int variationId) async {
    final controller = TextEditingController(text: '${context.read<AppState>().profile['email'] ?? ''}');
    final email = await showDialog<String>(context: context, builder: (_) => AlertDialog(title: const Text('Stoğa girince haber ver'), content: TextField(controller: controller, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet'))]));
    if (email == null || email.isEmpty || !mounted) return;
    try { final result = await context.read<AppState>().api.post('stock-alert', body: {'product_id': product.id, 'variation_id': variationId, 'email': email}); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Talebiniz kaydedildi.'}'))); } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
  }
}
