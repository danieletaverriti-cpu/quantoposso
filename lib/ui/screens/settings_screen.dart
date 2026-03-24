import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import 'package:quantoposso/services/budget_math.dart';
import 'package:quantoposso/services/notifications.dart';
import 'package:quantoposso/services/salary_cycle.dart';
import 'package:quantoposso/ui/screens/pro_screen.dart';
import 'package:quantoposso/ui/screens/export_screen.dart';
import 'package:quantoposso/services/backup_service.dart';
import 'package:quantoposso/ui/screens/security/app_pin_setup_screen.dart';


class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _savingCtrl;
  Timer? _debounce;
  double? _paydayDayDraft;


  @override
  void initState() {
    super.initState();
    _savingCtrl =
        TextEditingController(text: _fmt(widget.state.settings.monthlySaving));
    widget.state.addListener(_syncSavingController);
    _paydayDayDraft = widget.state.settings.paydayDay.toDouble();
  }
Future<void> _pickAvatar() async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 512,
  );
  if (xfile == null) return;

  final dir = await getApplicationDocumentsDirectory();
  final avatarDir = Directory('${dir.path}/profile');

  if (!await avatarDir.exists()) {
    await avatarDir.create(recursive: true);
  }

  final oldPath = widget.state.settings.profileAvatarPath;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final savedFile = File('${avatarDir.path}/avatar_$timestamp.jpg');

  await File(xfile.path).copy(savedFile.path);

  final updated = widget.state.settings.copyWith(
    profileAvatarPath: savedFile.path,
  );

  await widget.state.saveSettings(updated);
  await widget.state.refresh();

  if (oldPath != null && oldPath.isNotEmpty && oldPath != savedFile.path) {
    final oldFile = File(oldPath);
    if (await oldFile.exists()) {
      await oldFile.delete();
    }
  }

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Foto profilo aggiornata ✅')),
  );
}
Future<void> _clearAvatar() async {
  final oldPath = widget.state.settings.profileAvatarPath;

  if (oldPath != null && oldPath.isNotEmpty) {
    final file = File(oldPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  final updated = widget.state.settings.copyWith(
    clearProfileAvatarPath: true,
  );

  await widget.state.saveSettings(updated);
  await widget.state.refresh();

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Foto profilo rimossa'),
    ),
  );
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
    _paydayDayDraft = widget.state.settings.paydayDay.toDouble();
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

  final cycle = SalaryCycleService.estimateCycle(
    today: now,
    paydayDay: widget.state.settings.paydayDay,
    lastSalaryDateIso: widget.state.settings.lastSalaryDateIso,
    useRealSalaryCycle: widget.state.settings.useRealSalaryCycle,
  );

  final cycleStart = DateTime(
    cycle.start.year,
    cycle.start.month,
    cycle.start.day,
  );

  final cycleEndExclusive = DateTime(
    cycle.end.year,
    cycle.end.month,
    cycle.end.day,
  ).add(const Duration(days: 1));

  final income = widget.state.incomes
      .where((i) => !i.date.isBefore(cycleStart) && i.date.isBefore(cycleEndExclusive))
      .fold<double>(0, (s, i) => s + i.amount);

  final spentCycle = widget.state.expenses
      .where((e) => !e.date.isBefore(cycleStart) && e.date.isBefore(cycleEndExclusive))
      .fold<double>(0, (s, e) => s + e.amount);

  final fixed = widget.state.fixed.fold<double>(0, (s, f) => s + f.amount);

  final todayStart = DateTime(now.year, now.month, now.day);
  final cycleTotalDays = cycle.end.difference(cycle.start).inDays + 1;
  final cycleRemainingDaysRaw = cycle.end.difference(todayStart).inDays + 1;
  final cycleRemainingDays = cycleRemainingDaysRaw <= 0 ? 1 : cycleRemainingDaysRaw;

  return BudgetMath.compute(
    today: now,
    monthlyIncome: income,
    fixedExpensesTotal: fixed,
    goalMonthlySaving: widget.state.settings.monthlySaving,
    variableSpentThisMonth: spentCycle,
    cycleTotalDays: cycleTotalDays,
    cycleRemainingDays: cycleRemainingDays,
    variableSpentToday: _spentToday(),
  );
}

  Future<void> _applyAllSchedules(SettingsModel s) async {
    final snap = _computeBudget();
    final dayAllowance = snap.dayAllowance;
    final spentToday = _spentToday();
    final todayRemaining = dayAllowance - spentToday;

    // Mattina
    if (s.morningBudgetEnabled) {
      await NotificationsService.instance.scheduleMorningBudget(
        hour: s.morningBudgetHour,
        minute: s.morningBudgetMinute,
        todayRemaining: todayRemaining ,
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

/* da attivare quando si lancia adesso disattivata per check funzione
 void _openExport() {
  if (!widget.state.isProActive) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(state: widget.state),
      ),
    );
    return;
  }
*/

 void _openExport() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ExportScreen(state: widget.state),
    ),
  );
}
void _openTools() {
  if (!widget.state.isProActive) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(state: widget.state),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ToolsScreen(state: widget.state),
    ),
  );
}
Future<void> _openEmailSupport() async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'quantoposso.app@gmail.com',
    query: 'subject=Supporto Quanto Posso',
  );

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }

  if (!mounted) return;
  await Clipboard.setData(const ClipboardData(text: 'quantoposso.app@gmail.com'));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Email copiata: quantoposso.app@gmail.com'),
    ),
  );
}



