import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import 'add_movement_screen.dart' as add;

enum _MoveTypeFilter { all, expense, income }

enum _PeriodFilter {
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  thisYear,
  custom,
}

class MovementsScreen extends StatefulWidget {
  final AppState state;
  const MovementsScreen({super.key, required this.state});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  _MoveTypeFilter _type = _MoveTypeFilter.all;
  _PeriodFilter _period = _PeriodFilter.thisMonth;

  String _category = 'Tutte';
  DateTime? _from;
  DateTime? _to;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

        // 1) Build unified list
        final all = <_MoveItem>[];
        for (final e in widget.state.expenses) {
          all.add(_MoveItem.expense(
            id: e.id,
            amount: e.amount,
            category: e.category,
            date: e.date,
            note: e.note,
            impact: e.impact,
          ));
        }
        for (final i in widget.state.incomes) {
          all.add(_MoveItem.income(
            id: i.id,
            amount: i.amount,
            category: i.category,
            date: i.date,
            note: i.note,
          ));
        }
        all.sort((a, b) => b.date.compareTo(a.date));

        // 2) Categories available
        final availableCats = <String>{'Tutte'};
        for (final m in all) {
          if (_type == _MoveTypeFilter.expense && m.isIncome) continue;
          if (_type == _MoveTypeFilter.income && !m.isIncome) continue;
          availableCats.add(m.category);
        }
        final catList = availableCats.toList()
          ..sort((a, b) {
            if (a == 'Tutte') return -1;
            if (b == 'Tutte') return 1;
            return a.compareTo(b);
          });

        if (!availableCats.contains(_category)) _category = 'Tutte';

        // 3) Period range
        final now = DateTime.now();
        DateTime start;
        DateTime endExclusive;

        DateTime firstDayOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
        DateTime firstDayOfNextMonth(DateTime d) =>
            (d.month == 12) ? DateTime(d.year + 1, 1, 1) : DateTime(d.year, d.month + 1, 1);

        switch (_period) {
          case _PeriodFilter.thisMonth:
            start = firstDayOfMonth(now);
            endExclusive = firstDayOfNextMonth(now);
            break;
          case _PeriodFilter.lastMonth:
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            start = firstDayOfMonth(lastMonth);
            endExclusive = firstDayOfNextMonth(lastMonth);
            break;
          case _PeriodFilter.last7Days:
            start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
            endExclusive = DateTime(now.year, now.month, now.day + 1);
            break;
          case _PeriodFilter.last30Days:
            start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
            endExclusive = DateTime(now.year, now.month, now.day + 1);
            break;
          case _PeriodFilter.thisYear:
            start = DateTime(now.year, 1, 1);
            endExclusive = DateTime(now.year + 1, 1, 1);
            break;
          case _PeriodFilter.custom:
            final f = _from ?? firstDayOfMonth(now);
            final t = _to ?? now;
            start = DateTime(f.year, f.month, f.day);
            endExclusive = DateTime(t.year, t.month, t.day).add(const Duration(days: 1));
            break;
        }

        // 4) Apply filters
        final filtered = all.where((m) {
          if (_type == _MoveTypeFilter.expense && m.isIncome) return false;
          if (_type == _MoveTypeFilter.income && !m.isIncome) return false;
          if (_category != 'Tutte' && m.category != _category) return false;

          final d = m.date;
          if (d.isBefore(start)) return false;
          if (!d.isBefore(endExclusive)) return false;
          return true;
        }).toList();

        // Totals
        final spent = filtered.where((m) => !m.isIncome).fold<double>(0, (s, m) => s + m.amount);
        final inc = filtered.where((m) => m.isIncome).fold<double>(0, (s, m) => s + m.amount);

        // 5) Group by day
        final groups = <String, List<_MoveItem>>{};
        for (final m in filtered) {
          final key = DateFormat('yyyy-MM-dd').format(m.date);
          groups.putIfAbsent(key, () => []).add(m);
        }
        final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        String dayLabel(String key) {
          final d = DateTime.parse(key);
          final today = DateTime(now.year, now.month, now.day);
          final dd = DateTime(d.year, d.month, d.day);

          if (dd == today) return 'Oggi';
          if (dd == today.subtract(const Duration(days: 1))) return 'Ieri';
          return DateFormat('EEEE dd/MM', 'it_IT').format(d);
        }

