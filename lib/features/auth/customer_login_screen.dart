import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../../app/routes.dart';
import '../../data/auth/auth_retry.dart';
import '../../data/auth/session_service.dart';
import '../../data/stores/customer_profile_store.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/modern_ui.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    FocusScope.of(context).unfocus();

    if (_isRegisterMode) {
      await _register();
      return;
    }
    await _login();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      await runWithAuthRetry(() async {
        await client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      });
      await CustomerProfileStore.instance.ensureProfileExists();
      await CustomerProfileStore.instance.refreshProfile();
      await SessionService.saveRole(UserRole.customer);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.customerShell);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş hatası: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş yapılamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final auth = client.auth;
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      await runWithAuthRetry(() async {
        await auth.signUp(email: email, password: password);
      });
      // Email confirmation kapaliysa session direkt gelir; aciksa login deneyip devam ederiz.
      if (auth.currentSession == null) {
        await runWithAuthRetry(() async {
          await auth.signInWithPassword(email: email, password: password);
        });
      }
      await _upsertCustomerProfile();
      await CustomerProfileStore.instance.refreshProfile();
      await SessionService.saveRole(UserRole.customer);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.customerShell);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt tamamlanamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _upsertCustomerProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('profiles').upsert({
      'id': user.id,
      'role': 'customer',
      'full_name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModernAuthScaffold(
      title: 'Müşteri Girişi',
      subtitle: _isRegisterMode
          ? 'Bilgilerini gir, direkt kayıt ol.'
          : 'Giriş bilgilerini girip devam edebilirsin.',
      leading: IconButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed(
          Routes.roleSelect,
        ),
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.surfaceOverlay,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Giriş Yap'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Kayıt Ol'),
                    ),
                  ],
                  selected: {_isRegisterMode},
                  onSelectionChanged: (value) {
                    setState(() => _isRegisterMode = value.first);
                  },
                ),
                const SizedBox(height: 12),
                if (_isRegisterMode) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.length < 3) {
                        return 'En az 3 karakter gir.';
                      }
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
                      if (value.length < 10) {
                        return 'Geçerli telefon gir.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
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
                HoverLift(
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Text(
                      _isLoading
                          ? 'İşleniyor...'
                          : (_isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

