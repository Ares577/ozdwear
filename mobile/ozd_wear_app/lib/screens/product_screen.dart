import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int selectedImage = 0;
  int selectedVariation = 0;
  Product? detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (detail != null) return;
    final fallback = ModalRoute.of(context)!.settings.arguments as Product;
    context.read<AppState>().loadProductDetail(fallback).then((value) {
      if (mounted) setState(() => detail = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = detail ?? ModalRoute.of(context)!.settings.arguments as Product;
    final gallery = <String>[
      if (product.image.isNotEmpty) product.image,
      ...product.images.map((item) => item is Map ? '${item['url'] ?? item['image_url'] ?? ''}' : '$item'),
    ].where((url) => url.isNotEmpty).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await context.read<AppState>().toggleFavorite(product.id);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoriler güncellendi')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AspectRatio(
            aspectRatio: .86,
            child: gallery.isEmpty
                ? const Icon(Icons.image_outlined, size: 80)
                : CachedNetworkImage(imageUrl: gallery[selectedImage.clamp(0, gallery.length - 1)], fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined)),
          ),
          if (gallery.length > 1)
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 10),
                itemCount: gallery.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => selectedImage = i),
                  child: Container(width: 64, decoration: BoxDecoration(border: Border.all(color: selectedImage == i ? Colors.black : Colors.transparent, width: 2)), child: CachedNetworkImage(imageUrl: gallery[i], fit: BoxFit.cover)),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          if (product.brand.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(product.brand.toUpperCase(), style: const TextStyle(letterSpacing: 1.2, color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 10),
          Row(children: [Text('${product.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), if (product.oldPrice > product.price) ...[const SizedBox(width: 8), Text('${product.oldPrice.toStringAsFixed(2)} ₺', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey))]]),
          if (product.variations.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Beden / renk seçimi', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(product.variations.length, (i) {
                final item = product.variations[i];
                final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                final label = '${map['label'] ?? map['name'] ?? map['value'] ?? item}';
                return ChoiceChip(label: Text(label), selected: selectedVariation == i, onSelected: (_) => setState(() => selectedVariation = i));
              }),
            ),
          ],
          if (product.description.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(product.description)),
          if (product.rating > 0 || product.reviews.isNotEmpty) ...[
            const Divider(height: 32),
            Text('Müşteri değerlendirmeleri${product.reviewCount > 0 ? ' (${product.reviewCount})' : ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (product.rating > 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text('★ ${product.rating.toStringAsFixed(1)} / 5')),
            ...product.reviews.take(10).map((review) { final item = review is Map ? review : <String, dynamic>{}; return ListTile(contentPadding: EdgeInsets.zero, title: Text('${item['title'] ?? 'Değerlendirme'}'), subtitle: Text('${item['comment'] ?? ''}'), trailing: Text('★ ${item['rating'] ?? ''}')); }),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: product.inStock
                ? () async {
                    final variation = product.variations.isNotEmpty ? product.variations[selectedVariation] : null;
                    final variationId = variation is Map ? int.tryParse('${variation['id_variation'] ?? variation['id'] ?? 0}') ?? 0 : 0;
                    await context.read<AppState>().addToCart(product, variationId: variationId);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün sepete eklendi')));
                  }
                : null,
            child: Text(product.inStock ? 'Sepete ekle' : 'Tükendi'),
          ),
        ],
      ),
    );
  }
}
