import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatefulWidget { const ProfileScreen({super.key}); @override State<ProfileScreen> createState() => _ProfileScreenState(); }
class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController(), phone = TextEditingController(), email = TextEditingController(), currentPassword = TextEditingController(), newPassword = TextEditingController();
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final state = context.read<AppState>(); await state.loadProfile(); final p = state.profile; name.text = '${p['user_full_name'] ?? p['full_name'] ?? ''}'; phone.text = '${p['phone'] ?? ''}'; email.text = '${p['email'] ?? ''}'; if (mounted) setState(() => loading = false); }
  @override void dispose() { name.dispose(); phone.dispose(); email.dispose(); currentPassword.dispose(); newPassword.dispose(); super.dispose(); }
  Future<void> _save() async { final error = await context.read<AppState>().saveProfile(fullName: name.text.trim(), phone: phone.text.trim(), email: email.text.trim()); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Profil güncellendi'))); }
  Future<void> _password() async { final error = await context.read<AppState>().changePassword(currentPassword.text, newPassword.text); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Parolanız güncellendi'))); if (error == null) { currentPassword.clear(); newPassword.clear(); } }
  @override Widget build(BuildContext context) { if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator())); return Scaffold(appBar: AppBar(title: const Text('Profilim')), body: ListView(padding: const EdgeInsets.all(20), children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Ad soyad')), const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telefon')), const SizedBox(height: 12), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')), const SizedBox(height: 20), FilledButton(onPressed: _save, child: const Text('Profili kaydet')), const SizedBox(height: 32), const Text('Parola değiştir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), TextField(controller: currentPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut parola')), const SizedBox(height: 12), TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni parola')), const SizedBox(height: 12), OutlinedButton(onPressed: _password, child: const Text('Parolayı güncelle'))])); }
}
