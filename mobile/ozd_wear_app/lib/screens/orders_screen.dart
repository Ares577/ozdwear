import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<dynamic> future;
  @override void initState() { super.initState(); future = context.read<AppState>().api.get('orders'); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Siparişlerim')), body: FutureBuilder<dynamic>(future: future, builder: (_, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
    final payload = snapshot.data is Map ? snapshot.data as Map : const {};
    final rows = ((payload['data'] as List?) ?? const []).whereType<Map>().toList();
    if (rows.isEmpty) return const Center(child: Text('Henüz siparişiniz yok.'));
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) {
      final order = rows[i];
      return Card(child: ListTile(title: Text('#${order['reference'] ?? order['order_reference'] ?? order['id_order'] ?? ''}'), subtitle: Text('${order['status_label'] ?? order['status'] ?? ''}\n${order['date_add'] ?? order['date'] ?? ''}'), isThreeLine: true, trailing: Text('${order['total_formatted'] ?? order['total'] ?? ''}')));
    });
  }));
}
