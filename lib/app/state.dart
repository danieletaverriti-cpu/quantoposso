import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../services/budget_math.dart';
import '../services/notifications.dart';

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

// Expenses
  Future<void> addExpense(Expense e) async {
    await repo.upsertExpense(e);
    expenses = repo.getExpenses();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await repo.deleteExpense(id);
    expenses = repo.getExpenses();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  // Incomes
  Future<void> addIncome(Income i) async {
    await repo.upsertIncome(i);
    incomes = repo.getIncomes();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  Future<void> deleteIncome(String id) async {
    await repo.deleteIncome(id);
    incomes = repo.getIncomes();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  // Fixed
  Future<void> addFixed(FixedExpense e) async {
    await repo.upsertFixed(e);
    fixed = repo.getFixed();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  Future<void> deleteFixed(String id) async {
    await repo.deleteFixed(id);
    fixed = repo.getFixed();
    await _rescheduleNotificationsSafe();
    notifyListeners();
  }

  // Goals
  Future<void> addGoal(Goal g) async {
    await repo.upsertGoal(g);
    goals = repo.getGoals();
    notifyListeners();
  }

  // Alias per compatibilità con GoalsScreen
  Future<void> updateGoal(Goal g) => addGoal(g);

  Future<void> deleteGoal(String id) async {
    await repo.deleteGoal(id);
    goals = repo.getGoals();
    notifyListeners();
  }

  // Settings
  Future<void> saveSettings(SettingsModel s) async {
    await repo.saveSettings(s);
    settings = repo.settings;
    // ✅ Popup permessi notifiche al primo avvio (solo una volta)
if (!settings.notificationsPermissionRequested) {
  await NotificationsService.instance.requestPermissionsIfNeeded();
  await saveSettings(
    settings.copyWith(notificationsPermissionRequested: true),
  );
}
    notifyListeners();
  }
  

  // Alias per compatibilità con SettingsScreen
  Future<void> updateSettings(SettingsModel s) => saveSettings(s);

  // ✅ Profile
  Future<void> saveProfile(UserProfile p) async {
    await repo.saveProfile(p);
    profile = p;
    notifyListeners();
  }
  Future<void> setProfileAvatarPath(String? path) async {
  final updated = settings.copyWith(profileAvatarPath: path);
  await saveSettings(updated);
}

  Future<void> clearProfile() async {
    await repo.clearProfile();
    profile = null;
    notifyListeners();
  }
  double _spentToday() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return expenses
        .where((e) =>
            e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            e.date.isBefore(end))
        .fold<double>(0.0, (s, e) => s + e.amount);
  }

  Future<void> _rescheduleNotificationsSafe() async {
    try {
      final snap = budget;
      final dayAllowance = snap.dayAllowance;
      final spentToday = _spentToday();

      // ✅ Mattina
      if (settings.morningBudgetEnabled) {
        await NotificationsService.instance.scheduleMorningBudget(
          hour: settings.morningBudgetHour,
          minute: settings.morningBudgetMinute,
          dayAllowance: dayAllowance,
        );
      } else {
        await NotificationsService.instance.cancelMorningBudget();
      }

      // ✅ Sera (esito giornata)
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

      // ✅ LEGACY (se lo tieni ancora attivo nei settings)
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

      // ⚠️ PROMEMORIA SPESE:
      // Se nel tuo SettingsModel esistono i campi expenseReminderEnabled/hour/minute
      // allora sblocca questo pezzo (altrimenti lascialo commentato).
      
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
        // ignore: avoid_print
        print('reschedule notifications failed: $e');
      }
    }
  }
  BudgetSnapshot get budget {
    final now = DateTime.now();

    // Entrate del mese
    final monthlyIncome = incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .fold<double>(0.0, (sum, i) => sum + i.amount);

    // Spese variabili del mese
    final variableSpent = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    // Spese fisse
    final fixedTotal = fixed.fold<double>(0.0, (sum, f) => sum + f.amount);

    return BudgetMath.compute(
      today: now,
      monthlyIncome: monthlyIncome,
      fixedExpensesTotal: fixedTotal,
      goalMonthlySaving: settings.monthlySaving,
      variableSpentThisMonth: variableSpent,
    );
  }
}