import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final AppState state;
  const SplashScreen({super.key, required this.state});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _breathCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _outroCtrl;

  late final Animation<double> _introOpacity;
  late final Animation<double> _introScale;
  late final Animation<double> _breath;
  late final Animation<double> _outroOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _introCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _outroCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    _introOpacity = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _introScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack),
    );
    _breath = Tween<double>(begin: 0.985, end: 1.03).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _outroOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _outroCtrl, curve: Curves.easeIn),
    );

    _introCtrl.forward();

    _bootAndGo();
  }

  Future<void> _bootAndGo() async {
    // ✅ vogliamo vedere lo splash almeno X ms, ma intanto inizializziamo davvero lo state
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 2200));

    try {
      await widget.state.init(); // ✅ QUI È IL PUNTO CHIAVE
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Splash: state.init() error: $e');
        debugPrint('$st');
      }
    }

    await minSplash;

    if (!mounted || _navigated) return;
    _navigated = true;

    try {
      await _outroCtrl.forward();
    } catch (_) {}

    if (!mounted) return;

    final completed = widget.state.settings.onboardingCompleted;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) =>
            completed ? HomeShell(state: widget.state) : OnboardingScreen(state: widget.state),
        transitionsBuilder: (_, anim, __, child) {
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _bgCtrl.dispose();
    _breathCtrl.dispose();
    _dotsCtrl.dispose();
    _outroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _outroCtrl,
        builder: (_, __) {
          return Opacity(
            opacity: _outroOpacity.value,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (_, __) {
                    final t = _bgCtrl.value;
                    return Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-1.0 + 0.6 * t, -1.0),
                            end: Alignment(1.0, 1.0 - 0.6 * t),
                            colors: const [
                              Color(0xFF1D4ED8),
                              Color(0xFF2563EB),
                              Color(0xFF7C3AED),
                            ],
                          ),
                        ),
                        child: CustomPaint(painter: _SoftWavesPainter(progress: t)),
                      ),
                    );
                  },
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_introCtrl, _breathCtrl]),
                    builder: (_, __) {
                      return Opacity(
                        opacity: _introOpacity.value,
                        child: Transform.scale(
                          scale: _introScale.value * _breath.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 230,
                                    height: 230,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.10),
                                          Colors.white.withValues(alpha: 0.12),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.55, 1.0],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 170,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(alpha: 0.18),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                  ),
                                  Image.asset('assets/images/logo.png', width: 170),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Quanto Posso',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _LoadingDots(controller: _dotsCtrl),
                              const SizedBox(height: 6),
                              Text(
                                'Calcolo budget in corso…',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SoftWavesPainter extends CustomPainter {
  final double progress;
  _SoftWavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withValues(alpha: 0.08);
    final p2 = Paint()..color = Colors.white.withValues(alpha: 0.06);

    double wave(double x, double yBase, double amp, double freq, double phase) {
      return yBase + amp * math.sin((x / size.width) * freq * math.pi * 2 + phase);
    }

    final phase = progress * math.pi * 2;

    Path makeWave(double yBase, double amp, double freq, double phaseShift) {
      final path = Path()..moveTo(0, wave(0, yBase, amp, freq, phase + phaseShift));
      for (double x = 0; x <= size.width; x += 12) {
        path.lineTo(x, wave(x, yBase, amp, freq, phase + phaseShift));
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
      return path;
    }

    canvas.drawPath(makeWave(size.height * 0.22, 16, 1.15, 0.0), p1);
    canvas.drawPath(makeWave(size.height * 0.30, 12, 1.35, 1.2), p2);
  }

  @override
  bool shouldRepaint(covariant _SoftWavesPainter oldDelegate) => oldDelegate.progress != progress;
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final n = (controller.value * 3).floor() % 4;
        final text = '.' * n;
        return Text(
          text.padRight(3, ' '),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
          ),
        );
      },
    );
  }
}