import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});
  @override State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  Future<dynamic>? _future;
  Map<String, dynamic>? _post;

  @override
  void initState() {
    super.initState();
    _future = context.read<AppState>().api.get('blog');
  }

  @override
  Widget build(BuildContext context) {
    if (_post != null) return _detail(_post!);
    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: FutureBuilder<dynamic>(future: _future, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        final rows = ((snapshot.data?['data'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        if (rows.isEmpty) return const Center(child: Text('Henüz blog yazısı bulunmuyor.'));
        return RefreshIndicator(
          onRefresh: () async { setState(() => _future = context.read<AppState>().api.get('blog')); await _future; },
          child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: rows.length, separatorBuilder: (_, __) => const SizedBox(height: 14), itemBuilder: (_, index) {
            final post = rows[index];
            final image = '${post['cover_url'] ?? ''}';
            return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap: () async {
              try { final result = await context.read<AppState>().api.get('blog/${post['id_blog_post'] ?? post['id'] ?? 0}'); if (mounted) setState(() => _post = Map<String, dynamic>.from((result['data'] as Map?) ?? post)); }
              catch (_) { if (mounted) setState(() => _post = post); }
            }, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (image.isNotEmpty) SizedBox(height: 180, width: double.infinity, child: CachedNetworkImage(imageUrl: image, fit: BoxFit.cover)),
              Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${post['title'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                if ('${post['excerpt'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${post['excerpt']}', maxLines: 3, overflow: TextOverflow.ellipsis)),
                if ('${post['date_formatted'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${post['date_formatted']}', style: const TextStyle(color: Colors.grey, fontSize: 12))),
              ])),
            ])));
          }),
        );
      }),
    );
  }

  Widget _detail(Map<String, dynamic> post) => Scaffold(appBar: AppBar(title: const Text('Blog'), leading: IconButton(onPressed: () => setState(() => _post = null), icon: const Icon(Icons.arrow_back))), body: ListView(padding: const EdgeInsets.all(18), children: [
    if ('${post['cover_url'] ?? ''}'.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(14), child: CachedNetworkImage(imageUrl: '${post['cover_url']}', fit: BoxFit.cover)),
    const SizedBox(height: 18), Text('${post['title'] ?? ''}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
    if ('${post['date_formatted'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${post['date_formatted']}', style: const TextStyle(color: Colors.grey))),
    const SizedBox(height: 18), Text('${post['content'] ?? post['excerpt'] ?? ''}', style: const TextStyle(fontSize: 16, height: 1.5)),
  ]);
}
