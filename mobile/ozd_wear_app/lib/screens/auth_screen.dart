import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final login = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  void dispose() { login.dispose(); password.dispose(); super.dispose(); }

  Future<void> _run(Future<String?> Function() action) async {
    setState(() => busy = true);
    final error = await action();
    if (!mounted) return;
    setState(() => busy = false);
    if (error == null) Navigator.pop(context);
    else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş yap')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        TextField(controller: login, decoration: const InputDecoration(labelText: 'E-posta veya telefon')),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre')),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())), child: const Text('Şifremi unuttum'))),
        const SizedBox(height: 10),
        FilledButton(onPressed: busy ? null : () => _run(() => context.read<AppState>().login(login.text.trim(), password.text)), child: Text(busy ? 'Bekleyin...' : 'Giriş yap')),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: busy ? null : () => _run(context.read<AppState>().loginWithGoogle), icon: const Icon(Icons.account_circle_outlined), label: const Text('Google ile giriş yap')),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text('Yeni hesap oluştur')),
      ]),
    );
  }
}
