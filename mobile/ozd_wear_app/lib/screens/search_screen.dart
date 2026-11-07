import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget { const SearchScreen({super.key}); @override State<SearchScreen> createState() => _SearchScreenState(); }
class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  @override Widget build(BuildContext context) { final state = context.watch<AppState>(); return Scaffold(appBar: AppBar(title: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Ürün ara', border: InputBorder.none), onSubmitted: (value) { state.searchProducts(value); })), body: GridView.builder(padding: const EdgeInsets.all(16), itemCount: state.products.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63), itemBuilder: (_, i) => ProductCard(product: state.products[i], onTap: () => Navigator.pushNamed(context, '/product', arguments: state.products[i])))); }
}
