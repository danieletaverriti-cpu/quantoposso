import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/format.dart';

class ExpensesScreen extends StatelessWidget {
  final AppState state;
  const ExpensesScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(state.expenses);

    if (state.expenses.isEmpty) {
      return const Center(
        child: Text('Nessuna spesa ancora.\nAggiungine una dal tab "Aggiungi".', textAlign: TextAlign.center),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in grouped.entries) ...[
          _DayCard(day: entry.key, items: entry.value, onDelete: (id) => state.deleteExpense(id)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Map<DateTime, List<Expense>> _groupByDay(List<Expense> list) {
    final map = <DateTime, List<Expense>>{};
    for (final e in list) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(d, () => []).add(e);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: (map[k]!..sort((a, b) => b.date.compareTo(a.date)))};
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final List<Expense> items;
  final void Function(String id) onDelete;

  const _DayCard({required this.day, required this.items, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, e) => s + e.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel(day),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(euro(total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const Divider(height: 18),
            ...items.map((e) => _ExpenseRow(expense: e, onDelete: onDelete)),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  final Expense expense;
  final void Function(String id) onDelete;

  const _ExpenseRow({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      onDismissed: (_) => onDelete(expense.id),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            _CategoryIcon(category: expense.category),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(expense.note.isEmpty ? '—' : expense.note, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(euro(expense.amount), style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String category;
  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_iconFor(category), color: cs.primary),
    );
  }

  IconData _iconFor(String c) {
    final x = c.toLowerCase();
    if (x.contains('spesa')) return Icons.shopping_cart_outlined;
    if (x.contains('bar') || x.contains('caff')) return Icons.local_cafe_outlined;
    if (x.contains('benz') || x.contains('carbur')) return Icons.local_gas_station_outlined;
    if (x.contains('casa') || x.contains('affitto') || x.contains('mutuo')) return Icons.home_outlined;
    if (x.contains('svago') || x.contains('cinema') || x.contains('uscite')) return Icons.celebration_outlined;
    return Icons.category_outlined;
  }
}
