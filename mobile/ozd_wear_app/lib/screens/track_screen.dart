import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/app_state.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final controller = TextEditingController();
  Map<String, dynamic>? order;
  String? error;
  bool loading = false;

  Future<void> submit() async {
    final reference = controller.text.trim().toUpperCase();
    if (reference.isEmpty) return;
    setState(() { loading = true; error = null; order = null; });
    try {
      final result = await context.read<AppState>().api.get('track', query: {'reference': reference});
      final data = result['data'];
      if (data is Map) setState(() => order = Map<String, dynamic>.from(data));
    } catch (e) { setState(() => error = e.toString()); }
    if (mounted) setState(() => loading = false);
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sipariş takibi')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Sipariş numaranı yaz', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Örnek: OZD123ABC'),
      const SizedBox(height: 18),
      TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Sipariş numarası', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: loading ? null : submit, icon: const Icon(Icons.search), label: const Text('Siparişi sorgula')),
      if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(error!, style: const TextStyle(color: Colors.red))),
      if (order != null) ...[
        const Divider(height: 36),
        Text('#${order!['reference'] ?? controller.text}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${order!['status_label'] ?? order!['status'] ?? ''}'),
        if ('${order!['tracking_url'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: OutlinedButton.icon(onPressed: () async { final uri = Uri.tryParse('${order!['tracking_url']}'); if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication); }, icon: const Icon(Icons.local_shipping_outlined), label: Text('${order!['cargo_name'] ?? 'Kargo takibini aç'}'))),
      ],
    ]),
  );
  @override void dispose() { controller.dispose(); super.dispose(); }
}
