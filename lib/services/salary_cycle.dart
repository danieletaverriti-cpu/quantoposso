class SalaryCycleRange {
  final DateTime start;
  final DateTime end;
  final bool isEstimated;

  const SalaryCycleRange({
    required this.start,
    required this.end,
    required this.isEstimated,
  });
}

class SalaryCycleService {
  static SalaryCycleRange estimateCycle({
    required DateTime today,
    required int paydayDay,
    String? lastSalaryDateIso,
    bool useRealSalaryCycle = false,
  }) {
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (useRealSalaryCycle && lastSalaryDateIso != null) {
      final parsed = DateTime.tryParse(lastSalaryDateIso);
      if (parsed != null) {
        final realStart = DateTime(parsed.year, parsed.month, parsed.day);

        final nextMonth = realStart.month == 12 ? 1 : realStart.month + 1;
        final nextYear =
            realStart.month == 12 ? realStart.year + 1 : realStart.year;

        final nextCycleStart = _safeDate(nextYear, nextMonth, realStart.day);
        final realEnd = nextCycleStart.subtract(const Duration(days: 1));

        if (!normalizedToday.isBefore(realStart) &&
            !normalizedToday.isAfter(realEnd)) {
          return SalaryCycleRange(
            start: realStart,
            end: realEnd,
            isEstimated: false,
          );
        }

        if (normalizedToday.isAfter(realEnd)) {
          DateTime start;

          if (normalizedToday.day >= realStart.day) {
            start = _safeDate(
              normalizedToday.year,
              normalizedToday.month,
              realStart.day,
            );
          } else {
            final prevMonth =
                normalizedToday.month == 1 ? 12 : normalizedToday.month - 1;
            final prevYear = normalizedToday.month == 1
                ? normalizedToday.year - 1
                : normalizedToday.year;
            start = _safeDate(prevYear, prevMonth, realStart.day);
          }

          final nextEstimatedMonth = start.month == 12 ? 1 : start.month + 1;
          final nextEstimatedYear =
              start.month == 12 ? start.year + 1 : start.year;
          final nextEstimatedStart =
              _safeDate(nextEstimatedYear, nextEstimatedMonth, start.day);
          final end = nextEstimatedStart.subtract(const Duration(days: 1));

          return SalaryCycleRange(
            start: start,
            end: end,
            isEstimated: false,
          );
        }
      }
    }

    final safePayday = paydayDay.clamp(1, 31);

    DateTime start;

    if (normalizedToday.day >= safePayday) {
      start = _safeDate(normalizedToday.year, normalizedToday.month, safePayday);
    } else {
      final prevMonth =
          normalizedToday.month == 1 ? 12 : normalizedToday.month - 1;
      final prevYear = normalizedToday.month == 1
          ? normalizedToday.year - 1
          : normalizedToday.year;
      start = _safeDate(prevYear, prevMonth, safePayday);
    }

    final nextMonth = start.month == 12 ? 1 : start.month + 1;
    final nextYear = start.month == 12 ? start.year + 1 : start.year;

    final nextCycleStart = _safeDate(nextYear, nextMonth, safePayday);
    final end = nextCycleStart.subtract(const Duration(days: 1));

    return SalaryCycleRange(
      start: start,
      end: end,
      isEstimated: true,
    );
  }

  static DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }
}