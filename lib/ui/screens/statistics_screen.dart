import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/ui/screens/pro_screen.dart';

class StatisticsScreen extends StatefulWidget {
  final AppState state;
  const StatisticsScreen({super.key, required this.state});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');
        final data = _buildStats();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const _BlueHeaderBackground(),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            'Statistiche',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!widget.state.isProActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Panoramica mese',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMMM yyyy', 'it_IT').format(_selectedMonth),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _previousMonth,
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            IconButton(
                              onPressed: _nextMonth,
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panoramica mese',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 220,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        centerSpaceRadius: 48,
                                        sectionsSpace: 3,
                                        borderData: FlBorderData(show: false),
                                        sections: [
                                          PieChartSectionData(
                                            value: data.spent > 0 ? data.spent : 0.001,
                                            title: '',
                                            radius: 30,
                                            color: const Color(0xFFEF4444),
                                          ),
                                          PieChartSectionData(
                                            value: data.remaining > 0 ? data.remaining : 0.001,
                                            title: '',
                                            radius: 30,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          PieChartSectionData(
                                            value: data.saved > 0 ? data.saved : 0.001,
                                            title: '',
                                            radius: 30,
                                            color: const Color(0xFF22C55E),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _legendItem(
                                          color: const Color(0xFF2563EB),
                                          label: 'Budget rimanente',
                                          value: euro.format(data.remaining),
                                        ),
                                        const SizedBox(height: 12),
                                        _legendItem(
                                          color: const Color(0xFFEF4444),
                                          label: 'Spese',
                                          value: euro.format(data.spent),
                                        ),
                                        const SizedBox(height: 12),
                                        _legendItem(
                                          color: const Color(0xFF22C55E),
                                          label: 'Risparmio',
                                          value: euro.format(data.saved),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _InfoBanner(
                              text:
                                  'Hai speso il ${data.spentPercent.toStringAsFixed(0)}% del budget del mese. Ti restano ${euro.format(data.remaining)}.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Entrate',
                            value: euro.format(data.income),
                            icon: Icons.trending_up_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatMiniCard(
                            title: 'Spese',
                            value: euro.format(data.spent),
                            icon: Icons.trending_down_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _MonthComparisonCard(data: data),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (widget.state.isProActive) ...[
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _TrendInsightCard(data: data),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _TrendChartCard(data: data),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _CategoryDonutCard(data: data),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insight',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InsightTile(
                                icon: Icons.account_balance_wallet_rounded,
                                text:
                                    'Puoi spendere ancora ${euro.format(data.dailyAllowance)} al giorno fino a fine mese.',
                              ),
                              if (data.topCategory != null)
                                _InsightTile(
                                  icon: Icons.pie_chart_rounded,
                                  text:
                                      'La categoria più pesante è "${data.topCategory!.category}" con ${euro.format(data.topCategory!.amount)}.',
                                ),
                              _InsightTile(
                                icon: Icons.calendar_month_rounded,
                                text:
                                    'Hai registrato ${data.expenseCount} spese nel mese selezionato.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      _ProLockedCard(state: widget.state),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month))) return;

    setState(() {
      _selectedMonth = next;
    });
  }

  _StatsData _buildStats() {
    final monthStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final monthEnd = (_selectedMonth.month == 12)
        ? DateTime(_selectedMonth.year + 1, 1, 1)
        : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

    final incomes = widget.state.incomes.where((i) {
      return !i.date.isBefore(monthStart) && i.date.isBefore(monthEnd);
    }).toList();

    final expenses = widget.state.expenses.where((e) {
      return !e.date.isBefore(monthStart) && e.date.isBefore(monthEnd);
    }).toList();

    final income = incomes.fold<double>(0, (s, i) => s + i.amount);
    final spentOnly = expenses.fold<double>(0, (s, e) => s + e.amount);
    final fixed = widget.state.fixed.fold<double>(0, (s, f) => s + f.amount);
    final monthlySaving = widget.state.settings.monthlySaving;

    final spent = spentOnly + fixed;
    final saved = (income - spent).clamp(0.0, double.infinity).toDouble();
    final remaining = (income - spent - monthlySaving).clamp(0.0, double.infinity).toDouble();
    final spentPercent =
        income <= 0 ? 0.0 : ((spent / income) * 100).clamp(0.0, 100.0).toDouble();

    final categoryMap = <String, double>{};
    for (final e in expenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }

    final topCategories = categoryMap.entries
        .map((e) => _CategoryStat(category: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final today = (_selectedMonth.year == now.year && _selectedMonth.month == now.month)
        ? now.day
        : daysInMonth;

    final remainingDays = (daysInMonth - today + 1).clamp(1, 31).toDouble();
    final dailyAllowance = (remaining / remainingDays).toDouble();

    final prevMonthStart = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    final prevMonthEnd = DateTime(_selectedMonth.year, _selectedMonth.month, 1);

    final previousMonthSpent = widget.state.expenses
        .where((e) => !e.date.isBefore(prevMonthStart) && e.date.isBefore(prevMonthEnd))
        .fold<double>(0, (s, e) => s + e.amount);

    final previousMonthIncome = widget.state.incomes
        .where((i) => !i.date.isBefore(prevMonthStart) && i.date.isBefore(prevMonthEnd))
        .fold<double>(0, (s, i) => s + i.amount);

    final monthlyTrend = <_MonthlyPoint>[];
    for (int offset = 5; offset >= 0; offset--) {
      final d = DateTime(_selectedMonth.year, _selectedMonth.month - offset, 1);
      final start = DateTime(d.year, d.month, 1);
      final end = DateTime(d.year, d.month + 1, 1);

      final mIncome = widget.state.incomes
          .where((i) => !i.date.isBefore(start) && i.date.isBefore(end))
          .fold<double>(0, (s, i) => s + i.amount);

      final mSpent = widget.state.expenses
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .fold<double>(0, (s, e) => s + e.amount);

      monthlyTrend.add(
        _MonthlyPoint(
          label: DateFormat('MMM', 'it_IT').format(d),
          income: mIncome,
          spent: mSpent,
        ),
      );
    }

    return _StatsData(
      income: income.toDouble(),
      spent: spent.toDouble(),
      saved: saved.toDouble(),
      remaining: remaining.toDouble(),
      spentPercent: spentPercent.toDouble(),
      expenseCount: expenses.length,
      topCategories: topCategories,
      topCategory: topCategories.isEmpty ? null : topCategories.first,
      dailyAllowance: dailyAllowance.toDouble(),
      previousMonthSpent: previousMonthSpent.toDouble(),
      previousMonthIncome: previousMonthIncome.toDouble(),
      monthlyTrend: monthlyTrend,
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _StatsData {
  final double income;
  final double spent;
  final double saved;
  final double remaining;
  final double spentPercent;
  final int expenseCount;
  final List<_CategoryStat> topCategories;
  final _CategoryStat? topCategory;
  final double dailyAllowance;
  final double previousMonthSpent;
  final double previousMonthIncome;
  final List<_MonthlyPoint> monthlyTrend;

  _StatsData({
    required this.income,
    required this.spent,
    required this.saved,
    required this.remaining,
    required this.spentPercent,
    required this.expenseCount,
    required this.topCategories,
    required this.topCategory,
    required this.dailyAllowance,
    required this.previousMonthSpent,
    required this.previousMonthIncome,
    required this.monthlyTrend,
  });
}

class _MonthlyPoint {
  final String label;
  final double income;
  final double spent;

  _MonthlyPoint({
    required this.label,
    required this.income,
    required this.spent,
  });
}

class _CategoryStat {
  final String category;
  final double amount;

  _CategoryStat({
    required this.category,
    required this.amount,
  });
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthComparisonCard extends StatelessWidget {
  final _StatsData data;
  const _MonthComparisonCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    final spentDelta = data.spent - data.previousMonthSpent;
    final incomeDelta = data.income - data.previousMonthIncome;

    Widget deltaChip({
      required String label,
      required double delta,
      required bool positiveIsGood,
    }) {
      final isPositive = delta >= 0;
      final good = positiveIsGood ? isPositive : !isPositive;
      final color = good ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      final icon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label ${euro.format(delta.abs())}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confronto mese scorso',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        deltaChip(
          label: 'Spese',
          delta: spentDelta,
          positiveIsGood: false,
        ),
        const SizedBox(height: 10),
        deltaChip(
          label: 'Entrate',
          delta: incomeDelta,
          positiveIsGood: true,
        ),
      ],
    );
  }
}

class _TrendInsightCard extends StatelessWidget {
  final _StatsData data;
  const _TrendInsightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    final spentDelta = data.spent - data.previousMonthSpent;
    final incomeDelta = data.income - data.previousMonthIncome;

    final spendingImproved = spentDelta <= 0;
    final incomeImproved = incomeDelta >= 0;
    final overallGood = spendingImproved && incomeImproved;

    final title = overallGood
        ? 'Stai migliorando'
        : spendingImproved
            ? 'Buon controllo delle spese'
            : 'Occhio al trend del mese';

    final subtitle = overallGood
        ? 'Le tue spese sono sotto controllo e le entrate stanno reggendo bene.'
        : spendingImproved
            ? 'Hai speso meno rispetto al mese scorso, continua così.'
            : 'Questo mese stai spendendo più del mese scorso.';

    final accent = overallGood
        ? const Color(0xFF16A34A)
        : spendingImproved
            ? const Color(0xFF2563EB)
            : const Color(0xFFDC2626);

    final icon = overallGood
        ? Icons.trending_up_rounded
        : spendingImproved
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded;

    Widget pill({
      required IconData icon,
      required Color color,
      required String label,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        pill(
          icon: spentDelta <= 0
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: spentDelta <= 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
          label: 'Differenza spese',
          value: euro.format(spentDelta.abs()),
        ),
        const SizedBox(height: 10),
        pill(
          icon: incomeDelta >= 0
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          color: incomeDelta >= 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
          label: 'Differenza entrate',
          value: euro.format(incomeDelta.abs()),
        ),
      ],
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final _StatsData data;
  const _TrendChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = [
      ...data.monthlyTrend.map((e) => e.income),
      ...data.monthlyTrend.map((e) => e.spent),
      100.0,
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Andamento ultimi 6 mesi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _MiniLegend(color: Color(0xFF2563EB), label: 'Entrate'),
            SizedBox(width: 16),
            _MiniLegend(color: Color(0xFFEF4444), label: 'Spese'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.15,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.monthlyTrend.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          data.monthlyTrend[i].label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: const Color(0xFF2563EB),
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  ),
                  spots: List.generate(
                    data.monthlyTrend.length,
                    (i) => FlSpot(i.toDouble(), data.monthlyTrend[i].income),
                  ),
                ),
                LineChartBarData(
                  isCurved: true,
                  color: const Color(0xFFEF4444),
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                  ),
                  spots: List.generate(
                    data.monthlyTrend.length,
                    (i) => FlSpot(i.toDouble(), data.monthlyTrend[i].spent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryDonutCard extends StatelessWidget {
  final _StatsData data;
  const _CategoryDonutCard({required this.data});

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final top = data.topCategories.take(5).toList();
    final total = top.fold<double>(0, (s, e) => s + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorie',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dove vanno i tuoi soldi nel mese selezionato',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (top.isEmpty)
          const Text(
            'Nessuna spesa nel mese selezionato.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 42,
                          sectionsSpace: 3,
                          borderData: FlBorderData(show: false),
                          sections: List.generate(top.length, (i) {
                            final item = top[i];
                            return PieChartSectionData(
                              value: item.amount <= 0 ? 0.001 : item.amount,
                              title: '',
                              radius: 26,
                              color: _colors[i % _colors.length],
                            );
                          }),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Top',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            euro.format(total),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  children: List.generate(top.length, (i) {
                    final item = top[i];
                    final percent = total <= 0 ? 0.0 : (item.amount / total) * 100;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryLegendTile(
                        color: _colors[i % _colors.length],
                        title: item.category,
                        percent: percent,
                        amount: item.amount,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CategoryLegendTile extends StatelessWidget {
  final Color color;
  final String title;
  final double percent;
  final double amount;

  const _CategoryLegendTile({
    required this.color,
    required this.title,
    required this.percent,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            euro.format(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MiniLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InsightTile({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProLockedCard extends StatelessWidget {
  final AppState state;
  const _ProLockedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'Statistiche PRO',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sblocca categorie, insight intelligenti e analisi avanzate del tuo budget.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProScreen(state: state),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Passa a PRO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
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
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.10, size.width * 0.55, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.26, size.width, size.height * 0.20)
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
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
            ),
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