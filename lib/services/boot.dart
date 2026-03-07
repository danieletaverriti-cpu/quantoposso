import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/repository.dart';
import 'notifications.dart';

class Boot {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    await Repository.instance.init();

    await Repository.instance.ensureDefaultSettings();

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    final plugin = FlutterLocalNotificationsPlugin();
    await NotificationsService.instance.init(plugin);

    // ✅ NON chiedere permessi qui
  }
}
