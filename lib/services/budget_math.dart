class BudgetSnapshot {
  final double monthBudget;
  final double monthRemaining;

  final double dayAllowance; // media da oggi a fine ciclo
  final double weekRemaining; // quota giornaliera * giorni rimasti settimana

  final double todayRemaining;

  final int remainingDaysInMonth; // per compatibilità: ora = giorni rimasti nel ciclo
  final int remainingDaysInWeek;

  const BudgetSnapshot({
    required this.monthBudget,
    required this.monthRemaining,
    required this.dayAllowance,
    required this.weekRemaining,
    required this.todayRemaining,
    required this.remainingDaysInMonth,
    required this.remainingDaysInWeek,
  });
}

class BudgetMath {
  static DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: diff));
  }

  static DateTime _endOfWeek(DateTime d) {
    final start = _startOfWeek(d);
    return start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  static double _r2(double v) => double.parse(v.toStringAsFixed(2));

  static BudgetSnapshot compute({
    required DateTime today,
    required double monthlyIncome,
    required double fixedExpensesTotal,
    required double goalMonthlySaving,
    required double variableSpentThisMonth,

    // nuovi: ciclo stipendio
    int? cycleTotalDays,
    int? cycleRemainingDays,

    // opzionale
    double variableSpentToday = 0.0,
  }) {
    final now = DateTime(today.year, today.month, today.day);

    final monthBudget = monthlyIncome - fixedExpensesTotal - goalMonthlySaving;
    final monthRemaining = monthBudget - variableSpentThisMonth;

    final remainingDaysInCycle = (cycleRemainingDays ?? 1) <= 0
        ? 1
        : cycleRemainingDays!;

    final dayAllowance = monthRemaining / remainingDaysInCycle;

    final endWeek = _endOfWeek(now);
    final remainingDaysInWeek = endWeek.difference(now).inDays + 1;

    final weekRemaining = dayAllowance * remainingDaysInWeek;

    return BudgetSnapshot(
      monthBudget: _r2(monthBudget),
      monthRemaining: _r2(monthRemaining),
      dayAllowance: _r2(dayAllowance),
      weekRemaining: _r2(weekRemaining),
      todayRemaining: _r2(dayAllowance - variableSpentToday),
      remainingDaysInMonth: remainingDaysInCycle,
      remainingDaysInWeek: remainingDaysInWeek,
    );
  }
}