import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final subject = TextEditingController();
  final message = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    name.dispose(); email.dispose(); phone.dispose(); subject.dispose(); message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (name.text.isEmpty && state.profile['user_full_name'] != null) name.text = '${state.profile['user_full_name']}';
    if (email.text.isEmpty && state.profile['email'] != null) email.text = '${state.profile['email']}';
    if (phone.text.isEmpty && state.profile['phone'] != null) phone.text = '${state.profile['phone']}';
    return Scaffold(
      appBar: AppBar(title: const Text('İletişim')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Bize ulaşın', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Sorunuz veya talebiniz için formu doldurun.'),
            const SizedBox(height: 20),
            _field(name, 'Ad soyad', required: true),
            _field(email, 'E-posta', required: true, keyboard: TextInputType.emailAddress),
            _field(phone, 'Telefon', keyboard: TextInputType.phone),
            _field(subject, 'Konu'),
            _field(message, 'Mesajınız', required: true, maxLines: 6),
            const SizedBox(height: 12),
            FilledButton(onPressed: busy ? null : _submit, child: Text(busy ? 'Gönderiliyor...' : 'Mesaj gönder')),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = false, TextInputType? keyboard, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: required ? (value) => (value == null || value.trim().isEmpty) ? 'Bu alan zorunlu' : null : null,
        ),
      );

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final result = await context.read<AppState>().api.post('contact', body: {'full_name': name.text.trim(), 'email': email.text.trim(), 'phone': phone.text.trim(), 'subject': subject.text.trim(), 'message': message.text.trim()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Mesajınız gönderildi.'}')));
      Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
