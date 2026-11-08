import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  bool busy = false;
  @override void dispose() { email.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Şifremi unuttum')), body: ListView(padding: const EdgeInsets.all(20), children: [
    const Text('E-posta adresinizi yazın; şifre yenileme bağlantısı gönderelim.'), const SizedBox(height: 18),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta')), const SizedBox(height: 18),
    FilledButton(onPressed: busy ? null : _send, child: Text(busy ? 'Gönderiliyor...' : 'Bağlantı gönder')),
    const SizedBox(height: 12), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen())), child: const Text('Yenileme kodum var')),
  ]));
  Future<void> _send() async { setState(() => busy = true); final error = await context.read<AppState>().forgotPassword(email.text.trim()); if (!mounted) return; setState(() => busy = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'E-posta gönderildi.'))); if (error == null) Navigator.pop(context); }
}
