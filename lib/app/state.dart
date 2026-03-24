import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../services/budget_math.dart';
import '../services/notifications.dart';
import '../services/salary_cycle.dart';
import '../services/iap_service.dart';
import '../services/backup_service.dart';

class AppState extends ChangeNotifier {
  final repo = Repository.instance;

  List<Expense> expenses = [];
  List<Income> incomes = [];
  List<FixedExpense> fixed = [];
  List<Goal> goals = [];

  SettingsModel settings = const SettingsModel(
    
    dailyReminderEnabled: true,
    dailyReminderHour: 19,
    dailyReminderMinute: 30,
    monthlySaving: 300,
  );
  // ---------------- PRO ----------------

bool get isProActive {
  if (!settings.isProUnlocked) return false;

  if (settings.proExpiryDateIso == null) return true;

  final expiry = DateTime.tryParse(settings.proExpiryDateIso!);
  if (expiry == null) return true;

  return DateTime.now().isBefore(expiry);
}

  // ✅ onboarding profile
  UserProfile? profile;
  bool get hasProfile => profile != null;

  Future<void> init() async {
    await repo.init();
    await repo.ensureDefaultSettings();

    expenses = repo.getExpenses();
    incomes = repo.getIncomes();
    fixed = repo.getFixed();
    goals = repo.getGoals();
    settings = repo.settings;

    profile = repo.getProfile();
    
    await IapService.instance.init(this);

    notifyListeners();
  }

