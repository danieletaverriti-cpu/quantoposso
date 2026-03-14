import 'package:flutter/foundation.dart';

enum ExpenseImpact {
  daily,
  weekly,
  cycle,
}


@immutable

class Expense {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final ExpenseImpact impact;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.impact = ExpenseImpact.daily,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'impact' : impact.name,
      };

  factory Expense.fromMap(Map<dynamic, dynamic> m) => Expense(
        id: (m['id'] as String?) ?? '',
        amount: ((m['amount'] as num?) ?? 0).toDouble(),
        category: (m['category'] as String?) ?? '',
        date: DateTime.tryParse((m['date'] as String?) ?? '') ?? DateTime.now(),
        note: (m['note'] as String?) ?? '',
        impact: _expenseImpactFromString((m['impact'] as String?) ?? 'daily'),
      );
}

ExpenseImpact _expenseImpactFromString(String value) {
  switch (value) {
    case 'weekly':
      return ExpenseImpact.weekly;
    case 'cycle':
      return ExpenseImpact.cycle;
    case 'daily':
    default:
      return ExpenseImpact.daily;
  }
}

@immutable
class Income {
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  const Income({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Income.fromMap(Map<dynamic, dynamic> m) => Income(
        id: (m['id'] as String?) ?? '',
        amount: ((m['amount'] as num?) ?? 0).toDouble(),
        category: (m['category'] as String?) ?? '',
        date: DateTime.tryParse((m['date'] as String?) ?? '') ?? DateTime.now(),
        note: (m['note'] as String?) ?? '',
      );
}

@immutable
class FixedExpense {
  final String id;
  final String name;
  final double amount;

  const FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
      };

  factory FixedExpense.fromMap(Map<dynamic, dynamic> m) => FixedExpense(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        amount: ((m['amount'] as num?) ?? 0).toDouble(),
      );
}

@immutable
class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;

  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
      };

  factory Goal.fromMap(Map<dynamic, dynamic> m) => Goal(
        id: (m['id'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        targetAmount: ((m['targetAmount'] as num?) ?? 0).toDouble(),
        currentAmount: ((m['currentAmount'] as num?) ?? 0).toDouble(),
      );

  Goal copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
  }) =>
      Goal(
        id: id,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
      );
}

@immutable
class SettingsModel {
  // -------------------- LEGACY (compatibilità) --------------------
  final bool dailyReminderEnabled;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final int paydayDay;
  final String? lastSalaryDateIso;
  final bool useRealSalaryCycle;
  final bool isProUnlocked;
  final String? proPlan; // monthly / yearly
  final String? proExpiryDateIso;
  final bool proTrialUsed;

  /// Risparmio mensile
  final double monthlySaving;

  // -------------------- NOTIFICHE --------------------
  /// Mattina: "Oggi puoi spendere..."
  final bool morningBudgetEnabled;
  final int morningBudgetHour;
  final int morningBudgetMinute;

  /// Sera: "Complimenti 🎉" oppure "Hai sforato ⚠️"
  final bool eveningStatusEnabled;
  final int eveningStatusHour;
  final int eveningStatusMinute;

  /// ✅ NUOVA: promemoria inserimento spese (tap → Add spesa)
  final bool expenseReminderEnabled;
  final int expenseReminderHour;
  final int expenseReminderMinute;

  // -------------------- Profilo / onboarding --------------------
  final bool onboardingCompleted;
  final String? profileName;
  final String? profileAgeRange;
  final String? profileJob;
  final String? profileReason;
  final String? profileGoal;
  final String? profileAvatarPath;
  final bool notificationsPermissionRequested;

  const SettingsModel({
    // legacy
    this.dailyReminderEnabled = false,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 0,

   //stpendio
   this.paydayDay = 28,
   this.lastSalaryDateIso,
   this.useRealSalaryCycle = false,
    // app
    this.monthlySaving = 300,

    // notifiche (default attive)
    this.morningBudgetEnabled = true,
    this.morningBudgetHour = 8,
    this.morningBudgetMinute = 30,

    this.eveningStatusEnabled = true,
    this.eveningStatusHour = 21,
    this.eveningStatusMinute = 30,

    //abbonamento
    this.isProUnlocked = false,
    this.proPlan,
    this.proExpiryDateIso,
    this.proTrialUsed = false,

    // ✅ nuova
    this.expenseReminderEnabled = true,
    this.expenseReminderHour = 20,
    this.expenseReminderMinute = 0,

    // onboarding/profile
    this.onboardingCompleted = false,
    this.profileName,
    this.profileAgeRange,
    this.profileJob,
    this.profileReason,
    this.profileGoal,
    this.profileAvatarPath,
    this.notificationsPermissionRequested = false,
  });

