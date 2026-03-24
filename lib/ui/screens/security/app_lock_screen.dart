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
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _input = '';
  String? _error;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;

    final canUseBiometric =
        widget.type == 'biometric' || widget.type == 'biometric_pin';

    if (!canUseBiometric) return;

    _isAuthenticating = true;

    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Sblocca QuantoPosso',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      // niente: lasciamo eventuale fallback PIN o bottone riprova
    } finally {
      _isAuthenticating = false;
    }
  }

  void _onDigit(String d) {
    setState(() {
      if (_error != null) _error = null;

      if (_input.length < 4) {
        _input += d;
      }

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
        _error = null;
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'App protetta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sblocca per continuare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (showBiometricRetry) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _tryBiometric,
                        icon: const Icon(Icons.face_rounded),
                        label: const Text('Riprova Face ID / impronta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF111827),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showPin) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'oppure inserisci il PIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _input.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: filled
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 22,
                      child: _error == null
                          ? null
                          : Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFFD6D6),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final d
                            in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                          _btn(d, () => _onDigit(d)),
                        const SizedBox(width: 84, height: 84),
                        _btn('0', () => _onDigit('0')),
                        _btnIcon(Icons.backspace_rounded, _back),
                      ],
                    ),
                  ],
                ],
              ),
            ),
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
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
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
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}