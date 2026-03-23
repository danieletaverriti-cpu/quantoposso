import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/state.dart';
import '../../services/iap_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProScreen extends StatefulWidget {
  final AppState state;

  const ProScreen({super.key, required this.state});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulse = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
    _repeatPulse();
  }

  Future<void> _repeatPulse() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      await _controller.animateTo(1.0);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buyMonthly() async {
    try {
      await IapService.instance.buyMonthly();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquisto mensile avviato')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore acquisto mensile: $e')),
      );
    }
  }

  Future<void> _buyYearly() async {
    try {
      await IapService.instance.buyYearly();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquisto annuale avviato')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore acquisto annuale: $e')),
      );
    }
  }

  Future<void> _restore() async {
    try {
      await IapService.instance.restorePurchases();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ripristino acquisti avviato')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore ripristino: $e')),
      );
    }
  }

  Future<void> _openPrivacyPolicy() async {
  final uri = Uri.parse('https://victorious-argon-075.notion.site/Privacy-Policy-Quanto-Posso-32cdb36f4b6080e4b1dae80dd3b5aa7c');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _openTerms() async {
  final uri = Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

  Future<void> _startTrial() async {
    await widget.state.activateTrial();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prova PRO attivata per 7 giorni'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.state;

    final monthly = IapService.instance.monthlyProduct;
    final yearly = IapService.instance.yearlyProduct;

    double? yearlyMonthlyEquivalent;
    double? yearlySavingPercent;
    double? yearlySavingAmount;

    if (monthly != null && yearly != null) {
      yearlyMonthlyEquivalent = yearly.rawPrice / 12;
      yearlySavingAmount = (monthly.rawPrice * 12) - yearly.rawPrice;
      final fullYearMonthly = monthly.rawPrice * 12;
      if (fullYearMonthly > 0) {
        yearlySavingPercent = (yearlySavingAmount / fullYearMonthly) * 100;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _BlueHeaderBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.96, end: 1.0),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              final pulseValue =
                                  1 + (math.sin(DateTime.now().millisecond / 1000 * 2 * math.pi) * 0.01);
                              return Transform.scale(
                                scale: value * pulseValue,
                                child: child,
                              );
                            },
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFE082),
                                    Color(0xFFFFB300),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 28,
                                    spreadRadius: 1,
                                    color:
                                        Colors.amber.withValues(alpha: 0.32),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'QuantoPosso PRO',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Più controllo, più analisi,\npiù risparmio.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _GlassCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Cosa sblocchi con PRO',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 14),
      const _FeatureRow(
        icon: Icons.insights_rounded,
        text: 'Statistiche avanzate',
      ),
      const _FeatureRow(
        icon: Icons.stacked_line_chart_rounded,
        text: 'Grafici completi',
      ),
      const _FeatureRow(
        icon: Icons.auto_graph_rounded,
        text: 'Previsione spese',
      ),
      const _FeatureRow(
        icon: Icons.cloud_done_rounded,
        text: 'Backup automatico dei dati',
      ),
      const _FeatureRow(
        icon: Icons.restore_rounded,
        text: 'Ripristino rapido del backup',
      ),
      const _FeatureRow(
        icon: Icons.ios_share_rounded,
        text: 'Export dati PDF e CSV',
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFB300),
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Con PRO i tuoi dati restano protetti con backup automatico e ripristino semplice quando ne hai bisogno.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
                    const SizedBox(height: 16),
                    _GlassCard(
                      child: Column(
                        children: [
                          Container(
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: LinearGradient(
      colors: state.settings.proTrialUsed
          ? [
              const Color(0xFF94A3B8),
              const Color(0xFF64748B),
            ]
          : [
              const Color(0xFF2563EB),
              const Color(0xFF7C3AED),
            ],
    ),
    boxShadow: [
      BoxShadow(
        blurRadius: 18,
        offset: const Offset(0, 8),
        color: const Color(0xFF2563EB).withValues(alpha: 0.22),
      ),
    ],
  ),
  child: ElevatedButton.icon(
    onPressed: state.settings.proTrialUsed ? null : _startTrial,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      disabledForegroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
    ),
    icon: Icon(
      Icons.bolt_rounded,
      color: Colors.white.withValues(alpha: state.settings.proTrialUsed ? 0.85 : 1),
    ),
    label: Text(
      state.settings.proTrialUsed
          ? 'Prova già utilizzata'
          : 'Prova PRO gratis per 7 giorni',
      style: TextStyle(
        color: Colors.white.withValues(alpha: state.settings.proTrialUsed ? 0.85 : 1),
        fontWeight: FontWeight.w900,
        fontSize: 17,
      ),
    ),
  ),
),
const SizedBox(height: 8),
Text(
  state.settings.proTrialUsed
      ? 'Puoi comunque scegliere un piano PRO qui sotto'
      : 'Annulla quando vuoi',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.80),
  ),
),
                          const SizedBox(height: 18),
                          _PlanCard(
                            title: 'Mensile',
                            subtitle: 'Accesso completo a tutte le funzioni PRO',
                            price: monthly?.price ?? '2,99 €/mese',
                            buttonText: 'Scegli',
                            onTap: _buyMonthly,
                          ),
                          const SizedBox(height: 14),
                          _PlanCard(
                            title: 'Annuale',
                            subtitle: yearlyMonthlyEquivalent != null
                                ? '${yearlyMonthlyEquivalent.toStringAsFixed(2)} €/mese'
                                : 'Miglior rapporto qualità/prezzo',
                            price: yearly?.price ?? '17,99 €/anno',
                            buttonText: 'Scegli',
                            badge: 'PIÙ POPOLARE',
                            saving: yearlySavingAmount != null
                                ? yearlySavingPercent != null
                                    ? 'Risparmi ${yearlySavingAmount.toStringAsFixed(2)}€ • ${yearlySavingPercent.toStringAsFixed(0)}%'
                                    : 'Risparmi ${yearlySavingAmount.toStringAsFixed(2)}€'
                                : null,
                            highlight: true,
                            onTap: _buyYearly,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
  onPressed: _restore,
  child: const Text(
    'Ripristina acquisti',
    style: TextStyle(
      fontWeight: FontWeight.w800,
    ),
  ),
),

const SizedBox(height: 6),

// 🔗 LINK OBBLIGATORI (Apple)
Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: 6,
  children: [
    TextButton(
      onPressed: _openPrivacyPolicy,
      child: const Text(
        'Privacy Policy',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    const Text(
      '•',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    ),
    TextButton(
      onPressed: _openTerms,
      child: const Text(
        'Termini di utilizzo',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  ],
),

const SizedBox(height: 6),

// 📄 TESTO LEGALE OBBLIGATORIO
Text(
  'Abbonamento mensile: 1 mese a ${monthly?.price ?? '2,99 €/mese'}. '
  'Abbonamento annuale: 1 anno a ${yearly?.price ?? '17,99 €/anno'}. '
  'Il pagamento verrà addebitato sull’Apple ID alla conferma dell’acquisto. '
  'L’abbonamento si rinnova automaticamente salvo disdetta almeno 24 ore prima della scadenza. '
  'Il rinnovo verrà addebitato entro le 24 ore precedenti la fine del periodo corrente. '
  'Puoi gestire o annullare l’abbonamento dalle impostazioni del tuo account Apple. '
  'Eventuale periodo di prova gratuito verrà annullato se acquisti un abbonamento.',
  textAlign: TextAlign.center,
  style: theme.textTheme.bodySmall?.copyWith(
    color: Colors.white.withValues(alpha: 0.80),
    height: 1.4,
  ),
),
                    Text(
                      'L’abbonamento si rinnova automaticamente salvo disattivazione dalle impostazioni dello store.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String? subtitle;
  final String? badge;
  final String? saving;
  final bool highlight;
  final String buttonText;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.onTap,
    required this.buttonText,
    this.subtitle,
    this.badge,
    this.saving,
    this.highlight = false,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.highlight
                ? const Color(0xFFEEF4FF)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.highlight
                  ? const Color(0xFF2563EB)
                  : Colors.grey.shade300,
              width: widget.highlight ? 2 : 1,
            ),
            boxShadow: [
              if (widget.highlight)
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.price,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2563EB),
                          Color(0xFF7C3AED),
                        ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        widget.buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.saving != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.saving!,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}