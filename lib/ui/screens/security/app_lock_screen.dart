import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class AppLockScreen extends StatefulWidget {
  final String? pin;
  final String type; // biometric | pin | biometric_pin

  const AppLockScreen({
    super.key,
    required this.type,
    this.pin,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _localAuth = LocalAuthentication();

  String _input = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (widget.type == 'biometric' || widget.type == 'biometric_pin') {
      try {
        final ok = await _localAuth.authenticate(
          localizedReason: 'Sblocca QuantoPosso',
          options: const AuthenticationOptions(
            biometricOnly: true,
          ),
        );

        if (ok && mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (_) {}
    }
  }

  void _onDigit(String d) {
    setState(() {
      if (_error != null) _error = null;

      if (_input.length < 4) _input += d;

      if (_input.length == 4) {
        if (_input == widget.pin) {
          Navigator.of(context).pop(true);
        } else {
          _error = 'PIN errato';
          _input = '';
        }
      }
    });
  }

  void _back() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPin = widget.type == 'pin' || widget.type == 'biometric_pin';
    final showBiometricRetry =
        widget.type == 'biometric' || widget.type == 'biometric_pin';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock, color: Colors.white, size: 50),
              const SizedBox(height: 20),
              const Text(
                'Sblocca QuantoPosso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (showBiometricRetry) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.face, color: Colors.white),
                  label: const Text(
                    'Riprova Face ID / impronta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (showPin) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _input.length;
                    return Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: filled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _btn(d, () => _onDigit(d)),
                    const SizedBox(width: 84),
                    _btn('0', () => _onDigit('0')),
                    _btnIcon(Icons.backspace, _back),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String text, VoidCallback onTap) {
    return SizedBox(
      width: 84,
      height: 84,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _btnIcon(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 84,
      height: 84,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.white,
        ),
        child: Icon(icon),
      ),
    );
  }
}