  Map<String, dynamic> toMap() => {
        // legacy
        'dailyReminderEnabled': dailyReminderEnabled,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,

        // app
        'monthlySaving': monthlySaving,
        'paydayDay' : paydayDay,
        'lastSalaryDateIso' : lastSalaryDateIso,
        'useRealSalaryCycle': useRealSalaryCycle,

        // notifiche
        'morningBudgetEnabled': morningBudgetEnabled,
        'morningBudgetHour': morningBudgetHour,
        'morningBudgetMinute': morningBudgetMinute,

'notificationsPermissionRequested': notificationsPermissionRequested,

        'eveningStatusEnabled': eveningStatusEnabled,
        'eveningStatusHour': eveningStatusHour,
        'eveningStatusMinute': eveningStatusMinute,

        //abbonamento
        'isProUnlocked': isProUnlocked,
        'proPlan': proPlan,
        'proExpiryDateIso': proExpiryDateIso,
        'proTrialUsed': proTrialUsed,

        // ✅ nuova
        'expenseReminderEnabled': expenseReminderEnabled,
        'expenseReminderHour': expenseReminderHour,
        'expenseReminderMinute': expenseReminderMinute,

        // profile
        'onboardingCompleted': onboardingCompleted,
        'profileName': profileName,
        'profileAgeRange': profileAgeRange,
        'profileJob': profileJob,
        'profileReason': profileReason,
        'profileGoal': profileGoal,
        'profileAvatarPath': profileAvatarPath,
      };

  factory SettingsModel.fromMap(Map<dynamic, dynamic> m) => SettingsModel(
        // legacy
        dailyReminderEnabled: (m['dailyReminderEnabled'] as bool?) ?? false,
        dailyReminderHour: (m['dailyReminderHour'] as int?) ?? 20,
        dailyReminderMinute: (m['dailyReminderMinute'] as int?) ?? 0,

        // app
        monthlySaving: ((m['monthlySaving'] as num?) ?? 300).toDouble(),
        paydayDay: (m['paydayDay'] as int?) ?? 10,
        lastSalaryDateIso: m['lastSalaryDateIso'] as String?,
        useRealSalaryCycle: (m['useRealSalaryCycle'] as bool?) ?? false,

        // notifiche
        morningBudgetEnabled: (m['morningBudgetEnabled'] as bool?) ?? true,
        morningBudgetHour: (m['morningBudgetHour'] as int?) ?? 8,
        morningBudgetMinute: (m['morningBudgetMinute'] as int?) ?? 30,
        
        notificationsPermissionRequested: (m['notificationsPermissionRequested'] as bool?) ?? false,

        eveningStatusEnabled: (m['eveningStatusEnabled'] as bool?) ?? true,
        eveningStatusHour: (m['eveningStatusHour'] as int?) ?? 21,
        eveningStatusMinute: (m['eveningStatusMinute'] as int?) ?? 30,

        //abbonamento
        isProUnlocked: (m['isProUnlocked'] as bool?) ?? false,
        proPlan: m['proPlan'] as String?,
        proExpiryDateIso: m['proExpiryDateIso'] as String?,
        proTrialUsed: (m['proTrialUsed'] as bool?) ?? false,

        // ✅ nuova (fallback ai default)
        expenseReminderEnabled: (m['expenseReminderEnabled'] as bool?) ?? true,
        expenseReminderHour: (m['expenseReminderHour'] as int?) ?? 21,
        expenseReminderMinute: (m['expenseReminderMinute'] as int?) ?? 0,

        // profile
        onboardingCompleted: (m['onboardingCompleted'] as bool?) ?? false,
        profileName: m['profileName'] as String?,
        profileAgeRange: m['profileAgeRange'] as String?,
        profileJob: m['profileJob'] as String?,
        profileReason: m['profileReason'] as String?,
        profileGoal: m['profileGoal'] as String?,
        profileAvatarPath: m['profileAvatarPath'] as String?,
      );

