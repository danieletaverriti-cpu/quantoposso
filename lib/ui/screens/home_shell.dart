import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'dashboard_screen.dart' as dash;
import 'movements_screen.dart' as mov;
import 'add_movement_screen.dart' as add;
import 'fixed_screen.dart' as fix;
import 'goals_screen.dart' as goal;
import 'package:quantoposso/ui/screens/settings_screen.dart';
import 'faq_screen.dart';
import '../../services/salary_cycle.dart';
import 'package:quantoposso/ui/screens/pro_screen.dart';
import 'package:quantoposso/ui/screens/settings_screen.dart';
import 'package:quantoposso/ui/screens/statistics_screen.dart';
import 'package:quantoposso/ui/screens/security/app_lock_screen.dart';

class HomeShell extends StatefulWidget {
  final AppState state;
  const HomeShell({super.key, required this.state});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  int addMode = 0; // 0 = spesa, 1 = entrata 
  bool _locked = true;

Future<void> _checkLock() async {
  final s = widget.state.settings;

  if (!s.appLockEnabled || !s.appLockSetupCompleted) {
    if (mounted) {
      setState(() => _locked = false);
    }
    return;
  }

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AppLockScreen(
        type: s.appLockType,
        pin: s.appLockPin,
      ),
    ),
  );

  if (!mounted) return;

  if (result == true) {
    setState(() => _locked = false);
  }
}

Widget _bottomItem({
  required IconData icon,
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  const selectedColor = Color(0xFF2563EB);
  const normalColor = Color(0xFF6B7280);

  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 58,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? selectedColor : normalColor,
            size: selected ? 24 : 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? selectedColor : normalColor,
            ),
          ),
        ],
      ),
    ),
  );
}
  int? _pendingAddMode; // 0=spesa 1=entrata
  void _go(int i) {
    if (i == index) return;
    setState(() => index = i);
  }

  void _openSettings() {
  Navigator.pop(context); // chiude drawer
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SettingsScreen(state: widget.state),
    ),
  );
}

  void _openFaq() {
    Navigator.pop(context); // chiude drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FaqScreen(),
      ),
    );
  }

  void _openTools() {
  Navigator.pop(context); // chiude il drawer

  if (!widget.state.isProActive) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProScreen(state: widget.state),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ToolsScreen(state: widget.state),
    ),
  );
}


 void _openStatistics() {
  Navigator.pop(context); // chiude drawer

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StatisticsScreen(state: widget.state),
    ),
  );
}

Widget _drawerTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  String? subtitle,
  bool showPro = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),

              if (showPro)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  bool _isAddOpen() {
    // Se sei sulla tab "Aggiungi" (index 2), considera già aperto “Add”
    if (index == 2) return true;

    // Se sopra lo stack c’è già una pagina AddMovementScreen, evitiamo doppioni.
    // Non possiamo leggere direttamente lo stack, quindi usiamo una route name
    // (vedi openAdd) oppure controlliamo con ModalRoute in pushNamed.
    return false;
  }

  /// ✅ apre direttamente la schermata "Aggiungi" in modalità:
  /// mode: 0 = Spesa, 1 = Entrata
void openAdd({required int mode}) {
  setState(() {
    addMode = mode; // memorizza cosa hai premuto
    index = 2; // vai alla tab Aggiungi
  });
}

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      dash.DashboardScreen(
        state: widget.state,
        onNavigate: _go,
        onQuickAddExpense: () => openAdd(mode: 0),
        onQuickAddIncome: () => openAdd(mode: 1),
      ),

      mov.MovementsScreen(state: widget.state),

      // tab "Aggiungi"
  add.AddMovementScreen(
  key: ValueKey(addMode),
  state: widget.state,
  initialMode: addMode,
  onDone: () => _go(0),
),
      fix.FixedScreen(state: widget.state),
      goal.GoalsScreen(state: widget.state),
    ];

    return Scaffold(
      body: pages[index],

      drawer: Drawer(
  child: SafeArea(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Builder(
            builder: (context) {
              final profileName = (widget.state.profile?.name ?? '').trim();
              final initial = profileName.isEmpty
                  ? 'Q'
                  : profileName[0].toUpperCase();

              return Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileName.isEmpty ? 'Quanto Posso' : profileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Menu rapido',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            children: [
              _drawerTile(
                icon: Icons.settings_rounded,
                title: 'Impostazioni',
                onTap: _openSettings,
              ),
              _drawerTile(
                icon: Icons.help_outline_rounded,
                title: 'FAQ',
                onTap: _openFaq,
              ),
              _drawerTile(
                icon: Icons.emoji_events_rounded,
                title: 'Obiettivi',
                onTap: () {
                  Navigator.pop(context);
                  _go(4);
                },
              ),
              _drawerTile(
                icon: Icons.lock_rounded,
                title: 'Uscite fisse',
                onTap: () {
                  Navigator.pop(context);
                  _go(3);
                },
              ),
              _drawerTile(
                icon: Icons.receipt_long_rounded,
                title: 'Movimenti',
                onTap: () {
                  Navigator.pop(context);
                  _go(1);
                },
              ),
             _drawerTile(
  icon: Icons.build_rounded,
  title: 'Strumenti',
  subtitle: widget.state.isProActive
      ? 'Export • Backup • Ripristino'
      : 'Disponibile con QuantoPosso PRO',
  showPro: !widget.state.isProActive,
  onTap: _openTools,
),
_drawerTile(
  icon: Icons.bar_chart_rounded,
  title: 'Statistiche',
  subtitle: widget.state.isProActive
      ? 'Analisi, categorie e insight'
      : 'Scopri dove vanno i tuoi soldi',
  showPro: !widget.state.isProActive,
  onTap: _openStatistics,
),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'v1.0',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade700,
                  ),
            ),
          ),
        ),
      ],
    ),
  ),
),

   bottomNavigationBar: Padding(
  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
  child: Container(
    height: 78,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomItem(
          icon: Icons.grid_view_rounded,
          label: 'Home',
          selected: index == 0,
          onTap: () => _go(0),
        ),
        _bottomItem(
          icon: Icons.receipt_long_rounded,
          label: 'Lista',
          selected: index == 1,
          onTap: () => _go(1),
        ),

        // bottone centrale premium
        GestureDetector(
          onTap: () => _go(2),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),

        _bottomItem(
          icon: Icons.lock_rounded,
          label: 'Fisse',
          selected: index == 3,
          onTap: () => _go(3),
        ),
        _bottomItem(
          icon: Icons.emoji_events_rounded,
          label: 'Premi',
          selected: index == 4,
          onTap: () => _go(4),
        ),
      ],
    ),
  ),
   ),
   );
}
}
