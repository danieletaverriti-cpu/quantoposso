import 'dart:ui';
import 'package:flutter/material.dart';

class AppPinSetupScreen extends StatefulWidget {
  final void Function(String pin) onCompleted;

  const AppPinSetupScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<AppPinSetupScreen> createState() => _AppPinSetupScreenState();
}

class _AppPinSetupScreenState extends State<AppPinSetupScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _confirmMode = false;
  String? _error;

  void _onDigit(String digit) {
    setState(() {
      if (!_confirmMode) {
        if (_firstPin.length < 4) _firstPin += digit;
        if (_firstPin.length == 4) {
          _confirmMode = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit;
        if (_confirmPin.length == 4) {
          if (_confirmPin == _firstPin) {
            widget.onCompleted(_firstPin);
          } else {
            _error = 'I codici non coincidono';
            _firstPin = '';
            _confirmPin = '';
            _confirmMode = false;
          }
        }
      }
    });
  }

  void _backspace() {
    setState(() {
      if (!_confirmMode) {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = _confirmMode ? _confirmPin : _firstPin;
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 50),
                        const SizedBox(height: 20),
                        Text(
                          _confirmMode
                              ? 'Conferma il PIN'
                              : 'Scegli un PIN a 4 cifre',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final filled = i < value.length;
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
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 30),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final d in ['1','2','3','4','5','6','7','8','9'])
                              _btn(d, () => _onDigit(d)),
                            const SizedBox(width: 84),
                            _btn('0', () => _onDigit('0')),
                            _btnIcon(Icons.backspace, _backspace),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        ),
        child: Icon(icon),
      ),
    );
  }
}