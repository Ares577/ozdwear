import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late Future<dynamic> future;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() { future = context.read<AppState>().api.get('addresses'); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Adreslerim'), actions: [IconButton(onPressed: () => _edit(), icon: const Icon(Icons.add))]),
        body: FutureBuilder<dynamic>(
          future: future,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
            final payload = snapshot.data is Map ? snapshot.data as Map : const {};
            final rows = ((payload['data'] as List?) ?? const []).whereType<Map>().toList();
            if (rows.isEmpty) return Center(child: FilledButton(onPressed: () => _edit(), child: const Text('İlk adresi ekle')));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final address = rows[index];
                final id = int.tryParse('${address['id_address'] ?? 0}') ?? 0;
                final isDefault = address['is_default'] == 1 || address['is_default'] == true || '${address['is_default']}' == '1';
                return Card(
                  child: ListTile(
                    title: Text('${address['label'] ?? 'Adres'}${isDefault ? ' · Varsayılan' : ''}'),
                    subtitle: Text('${address['full_name'] ?? ''}\n${address['city'] ?? ''} / ${address['district'] ?? ''}\n${address['address_text'] ?? ''}'),
                    isThreeLine: true,
                    onTap: () => _edit(address),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'default') await context.read<AppState>().api.post('addresses/$id', body: {'is_default': 1});
                        if (value == 'delete') await context.read<AppState>().api.delete('addresses/$id', body: {});
                        if (value == 'edit') { await _edit(address); return; }
                        if (mounted) setState(_reload);
                      },
                      itemBuilder: (_) => [
                        if (!isDefault) const PopupMenuItem(value: 'default', child: Text('Varsayılan yap')),
                        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        const PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  Future<void> _edit([Map? existing]) async {
    final id = int.tryParse('${existing?['id_address'] ?? 0}') ?? 0;
    final label = TextEditingController(text: '${existing?['label'] ?? ''}');
    final name = TextEditingController(text: '${existing?['full_name'] ?? ''}');
    final phone = TextEditingController(text: '${existing?['phone'] ?? ''}');
    final city = TextEditingController(text: '${existing?['city'] ?? ''}');
    final district = TextEditingController(text: '${existing?['district'] ?? ''}');
    final text = TextEditingController(text: '${existing?['address_text'] ?? ''}');
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(id > 0 ? 'Adresi düzenle' : 'Yeni adres'),
        content: Form(key: form, child: SingleChildScrollView(child: Column(children: [
          TextFormField(controller: label, decoration: const InputDecoration(labelText: 'Adres başlığı')),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad'), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Telefon'), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          TextFormField(controller: city, decoration: const InputDecoration(labelText: 'İl'), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          TextFormField(controller: district, decoration: const InputDecoration(labelText: 'İlçe'), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
          TextFormField(controller: text, maxLines: 3, decoration: const InputDecoration(labelText: 'Açık adres'), validator: (v) => v!.isEmpty ? 'Zorunlu' : null),
        ])),),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () async { if (!form.currentState!.validate()) return; await context.read<AppState>().api.post(id > 0 ? 'addresses/$id' : 'addresses', body: {'label': label.text, 'full_name': name.text, 'phone': phone.text, 'city': city.text, 'district': district.text, 'address_text': text.text, 'is_default': existing?['is_default'] ?? (id == 0 ? 1 : 0)}); if (context.mounted) Navigator.pop(context, true); }, child: const Text('Kaydet')),
        ],
      ),
    );
    if (saved == true && mounted) setState(_reload);
  }
}
