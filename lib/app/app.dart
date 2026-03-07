import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/services/notifications.dart';

import '../ui/screens/splash_screen.dart';
import '../ui/screens/add_movement_screen.dart';

class QuantoPossoApp extends StatefulWidget {
  const QuantoPossoApp({super.key});

  @override
  State<QuantoPossoApp> createState() => _QuantoPossoAppState();
}

class _QuantoPossoAppState extends State<QuantoPossoApp> {
  final AppState state = AppState();

  // ✅ navigatorKey per navigare da handler notifica
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  static const String _routeAddExpense = '/add-expense';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('it_IT', null);

    // ✅ carica dati app (se già lo fai altrove non rompe, ma qui è “safe”)
    // ignore: discarded_futures
    state.init();

    // ✅ tap notifica → vai a schermata Aggiungi Spesa
    NotificationsService.instance.setOnNotificationTapHandler((payload) async {
      if (payload != NotificationsService.payloadOpenAddExpense) return;

      // aspetta il primo frame così il navigator è pronto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = _navKey.currentState;
        if (nav == null) return;

        // evita di aprire 10 volte la stessa pagina se tocchi più notifiche
        nav.pushNamed(_routeAddExpense);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navKey,
          debugShowCheckedModeBanner: false,
          title: 'Quanto Posso',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: const Color(0xFFF4F6FA),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          routes: {
            _routeAddExpense: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Aggiungi spesa')),
                  body: AddMovementScreen(
                    state: state,
                    onDone: () {
                      // opzionale: torna indietro dopo salvataggio
                      _navKey.currentState?.maybePop();
                    },
                    initialMode: 0, // ✅ 0 = spesa
                  ),
                ),
          },
          home: SplashScreen(state: state),
        );
      },
    );
  }
}