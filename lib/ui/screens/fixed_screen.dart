import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/format.dart';

class FixedScreen extends StatelessWidget {
  final AppState state;
  const FixedScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final total = state.fixed.fold<double>(0, (s, e) => s + e.amount);

        final incomeTotal = state.incomes.fold<double>(0, (s, i) => s + i.amount);
        final percent = incomeTotal <= 0 ? 0.0 : (total / incomeTotal).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                const _BlueHeaderBackground(),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Uscite fisse mensili',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.lock, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tieni sotto controllo tutte le spese ricorrenti del mese.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${state.fixed.length} voci',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Totale uscite fisse',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    euro(total),
                                    style: theme.textTheme.displaySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Queste uscite verranno considerate ogni mese',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 12,
                                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF6EE7B7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    incomeTotal <= 0
                                        ? 'Aggiungi entrate per vedere il peso delle uscite fisse'
                                        : 'Le spese fisse occupano il ${(percent * 100).round()}% delle entrate',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => _AddEditFixedDialog(
                                      onSave: state.addFixed,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  label: const Text(
                                    'Aggiungi uscita fissa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (state.fixed.isEmpty)
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            'Non hai ancora inserito uscite fisse.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...state.fixed.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FixedRow(
                            expense: e,
                            onDelete: state.deleteFixed,
                            onEdit: () => showDialog(
                              context: context,
                              builder: (_) => _AddEditFixedDialog(
                                existing: e,
                                onSave: state.addFixed,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FixedRow extends StatelessWidget {
  final FixedExpense expense;
  final void Function(String id) onDelete;
  final VoidCallback onEdit;

  const _FixedRow({
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  IconData _iconForName(String name) {
    final n = name.toLowerCase();
    if (n.contains('affitto') || n.contains('mutuo') || n.contains('casa')) {
      return Icons.home_rounded;
    }
    if (n.contains('netflix') ||
        n.contains('spotify') ||
        n.contains('disney') ||
        n.contains('prime')) {
      return Icons.subscriptions_rounded;
    }
    if (n.contains('vodafone') ||
        n.contains('tim') ||
        n.contains('wind') ||
        n.contains('iliad')) {
      return Icons.phone_iphone_rounded;
    }
    if (n.contains('luce') || n.contains('gas') || n.contains('bolletta')) {
      return Icons.bolt_rounded;
    }
    if (n.contains('internet') || n.contains('fibra')) {
      return Icons.wifi_rounded;
    }
    return Icons.currency_exchange_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => onDelete(expense.id),
      child: _GlassCard(
        child: ListTile(
          onTap: onEdit,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
            ),
            child: Icon(
              _iconForName(expense.name),
              color: Colors.white,
              size: 30,
            ),
          ),
          title: Text(
            expense.name.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Tocca per modificare',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                euro(expense.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'mensile',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEditFixedDialog extends StatefulWidget {
  final FixedExpense? existing;
  final Future<void> Function(FixedExpense e) onSave;

  const _AddEditFixedDialog({
    required this.onSave,
    this.existing,
  });

  @override
  State<_AddEditFixedDialog> createState() => _AddEditFixedDialogState();
}

class _AddEditFixedDialogState extends State<_AddEditFixedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _amount = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.amount
              .toStringAsFixed(
                widget.existing!.amount == widget.existing!.amount.roundToDouble()
                    ? 0
                    : 2,
              )
              .replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fixed = FixedExpense(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      amount: double.parse(_amount.text.trim().replaceAll(',', '.')),
    );

    await widget.onSave(fixed);

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit ? 'Uscita fissa aggiornata ✅' : 'Uscita fissa aggiunta ✅',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifica uscita fissa' : 'Nuova uscita fissa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci un nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo',
                hintText: 'es. 19,99',
              ),
              validator: (v) {
                final x = (v ?? '').trim();
                if (x.isEmpty) return 'Inserisci un importo';
                final parsed = double.tryParse(x.replaceAll(',', '.'));
                if (parsed == null) return 'Formato non valido';
                if (parsed <= 0) return 'Deve essere > 0';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salva'),
        ),
      ],
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
            stops: [0.0, 0.34, 0.34, 1.0],
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({
    required this.child,
    this.radius = 20,
  });

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