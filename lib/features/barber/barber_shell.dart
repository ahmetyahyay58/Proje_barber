import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../data/storage/media_storage.dart';
import '../../data/models/barber.dart';
import '../../data/models/appointment.dart';
import '../../data/models/barber_expense.dart';
import '../../data/stores/appointment_store.dart';
import '../../data/stores/barber_expense_store.dart';
import '../../data/stores/barber_store.dart';
import '../../data/stores/working_days_store.dart';
import '../../widgets/hover_lift.dart';
import 'location_picker_screen.dart';

enum _BarberMenu {
  home('Ana Ekran', Icons.dashboard_outlined),
  finance('Finans', Icons.bar_chart_outlined),
  appointments('Randevular', Icons.event_note_outlined),
  staff('Eleman Ekle/Çıkar', Icons.groups_outlined),
  prices('Fiyat Listesi', Icons.payments_outlined),
  daysOff('İzin Günleri', Icons.beach_access_outlined),
  settings('Genel Ayarlar', Icons.settings_outlined);

  const _BarberMenu(this.label, this.icon);
  final String label;
  final IconData icon;
}

class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  _BarberMenu _selected = _BarberMenu.home;

  @override
  void initState() {
    super.initState();
    AppointmentStore.instance.refreshAppointments();
    BarberStore.instance.refreshBarbers();
    BarberExpenseStore.instance.refreshExpenses();
  }

  void _select(_BarberMenu menu) {
    setState(() => _selected = menu);
    if (menu == _BarberMenu.appointments) {
      AppointmentStore.instance.refreshAppointments();
    } else if (menu == _BarberMenu.finance) {
      AppointmentStore.instance.refreshAppointments();
      BarberExpenseStore.instance.refreshExpenses();
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selected) {
      _BarberMenu.home => const _BarberHome(),
      _BarberMenu.finance => const _BarberFinancePage(),
      _BarberMenu.appointments => const _BarberAppointmentsPage(),
      _BarberMenu.staff => const _BarberStaffPage(),
      _BarberMenu.prices => const _BarberPriceListPage(),
      _BarberMenu.daysOff => const _BarberDaysOffPage(),
      _BarberMenu.settings => const _BarberSettingsPage(),
    };

    return Scaffold(
      appBar: AppBar(title: Text(_selected.label)),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const _DrawerHeader(title: 'Berber Paneli'),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in _BarberMenu.values)
                      HoverLift(
                        child: ListTile(
                          leading: Icon(item.icon),
                          title: Text(item.label),
                          selected: item == _selected,
                          onTap: () => _select(item),
                        ),
                      ),
                    const Divider(),
                    HoverLift(
                      child: ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Çıkış Yap'),
                        onTap: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.roleSelect,
                            (_) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: page,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: const Icon(Icons.content_cut),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider? _imageProviderFromSource(String? source) {
  if (source == null || source.isEmpty) return null;
  if (source.startsWith('data:image')) {
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    return MemoryImage(base64Decode(source.substring(comma + 1)));
  }
  if (source.startsWith('http://') || source.startsWith('https://')) {
    return NetworkImage(source);
  }
  if (kIsWeb) return null;
  final file = File(source);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

class _BarberHome extends StatelessWidget {
  const _BarberHome();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final barber = BarberStore.instance.currentUserBarber;
        return ValueListenableBuilder<List<Appointment>>(
          valueListenable: AppointmentStore.instance.appointments,
          builder: (context, appointments, ___) {
            final today = DateTime.now();
            final todayCount = barber == null
                ? 0
                : appointments.where((a) {
                    return a.barberId == barber.id &&
                        a.dateTime.year == today.year &&
                        a.dateTime.month == today.month &&
                        a.dateTime.day == today.day;
                  }).length;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  if (barber != null)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _imageProviderFromSource(barber.avatarPath),
                          child: _imageProviderFromSource(barber.avatarPath) == null
                              ? const Icon(Icons.storefront_outlined)
                              : null,
                        ),
                        title: Text(barber.name),
                        subtitle: Text('${barber.city} / ${barber.district}'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Özet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        title: 'Bugünkü Randevular',
                        value: '$todayCount',
                        icon: Icons.event_available_outlined,
                        color: scheme.primaryContainer,
                      ),
                      _StatCard(
                        title: 'Toplam Eleman',
                        value: '${barber?.masters.length ?? 0}',
                        icon: Icons.groups_outlined,
                        color: scheme.secondaryContainer,
                      ),
                      _StatCard(
                        title: 'İzin Günleri',
                        value: 'Ayarla',
                        icon: Icons.beach_access_outlined,
                        color: scheme.tertiaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: HoverLift(
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarberFinancePage extends StatefulWidget {
  const _BarberFinancePage();

  @override
  State<_BarberFinancePage> createState() => _BarberFinancePageState();
}

class _BarberFinancePageState extends State<_BarberFinancePage> {
  String? _staffFilter;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  @override
  void initState() {
    super.initState();
    AppointmentStore.instance.refreshAppointments();
    BarberExpenseStore.instance.refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, appointments, _) {
        final barber = BarberStore.instance.currentUserBarber;
        if (barber == null) {
          return const Center(child: Text('Berber kaydi bulunamadi.'));
        }
        final own = appointments
            .where((a) => a.barberId == barber.id && a.dateTime.isAfter(monthAgo))
            .toList();
        final realized = own.where((a) => a.dateTime.isBefore(now)).toList();
        final servicePriceByName = <String, int>{
          for (final s in barber.services) s.name.trim().toLowerCase(): s.price,
        };
        int incomeOf(Appointment a) {
          if (a.totalAmount > 0) return a.totalAmount;
          if (a.serviceNames.isEmpty) return 0;
          return a.serviceNames.fold<int>(0, (sum, name) {
            final key = name.trim().toLowerCase();
            return sum + (servicePriceByName[key] ?? 0);
          });
        }
        final incomeByDay = <DateTime, int>{};
        for (final a in realized) {
          final day = _dateOnly(a.dateTime);
          incomeByDay[day] = (incomeByDay[day] ?? 0) + incomeOf(a);
        }
        final sortedDays = incomeByDay.keys.toList()..sort((a, b) => b.compareTo(a));
        final staffNames = <String>{
          ...barber.masters,
          ...realized
              .map((a) => (a.masterName ?? '').trim())
              .where((e) => e.isNotEmpty),
        }.toList()
          ..sort();
        final effectiveStaff = _staffFilter != null && staffNames.contains(_staffFilter)
            ? _staffFilter
            : null;
        final staffRows = realized
            .where((a) => effectiveStaff == null || (a.masterName ?? '').trim() == effectiveStaff)
            .toList();
        final staffIncomeByDay = <DateTime, int>{};
        for (final a in staffRows) {
          final day = _dateOnly(a.dateTime);
          staffIncomeByDay[day] = (staffIncomeByDay[day] ?? 0) + incomeOf(a);
        }
        final summaryIncomeDay = realized
            .where((a) => _dateOnly(a.dateTime) == _dateOnly(now))
            .fold<int>(0, (s, a) => s + incomeOf(a));
        final summaryIncomeWeek = realized
            .where((a) => a.dateTime.isAfter(now.subtract(const Duration(days: 7))))
            .fold<int>(0, (s, a) => s + incomeOf(a));
        final summaryIncomeMonth = realized.fold<int>(0, (s, a) => s + incomeOf(a));

        return ValueListenableBuilder<List<BarberExpense>>(
          valueListenable: BarberExpenseStore.instance.expenses,
          builder: (context, expenses, __) {
            final expenseDay = expenses
                .where((e) => _dateOnly(e.incurredOn) == _dateOnly(now))
                .fold<int>(0, (s, e) => s + e.amount);
            final expenseWeek = expenses
                .where((e) => e.incurredOn.isAfter(now.subtract(const Duration(days: 7))))
                .fold<int>(0, (s, e) => s + e.amount);
            final expenseMonth = expenses
                .where((e) => e.incurredOn.isAfter(monthAgo))
                .fold<int>(0, (s, e) => s + e.amount);

            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Gunluk Gelir'),
                      Tab(text: 'Eleman Geliri'),
                      Tab(text: 'Giderler'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(label: 'Gunluk Gelir', value: summaryIncomeDay),
                        _SummaryChip(label: 'Haftalik Gelir', value: summaryIncomeWeek),
                        _SummaryChip(label: 'Aylik Gelir', value: summaryIncomeMonth),
                        _SummaryChip(label: 'Gunluk Gider', value: expenseDay, isExpense: true),
                        _SummaryChip(label: 'Haftalik Gider', value: expenseWeek, isExpense: true),
                        _SummaryChip(label: 'Aylik Gider', value: expenseMonth, isExpense: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const Text('Son 1 ay gunluk gelir tablosu'),
                            const SizedBox(height: 8),
                            for (final day in sortedDays)
                              Card(
                                child: ListTile(
                                  title: Text(_formatDate(day)),
                                  trailing: Text('₺${incomeByDay[day] ?? 0}'),
                                ),
                              ),
                            if (sortedDays.isEmpty)
                              const Card(
                                child: ListTile(title: Text('Son 1 ayda gelir kaydi yok.')),
                              ),
                          ],
                        ),
                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            DropdownButtonFormField<String?>(
                              initialValue: effectiveStaff,
                              decoration: const InputDecoration(
                                labelText: 'Eleman sec',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tum elemanlar'),
                                ),
                                for (final m in staffNames)
                                  DropdownMenuItem<String?>(
                                    value: m,
                                    child: Text(m),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _staffFilter = v),
                            ),
                            const SizedBox(height: 8),
                            for (final day in (staffIncomeByDay.keys.toList()..sort((a, b) => b.compareTo(a))))
                              Card(
                                child: ListTile(
                                  title: Text(_formatDate(day)),
                                  subtitle: Text(effectiveStaff ?? 'Tum elemanlar'),
                                  trailing: Text('₺${staffIncomeByDay[day] ?? 0}'),
                                ),
                              ),
                            if (staffIncomeByDay.isEmpty)
                              const Card(
                                child: ListTile(title: Text('Bu filtrede gelir kaydi yok.')),
                              ),
                          ],
                        ),
                        _ExpenseTab(expenses: expenses),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.isExpense = false,
  });

  final String label;
  final int value;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final bg = isExpense
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: ₺$value'),
    );
  }
}

class _ExpenseTab extends StatefulWidget {
  const _ExpenseTab({required this.expenses});

  final List<BarberExpense> expenses;

  @override
  State<_ExpenseTab> createState() => _ExpenseTabState();
}

class _ExpenseTabState extends State<_ExpenseTab> {
  Future<void> _openAddExpense() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? imageUrl;
    bool isUploading = false;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Gider Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Gider adi'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fiyat'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Detayli aciklama (istege bagli)',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDate: selectedDate,
                    );
                    if (picked == null) return;
                    setModal(() => selectedDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          try {
                            setModal(() => isUploading = true);
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: kIsWeb,
                    );
                    if (result == null) return;
                    final f = result.files.single;
                    Uint8List? bytes = f.bytes;
                    if ((bytes == null || bytes.isEmpty) && !kIsWeb && f.path != null) {
                      bytes = await File(f.path!).readAsBytes();
                    }
                    if (bytes == null || bytes.isEmpty) return;
                    final ownerId =
                        BarberStore.instance.currentUserBarber?.ownerId ??
                            Supabase.instance.client.auth.currentUser?.id;
                    if (ownerId == null) return;
                    final url = await MediaStorage.uploadImage(
                      folder: 'barber/expense',
                      ownerId: ownerId,
                      bytes: bytes,
                      extension: f.extension,
                    );
                    setModal(() => imageUrl = url);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gorsel yuklenemedi: $e')),
                            );
                          } finally {
                            if (mounted) {
                              setModal(() => isUploading = false);
                            }
                          }
                        },
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    isUploading
                        ? 'Yukleniyor...'
                        : (imageUrl == null
                            ? 'Gorsel ekle (istege bagli)'
                            : 'Gorsel eklendi'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final title = titleCtrl.text.trim();
                      final amountText = amountCtrl.text
                          .replaceAll('₺', '')
                          .replaceAll(',', '')
                          .trim();
                      final amount = int.tryParse(amountText) ?? -1;
                      if (title.isEmpty) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gider adi zorunlu.')),
                        );
                        return;
                      }
                      if (amount < 0) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gecerli bir fiyat gir.')),
                        );
                        return;
                      }
                      try {
                        setModal(() => isSaving = true);
                        await BarberExpenseStore.instance.addExpense(
                          title: title,
                          amount: amount,
                          incurredOn: selectedDate,
                          description: descCtrl.text,
                          imageUrl: imageUrl,
                        );
                        if (!context.mounted) return;
                        Navigator.of(ctx).pop();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gider kaydedilemedi: $e')),
                        );
                      } finally {
                        if (mounted) {
                          setModal(() => isSaving = false);
                        }
                      }
                    },
              child: Text(isSaving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Gider kayitlari')),
            FilledButton.icon(
              onPressed: _openAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Gider Ekle'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final e in widget.expenses)
          Card(
            child: ListTile(
              title: Text(e.title),
              subtitle: Text(
                '${e.incurredOn.day.toString().padLeft(2, '0')}.${e.incurredOn.month.toString().padLeft(2, '0')}.${e.incurredOn.year}',
              ),
              trailing: Text('₺${e.amount}'),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(e.title),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tutar: ₺${e.amount}'),
                          Text(
                            'Tarih: ${e.incurredOn.day.toString().padLeft(2, '0')}.${e.incurredOn.month.toString().padLeft(2, '0')}.${e.incurredOn.year}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (e.description ?? '').trim().isEmpty
                                ? 'Aciklama girilmemis.'
                                : e.description!,
                          ),
                          if (e.imageUrl != null && e.imageUrl!.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                e.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kapat'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (widget.expenses.isEmpty)
          const Card(
            child: ListTile(title: Text('Henuz gider kaydi yok.')),
          ),
      ],
    );
  }
}

class _BarberAppointmentsPage extends StatefulWidget {
  const _BarberAppointmentsPage();

  @override
  State<_BarberAppointmentsPage> createState() => _BarberAppointmentsPageState();
}

class _BarberAppointmentsPageState extends State<_BarberAppointmentsPage> {
  DateTime? _selectedFutureDay;
  DateTime? _selectedPastDay;
  String? _selectedMasterFilter;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateTime(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year • $hour:$minute';
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: AppointmentStore.instance.appointments,
      builder: (context, list, _) {
        final currentBarber = BarberStore.instance.currentUserBarber;
        final ownAppointments = currentBarber == null
            ? const <Appointment>[]
            : list.where((a) => a.barberId == currentBarber.id).toList();
        final masters = <String>{
          ...(currentBarber?.masters ?? const <String>[]),
          ...ownAppointments
              .map((a) => a.masterName?.trim() ?? '')
              .where((m) => m.isNotEmpty),
        }.toList()
          ..sort();
        final now = DateTime.now();
        final today = _dateOnly(now);
        final futureLimit = today.add(const Duration(days: 30));
        final pastLimit = today.subtract(const Duration(days: 90));

        final futureBase = ownAppointments
            .where((a) =>
                !a.dateTime.isBefore(today) && !a.dateTime.isAfter(futureLimit))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

        final pastBase = ownAppointments
            .where((a) =>
                a.dateTime.isBefore(today) && !a.dateTime.isBefore(pastLimit))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final futureByDate = _selectedFutureDay == null
            ? futureBase
            : futureBase
                .where((a) => _isSameDay(a.dateTime, _selectedFutureDay!))
                .toList();
        final pastByDate = _selectedPastDay == null
            ? pastBase
            : pastBase.where((a) => _isSameDay(a.dateTime, _selectedPastDay!)).toList();
        final futureItems = _selectedMasterFilter == null
            ? futureByDate
            : futureByDate
                .where((a) => (a.masterName ?? '').trim() == _selectedMasterFilter)
                .toList();
        final pastItems = _selectedMasterFilter == null
            ? pastByDate
            : pastByDate
                .where((a) => (a.masterName ?? '').trim() == _selectedMasterFilter)
                .toList();

        Widget buildList(List<Appointment> items, String emptyText) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(emptyText),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = items[i];
              final customerName =
                  (a.customerName == null || a.customerName!.trim().isEmpty)
                      ? 'Misafir müşteri'
                      : a.customerName!;
              final serviceText = a.serviceNames.isEmpty
                  ? 'Hizmet bilgisi yok'
                  : a.serviceNames.join(', ');
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(customerName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatDateTime(a.dateTime)),
                      Text('Telefon: ${a.customerPhone ?? '-'}'),
                      Text(serviceText),
                      if (a.masterName != null && a.masterName!.trim().isNotEmpty)
                        Text('Usta: ${a.masterName!}'),
                    ],
                  ),
                ),
              );
            },
          );
        }

        Future<void> pickFutureDate() async {
          final selected = await showDatePicker(
            context: context,
            firstDate: today,
            lastDate: futureLimit,
            initialDate: _selectedFutureDay ?? today,
          );
          if (selected == null) return;
          setState(() => _selectedFutureDay = selected);
        }

        Future<void> pickPastDate() async {
          final initial = _selectedPastDay ?? today.subtract(const Duration(days: 1));
          final selected = await showDatePicker(
            context: context,
            firstDate: pastLimit,
            lastDate: today.subtract(const Duration(days: 1)),
            initialDate: initial.isBefore(pastLimit) ? pastLimit : initial,
          );
          if (selected == null) return;
          setState(() => _selectedPastDay = selected);
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Gelecek'),
                  Tab(text: 'Geçmiş'),
                ],
              ),
              if (masters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _selectedMasterFilter,
                          decoration: const InputDecoration(
                            labelText: 'Eleman filtresi',
                            prefixIcon: Icon(Icons.person_search_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tum elemanlar'),
                            ),
                            for (final m in masters)
                              DropdownMenuItem<String?>(
                                value: m,
                                child: Text(m),
                              ),
                          ],
                          onChanged: (v) => setState(() => _selectedMasterFilter = v),
                        ),
                      ),
                      if (_selectedMasterFilter != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => setState(() => _selectedMasterFilter = null),
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: pickFutureDate,
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  label: Text(
                                    _selectedFutureDay == null
                                        ? 'Tüm Günler (1 ay)'
                                        : _formatDate(_selectedFutureDay!),
                                  ),
                                ),
                              ),
                              if (_selectedFutureDay != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => setState(() => _selectedFutureDay = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: buildList(
                            futureItems,
                            'Onumuzdeki 1 ay icinde randevu yok.',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: pickPastDate,
                                  icon: const Icon(Icons.calendar_month_outlined),
                                  label: Text(
                                    _selectedPastDay == null
                                        ? 'Tüm Günler (son 3 ay)'
                                        : _formatDate(_selectedPastDay!),
                                  ),
                                ),
                              ),
                              if (_selectedPastDay != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => setState(() => _selectedPastDay = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: buildList(
                            pastItems,
                            'Son 3 ay icinde gecmis randevu yok.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarberStaffPage extends StatefulWidget {
  const _BarberStaffPage();

  @override
  State<_BarberStaffPage> createState() => _BarberStaffPageState();
}

class _BarberStaffPageState extends State<_BarberStaffPage> {
  Future<void> _addStaff() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eleman Ekle'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Ad'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ctrl.dispose();
              Navigator.of(ctx).pop();
            },
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                final current = BarberStore.instance.currentUserBarber;
                if (current != null) {
                  final next = List<String>.from(current.masters);
                  if (!next.contains(name)) {
                    next.add(name);
                    await BarberStore.instance.updateMasters(next);
                  }
                }
              }
              ctrl.dispose();
              if (!mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final staff = BarberStore.instance.currentUserBarber?.masters ?? const <String>[];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Elemanlar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addStaff,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(staff[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final current = BarberStore.instance.currentUserBarber;
                          if (current == null) return;
                          final next = List<String>.from(current.masters)..removeAt(i);
                          await BarberStore.instance.updateMasters(next);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarberPriceListPage extends StatefulWidget {
  const _BarberPriceListPage();

  @override
  State<_BarberPriceListPage> createState() => _BarberPriceListPageState();
}

class _BarberPriceListPageState extends State<_BarberPriceListPage> {
  Future<void> _openServiceDialog({BarberService? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final durationCtrl = TextEditingController(
      text: editing?.durationMinutes.toString() ?? '30',
    );
    final priceCtrl = TextEditingController(text: editing?.price.toString() ?? '0');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing == null ? 'Hizmet Ekle' : 'Hizmeti Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Hizmet Adı'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Süre (dk)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final duration = int.tryParse(durationCtrl.text.trim()) ?? 0;
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (name.isEmpty || duration <= 0 || price < 0) return;
              await BarberStore.instance.upsertService(
                id: editing?.id,
                name: name,
                durationMinutes: duration,
                price: price,
              );
              if (!mounted) return;
              Navigator.of(ctx).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Barber>>(
      valueListenable: BarberStore.instance.barbers,
      builder: (context, _, __) {
        final services = BarberStore.instance.currentUserBarber?.services ?? const <BarberService>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fiyat Listesi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openServiceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Hizmet Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Henuz hizmet eklenmedi'),
                  subtitle: Text('Musteri tarafinda secilebilmesi icin hizmet ekleyin.'),
                ),
              ),
            for (final service in services)
              Card(
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text('${service.durationMinutes} dk'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${service.price} ₺'),
                      IconButton(
                        onPressed: () => _openServiceDialog(editing: service),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => BarberStore.instance.deleteService(service.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BarberDaysOffPage extends StatefulWidget {
  const _BarberDaysOffPage();

  @override
  State<_BarberDaysOffPage> createState() => _BarberDaysOffPageState();
}

class _BarberDaysOffPageState extends State<_BarberDaysOffPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: WorkingDaysStore.instance.daysOff,
      builder: (context, daysOff, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'İzin Günleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            for (var weekday = 1; weekday <= 7; weekday++)
              SwitchListTile(
                value: daysOff.contains(weekday),
                title: Text(WorkingDaysStore.weekdayNames[weekday] ?? ''),
                onChanged: (v) =>
                    WorkingDaysStore.instance.setDayOff(weekday, v),
              ),
          ],
        );
      },
    );
  }
}

class _BarberSettingsPage extends StatefulWidget {
  const _BarberSettingsPage();

  @override
  State<_BarberSettingsPage> createState() => _BarberSettingsPageState();
}

class _BarberSettingsPageState extends State<_BarberSettingsPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _aboutCtrl;
  Barber? _barber;

  @override
  void initState() {
    super.initState();
    _barber = BarberStore.instance.currentUserBarber;
    _nameCtrl = TextEditingController(text: _barber?.name ?? '');
    _aboutCtrl = TextEditingController(text: _barber?.about ?? '');
    BarberStore.instance.barbers.addListener(_syncCurrentBarber);
    BarberStore.instance.refreshBarbers();
  }

  @override
  void dispose() {
    BarberStore.instance.barbers.removeListener(_syncCurrentBarber);
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _syncCurrentBarber() {
    final current = BarberStore.instance.currentUserBarber;
    if (!mounted) return;
    setState(() {
      _barber = current;
      if (current != null) {
        _nameCtrl.text = current.name;
        _aboutCtrl.text = current.about ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    final barbers = BarberStore.instance.barbers.value;
    if (barbers.isEmpty || _barber == null) return;
    final current = _barber!;
    await BarberStore.instance.updateCurrentBarberProfile(
      name: _nameCtrl.text.trim().isEmpty ? current.name : _nameCtrl.text.trim(),
      about: _aboutCtrl.text.trim().isEmpty ? '' : _aboutCtrl.text.trim(),
    );
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil güncellendi.')),
    );
  }

  Future<void> _pickLocation() async {
    if (_barber == null) return;
    final barber = _barber!;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: barber.lat,
          initialLng: barber.lng,
        ),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      setState(() => _barber = BarberStore.instance.currentUserBarber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum kaydedildi.')),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    if (result == null) return;
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if ((bytes == null || bytes.isEmpty) && !kIsWeb && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null || bytes.isEmpty || _barber == null) return;
    final source = await MediaStorage.uploadImage(
      folder: 'barber/avatar',
      ownerId: _barber!.ownerId,
      bytes: bytes,
      extension: file.extension,
    );
    await BarberStore.instance.updateCurrentBarberProfile(avatarUrl: source);
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
  }

  Future<void> _pickGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null) return;
    final newPaths = <String>[];
    if (_barber == null) return;
    for (final f in result.files) {
      Uint8List? bytes = f.bytes;
      if ((bytes == null || bytes.isEmpty) && !kIsWeb && f.path != null) {
        bytes = await File(f.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) continue;
      final url = await MediaStorage.uploadImage(
        folder: 'barber/gallery',
        ownerId: _barber!.ownerId,
        bytes: bytes,
        extension: f.extension,
      );
      newPaths.add(url);
    }
    if (newPaths.isEmpty) return;
    final current = _barber!;
    final availableSlots = 3 - current.galleryPaths.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 3 galeri fotosu ekleyebilirsin.')),
      );
      return;
    }
    final limitedNewPaths = newPaths.take(availableSlots).toList();
    final merged = [...current.galleryPaths, ...limitedNewPaths];
    await BarberStore.instance.updateCurrentBarberProfile(galleryUrls: merged);
    final refreshed = BarberStore.instance.currentUserBarber;
    if (refreshed != null) {
      setState(() {
        _barber = refreshed;
      });
    }
    if (newPaths.length > limitedNewPaths.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sadece ilk 3 foto kaydedildi.')),
      );
    }
  }

  void _removeGalleryItem(int index) {
    if (_barber == null) return;
    final current = _barber!;
    if (index < 0 || index >= current.galleryPaths.length) return;
    final newGallery = List<String>.from(current.galleryPaths)..removeAt(index);
    BarberStore.instance.updateCurrentBarberProfile(galleryUrls: newGallery).then((_) {
      final refreshed = BarberStore.instance.currentUserBarber;
      if (!mounted) return;
      if (refreshed != null) {
        setState(() {
          _barber = refreshed;
        });
      }
    });
  }

  ImageProvider? _toImageProvider(String? source) {
    if (source == null || source.isEmpty) return null;
    if (source.startsWith('data:image')) {
      final comma = source.indexOf(',');
      if (comma < 0) return null;
      return MemoryImage(base64Decode(source.substring(comma + 1)));
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }
    if (kIsWeb) return null;
    final file = File(source);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  @override
  Widget build(BuildContext context) {
    if (_barber == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Profil düzenlemek için en az bir berber oluşturmalısın.'),
        ),
      );
    }

    final barber = _barber!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Genel Ayarlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Profil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Dükkan Konumu'),
                    subtitle: Text(
                      barber.lat != null && barber.lng != null
                          ? 'Kaydedildi • ${barber.lat!.toStringAsFixed(5)}, ${barber.lng!.toStringAsFixed(5)}'
                          : 'Henüz seçilmedi',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickLocation,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dükkan Adı',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aboutCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Hakkımda',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Medya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: _toImageProvider(barber.avatarPath),
                          child: _toImageProvider(barber.avatarPath) == null
                              ? const Icon(Icons.camera_alt_outlined)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Profil fotoğrafına dokunarak cihazından görsel seçebilirsin.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Galeri Fotoğrafları',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton.icon(
                        onPressed: _pickGallery,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Ekle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (barber.galleryPaths.isEmpty)
                    Text(
                      'Henüz galeri eklenmemiş.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: barber.galleryPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final path = barber.galleryPaths[index];
                          final provider = _toImageProvider(path);
                          if (provider == null) {
                            return const SizedBox.shrink();
                          }
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: provider,
                                  width: 120,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () => _removeGalleryItem(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Kaydet'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

