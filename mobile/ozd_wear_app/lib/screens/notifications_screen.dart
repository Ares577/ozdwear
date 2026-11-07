import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AppState>().loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (state.unreadNotifications > 0)
            TextButton(onPressed: state.markAllNotificationsRead, child: const Text('Tümünü oku')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.loadNotifications,
        child: state.notifications.isEmpty
            ? ListView(children: const [SizedBox(height: 180), Center(child: Text('Henüz bildiriminiz yok.'))])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final item = Map<String, dynamic>.from(state.notifications[index] as Map);
                  final unread = '${item['is_read'] ?? 0}' != '1';
                  final id = (item['id_notification'] as num?)?.toInt() ?? 0;
                  return ListTile(
                    onTap: () => state.markNotificationRead(id),
                    leading: Icon(unread ? Icons.notifications_active : Icons.notifications_none, color: unread ? Colors.black : Colors.grey),
                    title: Text('${item['title'] ?? ''}', style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
                    subtitle: Text('${item['message'] ?? ''}'),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    );
  }
}
