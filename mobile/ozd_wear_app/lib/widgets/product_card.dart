import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFavorite = state.favorites.any((item) => item is Map && int.tryParse('${item['id_product'] ?? item['id']}') == product.id);
    return InkWell(
    onTap: onTap,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Stack(children: [
        Container(color: Colors.white, width: double.infinity, child: product.image.isEmpty
          ? const Icon(Icons.image_outlined)
          : CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover, width: double.infinity, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined))),
        if (product.oldPrice > product.price) Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), color: Colors.black, child: const Text('İNDİRİM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)))),
        Positioned(top: 2, right: 2, child: Material(color: Colors.white.withOpacity(.9), shape: const CircleBorder(), child: IconButton(iconSize: 19, tooltip: 'Favorilere ekle', onPressed: state.signedIn ? () => state.toggleFavorite(product.id) : null, icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.black : Colors.black87)))),
        if (!product.inStock) Positioned.fill(child: Container(color: Colors.white70, alignment: Alignment.center, child: const Text('TÜKENDİ', style: TextStyle(fontWeight: FontWeight.w900)))),
      ])),
      const SizedBox(height: 8),
      Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Row(children: [Text('${product.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.w700)), if (product.oldPrice > product.price) ...[const SizedBox(width: 6), Text('${product.oldPrice.toStringAsFixed(2)} ₺', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12))]])
    ])
  );
  }
}
