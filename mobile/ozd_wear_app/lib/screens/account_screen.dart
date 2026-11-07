import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';
import 'orders_screen.dart';
import 'addresses_screen.dart';

class AccountScreen extends StatelessWidget { const AccountScreen({super.key}); @override Widget build(BuildContext context) { final state = context.watch<AppState>(); if (!state.signedIn) return Center(child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())), child: const Text('Giriş yap'))); return ListView(padding: const EdgeInsets.all(20), children: [const Text('Hesabım', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Sipariş, adres ve hesap ayarlarınızı yönetin.'), const SizedBox(height: 16), ListTile(title: const Text('Siparişlerim'), leading: const Icon(Icons.receipt_long_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))), ListTile(title: const Text('Adreslerim'), leading: const Icon(Icons.location_on_outlined), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))), ListTile(title: const Text('Çıkış yap'), leading: const Icon(Icons.logout), onTap: state.logout)]); } }