        Future<void> openEdit(_MoveItem m) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => add.AddMovementScreen(
                state: widget.state,
                onDone: () {},
                editing: add.EditingMovement(
                  isIncome: m.isIncome,
                  id: m.id,
                  amount: m.amount,
                  category: m.category,
                  date: m.date,
                  note: m.note,
                  impact: m.impact,
                ),
              ),
            ),
          );
        }

        Future<bool> confirmDelete(_MoveItem m) async {
          return (await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Eliminare movimento?'),
                  content: Text(
                    '${m.isIncome ? "Entrata" : "Spesa"}: ${m.category}\n'
                    'Importo: ${euro.format(m.amount)}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              )) ??
              false;
        }

        Future<void> deleteWithUndo(_MoveItem m) async {
          if (m.isIncome) {
            await widget.state.deleteIncome(m.id);
          } else {
            await widget.state.deleteExpense(m.id);
          }

          if (!context.mounted) return;

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Movimento eliminato ✅'),
              action: SnackBarAction(
                label: 'ANNULLA',
                onPressed: () async {
                  if (m.isIncome) {
                    await widget.state.addIncome(
                      Income(
                        id: m.id,
                        amount: m.amount,
                        category: m.category,
                        date: m.date,
                        note: m.note,

                      ),
                    );
                  } else {
                    await widget.state.addExpense(
                      Expense(
                        id: m.id,
                        amount: m.amount,
                        category: m.category,
                        date: m.date,
                        note: m.note,
                        impact: m.impact,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }

        // ✅ UPGRADE UI: background + glass + pill
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(child: Stack(
            children: [
              const _BlueHeaderBackground(),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 90),
                children: [
                  // HEADER
                  Row(
                    children: [
                      Text(
                        'Movimenti',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.receipt_long, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // TOTALS glass (come home)
                  _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniTotal(
                              title: 'Entrate',
                              value: euro.format(inc),
                              icon: Icons.trending_up,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF34D399), Color(0xFF16A34A)],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _miniTotal(
                              title: 'Spese',
                              value: euro.format(spent),
                              icon: Icons.trending_down,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // FILTERS glass
                  _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtri',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),

                          // ✅ Pill selector (invece di SegmentedButton)
                          Wrap(
                            spacing: 8,
                            children: [
                              _pillChip(
                                label: 'Tutti',
                                selected: _type == _MoveTypeFilter.all,
                                onTap: () => setState(() => _type = _MoveTypeFilter.all),
                              ),
                              _pillChip(
                                label: 'Spese',
                                selected: _type == _MoveTypeFilter.expense,
                                onTap: () => setState(() => _type = _MoveTypeFilter.expense),
                              ),
                              _pillChip(
                                label: 'Entrate',
                                selected: _type == _MoveTypeFilter.income,
                                onTap: () => setState(() => _type = _MoveTypeFilter.income),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _category,
                                  items: catList
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _category = v ?? 'Tutte'),
                                  decoration: const InputDecoration(
                                    labelText: 'Categoria',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<_PeriodFilter>(
                                  initialValue: _period,
                                  items: const [
                                    DropdownMenuItem(value: _PeriodFilter.thisMonth, child: Text('Questo mese')),
                                    DropdownMenuItem(value: _PeriodFilter.lastMonth, child: Text('Mese scorso')),
                                    DropdownMenuItem(value: _PeriodFilter.last7Days, child: Text('Ultimi 7 giorni')),
                                    DropdownMenuItem(value: _PeriodFilter.last30Days, child: Text('Ultimi 30 giorni')),
                                    DropdownMenuItem(value: _PeriodFilter.thisYear, child: Text('Questo anno')),
                                    DropdownMenuItem(value: _PeriodFilter.custom, child: Text('Personalizzato')),
                                  ],
                                  onChanged: (v) => setState(() => _period = v ?? _PeriodFilter.thisMonth),
                                  decoration: const InputDecoration(
                                    labelText: 'Periodo',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_period == _PeriodFilter.custom) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _from ?? DateTime.now(),
                                        firstDate: DateTime(DateTime.now().year - 2),
                                        lastDate: DateTime(DateTime.now().year + 2),
                                      );
                                      if (picked != null) setState(() => _from = picked);
                                    },
                                    icon: const Icon(Icons.calendar_month),
                                    label: Text(_from == null ? 'Da' : DateFormat('dd/MM/yyyy').format(_from!)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _to ?? DateTime.now(),
                                        firstDate: DateTime(DateTime.now().year - 2),
                                        lastDate: DateTime(DateTime.now().year + 2),
                                      );
                                      if (picked != null) setState(() => _to = picked);
                                    },
                                    icon: const Icon(Icons.calendar_month),
                                    label: Text(_to == null ? 'A' : DateFormat('dd/MM/yyyy').format(_to!)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _from = null;
                                  _to = null;
                                }),
                                child: const Text('Reset date'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LISTA
                  if (filtered.isEmpty)
                    _GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Nessun movimento nel periodo selezionato.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    for (final key in keys) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
                        child: Text(
                          dayLabel(key),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      _GlassCard(
                        child: Column(
                          children: [
                            for (int i = 0; i < groups[key]!.length; i++) ...[
                              _MovementRowPremium(
                                item: groups[key]![i],
                                euro: euro,
                                onTap: () => openEdit(groups[key]![i]),
                                onDelete: () async {
                                  final m = groups[key]![i];
                                  final ok = await confirmDelete(m);
                                  if (!ok) return;
                                  await deleteWithUndo(m);
                                },
                                confirmDismiss: () => confirmDelete(groups[key]![i]),
                                onDismissed: () => deleteWithUndo(groups[key]![i]),
                              ),
                              if (i != groups[key]!.length - 1) const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ],
                ],
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  // ✅ pill chip
  Widget _pillChip({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.55),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ✅ mini totals
  Widget _miniTotal({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Row premium (badge importo + icona pulita)
class _MovementRowPremium extends StatelessWidget {
  final _MoveItem item;
  final NumberFormat euro;
  final VoidCallback onTap;

  final Future<bool> Function() confirmDismiss;
  final VoidCallback onDismissed;
  final VoidCallback onDelete;

  const _MovementRowPremium({
    required this.item,
    required this.euro,
    required this.onTap,
    required this.confirmDismiss,
    required this.onDismissed,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = _CategoryStyle.from(item.category, isIncome: item.isIncome);
    final sign = item.isIncome ? '+' : '−';
    final amountColor = item.isIncome ? Colors.green : Colors.red;

    final subtitleParts = <String>[];
    subtitleParts.add(DateFormat('HH:mm').format(item.date));
    subtitleParts.add(item.isIncome ? 'Entrata' : 'Spesa');
    if (item.note.trim().isNotEmpty) subtitleParts.add(item.note.trim());

    return Dismissible(
      key: ValueKey('${item.isIncome ? "i" : "e"}_${item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDismiss(),
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: .12),
          child: Icon(style.icon, color: style.color),
        ),
        title: Text(
          item.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          subtitleParts.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: amountColor.withValues(alpha: 0.10),
                border: Border.all(color: amountColor.withValues(alpha: 0.22)),
              ),
              child: Text(
                '$sign ${euro.format(item.amount)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: amountColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Elimina',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------- MODELS -------------------- */

class _MoveItem {
  final bool isIncome;
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final ExpenseImpact impact;

  const _MoveItem._({
    required this.isIncome,
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.impact = ExpenseImpact.daily,
  });

 factory _MoveItem.expense({
  required String id,
  required double amount,
  required String category,
  required DateTime date,
  required String note,
  ExpenseImpact impact = ExpenseImpact.daily,
}) {
  return _MoveItem._(
    isIncome: false,
    id: id,
    amount: amount,
    category: category,
    date: date,
    note: note,
    impact: impact,
  );
}

  factory _MoveItem.income({
    required String id,
    required double amount,
    required String category,
    required DateTime date,
    required String note,
  }) {
    return _MoveItem._(
      isIncome: true,
      id: id,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle(this.icon, this.color);

  static _CategoryStyle from(String category, {required bool isIncome}) {
    if (isIncome) {
      switch (category) {
        case 'Stipendio':
          return const _CategoryStyle(Icons.badge_outlined, Colors.green);
        case 'Straordinari':
          return const _CategoryStyle(Icons.more_time, Colors.green);
        case 'Bonus':
          return const _CategoryStyle(Icons.card_giftcard, Colors.green);
        case 'Rimborso':
          return const _CategoryStyle(Icons.receipt_long, Colors.green);
        default:
          return const _CategoryStyle(Icons.payments_outlined, Colors.green);
      }
    }

    switch (category) {
      case 'Spesa alimentare':
        return const _CategoryStyle(Icons.shopping_basket_outlined, Colors.orange);
      case 'Casa':
        return const _CategoryStyle(Icons.home_outlined, Colors.indigo);
      case 'Bollette':
        return const _CategoryStyle(Icons.receipt_outlined, Colors.blueGrey);
      case 'Auto':
        return const _CategoryStyle(Icons.directions_car_outlined, Colors.teal);
      case 'Trasporti':
        return const _CategoryStyle(Icons.directions_bus_outlined, Colors.teal);
      case 'Bar':
        return const _CategoryStyle(Icons.local_cafe_outlined, Colors.brown);
      case 'Ristorante':
        return const _CategoryStyle(Icons.restaurant_outlined, Colors.deepOrange);
      case 'Salute':
        return const _CategoryStyle(Icons.health_and_safety_outlined, Colors.redAccent);
      case 'Svago':
        return const _CategoryStyle(Icons.sports_esports_outlined, Colors.purple);
      case 'Viaggi':
        return const _CategoryStyle(Icons.flight_takeoff_outlined, Colors.blue);
      case 'Abbigliamento':
        return const _CategoryStyle(Icons.checkroom_outlined, Colors.pink);
      case 'Sport':
        return const _CategoryStyle(Icons.fitness_center_outlined, Colors.deepPurple);
      case 'Tasse':
        return const _CategoryStyle(Icons.account_balance_outlined, Colors.blueGrey);
      case 'Regali':
        return const _CategoryStyle(Icons.redeem_outlined, Colors.pinkAccent);
      default:
        return const _CategoryStyle(Icons.category_outlined, Colors.grey);
    }
  }
}

/* -------------------- BACKGROUND + GLASS (same as home/settings) -------------------- */

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