import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/services/budget_math.dart';
import '../widgets/month_overview_chart.dart';
import '../../services/salary_cycle.dart';
import 'package:quantoposso/data/models.dart';



class DashboardScreen extends StatelessWidget {
  final AppState state;
  final void Function(int index)? onNavigate;
  final VoidCallback? onQuickAddExpense;
  final VoidCallback? onQuickAddIncome;

  const DashboardScreen({
    super.key,
    required this.state,
    this.onNavigate,
    this.onQuickAddExpense,
    this.onQuickAddIncome,
  });

  String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buongiorno';
    if (hour < 18) return 'Buon pomeriggio';
    return 'Buonasera';
  }

  void _go(int idx) => onNavigate?.call(idx);

  Future<void> _pickAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
    );
    if (xfile == null) return;

    final s = state.settings;
    await state.saveSettings(s.copyWith(profileAvatarPath: xfile.path));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto profilo aggiornata ✅')),
    );
  }


  

    List<_WeekRange> _fourWeekRangesFromCycle({
  required DateTime cycleStart,
  required DateTime cycleEnd,
}) {
  final totalDays = cycleEnd.difference(cycleStart).inDays + 1;
  final base = totalDays ~/ 4;
  final rem = totalDays % 4;

  final sizes = List<int>.generate(4, (i) => base + (i < rem ? 1 : 0));

  var cursor = DateTime(cycleStart.year, cycleStart.month, cycleStart.day);
  final out = <_WeekRange>[];

  for (int i = 0; i < 4; i++) {
    final start = cursor;
    final end = cursor.add(Duration(days: sizes[i] - 1));

    out.add(
      _WeekRange(
        weekIndex: i,
        start: start,
        end: end,
      ),
    );

    cursor = end.add(const Duration(days: 1));
  }

  return out;
}

int _currentWeekIndexFromCycle(DateTime now, List<_WeekRange> ranges) {
  final day = DateTime(now.year, now.month, now.day);

  for (final r in ranges) {
    if (!day.isBefore(r.start) && !day.isAfter(r.end)) {
      return r.weekIndex;
    }
  }
  return 3;
}