  //attivazioe versione pro

Future<void> unlockPro({
  required String plan,
  required DateTime expiry,
}) async {
  final updated = settings.copyWith(
    isProUnlocked: true,
    proPlan: plan,
    proExpiryDateIso: expiry.toIso8601String(),
  );

  await repo.saveSettings(updated);
  settings = updated;

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

//versione di prova
Future<void> activateTrial() async {
  if (settings.proTrialUsed) return;

  final expiry = DateTime.now().add(const Duration(days: 7));

  final updated = settings.copyWith(
    isProUnlocked: true,
    proPlan: "trial",
    proExpiryDateIso: expiry.toIso8601String(),
    proTrialUsed: true,
  );

  await repo.saveSettings(updated);
  settings = updated;

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

//revoca pro
Future<void> revokePro() async {
  final updated = settings.copyWith(
    isProUnlocked: false,
    clearProPlan: true,
    clearProExpiryDateIso: true,
  );

  await repo.saveSettings(updated);
  settings = updated;
  notifyListeners();
}

  Future<void> refresh() async {
    expenses = repo.getExpenses();
    incomes = repo.getIncomes();
    fixed = repo.getFixed();
    goals = repo.getGoals();
    settings = repo.settings;
    profile = repo.getProfile();
    notifyListeners();
  }

//backup dati
Future<void> importBackup(Map<String, dynamic> data) async {
  // Pulisci DB
  await repo.clearAllData();

  // Expenses
  final importedExpenses =
      ((data['expenses'] as List?) ?? [])
          .map((e) => Expense.fromMap(e as Map<dynamic, dynamic>))
          .toList();

  for (final e in importedExpenses) {
    await repo.upsertExpense(e);
  }

  // Incomes
  final importedIncomes =
      ((data['incomes'] as List?) ?? [])
          .map((i) => Income.fromMap(i as Map<dynamic, dynamic>))
          .toList();

  for (final i in importedIncomes) {
    await repo.upsertIncome(i);
  }

  // Fixed
  final importedFixed =
      ((data['fixed'] as List?) ?? [])
          .map((f) => FixedExpense.fromMap(f as Map<dynamic, dynamic>))
          .toList();

  for (final f in importedFixed) {
    await repo.upsertFixed(f);
  }

  // Goals
  final importedGoals =
      ((data['goals'] as List?) ?? [])
          .map((g) => Goal.fromMap(g as Map<dynamic, dynamic>))
          .toList();

  for (final g in importedGoals) {
    await repo.upsertGoal(g);
  }

  // Settings
  final importedSettings = SettingsModel.fromMap(
    (data['settings'] as Map?)?.cast<dynamic, dynamic>() ?? {},
  );

  await repo.saveSettings(importedSettings);

  // Ricarica tutto da Hive
  await refresh();
}
// Expenses
  Future<void> addExpense(Expense e) async {
  await repo.upsertExpense(e);
  expenses = repo.getExpenses();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  Future<void> deleteExpense(String id) async {
  await repo.deleteExpense(id);
  expenses = repo.getExpenses();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}
  // Incomes
  Future<void> addIncome(Income i) async {
  await repo.upsertIncome(i);
  incomes = repo.getIncomes();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  Future<void> deleteIncome(String id) async {
  await repo.deleteIncome(id);
  incomes = repo.getIncomes();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  // Fixed
Future<void> addFixed(FixedExpense e) async {
  await repo.upsertFixed(e);
  fixed = repo.getFixed();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  Future<void> deleteFixed(String id) async {
  await repo.deleteFixed(id);
  fixed = repo.getFixed();
  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  // Goals
  Future<void> addGoal(Goal g) async {
  await repo.upsertGoal(g);
  goals = repo.getGoals();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}
  // Alias per compatibilità con GoalsScreen
  Future<void> updateGoal(Goal g) => addGoal(g);

  Future<void> deleteGoal(String id) async {
  await repo.deleteGoal(id);
  goals = repo.getGoals();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}

  // Settings
  Future<void> saveSettings(SettingsModel s) async {
  await repo.saveSettings(s);
  settings = repo.settings;

  if (!settings.notificationsPermissionRequested) {
    await NotificationsService.instance.requestPermissionsIfNeeded();

    final updated = settings.copyWith(
      notificationsPermissionRequested: true,
    );

    await repo.saveSettings(updated);
    settings = updated;
  }

  await _rescheduleNotificationsSafe();

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}
  // Alias per compatibilità con SettingsScreen
  Future<void> updateSettings(SettingsModel s) => saveSettings(s);

  // ✅ Profile
  Future<void> saveProfile(UserProfile p) async {
  await repo.saveProfile(p);
  profile = p;

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}
  Future<void> setProfileAvatarPath(String? path) async {
  final updated = settings.copyWith(profileAvatarPath: path);
  await saveSettings(updated);
}

  Future<void> clearProfile() async {
  await repo.clearProfile();
  profile = null;

  if (isProActive) {
    await BackupService.instance.autoBackup(this);
  }

  notifyListeners();
}
  double _spentToday({
  required int cycleRemainingDays,
}) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));

  return expenses
      .where((e) =>
          e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(end))
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
}

  Future<void> _rescheduleNotificationsSafe() async {
  try {
    final now = DateTime.now();

    final cycle = SalaryCycleService.estimateCycle(
      today: now,
      paydayDay: settings.paydayDay,
      lastSalaryDateIso: settings.lastSalaryDateIso,
      useRealSalaryCycle: settings.useRealSalaryCycle,
    );

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

    final monthlyIncome = incomes
        .where((i) =>
            !i.date.isBefore(cycleStart) && i.date.isBefore(cycleEndExclusive))
        .fold<double>(0.0, (sum, i) => sum + i.amount);

    final variableSpent = expenses
        .where((e) =>
            !e.date.isBefore(cycleStart) && e.date.isBefore(cycleEndExclusive))
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final fixedTotal = fixed.fold<double>(0.0, (sum, f) => sum + f.amount);

    final todayStart = DateTime(now.year, now.month, now.day);
    final cycleTotalDays = cycle.end.difference(cycle.start).inDays + 1;
    final cycleRemainingDaysRaw = cycle.end.difference(todayStart).inDays + 1;
    final cycleRemainingDays =
        cycleRemainingDaysRaw <= 0 ? 1 : cycleRemainingDaysRaw;

    final spentToday = _spentToday(
      cycleRemainingDays: cycleRemainingDays,
    );

    final snap = BudgetMath.compute(
      today: now,
      monthlyIncome: monthlyIncome,
      fixedExpensesTotal: fixedTotal,
      goalMonthlySaving: settings.monthlySaving,
      variableSpentThisMonth: variableSpent,
      cycleTotalDays: cycleTotalDays,
      cycleRemainingDays: cycleRemainingDays,
      variableSpentToday: spentToday,
    );

    final dayAllowance = snap.dayAllowance;

    if (settings.morningBudgetEnabled) {
      await NotificationsService.instance.scheduleMorningBudget(
  hour: settings.morningBudgetHour,
  minute: settings.morningBudgetMinute,
  todayRemaining: snap.todayRemaining,
);
    } else {
      await NotificationsService.instance.cancelMorningBudget();
    }

    if (settings.eveningStatusEnabled) {
      await NotificationsService.instance.scheduleEveningStatus(
        hour: settings.eveningStatusHour,
        minute: settings.eveningStatusMinute,
        dayAllowance: dayAllowance,
        spentToday: spentToday,
      );
    } else {
      await NotificationsService.instance.cancelEveningStatus();
    }

    if (settings.dailyReminderEnabled) {
      await NotificationsService.instance.scheduleDailyBudgetReminder(
        hour: settings.dailyReminderHour,
        minute: settings.dailyReminderMinute,
        dayAllowance: dayAllowance,
        todayRemaining: snap.todayRemaining,
      );
    } else {
      await NotificationsService.instance.cancelDailyReminder();
    }

    if (settings.expenseReminderEnabled) {
      await NotificationsService.instance.scheduleExpenseReminder(
        hour: settings.expenseReminderHour,
        minute: settings.expenseReminderMinute,
      );
    } else {
      await NotificationsService.instance.cancelExpenseReminder();
    }
  } catch (e) {
    if (kDebugMode) {
      print('reschedule notifications failed: $e');
    }
  }
}
  BudgetSnapshot get budget {
  final now = DateTime.now();

  final cycle = SalaryCycleService.estimateCycle(
    today: now,
    paydayDay: settings.paydayDay,
    lastSalaryDateIso: settings.lastSalaryDateIso,
    useRealSalaryCycle: settings.useRealSalaryCycle,
  );

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

  final monthlyIncome = incomes
      .where((i) =>
          !i.date.isBefore(cycleStart) && i.date.isBefore(cycleEndExclusive))
      .fold<double>(0.0, (sum, i) => sum + i.amount);

  final variableSpent = expenses
      .where((e) =>
          !e.date.isBefore(cycleStart) && e.date.isBefore(cycleEndExclusive))
      .fold<double>(0.0, (sum, e) => sum + e.amount);

  final fixedTotal = fixed.fold<double>(0.0, (sum, f) => sum + f.amount);

  final todayStart = DateTime(now.year, now.month, now.day);
  final cycleTotalDays = cycle.end.difference(cycle.start).inDays + 1;
  final cycleRemainingDaysRaw = cycle.end.difference(todayStart).inDays + 1;
  final cycleRemainingDays =
      cycleRemainingDaysRaw <= 0 ? 1 : cycleRemainingDaysRaw;

  final spentToday = _spentToday(
    cycleRemainingDays: cycleRemainingDays,
  );

  return BudgetMath.compute(
    today: now,
    monthlyIncome: monthlyIncome,
    fixedExpensesTotal: fixedTotal,
    goalMonthlySaving: settings.monthlySaving,
    variableSpentThisMonth: variableSpent,
    cycleTotalDays: cycleTotalDays,
    cycleRemainingDays: cycleRemainingDays,
    variableSpentToday: spentToday,
  );
}

}