  SettingsModel copyWith({
    // legacy
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,

    // app
    double? monthlySaving,
    int? paydayDay,
    String? lastSalaryDateIso,
    bool? useRealSalaryCycle,
    bool clearLastSalaryDateIso = false,

    // notifiche
    bool? morningBudgetEnabled,
    int? morningBudgetHour,
    int? morningBudgetMinute,

    bool? notificationsPermissionRequested,

    bool? eveningStatusEnabled,
    int? eveningStatusHour,
    int? eveningStatusMinute,

    //abbonamento
    bool? isProUnlocked,
    String? proPlan,
    String? proExpiryDateIso,
    bool? proTrialUsed,
    bool clearProPlan = false,
    bool clearProExpiryDateIso = false,

    // ✅ nuova
    bool? expenseReminderEnabled,
    int? expenseReminderHour,
    int? expenseReminderMinute,

    // profile
    bool? onboardingCompleted,
    String? profileName,
    String? profileAgeRange,
    String? profileJob,
    String? profileReason,
    String? profileGoal,
    String? profileAvatarPath,

    bool clearProfileName = false,
    bool clearProfileAgeRange = false,
    bool clearProfileJob = false,
    bool clearProfileReason = false,
    bool clearProfileGoal = false,
    bool clearProfileAvatarPath = false,
  }) {
    return SettingsModel(
      // legacy
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,

      // app
      monthlySaving: monthlySaving ?? this.monthlySaving,
      paydayDay: paydayDay ?? this.paydayDay,
      lastSalaryDateIso: clearLastSalaryDateIso
    ? null
    : (lastSalaryDateIso ?? this.lastSalaryDateIso),
useRealSalaryCycle: useRealSalaryCycle ?? this.useRealSalaryCycle,

      // notifiche
      morningBudgetEnabled: morningBudgetEnabled ?? this.morningBudgetEnabled,
      morningBudgetHour: morningBudgetHour ?? this.morningBudgetHour,
      morningBudgetMinute: morningBudgetMinute ?? this.morningBudgetMinute,

      notificationsPermissionRequested: notificationsPermissionRequested ?? this.notificationsPermissionRequested,

      eveningStatusEnabled: eveningStatusEnabled ?? this.eveningStatusEnabled,
      eveningStatusHour: eveningStatusHour ?? this.eveningStatusHour,
      eveningStatusMinute: eveningStatusMinute ?? this.eveningStatusMinute,

      //abbonamento
      isProUnlocked: isProUnlocked ?? this.isProUnlocked,
      proPlan: clearProPlan ? null : (proPlan ?? this.proPlan),
      proExpiryDateIso: clearProExpiryDateIso
      ? null
      : (proExpiryDateIso ?? this.proExpiryDateIso),
      proTrialUsed: proTrialUsed ?? this.proTrialUsed,

      // ✅ nuova
      expenseReminderEnabled: expenseReminderEnabled ?? this.expenseReminderEnabled,
      expenseReminderHour: expenseReminderHour ?? this.expenseReminderHour,
      expenseReminderMinute: expenseReminderMinute ?? this.expenseReminderMinute,

      // profile
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileName: clearProfileName ? null : (profileName ?? this.profileName),
      profileAgeRange: clearProfileAgeRange ? null : (profileAgeRange ?? this.profileAgeRange),
      profileJob: clearProfileJob ? null : (profileJob ?? this.profileJob),
      profileReason: clearProfileReason ? null : (profileReason ?? this.profileReason),
      profileGoal: clearProfileGoal ? null : (profileGoal ?? this.profileGoal),
      profileAvatarPath: clearProfileAvatarPath ? null : (profileAvatarPath ?? this.profileAvatarPath),
    );
  }
}
@immutable
class UserProfile {
  final String name;
  final String ageRange;
  final String job;
  final String reason;
  final String goal;

  const UserProfile({
    required this.name,
    required this.ageRange,
    required this.job,
    required this.reason,
    required this.goal,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'ageRange': ageRange,
        'job': job,
        'reason': reason,
        'goal': goal,
      };

  factory UserProfile.fromMap(Map<dynamic, dynamic> m) => UserProfile(
        name: (m['name'] as String?) ?? '',
        ageRange: (m['ageRange'] as String?) ?? '',
        job: (m['job'] as String?) ?? '',
        reason: (m['reason'] as String?) ?? '',
        goal: (m['goal'] as String?) ?? '',
      );

  /// Applica i campi profilo ai settings ESISTENTI (senza resettare il resto).
  SettingsModel applyToSettings(SettingsModel base, {bool onboardingCompleted = true}) {
    return base.copyWith(
      onboardingCompleted: onboardingCompleted,
      profileName: name.isEmpty ? null : name,
      profileAgeRange: ageRange.isEmpty ? null : ageRange,
      profileJob: job.isEmpty ? null : job,
      profileReason: reason.isEmpty ? null : reason,
      profileGoal: goal.isEmpty ? null : goal,
    );
  }
}