import 'package:flutter/material.dart';
import 'package:il_ilce_dropdown/city_district_dropdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_theme.dart';
import '../../app/routes.dart';
import '../../data/auth/auth_retry.dart';
import '../../data/stores/barber_store.dart';
import '../../widgets/hover_lift.dart';
import '../../widgets/modern_ui.dart';

class BarberLoginScreen extends StatefulWidget {
  const BarberLoginScreen({super.key});

  @override
  State<BarberLoginScreen> createState() => _BarberLoginScreenState();
}

class _BarberLoginScreenState extends State<BarberLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String? _selectedCity;
  String? _selectedDistrict;

  static final Map<String, List<String>> _cityDistricts = _buildCityDistricts();

  static Map<String, List<String>> _buildCityDistricts() {
    final cityNameById = <String, String>{};
    for (final city in cityList) {
      if (city.id == '0') continue;
      var cityName = city.name.trim();
      // Paket datasinda 66 sehri yanlis isimlenmis olabiliyor.
      if (city.id == '66') cityName = 'YOZGAT';
      cityNameById[city.id] = _toTitleCaseTr(cityName);
    }

    final cityDistricts = <String, List<String>>{};
    for (final district in districtList) {
      if (district.id == '0') continue;
      final cityName = cityNameById[district.cityId];
      if (cityName == null) continue;
      final districtName = _toTitleCaseTr(district.name);
      cityDistricts.putIfAbsent(cityName, () => <String>[]).add(districtName);
    }

    final sortedCities = cityDistricts.keys.toList()
      ..sort(_compareTrAlphabetical);
    final normalized = <String, List<String>>{};
    for (final city in sortedCities) {
      final districts = cityDistricts[city]!..sort(_compareTrAlphabetical);
      normalized[city] = districts.toSet().toList();
    }
    return normalized;
  }

  static int _compareTrAlphabetical(String a, String b) {
    const alphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';
    final aNorm = a.toLowerCase();
    final bNorm = b.toLowerCase();
    final minLen = aNorm.length < bNorm.length ? aNorm.length : bNorm.length;

    for (var i = 0; i < minLen; i++) {
      final ai = alphabet.indexOf(aNorm[i]);
      final bi = alphabet.indexOf(bNorm[i]);
      if (ai != bi) {
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      }
    }
    return aNorm.length.compareTo(bNorm.length);
  }

  static String _toTitleCaseTr(String value) {
    final lower = value.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => _upperFirstTr(w))
        .join(' ');
  }

  static String _upperFirstTr(String word) {
    if (word.isEmpty) return word;
    final first = word[0];
    final rest = word.substring(1);
    const trUpper = {
      'i': 'İ',
      'ı': 'I',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
    };
    return '${trUpper[first] ?? first.toUpperCase()}$rest';
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
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
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();
      final auth = client.auth;

      await runWithAuthRetry(() async {
        await auth.signInWithPassword(email: email, password: password);
      });

      await BarberStore.instance.refreshBarbers();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.barberShell);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş hatası: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt alınamadı: $e')),
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
      if (auth.currentSession == null) {
        await runWithAuthRetry(() async {
          await auth.signInWithPassword(email: email, password: password);
        });
      }

      await BarberStore.instance.upsertCurrentUserBarber(
        name: _shopNameCtrl.text.trim(),
        city: _selectedCity ?? '',
        district: _selectedDistrict ?? '',
        address: _addressCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.barberShell);
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

  @override
  Widget build(BuildContext context) {
    return ModernAuthScaffold(
      title: 'Berber Girişi',
      subtitle: _isRegisterMode
          ? 'Bilgileri doldur, direkt kayıt ol.'
          : 'Giriş bilgilerini doldurup panele geçebilirsin.',
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
                    controller: _shopNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Dükkan Adı',
                      prefixIcon: Icon(Icons.store_outlined),
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
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    items: _cityDistricts.keys
                        .map(
                          (city) => DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                        _selectedDistrict = null;
                      });
                    },
                    validator: (value) => value == null ? 'Şehir seç.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'İlçe',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: (_selectedCity == null
                            ? const <String>[]
                            : _cityDistricts[_selectedCity] ?? const <String>[])
                        .map(
                          (district) => DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          ),
                        )
                        .toList(),
                    onChanged: _selectedCity == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedDistrict = value;
                            });
                          },
                    validator: (value) => value == null ? 'İlçe seç.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.length < 5) return 'Adres gir.';
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

