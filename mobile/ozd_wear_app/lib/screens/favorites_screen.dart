import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget { const FavoritesScreen({super.key}); @override State<FavoritesScreen> createState() => _FavoritesScreenState(); }
class _FavoritesScreenState extends State<FavoritesScreen> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadFavorites()); }
  @override Widget build(BuildContext context) { final state = context.watch<AppState>(); final products = state.favorites.whereType<Map>().map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList(); if (!state.signedIn) return const Center(child: Text('Favorilerinizi görmek için giriş yapın.')); return RefreshIndicator(onRefresh: state.loadFavorites, child: products.isEmpty ? ListView(children: const [Padding(padding: EdgeInsets.symmetric(vertical: 100), child: Center(child: Text('Henüz favori ürününüz yok.')))]) : GridView.builder(padding: const EdgeInsets.all(16), itemCount: products.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63), itemBuilder: (_, i) => ProductCard(product: products[i], onTap: () => Navigator.pushNamed(context, '/product', arguments: products[i])))); }
}
