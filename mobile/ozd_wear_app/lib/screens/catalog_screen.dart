import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatelessWidget { const CatalogScreen({super.key}); @override Widget build(BuildContext context) { final state = context.watch<AppState>(); return SafeArea(child: Column(children: [AppBar(title: const Text('Ürünler')), Expanded(child: state.products.isEmpty ? Center(child: ElevatedButton(onPressed: state.loadProducts, child: const Text('Ürünleri yükle'))) : GridView.builder(padding: const EdgeInsets.all(16), itemCount: state.products.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63), itemBuilder: (_, i) => ProductCard(product: state.products[i], onTap: () => Navigator.pushNamed(context, '/product', arguments: state.products[i]))))])); } }
