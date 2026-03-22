import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/services/app_lock_service.dart';

class AppUnlockScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onUnlocked;

  const AppUnlockScreen({
    super.key,
    required this.state,
    required this.onUnlocked,
  });

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen> {
  String _pin = '';
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricIfNeeded();
    });
  }

  Future<void> _tryBiometricIfNeeded() async {
    final type = widget.state.settings.appLockType;
    if (type == 'biometric' || type == 'biometric_pin') {
      setState(() => _loading = true);
      final ok = await AppLockService.instance.authenticate();
      if (!mounted) return;
      setState(() => _loading = false);

      if (ok) {
        widget.onUnlocked();
      }
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;

    setState(() {
      _pin += digit;
      _error = null;
    });

    if (_pin.length == 4) {
      final savedPin = widget.state.settings.appLockPin;
      if (_pin == savedPin) {
        widget.onUnlocked();
      } else {
        setState(() {
          _pin = '';
          _error = 'PIN errato';
        });
      }
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.state.settings.appLockType;
    final showPin = type == 'pin' || type == 'biometric_pin';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 72),
              const SizedBox(height: 16),
              const Text(
                'QuantoPosso bloccata',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                showPin
                    ? 'Sblocca con PIN o biometria'
                    : 'Autenticati per continuare',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_loading) const CircularProgressIndicator(),

              if (showPin) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: filled ? Colors.blue : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],

              const Spacer(),

              if (type == 'biometric' || type == 'biometric_pin')
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: _tryBiometricIfNeeded,
                    icon: const Icon(Icons.face_rounded),
                    label: const Text('Sblocca con Face ID / impronta'),
                  ),
                ),

              if (showPin)
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final digit in ['1','2','3','4','5','6','7','8','9'])
                      _PinButton(
                        label: digit,
                        onTap: () => _onDigit(digit),
                      ),
                    const SizedBox(width: 84),
                    _PinButton(
                      label: '0',
                      onTap: () => _onDigit('0'),
                    ),
                    _PinButton(
                      icon: Icons.backspace_outlined,
                      onTap: _backspace,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PinButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
        ),
        child: icon != null
            ? Icon(icon)
            : Text(
                label!,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}