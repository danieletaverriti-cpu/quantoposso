import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/format.dart';

class GoalsScreen extends StatelessWidget {
  final AppState state;
  const GoalsScreen({super.key, required this.state});

  Gradient _goalGradient(Goal goal) {
    final p = goal.progress.clamp(0.0, 1.0);

    if (p >= 1) {
      return const LinearGradient(
        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (p >= 0.6) {
      return const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (p >= 0.25) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF64748B), Color(0xFF334155)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _goalAccent(Goal goal) {
    final p = goal.progress.clamp(0.0, 1.0);

    if (p >= 1) return const Color(0xFF16A34A);
    if (p >= 0.6) return const Color(0xFF2563EB);
    if (p >= 0.25) return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final goals = state.goals.toList()
          ..sort((a, b) => b.progress.compareTo(a.progress));

        final topGoal = goals.isEmpty ? null : goals.first;

        return SafeArea(
          child: Stack(
            children: [
              const _GoalsBackground(),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Obiettivi di risparmio',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                              color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => _AddGoalDialog(onAdd: state.addGoal),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Nuovo',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tieni d’occhio i tuoi traguardi e aggiorna i progressi quando vuoi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (topGoal != null) ...[
                    _TopGoalHero(
                      goal: topGoal,
                      gradient: _goalGradient(topGoal),
                      accent: _goalAccent(topGoal),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (goals.isEmpty)
                    const _EmptyGoalsCard()
                  else
                    ...goals.map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GoalCardPremium(
                          goal: g,
                          accent: _goalAccent(g),
                          gradient: _goalGradient(g),
                          onUpdate: state.addGoal,
                          onDelete: state.deleteGoal,
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

class _GoalsBackground extends StatelessWidget {
  const _GoalsBackground();

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
            stops: [0.0, 0.26, 0.26, 1.0],
          ),
        ),
        child: CustomPaint(painter: _GoalsWavePainter()),
      ),
    );
  }
}

class _GoalsWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final path = Path()
      ..moveTo(0, size.height * 0.13)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.08,
        size.width * 0.52,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.22,
        size.width,
        size.height * 0.16,
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
    this.radius = 22,
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

class _TopGoalHero extends StatelessWidget {
  final Goal goal;
  final Gradient gradient;
  final Color accent;

  const _TopGoalHero({
    required this.goal,
    required this.gradient,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = (goal.targetAmount - goal.currentAmount).clamp(0, double.infinity);
    final estimatedMonths = goal.currentAmount <= 0
        ? null
        : ((goal.targetAmount - goal.currentAmount) / (goal.currentAmount <= 0 ? 1 : goal.currentAmount))
            .abs();

    return _GlassCard(
      radius: 26,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: gradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${(goal.progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${euro(goal.currentAmount)} / ${euro(goal.targetAmount)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    missing <= 0
                        ? 'Obiettivo completato 🎉'
                        : 'Mancano ${euro(missing)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: goal.progress.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _GoalMiniStat(
                    title: 'Target',
                    value: euro(goal.targetAmount),
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GoalMiniStat(
                    title: 'Accantonato',
                    value: euro(goal.currentAmount),
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GoalMiniStat(
                    title: 'Mancante',
                    value: euro(missing),
                    accent: accent,
                  ),
                ),
              ],
            ),
            if (estimatedMonths != null) ...[
              const SizedBox(height: 10),
              Text(
                'Continua così: stai avanzando bene verso il tuo obiettivo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalMiniStat extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _GoalMiniStat({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalsCard extends StatelessWidget {
  const _EmptyGoalsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassCard(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Nessun obiettivo ancora',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea il tuo primo obiettivo di risparmio e inizia a monitorare i progressi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCardPremium extends StatelessWidget {
  final Goal goal;
  final Color accent;
  final Gradient gradient;
  final Future<void> Function(Goal g) onUpdate;
  final Future<void> Function(String id) onDelete;

  const _GoalCardPremium({
    required this.goal,
    required this.accent,
    required this.gradient,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missing = (goal.targetAmount - goal.currentAmount).clamp(0, double.infinity);

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Elimina',
                  onPressed: () => onDelete(goal.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${euro(goal.currentAmount)} / ${euro(goal.targetAmount)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoChip(
                    label: 'Manca',
                    value: euro(missing),
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniInfoChip(
                    label: 'Stato',
                    value: goal.progress >= 1
                        ? 'Completato'
                        : goal.progress >= 0.6
                            ? 'Ottimo'
                            : goal.progress >= 0.25
                                ? 'Avviato'
                                : 'All’inizio',
                    accent: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: gradient,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _UpdateGoalDialog(goal: goal, onSave: onUpdate),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  label: const Text(
                    'Aggiorna',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MiniInfoChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final Future<void> Function(Goal g) onAdd;
  const _AddGoalDialog({required this.onAdd});

  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final g = Goal(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      targetAmount: double.parse(_target.text.trim().replaceAll(',', '.')),
      currentAmount: 0,
    );

    await widget.onAdd(g);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Obiettivo creato ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo obiettivo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                hintText: 'Es. Auto nuova',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci un titolo' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target',
                hintText: 'es. 5000',
              ),
              validator: (v) {
                final x = (v ?? '').trim();
                if (x.isEmpty) return 'Inserisci un target';
                final parsed = double.tryParse(x.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Valore non valido';
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
          child: const Text('Crea'),
        ),
      ],
    );
  }
}

class _UpdateGoalDialog extends StatefulWidget {
  final Goal goal;
  final Future<void> Function(Goal g) onSave;
  const _UpdateGoalDialog({
    required this.goal,
    required this.onSave,
  });

  @override
  State<_UpdateGoalDialog> createState() => _UpdateGoalDialogState();
}

class _UpdateGoalDialogState extends State<_UpdateGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _current;

  @override
  void initState() {
    super.initState();
    _current = TextEditingController(
      text: widget.goal.currentAmount.toStringAsFixed(2).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_current.text.trim().replaceAll(',', '.'));

    await widget.onSave(
      widget.goal.copyWith(currentAmount: amount),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Obiettivo aggiornato ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aggiorna: ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _current,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Risparmiato finora',
            hintText: 'es. 120,00',
          ),
          validator: (v) {
            final x = (v ?? '').trim();
            final parsed = double.tryParse(x.replaceAll(',', '.'));
            if (parsed == null || parsed < 0) return 'Valore non valido';
            return null;
          },
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