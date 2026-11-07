import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<dynamic> future;
  int? addressId;
  int? cargoId;
  String payment = '';
  bool accepted = false;
  bool busy = false;
  @override void initState() { super.initState(); future = context.read<AppState>().checkoutSummary(); }

  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ödeme')), body: FutureBuilder<dynamic>(future: future, builder: (_, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
    final payload = snapshot.data is Map ? snapshot.data as Map : const {};
    final data = payload['data'] is Map ? payload['data'] as Map : const {};
    final addresses = ((data['addresses'] as List?) ?? const []).whereType<Map>().toList();
    final cargo = ((data['cargo'] as List?) ?? const []).whereType<Map>().toList();
    final payments = ((data['payments'] as List?) ?? const []).map((e) => '$e').toList();
    addressId ??= addresses.isNotEmpty ? int.tryParse('${addresses.first['id_address'] ?? addresses.first['id']}') : null;
    cargoId ??= cargo.isNotEmpty ? int.tryParse('${cargo.first['id_cargo'] ?? cargo.first['id']}') : null;
    payment = payment.isEmpty && payments.isNotEmpty ? payments.first : payment;
    return ListView(padding: const EdgeInsets.all(18), children: [
      _section('Teslimat adresi', addresses.isEmpty ? const Text('Kayıtlı adres bulunamadı.') : DropdownButtonFormField<int>(value: addressId, items: addresses.map((a) { final id = int.tryParse('${a['id_address'] ?? a['id']}') ?? 0; return DropdownMenuItem(value: id, child: Text('${a['label'] ?? a['address_label'] ?? a['city'] ?? 'Adres'}')); }).toList(), onChanged: (value) => setState(() => addressId = value))),
      _section('Kargo', cargo.isEmpty ? const Text('Varsayılan kargo uygulanacak.') : DropdownButtonFormField<int>(value: cargoId, items: cargo.map((c) { final id = int.tryParse('${c['id_cargo'] ?? c['id']}') ?? 0; return DropdownMenuItem(value: id, child: Text('${c['name'] ?? c['cargo_name'] ?? c}')); }).toList(), onChanged: (value) => setState(() => cargoId = value))),
      _section('Ödeme yöntemi', payments.isEmpty ? const Text('Ödeme yöntemi bulunamadı.') : DropdownButtonFormField<String>(value: payment.isEmpty ? null : payment, items: payments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: (value) => setState(() => payment = value ?? ''))),
      CheckboxListTile(value: accepted, onChanged: (value) => setState(() => accepted = value == true), title: const Text('Mesafeli satış ve gizlilik şartlarını kabul ediyorum.')),
      const SizedBox(height: 12), FilledButton(onPressed: busy ? null : () => _submit(addressId, cargoId, payment), child: Text(busy ? 'Sipariş oluşturuluyor...' : 'Siparişi tamamla')),
    ]);
  }));

  Widget _section(String title, Widget child) => Card(margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 10), child])));

  Future<void> _submit(int? address, int? cargo, String paymentMethod) async {
    if (!accepted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devam etmek için sözleşmeleri kabul edin.'))); return; }
    setState(() => busy = true);
    try {
      final result = await context.read<AppState>().placeOrder({'id_address': address, 'id_cargo': cargo, 'payment_method': paymentMethod, 'accept_terms': 1});
      if (!mounted) return;
      final message = (result is Map ? result['message'] : null) ?? 'Sipariş oluşturuldu.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message')));
      Navigator.pop(context);
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); } finally { if (mounted) setState(() => busy = false); }
  }
}
