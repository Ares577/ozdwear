import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});
  @override State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? product;
  int selectedImage = 0;
  int selectedVariation = 0;
  int reviewRating = 5;
  final reviewTitle = TextEditingController();
  final reviewComment = TextEditingController();
  final Map<String, String> selectedOptions = {};
  bool loading = true;
  bool reviewBusy = false;

  @override
  void dispose() { reviewTitle.dispose(); reviewComment.dispose(); super.dispose(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (product != null) return;
    final fallback = ModalRoute.of(context)?.settings.arguments as Product?;
    if (fallback == null) return;
    product = fallback;
    _loadDetail(fallback);
  }

  Future<void> _loadDetail(Product fallback) async {
    try {
      final loaded = await context.read<AppState>().loadProductDetail(fallback);
      if (mounted) setState(() { product = loaded; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitReview(Product item) async {
    if (reviewComment.text.trim().length < 10) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum en az 10 karakter olmalı.'))); return; }
    setState(() => reviewBusy = true);
    try {
      final result = await context.read<AppState>().api.post('reviews', body: {'product_id': item.id, 'rating': reviewRating, 'title': reviewTitle.text.trim(), 'comment': reviewComment.text.trim()});
      if (!mounted) return;
      reviewTitle.clear(); reviewComment.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Yorumunuz alındı.'}')));
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
    finally { if (mounted) setState(() => reviewBusy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final item = product;
    if (item == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final gallery = <String>[item.image, ...item.images.map((value) => value is Map ? '${value['url'] ?? ''}' : '$value')].where((url) => url.isNotEmpty).toSet().toList();
    final variation = item.variations.isNotEmpty && selectedVariation < item.variations.length && item.variations[selectedVariation] is Map
        ? Map<String, dynamic>.from(item.variations[selectedVariation] as Map) : const <String, dynamic>{};
    final price = double.tryParse('${variation['price'] ?? item.price}') ?? item.price;
    final selectedInStock = variation.isEmpty || variation['in_stock'] == null || variation['in_stock'] == true || variation['in_stock'] == 1;
    final optionData = item.optionGroups;
    return Scaffold(
      appBar: AppBar(title: const Text('Ürün'), actions: [
        IconButton(onPressed: () async {
          try { await context.read<AppState>().toggleFavorite(item.id); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoriler güncellendi'))); }
          catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
        }, icon: const Icon(Icons.favorite_border)),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        AspectRatio(aspectRatio: .86, child: gallery.isEmpty ? const Icon(Icons.image_outlined, size: 80) : CachedNetworkImage(imageUrl: gallery[selectedImage < gallery.length ? selectedImage : 0], fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined))),
        if (gallery.length > 1) SizedBox(height: 74, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(top: 10), itemCount: gallery.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, index) => GestureDetector(onTap: () => setState(() => selectedImage = index), child: Container(width: 64, decoration: BoxDecoration(border: Border.all(color: selectedImage == index ? Colors.black : Colors.transparent, width: 2)), child: CachedNetworkImage(imageUrl: gallery[index], fit: BoxFit.cover))))),
        const SizedBox(height: 20),
        Text(item.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        if (item.brand.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(item.brand.toUpperCase(), style: const TextStyle(letterSpacing: 1.2, color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 10),
        Row(children: [Text('${price.toStringAsFixed(2)} ₺${item.saleUnit == 'piece' ? '' : ' / ${item.saleUnit}'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), if (item.oldPrice > price) ...[const SizedBox(width: 8), Text('${item.oldPrice.toStringAsFixed(2)} ₺', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey))]]),
        if (item.variations.isNotEmpty) ...[
          const SizedBox(height: 20), const Text('Beden / renk seçimi', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
          Wrap(spacing: 8, children: List.generate(item.variations.length, (index) { final value = item.variations[index]; final label = value is Map ? '${value['label'] ?? value['name'] ?? value['value'] ?? 'Seçenek'}' : '$value'; final stock = value is Map ? (int.tryParse('${value['stock'] ?? 1}') ?? 1) : 1; return ChoiceChip(label: Text(stock > 0 ? label : '$label (Tükendi)'), selected: selectedVariation == index, onSelected: stock > 0 ? (_) => setState(() => selectedVariation = index) : null); })),
        ],
        if (optionData.isNotEmpty) ...[
          const SizedBox(height: 20), const Text('Ürün seçenekleri', style: TextStyle(fontWeight: FontWeight.w700)),
          ...optionData.whereType<Map>().map((group) { final name = '${group['name'] ?? ''}'; final values = ((group['values'] as List?) ?? const []).map((value) => '$value').toList(); return Padding(padding: const EdgeInsets.only(top: 10), child: DropdownButtonFormField<String>(value: selectedOptions[name], decoration: InputDecoration(labelText: name, border: const OutlineInputBorder()), items: values.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() { if (value != null) selectedOptions[name] = value; }))); }),
        ],
        if (item.isM2) const Padding(padding: EdgeInsets.only(top: 14), child: Text('Bu ürün ölçüye göre hesaplanır. Genişlik ve uzunluk bilgilerini ödeme adımında kontrol edin.')),
        if (item.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(item.description)),
        if (item.rating > 0 || item.reviews.isNotEmpty) ...[
          const Divider(height: 32), Text('Müşteri değerlendirmeleri${item.reviewCount > 0 ? ' (${item.reviewCount})' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (item.rating > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('★ ${item.rating.toStringAsFixed(1)} / 5')),
          ...item.reviews.take(10).map((review) { final value = review is Map ? review : <String, dynamic>{}; return ListTile(contentPadding: EdgeInsets.zero, title: Text('${value['title'] ?? 'Değerlendirme'}'), subtitle: Text('${value['comment'] ?? ''}'), trailing: Text('★ ${value['rating'] ?? ''}')); }),
        ],
        if (context.watch<AppState>().signedIn) ...[
          const Divider(height: 32), const Text('Değerlendirme yaz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8), Wrap(spacing: 4, children: List.generate(5, (index) => IconButton(onPressed: () => setState(() => reviewRating = index + 1), icon: Icon(index < reviewRating ? Icons.star : Icons.star_border), color: Colors.black))),
          TextField(controller: reviewTitle, decoration: const InputDecoration(labelText: 'Başlık')), const SizedBox(height: 8),
          TextField(controller: reviewComment, maxLines: 4, decoration: const InputDecoration(labelText: 'Yorumunuz', border: OutlineInputBorder())), const SizedBox(height: 10),
          FilledButton(onPressed: reviewBusy ? null : () => _submitReview(item), child: Text(reviewBusy ? 'Gönderiliyor...' : 'Yorumu gönder')),
        ],
        if (item.relatedProducts.isNotEmpty) ...[
          const Divider(height: 34), const Text('Bunları da beğenebilirsiniz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 12),
          SizedBox(height: 245, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: item.relatedProducts.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, index) {
            final related = item.relatedProducts[index];
            if (related is! Map) return const SizedBox.shrink();
            final relatedProduct = Product.fromJson(Map<String, dynamic>.from(related));
            return SizedBox(width: 150, child: ProductCard(product: relatedProduct, onTap: () => Navigator.pushReplacementNamed(context, '/product', arguments: relatedProduct)));
          })),
        ],
        const SizedBox(height: 20),
        FilledButton(onPressed: item.inStock && selectedInStock ? () async { try { final options = <String, String>{...selectedOptions}; await context.read<AppState>().addToCart(item, variationId: int.tryParse('${variation['id_variation'] ?? variation['id'] ?? 0}') ?? 0, options: options); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün sepete eklendi'))); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } } : null, child: Text(!item.inStock || !selectedInStock ? 'Tükendi' : 'Sepete ekle')),
      ]),
    );
  }
}