String _rangeLabel(DateTime start, DateTime end) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(start.day)}/${two(start.month)}-${two(end.day)}/${two(end.month)}';
}

  
double _spentForWeekBox({
  required DateTime startInclusive,
  required DateTime endExclusive,
  required int totalWeekBoxes,
}) {
  return state.expenses.fold<double>(0.0, (sum, e) {
    switch (e.impact) {
      case ExpenseImpact.daily:
        final isInside =
            !e.date.isBefore(startInclusive) && e.date.isBefore(endExclusive);
        return isInside ? sum + e.amount : sum;

      case ExpenseImpact.weekly:
        final isInside =
            !e.date.isBefore(startInclusive) && e.date.isBefore(endExclusive);
        return isInside ? sum + (e.amount / 7.0) : sum;

      case ExpenseImpact.cycle:
        return sum + (e.amount / totalWeekBoxes);
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');
        final profileName = (state.profile?.name ?? '').trim();

        final now = DateTime.now();

final cycle = SalaryCycleService.estimateCycle(
  today: now,
  paydayDay: state.settings.paydayDay,
  lastSalaryDateIso: state.settings.lastSalaryDateIso,
  useRealSalaryCycle: state.settings.useRealSalaryCycle,
);

String two(int n) => n.toString().padLeft(2, '0');

final cycleLabel =
    '${two(cycle.start.day)}/${two(cycle.start.month)} → ${two(cycle.end.day)}/${two(cycle.end.month)}';

final cycleStart = DateTime(
  cycle.start.year,
  cycle.start.month,
  cycle.start.day,
);
final cycleEndExclusive = DateTime(
  cycle.end.year,
  cycle.end.month,
  cycle.end.day,
).add(const Duration(days: 1));

       final incomeTotal = state.incomes
    .where(
      (i) =>
          !i.date.isBefore(cycleStart) &&
          i.date.isBefore(cycleEndExclusive),
    )
    .fold<double>(0.0, (sum, i) => sum + i.amount);

     final spentThisCycle = state.expenses
    .where(
      (e) =>
          !e.date.isBefore(cycleStart) &&
          e.date.isBefore(cycleEndExclusive),
    )
    .fold<double>(0.0, (sum, e) => sum + e.amount);

        final todayStart = DateTime(now.year, now.month, now.day);
        final tomorrowStart = todayStart.add(const Duration(days: 1));
        final remainingDaysInCycle =
    cycle.end.difference(todayStart).inDays + 1;
        final cycleRemainingDaysRaw = cycle.end.difference(todayStart).inDays + 1;
final cycleRemainingDays = cycleRemainingDaysRaw <= 0 ? 1 : cycleRemainingDaysRaw;

final spentToday = state.expenses
    .where(
      (e) =>
          e.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(tomorrowStart),
    )
    .fold<double>(0.0, (sum, e) {
      switch (e.impact) {
        case ExpenseImpact.daily:
          return sum + e.amount;
        case ExpenseImpact.weekly:
          return sum + (e.amount / 7.0);
        case ExpenseImpact.cycle:
          return sum + (e.amount / cycleRemainingDays);
      }
    });

        final fixedTotal =
            state.fixed.fold<double>(0.0, (sum, f) => sum + f.amount);

        final saving = state.settings.monthlySaving.toDouble();

        final cycleTotalDays = cycle.end.difference(cycle.start).inDays + 1;
        

       final snap = BudgetMath.compute(
  today: now,
  monthlyIncome: incomeTotal,
  fixedExpensesTotal: fixedTotal,
  goalMonthlySaving: saving,
  variableSpentThisMonth: spentThisCycle,
  cycleTotalDays: cycleTotalDays,
  cycleRemainingDays: cycleRemainingDays,
  variableSpentToday: spentToday,
);

      final daysLeft = remainingDaysInCycle <= 0 ? 1 : remainingDaysInCycle;

        final dayAllowance = snap.dayAllowance;
        final remainingToday = dayAllowance - spentToday;

        final variableBudget = snap.monthBudget;
        final monthProgress = variableBudget <= 0
            ? 0.0
            : (spentThisCycle / variableBudget).clamp(0.0, 1.0);

        final noIncome = incomeTotal == 0;
        final isOver = remainingToday < 0;
        final low = !isOver && remainingToday <= 10;

        final Gradient heroGradient = noIncome
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF64748B), Color(0xFF334155), Color(0xFF0F172A)],
              )
            : isOver
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF7F1D1D)],
                  )
                : low
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFEA580C)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF7C3AED)],
                      );

        final Gradient pillGradient = noIncome
            ? const LinearGradient(colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
            : isOver
                ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)])
                : low
                    ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)])
                    : const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF60A5FA)]);

        final todayTitle = noIncome
            ? 'Inserisci un’entrata'
            : isOver
                ? 'Hai sforato oggi'
                : 'Quanto posso spendere oggi?';

        final todayValue = noIncome
            ? euro.format(0)
            : euro.format(isOver ? remainingToday.abs() : remainingToday);

        final pillText = noIncome
            ? 'Senza entrate non posso calcolare il budget'
            : isOver
                ? 'Sei oltre il budget di oggi'
                : low
                    ? 'Occhio: oggi sei al limite'
                    : '$daysLeft giorni rimasti al prossimo stipendio';

        final ctaText = (noIncome || isOver) ? 'Aggiungi entrata' : 'Aggiungi spesa';
        final ctaIcon = (noIncome || isOver) ? Icons.south_west : Icons.add;

       final ranges = _fourWeekRangesFromCycle(
  cycleStart: cycle.start,
  cycleEnd: cycle.end,
);

