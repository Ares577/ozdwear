import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool popupRequested = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadProducts());
  }

  Future<void> _open(String target) async {
    final uri = Uri.tryParse(target);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!popupRequested && state.popup.isNotEmpty) {
      popupRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPopup(state.popup));
    }
    final logos = (state.bootstrap['logos'] as Map?) ?? const {};
    final headerLogo = ((logos['header'] as Map?)?['url'] ?? '').toString();
    final slidesMap = (state.bootstrap['slides'] as Map?) ?? const {};
    final heroSlides = (slidesMap['hero'] as List?) ?? const [];
    final promoSlides = (slidesMap['promo'] as List?) ?? const [];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.loadProducts,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xfff7f7f5),
            title: headerLogo.isEmpty
                ? Image.asset('assets/branding/ozdwear-logo.png', width: 120, height: 28, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('OZD WEAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)))
                : CachedNetworkImage(imageUrl: headerLogo, height: 28, errorWidget: (_, __, ___) => const Text('OZD WEAR')),
            actions: [IconButton(onPressed: () => Navigator.pushNamed(context, '/search'), icon: const Icon(Icons.search))],
          ),
          if (heroSlides.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 190,
                child: PageView.builder(
                  itemCount: heroSlides.length,
                  itemBuilder: (_, index) {
                    final slide = Map<String, dynamic>.from(heroSlides[index] as Map);
                    final image = '${slide['image_url'] ?? slide['image'] ?? ''}';
                    final target = '${slide['url'] ?? slide['link_url'] ?? slide['link'] ?? slide['target_url'] ?? ''}';
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: GestureDetector(
                        onTap: target.isEmpty ? null : () => _open(target),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black12)),
                              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent]))),
                              Positioned(left: 18, bottom: 16, child: Text('${slide['title'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (promoSlides.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  scrollDirection: Axis.horizontal,
                  itemCount: promoSlides.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final slide = Map<String, dynamic>.from(promoSlides[index] as Map);
                    final image = '${slide['image_url'] ?? slide['image'] ?? ''}';
                    final target = '${slide['url'] ?? slide['link_url'] ?? slide['link'] ?? ''}';
                    return GestureDetector(
                      onTap: target.isEmpty ? null : () => _open(target),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 260,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (image.isNotEmpty) CachedNetworkImage(imageUrl: image, fit: BoxFit.cover) else Container(color: Colors.black12),
                              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black54, Colors.transparent]))),
                              Positioned(left: 12, bottom: 10, child: Text('${slide['title'] ?? slide['subtitle'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 8), child: Text('Yeni sezon', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)))),
          if (state.categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final item = Map<String, dynamic>.from(state.categories[index] as Map);
                    final id = int.tryParse('${item['id'] ?? item['id_category'] ?? 0}') ?? 0;
                    final image = '${item['image_url'] ?? ''}';
                    return GestureDetector(
                      onTap: () => state.loadProducts(categoryId: id),
                      child: SizedBox(
                        width: 94,
                        child: Column(
                          children: [
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image.isEmpty ? Container(color: Colors.white, child: const Icon(Icons.category_outlined)) : CachedNetworkImage(imageUrl: image, width: 94, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.category_outlined)))),
                            const SizedBox(height: 4),
                            Text('${item['name'] ?? item['category_name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (state.loading && state.products.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = state.products[index];
                  return ProductCard(product: product, onTap: () => Navigator.pushNamed(context, '/product', arguments: product));
                }, childCount: state.products.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 14, childAspectRatio: .63),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _showPopup(Map<String, dynamic> campaign) async {
    if (!mounted) return;
    final image = '${campaign['image_url'] ?? ''}';
    final imageLink = '${campaign['image_link_url'] ?? campaign['button_url'] ?? ''}';
    final button = '${campaign['button_text'] ?? ''}';
    final target = imageLink.isNotEmpty ? imageLink : '${campaign['button_url'] ?? ''}';
    await showDialog<void>(context: context, builder: (_) => AlertDialog(
      title: Text('${campaign['title'] ?? ''}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (image.isNotEmpty) GestureDetector(onTap: target.isEmpty ? null : () { Navigator.pop(context); _open(target); }, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover))),
        if ('${campaign['body_html'] ?? ''}'.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${campaign['body_html']}')),
      ])),
      actions: [if (button.isNotEmpty && target.isNotEmpty) TextButton(onPressed: () { Navigator.pop(context); _open(target); }, child: Text(button)), TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat'))],
    ));
  }
}
