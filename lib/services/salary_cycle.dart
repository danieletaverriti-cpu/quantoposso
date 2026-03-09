class SalaryCycleRange {
  final DateTime start;
  final DateTime end;

  const SalaryCycleRange({
    required this.start,
    required this.end,
  });
}

class SalaryCycleService {
  static SalaryCycleRange estimateCycle({
    required DateTime today,
    required int paydayDay,
  }) {
    final safePayday = paydayDay.clamp(1, 31);

    DateTime start;

    if (today.day >= safePayday) {
      start = _safeDate(today.year, today.month, safePayday);
    } else {
      final prevMonth = today.month == 1 ? 12 : today.month - 1;
      final prevYear = today.month == 1 ? today.year - 1 : today.year;
      start = _safeDate(prevYear, prevMonth, safePayday);
    }

    final nextMonth = start.month == 12 ? 1 : start.month + 1;
    final nextYear = start.month == 12 ? start.year + 1 : start.year;

    final nextCycleStart = _safeDate(nextYear, nextMonth, safePayday);
    final end = nextCycleStart.subtract(const Duration(days: 1));

    return SalaryCycleRange(start: start, end: end);
  }

  static DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }
}