final currentWeek = _currentWeekIndexFromCycle(now, ranges);
        final weekBudget = variableBudget <= 0 ? 0.0 : (variableBudget / 4.0);

        final weeklyCards = <_WeekCardData>[];
        for (final r in ranges) {
  final start = DateTime(r.start.year, r.start.month, r.start.day);
  final endExclusive =
      DateTime(r.end.year, r.end.month, r.end.day).add(const Duration(days: 1));

 final spentWeek = _spentForWeekBox(
  startInclusive: start,
  endExclusive: endExclusive,
  totalWeekBoxes: ranges.length,
);

  final remainingWeek = weekBudget - spentWeek;

  weeklyCards.add(
    _WeekCardData(
      label: 'Sett. ${r.weekIndex + 1}',
      rangeText: _rangeLabel(r.start, r.end),
      budget: weekBudget,
      spent: spentWeek,
      remaining: remainingWeek,
      isCurrent: r.weekIndex == currentWeek,
    ),
  );
}

        final recent = <_MoveRow>[];
        for (final e in state.expenses) {
          recent.add(
            _MoveRow(
              date: e.date,
              title: e.category,
              subtitle: e.note.isEmpty ? 'Spesa' : e.note,
              amount: -e.amount,
              icon: Icons.shopping_bag_outlined,
            ),
          );
        }
        for (final i in state.incomes) {
          recent.add(
            _MoveRow(
              date: i.date,
              title: i.category,
              subtitle: i.note.isEmpty ? 'Entrata' : i.note,
              amount: i.amount,
              icon: Icons.payments_outlined,
            ),
          );
        }
        recent.sort((a, b) => b.date.compareTo(a.date));
        final topRecent = recent.take(4).toList();

        return SafeArea(
            child: Stack(
              children: [
                const _BlueHeaderBackground(),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                            icon: const Icon(Icons.menu, color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Quanto Posso',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Builder(
                          builder: (ctx) => IconButton(
                            tooltip: 'Profilo',
                            onPressed: () => _pickAvatar(ctx),
                            icon: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  (state.settings.profileAvatarPath == null ||
                                          state.settings.profileAvatarPath!.isEmpty)
                                      ? null
                                      : FileImage(File(state.settings.profileAvatarPath!)),
                              child: (state.settings.profileAvatarPath == null ||
                                      state.settings.profileAvatarPath!.isEmpty)
                                  ? Text(
                                      profileName.isEmpty
                                          ? '?'
                                          : profileName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF1E40AF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
  profileName.isEmpty
      ? '${greeting()}! 👋'
      : '${greeting()} $profileName! 👋',
  style: theme.textTheme.titleMedium?.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w800,
  ),
),
const SizedBox(height: 10),

Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.18),
    ),
  ),
  child: Row(
    children: [
      const Icon(
        Icons.calendar_month_rounded,
        color: Colors.white,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'Ciclo stipendio: $cycleLabel',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  ),
),

const SizedBox(height: 12),

_HeroCard(
  heroGradient: heroGradient,
  pillGradient: pillGradient,
  todayTitle: todayTitle,
  todayValue: todayValue,
  spentToday: euro.format(spentToday),
  progressValue: monthProgress,
  progressLabel: variableBudget <= 0
      ? 'Budget mensile non disponibile'
      : 'Budget mensile: ${euro.format(spentThisCycle)} / ${euro.format(variableBudget)}',
  pillText: pillText,
  ctaText: ctaText,
  ctaIcon: ctaIcon,
  onRefresh: () => state.refresh(),
  onAdd: () {
    if (noIncome || isOver) {
      (onQuickAddIncome ?? () => _go(2)).call();
    } else {
      (onQuickAddExpense ?? () => _go(2)).call();
    }
  },
),

                    const SizedBox(height: 14),

                    _SectionHeader(
                      title: 'Azioni rapide',
                      actionText: 'Vedi tutti ›',
                      onTap: () => _go(1),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _PillAction(
                            label: 'Spesa',
                            icon: Icons.shopping_cart_outlined,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                            ),
                            onTap: () {
                              if (onQuickAddExpense != null) {
                                onQuickAddExpense!.call();
                              } else {
                                _go(2);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PillAction(
                            label: 'Entrata',
                            icon: Icons.euro,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            onTap: () {
                              if (onQuickAddIncome != null) {
                                onQuickAddIncome!.call();
                              } else {
                                _go(2);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PillAction(
                            label: 'Fissa',
                            icon: Icons.lock_outline,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                            ),
                            onTap: () => _go(3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _SectionHeader(
                      title: 'Settimane',
                      actionText: 'Scorri ›',
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 156,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: weeklyCards.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 170,
                            child: _WeekBoxCompact(
                              data: weeklyCards[index],
                              euro: euro,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.calendar_month,
                            title: 'Entrate',
                            value: euro.format(incomeTotal),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF34D399), Color(0xFF16A34A)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.trending_down,
                            title: 'Speso',
                            value: euro.format(spentThisCycle),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            icon: Icons.account_balance_wallet,
                            title: 'Rimane',
                            value: euro.format(snap.monthRemaining),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _SectionHeader(
                      title: 'Ultimi movimenti',
                      actionText: 'Vedi tutti ›',
                      onTap: () => _go(1),
                    ),
                    const SizedBox(height: 10),

                    _GlassCard(
                      child: topRecent.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'Ancora vuoto. Aggiungi una spesa o un’entrata.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (int idx = 0; idx < topRecent.length; idx++) ...[
                                  _MovementTile(row: topRecent[idx], euro: euro),
                                  if (idx != topRecent.length - 1)
                                    const Divider(height: 1),
                                ],
                              ],
                            ),
                    ),

                    const SizedBox(height: 14),

                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panoramica del mese',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MonthOverviewChart(
                              income: incomeTotal,
                              spent: spentThisCycle,
                              saving: saving,
                              remaining: snap.monthRemaining,
                            ),
                          ],
                        ),
                      ),
                    ),

                   ],
                ),
              ],
            )
           );

             },
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroCard extends StatelessWidget {
  final Gradient heroGradient;
  final Gradient pillGradient;
  final String todayTitle;
  final String todayValue;
  final String spentToday;
  final double progressValue;
  final String progressLabel;
  final String pillText;
  final String ctaText;
  final IconData ctaIcon;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;

  const _HeroCard({
    required this.heroGradient,
    required this.pillGradient,
    required this.todayTitle,
    required this.todayValue,
    required this.spentToday,
    required this.progressValue,
    required this.progressLabel,
    required this.pillText,
    required this.ctaText,
    required this.ctaIcon,
    required this.onRefresh,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassCard(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: heroGradient,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    todayTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      todayValue,
                      key: ValueKey(todayValue),
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Speso oggi: $spentToday',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progressValue),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: pillGradient,
              ),
              child: Text(
                pillText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(ctaIcon, color: Colors.white),
                  label: Text(
                    ctaText,
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
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({required this.child, this.radius = 20});

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

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Gradient gradient;

  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PillAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  final _MoveRow row;
  final NumberFormat euro;

  const _MovementTile({required this.row, required this.euro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = row.amount >= 0;
    final color = isIncome ? Colors.green : Colors.red;
    final sign = isIncome ? '+' : '−';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(row.icon, color: color),
      ),
      title: Text(
        row.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${DateFormat('dd/MM').format(row.date)} • ${row.subtitle}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$sign ${euro.format(row.amount.abs())}',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _MoveRow {
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;

  _MoveRow({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });
}

class _WeekBoxCompact extends StatelessWidget {
  final _WeekCardData data;
  final NumberFormat euro;

  const _WeekBoxCompact({
    required this.data,
    required this.euro,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isOver = data.remaining < 0;
    final color =
        isOver ? Colors.red : (data.remaining <= 10 ? Colors.orange : Colors.green);

    return _GlassCard(
      radius: 18,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: data.isCurrent
              ? Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (data.isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Ora',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              data.rangeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              euro.format(data.remaining),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Speso ${euro.format(data.spent)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: data.budget <= 0 ? 0 : (data.spent / data.budget).clamp(0, 1),
                minHeight: 7,
                backgroundColor: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCardData {
  final String label;
  final String rangeText;
  final double budget;
  final double spent;
  final double remaining;
  final bool isCurrent;

  const _WeekCardData({
    required this.label,
    required this.rangeText,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.isCurrent,
  });
}

class _WeekRange {
  final int weekIndex;
  final DateTime start;
  final DateTime end;

  const _WeekRange({
    required this.weekIndex,
    required this.start,
    required this.end,
  });
}