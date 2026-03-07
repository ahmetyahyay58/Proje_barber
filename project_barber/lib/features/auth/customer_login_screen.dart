import 'package:flutter/material.dart';

import '../../app/routes.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    Navigator.of(context).pushReplacementNamed(Routes.customerShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Girişi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bilgilerini gir',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Şimdilik demo giriş: doldurup devam edebilirsin.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.length < 3) return 'En az 3 karakter gir.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon',
                    hintText: '05xx xxx xx xx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final value = (v ?? '').replaceAll(' ', '').trim();
                    if (value.length < 10) return 'Geçerli telefon gir.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.length < 4) return 'En az 4 karakter gir.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Giriş Yap'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    Routes.roleSelect,
                  ),
                  child: const Text('Geri Dön (Rol Seçimi)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

