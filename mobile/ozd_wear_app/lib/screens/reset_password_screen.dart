import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialToken;
  const ResetPasswordScreen({super.key, this.initialToken = ''});
  @override State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController token;
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool busy = false;
  @override void initState() { super.initState(); token = TextEditingController(text: widget.initialToken); }
  @override void dispose() { token.dispose(); password.dispose(); confirmation.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Şifreyi yenile')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('E-postadaki yenileme kodunu ve yeni parolanızı girin.'), const SizedBox(height: 18), TextField(controller: token, decoration: const InputDecoration(labelText: 'Yenileme kodu')), const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni parola')), const SizedBox(height: 12), TextField(controller: confirmation, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni parola tekrar')), const SizedBox(height: 20), FilledButton(onPressed: busy ? null : _submit, child: Text(busy ? 'Güncelleniyor...' : 'Parolayı güncelle'))]));
  Future<void> _submit() async { if (token.text.trim().isEmpty || password.text.isEmpty || password.text != confirmation.text) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod ve parola alanlarını doğru doldurun.'))); return; } setState(() => busy = true); final error = await context.read<AppState>().resetPassword(token.text.trim(), password.text, confirmation.text); if (!mounted) return; setState(() => busy = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Parolanız güncellendi.'))); if (error == null) Navigator.pop(context); }
}
