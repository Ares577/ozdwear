import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() { if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) context.read<AppState>().loadMoreProducts(); });
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return SafeArea(child: Column(children: [
      AppBar(title: const Text('Ürünler'), actions: [PopupMenuButton<String>(onSelected: (value) {
        if (value == 'newest' || value == 'price_asc' || value == 'price_desc') state.loadProducts(sort: value);
        else state.loadProducts(filter: value == 'all' ? '' : value);
      }, itemBuilder: (_) => const [
        PopupMenuItem(value: 'all', child: Text('Tüm ürünler')), PopupMenuItem(value: 'newest', child: Text('Yeni ürünler')), PopupMenuItem(value: 'price_asc', child: Text('Fiyat: düşükten yükseğe')), PopupMenuItem(value: 'price_desc', child: Text('Fiyat: yüksekten düşüğe')), PopupMenuItem(value: 'discounted', child: Text('İndirimliler')), PopupMenuItem(value: 'top-rated', child: Text('En beğenilenler')),
      ])]),
      if (state.categories.isNotEmpty) SizedBox(height: 92, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: state.categories.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) {
        final c = Map<String, dynamic>.from(state.categories[i] as Map);
        final id = int.tryParse('${c['id'] ?? c['id_category'] ?? 0}') ?? 0;
        final image = '${c['image_url'] ?? ''}';
        return GestureDetector(onTap: () => state.loadProducts(categoryId: id), child: SizedBox(width: 82, child: Column(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image.isEmpty ? Container(color: Colors.white, child: const Icon(Icons.category_outlined)) : CachedNetworkImage(imageUrl: image, width: 82, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.category_outlined)))),
          const SizedBox(height: 4), Text('${c['name'] ?? c['category_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ])));
      })),
      if (state.brands.isNotEmpty) SizedBox(height: 46, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: state.brands.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) {
        final brand = Map<String, dynamic>.from(state.brands[i] as Map);
        final id = int.tryParse('${brand['id_brand'] ?? brand['id'] ?? 0}') ?? 0;
        return ActionChip(label: Text('${brand['brand_name'] ?? brand['name'] ?? ''}'), onPressed: () => state.loadProducts(brandId: id));
      })),
      Expanded(child: state.loading && state.products.isEmpty ? const Center(child: CircularProgressIndicator()) : state.products.isEmpty ? Center(child: ElevatedButton(onPressed: state.loadProducts, child: const Text('Ürünleri yükle'))) : GridView.builder(controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: state.products.length + (state.loadingMoreProducts ? 1 : 0), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63), itemBuilder: (_, i) { if (i >= state.products.length) return const Center(child: CircularProgressIndicator()); return ProductCard(product: state.products[i], onTap: () => Navigator.pushNamed(context, '/product', arguments: state.products[i])); })),
    ]));
  }
}
