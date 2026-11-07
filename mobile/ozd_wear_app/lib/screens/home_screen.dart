import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadProducts()); }
  @override Widget build(BuildContext context) { final state = context.watch<AppState>(); return SafeArea(child: RefreshIndicator(onRefresh: state.loadProducts, child: CustomScrollView(slivers: [SliverAppBar(pinned: true, title: const Text('OZD WEAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)), actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/search'), icon: const Icon(Icons.search))], backgroundColor: const Color(0xfff7f7f5)), const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 8), child: Text('Yeni sezon', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)))), if (state.loading && state.products.isEmpty) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())) else SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, i) { final product = state.products[i]; return ProductCard(product: product, onTap: () => Navigator.pushNamed(context, '/product', arguments: product)); }, childCount: state.products.length), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63))) ]))); }
}
