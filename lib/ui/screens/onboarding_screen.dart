import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import 'home_shell.dart';
import 'package:quantoposso/services/app_lock_service.dart';
import 'package:quantoposso/ui/screens/security/pin_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final AppState state;
  const OnboardingScreen({super.key, required this.state});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();

  String _ageRange = '25-34';
  String _job = 'Operaio';
  String _reason = 'Risparmiare';
  String _goal = 'Auto';

  double _monthlySaving = 300;
  double _paydayDay = 28;
  bool _saving = false;

  bool _biometricAvailable = false;
bool _appLockEnabled = false;
String _appLockType = 'none'; // none | biometric | pin | biometric_pin
String? _appLockPin;

  @override
  void initState() {
    super.initState();

    final s = widget.state.settings;
    _monthlySaving = s.monthlySaving;
    _paydayDay = s.paydayDay.toDouble();

    if ((s.profileName ?? '').trim().isNotEmpty) {
      _nameCtrl.text = s.profileName!.trim();
    }

    _appLockEnabled = s.appLockEnabled;
    _appLockType = s.appLockType;
    _appLockPin = s.appLockPin;

    _loadBiometricAvailability();

  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricAvailability() async {
    final available = await AppLockService.instance.isAvailable();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
  }

  String get _securitySubtitle {
    switch (_appLockType) {
      case 'biometric':
        return 'Face ID / impronta attivi';
      case 'pin':
        return 'PIN a 4 cifre attivo';
      case 'biometric_pin':
        return 'Biometria + PIN attivi';
      default:
        return 'Nessun blocco impostato';
    }
  }

  Future<void> _selectNoLock() async {
    setState(() {
      _appLockEnabled = false;
      _appLockType = 'none';
      _appLockPin = null;
    });
  }

  Future<void> _selectBiometric() async {
    setState(() {
      _appLockEnabled = true;
      _appLockType = 'biometric';
      _appLockPin = null;
    });
  }

  Future<void> _selectPinOnly() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          onCompleted: (pin) {
            _appLockEnabled = true;
            _appLockType = 'pin';
            _appLockPin = pin;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _selectBiometricPin() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          onCompleted: (pin) {
            _appLockEnabled = true;
            _appLockType = 'biometric_pin';
            _appLockPin = pin;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _finish() async {
    if (_saving) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);

    final s = widget.state.settings;
    final name = _nameCtrl.text.trim();

    final profile = UserProfile(
      name: name,
      ageRange: _ageRange,
      job: _job,
      reason: _reason,
      goal: _goal,
    );

    await widget.state.saveSettings(
      s.copyWith(
        onboardingCompleted: true,
        monthlySaving: _monthlySaving,
        paydayDay: _paydayDay.round(),
        profileName: name,
        appLockEnabled: _appLockEnabled,
        appLockType: _appLockType,
        appLockPin: _appLockPin,
        clearAppLockPin: _appLockType == 'none',
        appLockSetupCompleted: true,
      ),
    );

    await widget.state.saveProfile(profile);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeShell(state: widget.state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final euro = _monthlySaving.toStringAsFixed(0);

    return Scaffold(
      body: Stack(
        children: [
          const _OnboardingBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Quanto Posso',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Benvenuto 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Impostiamo 2 cose e sei pronto a capire quanto puoi spendere davvero.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                const _StepPills(),
                const SizedBox(height: 18),
                _GlassCard(
                  radius: 28,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _SectionTitle(
                            icon: Icons.person_outline_rounded,
                            title: 'Profilo',
                            subtitle: 'Ci aiuta a personalizzare meglio l’esperienza.',
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Come ti chiami?',
                              hintText: 'Es. Daniele',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              final t = (v ?? '').trim();
                              if (t.isEmpty) return 'Inserisci il nome';
                              if (t.length < 2) return 'Nome troppo corto';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _DropRowPremium(
                            label: 'Fascia età',
                            icon: Icons.cake_outlined,
                            value: _ageRange,
                            items: const ['18-24', '25-34', '35-44', '45-54', '55+'],
                            onChanged: (v) => setState(() => _ageRange = v),
                          ),
                          const SizedBox(height: 12),
                          _DropRowPremium(
                            label: 'Lavoro',
                            icon: Icons.work_outline_rounded,
                            value: _job,
                            items: const [
                              'Operaio',
                              'Impiegato',
                              'Autonomo',
                              'Studente',
                              'Altro',
                            ],
                            onChanged: (v) => setState(() => _job = v),
                          ),
                          const SizedBox(height: 12),
                          _DropRowPremium(
                            label: 'Motivo principale',
                            icon: Icons.insights_outlined,
                            value: _reason,
                            items: const [
                              'Risparmiare',
                              'Controllare spese',
                              'Rientrare dai debiti',
                              'Altro',
                            ],
                            onChanged: (v) => setState(() => _reason = v),
                          ),
                          const SizedBox(height: 12),
                          _DropRowPremium(
                            label: 'Obiettivo',
                            icon: Icons.emoji_events_outlined,
                            value: _goal,
                            items: const [
                              'Auto',
                              'Viaggio',
                              'Casa',
                              'Emergenze',
                              'Altro',
                            ],
                            onChanged: (v) => setState(() => _goal = v),
                          ),
                          const SizedBox(height: 18),
                          _SavingCard(
                            euro: euro,
                            monthlySaving: _monthlySaving,
                            onMinus: () => setState(() {
                              _monthlySaving = (_monthlySaving - 10).clamp(0, 5000);
                            }),
                            onPlus: () => setState(() {
                              _monthlySaving = (_monthlySaving + 10).clamp(0, 5000);
                            }),
                            onSlider: (v) => setState(() => _monthlySaving = v),
                          ),
                          const SizedBox(height: 16),

Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(22),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF8FAFF), Color(0xFFF4F6FA)],
    ),
    border: Border.all(
      color: theme.dividerColor.withValues(alpha: 0.35),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Quando ricevi di solito lo stipendio?',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Ci serve per stimare il ciclo del budget.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Text(
            'Giorno ${_paydayDay.round()}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          _RoundIconButton(
            icon: Icons.remove_rounded,
            onTap: () => setState(() {
              _paydayDay = (_paydayDay - 1).clamp(1, 31);
            }),
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.add_rounded,
            onTap: () => setState(() {
              _paydayDay = (_paydayDay + 1).clamp(1, 31);
            }),
          ),
        ],
      ),
      const SizedBox(height: 8),
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
          value: _paydayDay.clamp(1, 31),
          label: _paydayDay.round().toString(),
          onChanged: (v) => setState(() => _paydayDay = v),
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

                          const SizedBox(height: 16),

                          _SecurityCard(
                            biometricAvailable: _biometricAvailable,
                            currentType: _appLockType,
                            subtitle: _securitySubtitle,
                            onNoLock: _selectNoLock,
                            onBiometric: _selectBiometric,
                            onPin: _selectPinOnly,
                            onBiometricPin: _selectBiometricPin,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _finish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                                label: Text(
                                  _saving ? 'Salvataggio...' : 'Continua',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

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
            stops: [0.0, 0.34, 0.34, 1.0],
          ),
        ),
        child: CustomPaint(painter: _OnboardingWavePainter()),
      ),
    );
  }
}

