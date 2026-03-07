import 'package:flutter/material.dart';

import '../../app/routes.dart';

class BarberLoginScreen extends StatefulWidget {
  const BarberLoginScreen({super.key});

  @override
  State<BarberLoginScreen> createState() => _BarberLoginScreenState();
}

class _BarberLoginScreenState extends State<BarberLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    Navigator.of(context).pushReplacementNamed(Routes.barberShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Berber Girişi')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'İşletme bilgileri',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Şimdilik demo giriş: doldurup panele geçebilirsin.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _shopNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dükkan Adı',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.length < 3) return 'En az 3 karakter gir.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (!value.contains('@')) return 'Geçerli e-posta gir.';
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
                  child: const Text('Panele Gir'),
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

