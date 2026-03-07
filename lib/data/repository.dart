import 'package:hive/hive.dart';
import 'models.dart';

class Repository {
  Repository._();
  static final Repository instance = Repository._();

  static const _boxExpenses = 'expenses';
  static const _boxIncomes = 'incomes';
  static const _boxFixed = 'fixed_expenses';
  static const _boxGoals = 'goals';
  static const _boxSettings = 'settings';

  // ✅ profilo onboarding
  static const _boxProfile = 'profile';

  late Box _expenses;
  late Box _incomes;
  late Box _fixed;
  late Box _goals;
  late Box _settings;
  late Box _profile;

  Future<void> init() async {
    _expenses = await Hive.openBox(_boxExpenses);
    _incomes = await Hive.openBox(_boxIncomes);
    _fixed = await Hive.openBox(_boxFixed);
    _goals = await Hive.openBox(_boxGoals);
    _settings = await Hive.openBox(_boxSettings);
    _profile = await Hive.openBox(_boxProfile);
  }

  // -------------------- EXPENSES --------------------
  List<Expense> getExpenses() => _expenses.values
      .whereType<Map>()
      .map((e) => Expense.fromMap(Map<dynamic, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> upsertExpense(Expense e) async => _expenses.put(e.id, e.toMap());
  Future<void> deleteExpense(String id) async => _expenses.delete(id);

  // -------------------- INCOMES --------------------
  List<Income> getIncomes() => _incomes.values
      .whereType<Map>()
      .map((e) => Income.fromMap(Map<dynamic, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> upsertIncome(Income i) async => _incomes.put(i.id, i.toMap());
  Future<void> deleteIncome(String id) async => _incomes.delete(id);

  // -------------------- FIXED --------------------
  List<FixedExpense> getFixed() => _fixed.values
      .whereType<Map>()
      .map((e) => FixedExpense.fromMap(Map<dynamic, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  Future<void> upsertFixed(FixedExpense e) async => _fixed.put(e.id, e.toMap());
  Future<void> deleteFixed(String id) async => _fixed.delete(id);

  // -------------------- GOALS --------------------
  List<Goal> getGoals() => _goals.values
      .whereType<Map>()
      .map((e) => Goal.fromMap(Map<dynamic, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));

  Future<void> upsertGoal(Goal g) async => _goals.put(g.id, g.toMap());
  Future<void> deleteGoal(String id) async => _goals.delete(id);

  // -------------------- SETTINGS --------------------
  SettingsModel get settings {
    final raw = _settings.get('main');
    if (raw is Map) {
      return SettingsModel.fromMap(Map<dynamic, dynamic>.from(raw));
    }
    // default se non esiste
    return const SettingsModel(
      dailyReminderEnabled: false,
      dailyReminderHour: 20,
      dailyReminderMinute: 0,
      monthlySaving: 300,
      morningBudgetEnabled: true,
      morningBudgetHour: 8,
      morningBudgetMinute: 30,
      eveningStatusEnabled: true,
      eveningStatusHour: 21,
      eveningStatusMinute: 30,
    );
  }

  Future<void> saveSettings(SettingsModel s) async =>
      _settings.put('main', s.toMap());

  /// ✅ SOLO settings default. NIENTE dati demo.
  Future<void> ensureDefaultSettings() async {
    if (_settings.get('main') == null) {
      await saveSettings(const SettingsModel(
        dailyReminderEnabled: false,
        dailyReminderHour: 20,
        dailyReminderMinute: 0,
        monthlySaving: 300,
        morningBudgetEnabled: true,
        morningBudgetHour: 8,
        morningBudgetMinute: 30,
        eveningStatusEnabled: true,
        eveningStatusHour: 21,
        eveningStatusMinute: 30,
      ));
    }
    // ❌ niente seed spese fisse
  }

  // -------------------- PROFILE (Onboarding) --------------------
  UserProfile? getProfile() {
    final raw = _profile.get('profile');
    if (raw is Map) {
      return UserProfile.fromMap(Map<dynamic, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> saveProfile(UserProfile p) async {
    await _profile.put('profile', p.toMap());
  }

  Future<void> clearProfile() async {
    await _profile.delete('profile');
  }

  // -------------------- RESET UTILS (facoltative ma utili) --------------------
  Future<void> clearFixed() async => _fixed.clear();

  Future<void> clearAllData() async {
    await _expenses.clear();
    await _incomes.clear();
    await _fixed.clear();
    await _goals.clear();
    await _settings.clear();
    await _profile.clear();
  }
}