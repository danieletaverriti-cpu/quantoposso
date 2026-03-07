import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import 'package:quantoposso/services/budget_math.dart';
import 'package:quantoposso/services/notifications.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _savingCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _savingCtrl =
        TextEditingController(text: _fmt(widget.state.settings.monthlySaving));
    widget.state.addListener(_syncSavingController);
  }
Future<void> _pickAvatar() async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 512,
  );
  if (xfile == null) return;

  final s = widget.state.settings;
  final updated = s.copyWith(profileAvatarPath: xfile.path);
  await widget.state.saveSettings(updated);
}

Future<void> _clearAvatar() async {
  final s = widget.state.settings;
  final updated = s.copyWith(clearProfileAvatarPath: true);
  await widget.state.saveSettings(updated);
}
  @override
  void dispose() {
    widget.state.removeListener(_syncSavingController);
    _debounce?.cancel();
    _savingCtrl.dispose();
    super.dispose();
  }

  void _syncSavingController() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) return;

    final wanted = _fmt(widget.state.settings.monthlySaving);
    if (_savingCtrl.text != wanted) _savingCtrl.text = wanted;
  }

  static String _fmt(double v) =>
      v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  double? _parseEuro(String raw) {
    final cleaned = raw.trim().replaceAll('€', '').replaceAll(' ', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  double _spentToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return widget.state.expenses
        .where((e) =>
            e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(end))
        .fold<double>(0.0, (s, e) => s + e.amount);
  }

  BudgetSnapshot _computeBudget() {
    final now = DateTime.now();

    final income = widget.state.incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .fold<double>(0, (s, i) => s + i.amount);

    final spentMonth = widget.state.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);

    final fixed = widget.state.fixed.fold<double>(0, (s, f) => s + f.amount);

    return BudgetMath.compute(
      today: now,
      monthlyIncome: income,
      fixedExpensesTotal: fixed,
      goalMonthlySaving: widget.state.settings.monthlySaving,
      variableSpentThisMonth: spentMonth,
      variableSpentToday: _spentToday(),
    );
  }

  Future<void> _applyAllSchedules(SettingsModel s) async {
    final snap = _computeBudget();
    final dayAllowance = snap.dayAllowance;
    final spentToday = _spentToday();

    // Mattina
    if (s.morningBudgetEnabled) {
      await NotificationsService.instance.scheduleMorningBudget(
        hour: s.morningBudgetHour,
        minute: s.morningBudgetMinute,
        dayAllowance: dayAllowance,
      );
    } else {
      await NotificationsService.instance.cancelMorningBudget();
    }

    // Sera
    if (s.eveningStatusEnabled) {
      await NotificationsService.instance.scheduleEveningStatus(
        hour: s.eveningStatusHour,
        minute: s.eveningStatusMinute,
        dayAllowance: dayAllowance,
        spentToday: spentToday,
      );
    } else {
      await NotificationsService.instance.cancelEveningStatus();
    }

    // Promemoria spese (DEVONO ESISTERE in SettingsModel + NotificationsService)
    if (s.expenseReminderEnabled) {
      await NotificationsService.instance.scheduleExpenseReminder(
        hour: s.expenseReminderHour,
        minute: s.expenseReminderMinute,
      );
    } else {
      await NotificationsService.instance.cancelExpenseReminder();
    }
  }

  Future<void> _pickTime({
    required int initialHour,
    required int initialMinute,
    required Future<void> Function(TimeOfDay picked) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked == null) return;

    await onPicked(picked);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Orario impostato: '
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ✅',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final s = widget.state.settings;
        final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const _BlueHeaderBackground(),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'Impostazioni',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.tune, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

_GlassCard(
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            backgroundImage: (s.profileAvatarPath == null || s.profileAvatarPath!.isEmpty)
                ? null
                : FileImage(File(s.profileAvatarPath!)),
            child: (s.profileAvatarPath == null || s.profileAvatarPath!.isEmpty)
                ? const Icon(Icons.person, color: Color(0xFF1E40AF))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profilo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Tocca l’avatar per scegliere una foto',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Rimuovi foto',
          onPressed: (s.profileAvatarPath == null || s.profileAvatarPath!.isEmpty) ? null : _clearAvatar,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  ),
),
                  // RISPARMIO
                  _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risparmio',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _savingCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) {
                              _debounce?.cancel();
                              _debounce =
                                  Timer(const Duration(milliseconds: 400), () async {
                                final v = _parseEuro(_savingCtrl.text);
                                if (v == null || v < 0) return;
                                await widget.state
                                    .saveSettings(s.copyWith(monthlySaving: v));
                                await _applyAllSchedules(widget.state.settings);
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Risparmio mensile',
                              prefixText: '€ ',
                              helperText:
                                  'Attuale: ${euro.format(s.monthlySaving)}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // NOTIFICHE
                  _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifiche',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),

                          // MATTINA
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Budget al mattino'),
                            subtitle: Text(
                              'Orario: ${s.morningBudgetHour.toString().padLeft(2, '0')}:${s.morningBudgetMinute.toString().padLeft(2, '0')}',
                            ),
                            value: s.morningBudgetEnabled,
                            onChanged: (v) async {
                              await NotificationsService.instance
                                  .requestPermissionsIfNeeded();
                              final updated = s.copyWith(morningBudgetEnabled: v);
                              await widget.state.saveSettings(updated);
                              await _applyAllSchedules(updated);
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.schedule),
                            title: const Text('Imposta orario budget mattino'),
                            enabled: s.morningBudgetEnabled,
                            onTap: !s.morningBudgetEnabled
                                ? null
                                : () => _pickTime(
                                      initialHour: s.morningBudgetHour,
                                      initialMinute: s.morningBudgetMinute,
                                      onPicked: (t) async {
                                        final updated = s.copyWith(
                                          morningBudgetHour: t.hour,
                                          morningBudgetMinute: t.minute,
                                        );
                                        await widget.state.saveSettings(updated);
                                        await _applyAllSchedules(updated);
                                      },
                                    ),
                          ),

                          const Divider(height: 20),

                          // SERA
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Esito giornata'),
                            subtitle: Text(
                              'Orario: ${s.eveningStatusHour.toString().padLeft(2, '0')}:${s.eveningStatusMinute.toString().padLeft(2, '0')}',
                            ),
                            value: s.eveningStatusEnabled,
                            onChanged: (v) async {
                              await NotificationsService.instance
                                  .requestPermissionsIfNeeded();
                              final updated = s.copyWith(eveningStatusEnabled: v);
                              await widget.state.saveSettings(updated);
                              await _applyAllSchedules(updated);
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.schedule),
                            title: const Text('Imposta orario esito giornata'),
                            enabled: s.eveningStatusEnabled,
                            onTap: !s.eveningStatusEnabled
                                ? null
                                : () => _pickTime(
                                      initialHour: s.eveningStatusHour,
                                      initialMinute: s.eveningStatusMinute,
                                      onPicked: (t) async {
                                        final updated = s.copyWith(
                                          eveningStatusHour: t.hour,
                                          eveningStatusMinute: t.minute,
                                        );
                                        await widget.state.saveSettings(updated);
                                        await _applyAllSchedules(updated);
                                      },
                                    ),
                          ),

                          const Divider(height: 20),

                          // PROMEMORIA SPESE
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Promemoria inserimento spese'),
                            subtitle: Text(
                              'Orario: ${s.expenseReminderHour.toString().padLeft(2, '0')}:${s.expenseReminderMinute.toString().padLeft(2, '0')}',
                            ),
                            value: s.expenseReminderEnabled,
                            onChanged: (v) async {
                              await NotificationsService.instance
                                  .requestPermissionsIfNeeded();
                              final updated =
                                  s.copyWith(expenseReminderEnabled: v);
                              await widget.state.saveSettings(updated);
                              await _applyAllSchedules(updated);
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.schedule),
                            title: const Text('Imposta orario promemoria spese'),
                            enabled: s.expenseReminderEnabled,
                            onTap: !s.expenseReminderEnabled
                                ? null
                                : () => _pickTime(
                                      initialHour: s.expenseReminderHour,
                                      initialMinute: s.expenseReminderMinute,
                                      onPicked: (t) async {
                                        final updated = s.copyWith(
                                          expenseReminderHour: t.hour,
                                          expenseReminderMinute: t.minute,
                                        );
                                        await widget.state.saveSettings(updated);
                                        await _applyAllSchedules(updated);
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------- BACKGROUND (TOP LEVEL) -------------------- */

class _BlueHeaderBackground extends StatelessWidget {
  const _BlueHeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1D4ED8),
              Color(0xFF2563EB),
              Color(0xFFF4F6FA),
              Color(0xFFF4F6FA),
            ],
            stops: [0.0, 0.38, 0.38, 1.0],
          ),
        ),
        child: CustomPaint(painter: _WavesPainter()),
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(0, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.10,
        size.width * 0.55,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.26,
        size.width,
        size.height * 0.20,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* -------------------- GLASS CARD (TOP LEVEL) -------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({required this.child, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 14),
                color: Colors.black.withValues(alpha: 0.10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}