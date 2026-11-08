import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CmsScreen extends StatefulWidget {
  final String slug;
  final String fallbackTitle;
  const CmsScreen({super.key, required this.slug, required this.fallbackTitle});

  @override
  State<CmsScreen> createState() => _CmsScreenState();
}

class _CmsScreenState extends State<CmsScreen> {
  late Future<dynamic> future;

  @override
  void initState() {
    super.initState();
    future = context.read<AppState>().api.get('cms/${Uri.encodeComponent(widget.slug)}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.fallbackTitle)),
        body: FutureBuilder<dynamic>(
          future: future,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
            final payload = snapshot.data is Map ? snapshot.data as Map : const {};
            final data = payload['data'] is Map ? payload['data'] as Map : const {};
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text('${data['title'] ?? widget.fallbackTitle}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              if ('${data['summary'] ?? ''}'.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('${data['summary']}')),
              const Divider(height: 32),
              SelectableText('${data['content'] ?? ''}', style: const TextStyle(fontSize: 16, height: 1.55)),
            ]);
          },
        ),
      );
}