void _openSupportPage() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const _SupportPage(),
    ),
  );
}

void _openPrivacyPage() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const _PrivacyPage(),
    ),
  );
}

void _openTermsPage() {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const _TermsPage(),
    ),
  );
}

String get _privacyText => '''
Privacy Policy  
Aggiornata al 23/03/2026  

Quanto Posso ("noi", "nostro") rispetta la tua privacy. La presente Informativa descrive come vengono gestite le informazioni quando utilizzi l’applicazione mobile Quanto Posso.

## Dati raccolti

Quanto Posso non raccoglie dati personali, come ad esempio:
- Nome
- Email
- Numero di telefono
- Posizione

Tutti i dati inseriti dall’utente (come spese e informazioni finanziarie) vengono salvati esclusivamente sul dispositivo dell’utente e non vengono trasmessi ai nostri server.

## Utilizzo dei dati

Poiché non raccogliamo dati personali, non utilizziamo, condividiamo o vendiamo alcuna informazione degli utenti.

## Pagamenti

Tutti i pagamenti e gli abbonamenti sono gestiti in modo sicuro da Apple tramite App Store.  
Non abbiamo accesso ai dati di pagamento dell’utente.

## Conservazione dei dati

I dati vengono salvati localmente sul dispositivo dell’utente.  
Se l’app viene disinstallata, i dati potrebbero essere eliminati definitivamente, salvo eventuali backup del dispositivo.

## Servizi di terze parti

L’app non utilizza strumenti di tracciamento, analisi o pubblicità di terze parti.

## Minori

L’app non è destinata a minori di 13 anni e non raccoglie consapevolmente dati personali di minori.

## Modifiche alla presente informativa

Ci riserviamo il diritto di aggiornare la presente Privacy Policy. Eventuali modifiche saranno rese disponibili all’interno dell’app.

## Contatti

Per qualsiasi domanda relativa alla presente informativa, puoi contattarci all’indirizzo:  
quantoposso.app@gmail.com
''';


String get _termsText => '''
Termini di utilizzo – Quanto Posso

Rimando a : https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

Per supporto o informazioni:
quantoposso.app@gmail.com
''';

void _showAppInfo() {
  showAboutDialog(
    context: context,
    applicationName: 'Quanto Posso',
    applicationVersion: 'v1.0',
    applicationLegalese: '© 2026 Quanto Posso',
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
        final avatarPath = s.profileAvatarPath;
final hasAvatar = avatarPath != null &&
    avatarPath.isNotEmpty &&
    File(avatarPath).existsSync();

        return Scaffold(
          appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
    onPressed: () => Navigator.of(context).maybePop(),
  ),
  title: Text(
    'Menù',
    style: theme.textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  ),
  actions: const [
    Padding(
      padding: EdgeInsets.only(right: 12),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(Icons.tune, color: Color(0xFF1E40AF)),
      ),
    ),
  ],
),
extendBodyBehindAppBar: true,

          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const _BlueHeaderBackground(),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
                children: [
                 

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
  backgroundImage: hasAvatar ? FileImage(File(avatarPath)) : null,
  child: !hasAvatar
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
          onPressed: hasAvatar ? _clearAvatar : null,
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

const SizedBox(height: 18),

Text(
  'Ciclo stipendio',
  style: theme.textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w900,
  ),
),
const SizedBox(height: 6),
Text(
  'Usato per stimare il ciclo del budget. Puoi cambiarlo se cambia lavoro o data accredito.',
  style: theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
    height: 1.3,
  ),
),
const SizedBox(height: 12),

