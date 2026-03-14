import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/state.dart';
import '../../services/iap_service.dart';

class ProScreen extends StatelessWidget {
  final AppState state;

  const ProScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final monthly = IapService.instance.monthlyProduct;
    final yearly = IapService.instance.yearlyProduct;
    double? yearlyMonthlyEquivalent;
double? yearlySaving;

if (monthly != null && yearly != null) {
  yearlyMonthlyEquivalent = yearly.rawPrice / 12;
  yearlySaving = (monthly.rawPrice * 12) - yearly.rawPrice;
}

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [

          const _BlueHeaderBackground(),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 60,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "QuantoPosso PRO",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Controlla davvero il tuo denaro",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                _feature("Statistiche avanzate"),
                _feature("Grafici completi"),
                _feature("Previsione spese"),
                _feature("Backup dati"),
                _feature("Export dati"),

                const SizedBox(height: 30),

                _GlassCard(
                  
                  child:Column(
  children: [

    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: state.settings.proTrialUsed
            ? null
            : () async {
                await state.activateTrial();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Prova PRO attivata per 7 giorni"),
                  ),
                );

                Navigator.pop(context);
              },
        child: Text(
          state.settings.proTrialUsed
              ? "Trial già usato"
              : "Prova gratis 7 giorni",
        ),
      ),
    ),

    const SizedBox(height: 20),

    _planCard(
      title: "Mensile",
      subtitle: "Accesso completo",
      price: monthly?.price ?? "1,99 €/mese",
      onTap: () async {
        await IapService.instance.buyMonthly();
      },
    ),

    const SizedBox(height: 12),

    _planCard(
      title: "Annuale",
      subtitle: yearlyMonthlyEquivalent != null
          ? "${yearlyMonthlyEquivalent.toStringAsFixed(2)} €/mese"
          : "Miglior prezzo",
      price: yearly?.price ?? "14,99 €/anno",
      highlight: true,
      badge: "PIÙ POPOLARE",
      saving: yearlySaving != null
          ? "Risparmi ${yearlySaving.toStringAsFixed(2)}€"
          : null,
      onTap: () async {
        await IapService.instance.buyYearly();
      },
    ),
  ],
),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () async {
                    await IapService.instance.restorePurchases();

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ripristino acquisti avviato"),
                      ),
                    );
                  },
                  child: const Text("Ripristina acquisti"),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  Widget _planCard({
  required String title,
  required String price,
  required VoidCallback onTap,
  String? subtitle,
  bool highlight = false,
  String? badge,
  String? saving,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight ? Colors.blue : Colors.grey.shade300,
        width: highlight ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
          ],
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
          ),
        ],

        const SizedBox(height: 10),

        Row(
          children: [

            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: onTap,
              child: const Text("Scegli"),
            )
          ],
        ),

        if (saving != null) ...[
          const SizedBox(height: 6),
          Text(
            saving,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]
      ],
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
    final p = Paint()..color = Colors.white.withOpacity(0.1);

    final path = Path()
      ..moveTo(0, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.10,
        size.width * 0.55,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}