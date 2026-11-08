import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});
  @override State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  late Future<dynamic> future;
  @override void initState() { super.initState(); future = context.read<AppState>().api.get('returns'); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('İadelerim')), body: FutureBuilder<dynamic>(future: future, builder: (_, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
    if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
    final payload = snapshot.data is Map ? snapshot.data as Map : const {};
    final rows = ((payload['data'] as List?) ?? const []).whereType<Map>().toList();
    if (rows.isEmpty) return const Center(child: Text('Henüz iade talebiniz yok.'));
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) { final row = rows[i]; return Card(child: ListTile(title: Text('Sipariş #${row['reference'] ?? row['id_order'] ?? ''}'), subtitle: Text('${row['status_label'] ?? row['status'] ?? ''}\n${row['date_add'] ?? ''}'), isThreeLine: true, trailing: Text('İade #${row['id_return'] ?? ''}'))); });
  }));
}
