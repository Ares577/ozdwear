import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'addresses_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'contact_screen.dart';
import 'cms_screen.dart';
import 'track_screen.dart';
import 'returns_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.signedIn) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())), child: const Text('Giriş yap')),
      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackScreen())), child: const Text('Sipariş takibi')),
      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen())), child: const Text('İletişim')),
      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CmsScreen(slug: 'gizlilik', fallbackTitle: 'Gizlilik ve KVKK'))), child: const Text('Gizlilik ve KVKK')),
    ]));
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Hesabım', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Sipariş, adres ve hesap ayarlarınızı yönetin.'), const SizedBox(height: 16),
      ListTile(title: const Text('Profilim ve parola'), leading: const Icon(Icons.person_outline), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
      ListTile(title: Text('Bildirimler${state.unreadNotifications > 0 ? ' (${state.unreadNotifications})' : ''}'), leading: const Icon(Icons.notifications_none), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
      ListTile(title: const Text('Siparişlerim'), leading: const Icon(Icons.receipt_long_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
      ListTile(title: const Text('Sipariş takibi'), leading: const Icon(Icons.local_shipping_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackScreen()))),
      ListTile(title: const Text('İadelerim'), leading: const Icon(Icons.assignment_return_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnsScreen()))),
      ListTile(title: const Text('Adreslerim'), leading: const Icon(Icons.location_on_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
      ListTile(title: const Text('İletişim'), leading: const Icon(Icons.mail_outline), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen()))),
      ListTile(title: const Text('Gizlilik ve KVKK'), leading: const Icon(Icons.privacy_tip_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CmsScreen(slug: 'gizlilik', fallbackTitle: 'Gizlilik ve KVKK')))),
      ListTile(title: const Text('Mesafeli satış sözleşmesi'), leading: const Icon(Icons.description_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CmsScreen(slug: 'mesafeli-satis', fallbackTitle: 'Mesafeli satış sözleşmesi')))),
      ListTile(title: const Text('Çıkış yap'), leading: const Icon(Icons.logout), onTap: state.logout),
    ]);
  }
}
