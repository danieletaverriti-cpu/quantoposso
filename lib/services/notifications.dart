import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  late final FlutterLocalNotificationsPlugin _plugin;

  // -------------------- IDS --------------------
  static const int _morningId = 1000;
  static const int _eveningStatusId = 1002;
  static const int _expenseReminderId = 1003; // ✅ promemoria spese (tap → Add spesa)
  static const int _dailyId = 1001; // legacy
  static const int _testId = 9999;
  static const int _debugId = 8888;

  // -------------------- CHANNELS --------------------
  static const String _morningChannelId = 'morning_budget';
  static const String _eveningChannelId = 'evening_status';
  static const String _expenseChannelId = 'expense_reminder';
  static const String _dailyChannelId = 'daily_reminder'; // legacy
  static const String _testChannelId = 'test_channel';
  static const String _debugChannelId = 'debug_schedule';

  // -------------------- PAYLOADS --------------------
  static const String payloadOpenAddExpense = 'open_add_expense';

  Future<void> Function(String? payload)? _onTap;

  void setOnNotificationTapHandler(
    Future<void> Function(String? payload) handler,
  ) {
    _onTap = handler;
  }

  Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    // ✅ NELLA TUA VERSIONE: è "settings:", NON "initializationSettings:"
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse r) async {
        try {
          final handler = _onTap;
          if (handler != null) await handler(r.payload);
        } catch (_) {}
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _morningChannelId,
          'Budget mattina',
          description: 'Notifica del budget giornaliero al mattino',
          importance: Importance.defaultImportance,
        ),
      );

      // Legacy daily (usato da state.dart)
await android.createNotificationChannel(
  const AndroidNotificationChannel(
    _dailyChannelId,
    'Promemoria budget',
    description: 'Promemoria con budget di oggi',
    importance: Importance.defaultImportance,
  ),
);

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _eveningChannelId,
          'Esito giornata',
          description: 'Complimenti se sei in budget, avviso se sfori',
          importance: Importance.defaultImportance,
        ),
      );

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _expenseChannelId,
          'Promemoria spese',
          description: 'Promemoria per inserire le spese della giornata',
          importance: Importance.defaultImportance,
        ),
      );

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _testChannelId,
          'Test',
          description: 'Canale test notifiche',
          importance: Importance.high,
        ),
      );

      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _debugChannelId,
          'Debug schedule',
          description: 'Canale debug schedulazione',
          importance: Importance.high,
        ),
      );
    }
  }

  // ✅ permessi (Android 13+ / iOS)
  Future<void> requestPermissionsIfNeeded() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  // -------------------- DETAILS --------------------

  NotificationDetails _morningDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _morningChannelId,
          'Budget mattina',
          channelDescription: 'Notifica del budget giornaliero al mattino',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  NotificationDetails _eveningDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _eveningChannelId,
          'Esito giornata',
          channelDescription: 'Complimenti se sei in budget, avviso se sfori',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  NotificationDetails _expenseDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _expenseChannelId,
          'Promemoria spese',
          channelDescription: 'Promemoria per inserire le spese della giornata',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  NotificationDetails _testDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannelId,
          'Test',
          channelDescription: 'Canale test notifiche',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  NotificationDetails _debugDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _debugChannelId,
          'Debug schedule',
          channelDescription: 'Canale debug schedulazione',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      NotificationDetails _dailyDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        _dailyChannelId,
        'Promemoria budget',
        channelDescription: 'Promemoria con budget di oggi',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

  // -------------------- CANCEL --------------------

  Future<void> cancelMorningBudget() async => _plugin.cancel(id: _morningId);

  Future<void> cancelEveningStatus() async =>
      _plugin.cancel(id: _eveningStatusId);

  Future<void> cancelExpenseReminder() async =>
      _plugin.cancel(id: _expenseReminderId);
  

  Future<void> cancelAllBudgetNotifications() async {
    await cancelMorningBudget();
    await cancelEveningStatus();
    await cancelExpenseReminder();
  }

  // -------------------- DEBUG/TEST --------------------

  Future<void> showTestNow() async {
    await _plugin.show(
      id: _testId,
      title: 'Quanto Posso',
      body: 'Notifica di test ✅',
      notificationDetails: _testDetails(),
      payload: payloadOpenAddExpense,
    );
  }

  Future<void> debugScheduleIn10Seconds() async {
    final when = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    await _plugin.zonedSchedule(
      id: _debugId,
      title: 'Debug',
      body: 'Schedulata: arriva ora ✅',
      scheduledDate: when,
      notificationDetails: _debugDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payloadOpenAddExpense,
    );
  }

  Future<int> pendingCount() async {
    if (!kDebugMode) return 0;
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  // -------------------- HELPERS --------------------

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  String _euro(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  // -------------------- MATTINA: BUDGET DI OGGI --------------------

  Future<void> scheduleMorningBudget({
    required int hour,
    required int minute,
    required double dayAllowance,
  }) async {
    final when = _nextInstance(hour, minute);

    await _plugin.zonedSchedule(
      id: _morningId,
      title: 'Quanto Posso',
      body: 'Oggi puoi spendere ~ ${_euro(dayAllowance)}€ 💡',
      scheduledDate: when,
      notificationDetails: _morningDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadOpenAddExpense,
    );
  }
// -------------------- LEGACY (usato da state.dart) --------------------
/// NON rimuovere: serve per compatibilità con state.dart
Future<void> scheduleDailyBudgetReminder({
  required int hour,
  required int minute,
  required double dayAllowance,
  double? todayRemaining,
}) async {
  final when = _nextInstance(hour, minute);
  final today = todayRemaining ?? dayAllowance;

  await _plugin.zonedSchedule(
    id: _dailyId,
    title: 'Quanto Posso',
    body: 'Oggi puoi spendere ~ ${_euro(today)}€',
    scheduledDate: when,
    notificationDetails: _dailyDetails(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: payloadOpenAddExpense,
  );
}

Future<void> cancelDailyReminder() async {
  await _plugin.cancel(id: _dailyId);
}
  // -------------------- SERA: ESITO GIORNATA --------------------

  Future<void> scheduleEveningStatus({
    required int hour,
    required int minute,
    required double dayAllowance,
    required double spentToday,
  }) async {
    final when = _nextInstance(hour, minute);

    final inBudget = spentToday <= dayAllowance;
    final diff = (dayAllowance - spentToday);

    final body = inBudget
        ? 'Bravissimo! Sei dentro budget 🎉\nOggi ti restavano ~ ${_euro(diff)}€'
        : 'Hai sforato di ~ ${_euro(-diff)}€ ⚠️\nDomani fai più attenzione 💪';

    await _plugin.zonedSchedule(
      id: _eveningStatusId,
      title: 'Quanto Posso',
      body: body,
      scheduledDate: when,
      notificationDetails: _eveningDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadOpenAddExpense,
    );
  }

  // -------------------- ✅ PROMEMORIA INSERIMENTO SPESE --------------------

  Future<void> scheduleExpenseReminder({
    required int hour,
    required int minute,
  }) async {
    final when = _nextInstance(hour, minute);

    await _plugin.zonedSchedule(
      id: _expenseReminderId,
      title: 'Quanto Posso',
      body: 'Hai inserito tutte le spese di oggi? 🧾',
      scheduledDate: when,
      notificationDetails: _expenseDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadOpenAddExpense,
    );
  }
}