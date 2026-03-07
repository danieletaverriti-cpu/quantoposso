import 'package:quantoposso/data/models.dart';

class BudgetSnapshot {
  final double income;
  final double fixed;
  final double saving;

  final double spent;        // speso nel mese
  final double remaining;    // rimanente mese

  final double daily;        // media giornaliera da oggi a fine mese
  final double weekly;       // media questa settimana

  // ✅ NUOVI
  final double spentToday;       // speso oggi
  final double todayRemaining;   // OGGI REALE: quanto puoi spendere ancora oggi

  final bool impossible;
  final bool overspent;

  final int remainingDaysInMonth;
  final int remainingDaysInWeek;

  const BudgetSnapshot({
    required this.income,
    required this.fixed,
    required this.saving,
    required this.spent,
    required this.remaining,
    required this.daily,
    required this.weekly,
    required this.spentToday,
    required this.todayRemaining,
    required this.impossible,
    required this.overspent,
    required this.remainingDaysInMonth,
    required this.remainingDaysInWeek,
  });
}

class BudgetService {
  static DateTime _endOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  static DateTime _endOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final daysToSunday = DateTime.sunday - day.weekday;
    return day.add(Duration(days: daysToSunday));
  }

  static double _r2(double v) => double.parse(v.toStringAsFixed(2));

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static BudgetSnapshot compute({
    required double incomeMonthly,
    required double savingMonthly,
    required List<FixedExpense> fixed,
    required List<Expense> expenses,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final d = DateTime(today.year, today.month, today.day);

    final fixedTotal = fixed.fold<double>(0.0, (s, f) => s + f.amount);

    // Speso nel mese
    final spentThisMonth = expenses
        .where((e) => e.date.year == d.year && e.date.month == d.month)
        .fold<double>(0.0, (s, e) => s + e.amount);

    // ✅ Speso oggi
    final spentToday = expenses
        .where((e) => _sameDay(e.date, d))
        .fold<double>(0.0, (s, e) => s + e.amount);

    final availableAfterFixedAndSaving = incomeMonthly - fixedTotal - savingMonthly;
    final impossible = availableAfterFixedAndSaving < 0;

    final remaining = availableAfterFixedAndSaving - spentThisMonth;
    final overspent = remaining < 0;

    final endMonth = _endOfMonth(d);
    final remainingDaysInMonth = endMonth.difference(d).inDays + 1;

    final endWeek = _endOfWeek(d);
    final remainingDaysInWeek = endWeek.difference(d).inDays + 1;

    // Media da oggi a fine mese (con ciò che resta ORA)
    final daily = remainingDaysInMonth > 0 ? (remaining / remainingDaysInMonth) : 0.0;

    // ✅ “Quota pianificata per oggi” = come se oggi non avessi ancora speso nulla:
    // (remaining + spentToday) / giorniRimasti
    final dailyPlannedToday = remainingDaysInMonth > 0
        ? ((remaining + spentToday) / remainingDaysInMonth)
        : 0.0;

    // ✅ Oggi reale = quota pianificata - già speso oggi
    final todayRemaining = dailyPlannedToday - spentToday;

    final weekly = daily * remainingDaysInWeek;

    return BudgetSnapshot(
      income: _r2(incomeMonthly),
      fixed: _r2(fixedTotal),
      saving: _r2(savingMonthly),
      spent: _r2(spentThisMonth),
      remaining: _r2(remaining),
      daily: _r2(daily),
      weekly: _r2(weekly),
      spentToday: _r2(spentToday),
      todayRemaining: _r2(todayRemaining),
      impossible: impossible,
      overspent: overspent,
      remainingDaysInMonth: remainingDaysInMonth,
      remainingDaysInWeek: remainingDaysInWeek,
    );
  }
}