class _OnboardingWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(0, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.11,
        size.width * 0.56,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width,
        size.height * 0.19,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({
    required this.child,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 14),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StepPills extends StatelessWidget {
  const _StepPills();

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, bool active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.white
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF1D4ED8) : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill('Profilo', true),
        pill('Abitudini', false),
        pill('Obiettivo', false),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropRowPremium extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropRowPremium({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _SavingCard extends StatelessWidget {
  final String euro;
  final double monthlySaving;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<double> onSlider;

  const _SavingCard({
    required this.euro,
    required this.monthlySaving,
    required this.onMinus,
    required this.onPlus,
    required this.onSlider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFF), Color(0xFFF4F6FA)],
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quanto vuoi risparmiare al mese?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lo useremo per calcolare automaticamente quanto puoi spendere ogni giorno.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '$euro € / mese',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _RoundIconButton(
                icon: Icons.remove_rounded,
                onTap: onMinus,
              ),
              const SizedBox(width: 8),
              _RoundIconButton(
                icon: Icons.add_rounded,
                onTap: onPlus,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            ),
            child: Slider(
              min: 0,
              max: 2000,
              divisions: 200,
              value: monthlySaving.clamp(0, 2000),
              onChanged: onSlider,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '0€',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '2000€',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final bool biometricAvailable;
  final String currentType;
  final String subtitle;
  final VoidCallback onNoLock;
  final VoidCallback onBiometric;
  final VoidCallback onPin;
  final VoidCallback onBiometricPin;

  const _SecurityCard({
    required this.biometricAvailable,
    required this.currentType,
    required this.subtitle,
    required this.onNoLock,
    required this.onBiometric,
    required this.onPin,
    required this.onBiometricPin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget option({
      required IconData icon,
      required String title,
      required String value,
      required VoidCallback onTap,
    }) {
      final selected = currentType == value;

      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEEF2FF)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : theme.dividerColor.withValues(alpha: 0.35),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : null,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2563EB),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFF), Color(0xFFF4F6FA)],
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sicurezza',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Proteggi QuantoPosso quando apri l’app. Puoi cambiare questa scelta in qualsiasi momento.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          option(
            icon: Icons.lock_open_rounded,
            title: 'Nessun blocco',
            value: 'none',
            onTap: onNoLock,
          ),
          const SizedBox(height: 10),
          if (biometricAvailable) ...[
            option(
              icon: Icons.face_rounded,
              title: 'Face ID / impronta',
              value: 'biometric',
              onTap: onBiometric,
            ),
            const SizedBox(height: 10),
          ],
          option(
            icon: Icons.pin_rounded,
            title: 'PIN a 4 cifre',
            value: 'pin',
            onTap: onPin,
          ),
          if (biometricAvailable) ...[
            const SizedBox(height: 10),
            option(
              icon: Icons.security_rounded,
              title: 'Biometria + PIN',
              value: 'biometric_pin',
              onTap: onBiometricPin,
            ),
          ],
        ],
      ),
    );
  }
}
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: const Color(0xFF1D4ED8)),
        ),
      ),
    );
  }
}