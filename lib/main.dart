import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'services/boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Cattura errori Flutter (build/layout ecc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // ✅ Cattura errori "fuori Flutter" (async, platform, ecc.)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🔥 UNCAUGHT (PlatformDispatcher): $error');
    debugPrint('📌 STACK:\n$stack');
    return true; // evita crash silenzioso
  };

  // ✅ Cattura errori async dentro zone (Boot/init ecc.)
  await runZonedGuarded(() async {
    await Boot.init();
    runApp(const QuantoPossoApp());
  }, (Object error, StackTrace stack) {
    debugPrint('🔥 UNCAUGHT (Zone): $error');
    debugPrint('📌 STACK:\n$stack');
  });
}