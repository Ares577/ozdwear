import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final coupon = TextEditingController();
  bool couponBusy = false;
  @override void dispose() { coupon.dispose(); super.dispose(); }
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadCart()); }
  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.cart;
    final items = (data['items'] as List?)?.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() ?? const <Map<String, dynamic>>[];
    return SafeArea(child: RefreshIndicator(onRefresh: state.loadCart, child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      const Text('Sepetim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
      if (items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 70), child: Center(child: Text('Sepetiniz boş.'))) else ...items.map((item) => _cartItem(state, item)),
      const Divider(height: 30), _row('Ara toplam', data['subtotal_formatted'] ?? data['subtotal']), if ((data['discount'] ?? 0).toString() != '0') _row('İndirim', data['discount_formatted'] ?? data['discount']), _row('Kargo', data['shipping_formatted'] ?? data['shipping']), _row('Toplam', data['grand_total_formatted'] ?? data['grand_total'], bold: true),
      if (items.isNotEmpty) ...[
        const SizedBox(height: 16),
        Row(children: [Expanded(child: TextField(controller: coupon, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kupon kodu', border: OutlineInputBorder()))), const SizedBox(width: 8), FilledButton(onPressed: couponBusy ? null : _applyCoupon, child: Text(couponBusy ? '...' : 'Uygula'))]),
        if ('${data['coupon_code'] ?? ''}'.isNotEmpty) TextButton.icon(onPressed: context.read<AppState>().removeCoupon, icon: const Icon(Icons.close), label: Text('Kuponu kaldır: ${data['coupon_code']}')),
      ],
      const SizedBox(height: 18),
      if (items.isNotEmpty) FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())), child: const Text('Ödemeye geç')),
    ])));
  }
  Future<void> _applyCoupon() async {
    if (coupon.text.trim().isEmpty) return;
    setState(() => couponBusy = true);
    final error = await context.read<AppState>().applyCoupon(coupon.text.trim());
    if (!mounted) return;
    setState(() => couponBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Kupon uygulandı.')));
    if (error == null) coupon.clear();
  }
  Widget _cartItem(AppState state, Map<String, dynamic> item) {
    final quantity = double.tryParse('${item['qty']}') ?? 1;
    return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
      SizedBox(width: 76, height: 92, child: CachedNetworkImage(imageUrl: '${item['image_url'] ?? ''}', fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.image_outlined))), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['product_name'] ?? ''}', maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700)), if ('${item['variation_label'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('${item['variation_label']}', style: const TextStyle(color: Colors.grey))), const SizedBox(height: 8), Text('${item['line_total_formatted'] ?? item['line_total'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)), Row(children: [IconButton(onPressed: quantity > 1 ? () => state.updateCartItem(item, quantity - 1) : null, icon: const Icon(Icons.remove_circle_outline)), Text('${item['qty_label'] ?? item['qty'] ?? 1}'), IconButton(onPressed: () => state.updateCartItem(item, quantity + 1), icon: const Icon(Icons.add_circle_outline)), IconButton(onPressed: () => state.removeCartItem(item), icon: const Icon(Icons.delete_outline))])]))
    ])));
  }
  Widget _row(String label, dynamic value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400)), Text('$value', style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600))]));
}
