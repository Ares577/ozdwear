import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Container(color: Colors.white, width: double.infinity, child: product.image.isEmpty ? const Icon(Icons.image_outlined) : CachedNetworkImage(imageUrl: product.image, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined)))), const SizedBox(height: 8), Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('${product.price.toStringAsFixed(2)} ₺', style: const TextStyle(fontWeight: FontWeight.w700))]));
}