Row(
  children: [
    Text(
      'Giorno ${s.paydayDay}',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
      ),
    ),
    const Spacer(),
    IconButton(
      onPressed: () async {
        final newDay = (s.paydayDay - 1).clamp(1, 31);
        final updated = s.copyWith(paydayDay: newDay);
        await widget.state.saveSettings(updated);
      },
      icon: const Icon(Icons.remove_circle_outline),
    ),
    IconButton(
      onPressed: () async {
        final newDay = (s.paydayDay + 1).clamp(1, 31);
        final updated = s.copyWith(paydayDay: newDay);
        await widget.state.saveSettings(updated);
      },
      icon: const Icon(Icons.add_circle_outline),
    ),
  ],
),

SliderTheme(
  data: SliderTheme.of(context).copyWith(
    trackHeight: 6,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
  ),
  child: Slider(
    min: 1,
    max: 31,
    divisions: 30,
    value: (_paydayDayDraft ?? s.paydayDay.toDouble()).clamp(1, 31),
    label: (_paydayDayDraft ?? s.paydayDay.toDouble()).round().toString(),

    onChanged: (v) {
      setState(() => _paydayDayDraft = v);
    },

    onChangeEnd: (v) async {
      final updated = s.copyWith(paydayDay: v.round());
      await widget.state.saveSettings(updated);

      if (mounted) {
        setState(() => _paydayDayDraft = updated.paydayDay.toDouble());
      }
    },
  ),
),
Row(
  children: [
    Text(
      '1',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
    const Spacer(),
    Text(
      '31',
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  ],
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


const SizedBox(height: 12),

_GlassCard(
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sicurezza',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Blocca app'),
          subtitle: Text(
            s.appLockEnabled
                ? 'Protezione attiva'
                : 'Protezione disattivata',
          ),
          value: s.appLockEnabled,
          onChanged: (v) async {
            if (!v) {
              final updated = s.copyWith(
                appLockEnabled: false,
                appLockType: 'none',
                clearAppLockPin: true,
              );
              await widget.state.saveSettings(updated);
              return;
            }

            if (!mounted) return;

            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Scegli il blocco app',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),

                        ListTile(
                          leading: const Icon(Icons.face_rounded),
                          title: const Text('Face ID / impronta'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            final updated = s.copyWith(
                              appLockEnabled: true,
                              appLockType: 'biometric',
                              clearAppLockPin: true,
                              appLockSetupCompleted: true,
                            );
                            await widget.state.saveSettings(updated);
                          },
                        ),

                        ListTile(
                          leading: const Icon(Icons.pin_rounded),
                          title: const Text('PIN a 4 cifre'),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppPinSetupScreen(
                                  onCompleted: (pin) async {
                                    final updated = widget.state.settings.copyWith(
                                      appLockEnabled: true,
                                      appLockType: 'pin',
                                      appLockPin: pin,
                                      appLockSetupCompleted: true,
                                    );
                                    await widget.state.saveSettings(updated);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        ListTile(
                          leading: const Icon(Icons.security_rounded),
                          title: const Text('Biometria + PIN'),
                          onTap: () async {
                            Navigator.of(context).pop();

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppPinSetupScreen(
                                  onCompleted: (pin) async {
                                    final updated = widget.state.settings.copyWith(
                                      appLockEnabled: true,
                                      appLockType: 'biometric_pin',
                                      appLockPin: pin,
                                      appLockSetupCompleted: true,
                                    );
                                    await widget.state.saveSettings(updated);
                                    if (!mounted) return;
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),

        if (s.appLockEnabled) ...[
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('Tipo di blocco'),
            subtitle: Text(
              switch (s.appLockType) {
                'biometric' => 'Face ID / impronta',
                'pin' => 'PIN a 4 cifre',
                'biometric_pin' => 'Biometria + PIN',
                _ => 'Nessuno',
              },
            ),
          ),
        ],
      ],
    ),
  ),
),



                  const SizedBox(height: 12),
_GlassCard(
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'Supporto',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 10),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.support_agent_outlined),
          title: const Text('Assistenza'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openSupportPage,
        ),

        const Divider(),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openPrivacyPage,
        ),

        const Divider(),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Termini e condizioni'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openTermsPage,
        ),

        const Divider(),

        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mail_outline),
          title: const Text('Contattaci'),
          subtitle: const Text('quantoposso.app@gmail.com'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openEmailSupport,
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
class _SupportPage extends StatelessWidget {
  const _SupportPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistenza')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Hai bisogno di aiuto con Quanto Posso?\n\n'
          'Puoi contattare il supporto scrivendo a:\n\n'
          'quantoposso.app@gmail.com',
        ),
      ),
    );
  }
}
class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Quanto Posso non raccoglie dati personali.\n\n'
          'Le informazioni inserite nell\'app vengono salvate '
          'principalmente sul dispositivo dell\'utente.',
        ),
      ),
    );
  }
}
class _TermsPage extends StatelessWidget {
  const _TermsPage();
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termini e condizioni')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Quanto Posso è un\'app di supporto alla gestione '
          'del budget personale.\n\n'
          'L\'app non fornisce consulenza finanziaria.',
        ),
      ),
    );
  }
}
class ToolsScreen extends StatefulWidget {
  final AppState state;
  const ToolsScreen({super.key, required this.state});
  

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
   bool _showBackupInfo = false;

Widget _backupInfoCard(ThemeData theme) {
  return _GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _showBackupInfo = !_showBackupInfo;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Come funziona il backup?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  _showBackupInfo
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          if (_showBackupInfo) ...[
            const SizedBox(height: 14),
            Text(
              'QuantoPosso salva automaticamente una copia locale dei tuoi dati sul dispositivo ogni volta che modifichi spese, entrate, uscite fisse, obiettivi o impostazioni.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Questo ti permette di:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const _BackupBullet(text: 'ripristinare rapidamente l’ultimo backup automatico'),
            const _BackupBullet(text: 'esportare un backup manuale quando vuoi'),
            const _BackupBullet(text: 'importare un backup salvato in precedenza'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Importante: il backup automatico è locale. Se disinstalli l’app o azzeri il dispositivo, i backup automatici potrebbero non essere recuperabili. Per maggiore sicurezza usa anche “Crea backup”.',
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Future<void> _showBusyDialog({
    required String text,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoneSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmRestore() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Ripristinare backup?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Il ripristino sostituirà tutti i dati attuali con quelli del backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continua'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _BlueHeaderBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Strumenti',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [

                      const SizedBox(height: 8),

                      _backupInfoCard(theme),

                      const SizedBox(height: 12),

                      _GlassCard(
                        child: Column(
                          children: [
                            _ToolTile(
                              icon: Icons.ios_share_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF7C3AED),
                                ],
                              ),
                              title: 'Esporta dati',
                              subtitle: 'PDF e CSV premium',
                              badge: 'PDF',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExportScreen(state: widget.state),
                                  ),
                                );
                              },
                            ),

                            const Divider(height: 1),

                            _ToolTile(
                              icon: Icons.cloud_upload_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                              ),
                              title: 'Crea backup',
                              subtitle: 'Salva tutti i dati dell\'app',
                              badge: 'Backup',
                              onTap: () async {
                                await _showBusyDialog(
                                  text: 'Sto creando il backup...',
                                );

                                try {
                                  await BackupService.instance.exportBackup(widget.state);

                                  if (mounted) Navigator.of(context).pop();

                                  _showDoneSnack('Backup creato con successo ✅');
                                } catch (_) {
                                  if (mounted) Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Errore durante il backup'),
                                    ),
                                  );
                                }
                              },
                            ),

                            const Divider(height: 1),

                            _ToolTile(
                              icon: Icons.cloud_download_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF59E0B),
                                  Color(0xFFF97316),
                                ],
                              ),
                              title: 'Ripristina backup',
                              subtitle: 'Importa dati da backup',
                              badge: 'Restore',
                              onTap: () async {
                                final ok = await _confirmRestore();
                                if (!ok) return;

                                await _showBusyDialog(
                                  text: 'Sto ripristinando il backup...',
                                );

                                try {
                                  await BackupService.instance.importBackup(widget.state);

                                  if (mounted) Navigator.of(context).pop();

                                  _showDoneSnack('Backup ripristinato ✅');
                                } catch (_) {
                                  if (mounted) Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Errore durante il ripristino'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB300)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'I backup proteggono spese, entrate e obiettivi.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupBullet extends StatelessWidget {
  final String text;

  const _BackupBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
