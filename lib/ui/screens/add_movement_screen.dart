import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/qp_design.dart';

/// Usato solo per la modalità modifica (edit da lista movimenti)
class EditingMovement {
  final bool isIncome;
  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;
  final ExpenseImpact impact;

  const EditingMovement({
    required this.isIncome,
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.impact = ExpenseImpact.daily,
  });
}

class AddMovementScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onDone;

  /// Se presente → schermata in modalità modifica
  final EditingMovement? editing;

  /// ✅ 0 = Spesa, 1 = Entrata (solo quando NON stai modificando)
  final int? initialMode;

  /// ✅ Se valorizzato, forza SEMPRE la modalità e blocca lo switch UI.
  /// Utile quando arrivi da notifica (es: forceMode: 0 per aprire "Aggiungi Spesa").
  final int? forceMode;

  const AddMovementScreen({
    super.key,
    required this.state,
    required this.onDone,
    this.editing,
    this.initialMode,
    this.forceMode,
  });

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  int _mode = 0; // 0 = Spesa, 1 = Entrata

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  String _expenseCategory = 'Varie';
  String _incomeCategory = 'Stipendio';
  ExpenseImpact _expenseImpact = ExpenseImpact.daily;

  int? get _forcedMode => widget.forceMode?.clamp(0, 1);

  void _applyInitialMode() {
    // Priorità:
    // 1) editing → decide lui
    // 2) forceMode → blocca
    // 3) initialMode → default
    final ed = widget.editing;
    if (ed != null) {
      _mode = ed.isIncome ? 1 : 0;
      return;
    }

    if (_forcedMode != null) {
      _mode = _forcedMode!;
      return;
    }

    if (widget.initialMode != null) {
      _mode = widget.initialMode!.clamp(0, 1);
      return;
    }

    _mode = 0;
  }

  @override
  void initState() {
    super.initState();

    _applyInitialMode();

    // ✅ se stai modificando, carica i valori
    final ed = widget.editing;
    if (ed != null) {
      _amountCtrl.text = ed.amount.toStringAsFixed(
        ed.amount == ed.amount.roundToDouble() ? 0 : 2,
      );
      _noteCtrl.text = ed.note;
      _date = ed.date;

      if (ed.isIncome) {
  _incomeCategory = ed.category;
} else {
  _expenseCategory = ed.category;
  _expenseImpact = ed.impact;
}
    }
  }

  @override
  void didUpdateWidget(covariant AddMovementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se cambia forceMode (o si entra/esce da editing) teniamo la UI coerente
    final oldForced = oldWidget.forceMode?.clamp(0, 1);
    final newForced = widget.forceMode?.clamp(0, 1);

    if (oldWidget.editing != widget.editing || oldForced != newForced) {
      setState(() {
        _applyInitialMode();
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll('€', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _resetForm() {
  _amountCtrl.clear();
  _noteCtrl.clear();
  _date = DateTime.now();
  _expenseImpact = ExpenseImpact.daily;
  setState(() {});
}

  Future<void> _save() async {
    final amount = _parseAmount(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    final ed = widget.editing;

    // Se stiamo modificando: elimina prima il vecchio
    if (ed != null) {
      if (ed.isIncome) {
        await widget.state.deleteIncome(ed.id);
      } else {
        await widget.state.deleteExpense(ed.id);
      }
    }

    // sicurezza: se forceMode è attivo, salva coerente a forceMode
    final effectiveMode = _forcedMode ?? _mode;

    final id = ed?.id ??
        (effectiveMode == 0
            ? 'e_${DateTime.now().millisecondsSinceEpoch}'
            : 'i_${DateTime.now().millisecondsSinceEpoch}');

    if (effectiveMode == 0) {
      final e = Expense(
        id: id,
        amount: amount,
        category: _expenseCategory,
        date: _date,
        note: _noteCtrl.text.trim(),
        impact: _expenseImpact,
      );
      await widget.state.addExpense(e);
    } else {
      final i = Income(
  id: id,
  amount: amount,
  category: _incomeCategory,
  date: _date,
  note: _noteCtrl.text.trim(),
);
await widget.state.addIncome(i);

// Se è uno stipendio, aggiorna il ciclo reale
if (_incomeCategory == 'Stipendio') {
  final currentSettings = widget.state.settings;
  await widget.state.saveSettings(
    currentSettings.copyWith(
      lastSalaryDateIso: _date.toIso8601String(),
      useRealSalaryCycle: true,
    ),
  );
}
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ed == null
              ? (effectiveMode == 0 ? 'Spesa salvata ✅' : 'Entrata salvata ✅')
              : 'Modifica salvata ✅',
        ),
      ),
    );

    if (ed == null) {
      _resetForm();
      widget.onDone();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // categorie estese
    final selectedMode = (_forcedMode ?? _mode);
final isExpense = selectedMode == 0;

final Color activeColor = isExpense ? const Color(0xFFEF4444) : const Color(0xFF16A34A); // rosso / verde
    final expenseCategories = <String>[
  'Abbigliamento',
  'Auto',
  'Bar',
  'Bollette',
  'Casa',
  'Regali',
  'Ristorante',
  'Salute',
  'Spesa alimentare',
  'Sport',
  'Svago',
  'Tasse',
  'Trasporti',
  'Varie',
  'Viaggi',
];

    final incomeCategories = <String>[
      'Stipendio',
      'Straordinari',
      'Bonus',
      'Rimborso',
      'Altro',
    ];

    
    final euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    final now = DateTime.now();
    final monthIncome = widget.state.incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .fold<double>(0, (s, i) => s + i.amount);

    final monthSpent = widget.state.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (s, e) => s + e.amount);

    Widget kv(String k, String v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final canChangeMode = widget.editing == null && _forcedMode == null;
return Scaffold(
  body: SafeArea(child: Stack(
  children: [
    const BlueHeaderBackground(),
    ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.editing == null ? 'Aggiungi movimento' : 'Modifica movimento',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riepilogo mese',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                kv('Entrate registrate', euro.format(monthIncome)),
                kv('Spese registrate', euro.format(monthSpent)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: 

SegmentedButton<int>(
  style: ButtonStyle(
    // colore quando SELEZIONATO
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return activeColor.withValues(alpha: 0.18);
      }
      return Colors.transparent;
    }),
    // bordo
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return BorderSide(color: activeColor.withValues(alpha: 0.55));
      }
      return BorderSide(color: Colors.black.withValues(alpha: 0.12));
    }),
    // testo + icona
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return activeColor;
      return Colors.black.withValues(alpha: 0.70);
    }),
  ),
  segments: const [
    ButtonSegment(value: 0, icon: Icon(Icons.remove), label: Text('Spesa')),
    ButtonSegment(value: 1, icon: Icon(Icons.add), label: Text('Entrata')),
  ],
  selected: {selectedMode},
  onSelectionChanged: canChangeMode ? (s) => setState(() => _mode = s.first) : null,
),
          ),
        ),

        const SizedBox(height: 12),

        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isExpense ? 'Importo spesa' : 'Importo entrata',
                    prefixText: '€ ',
                  ),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: isExpense ? _expenseCategory : _incomeCategory,
                  items: (isExpense ? expenseCategories : incomeCategories)
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      if (isExpense) {
                        _expenseCategory = v ?? 'Varie';
                      } else {
                        _incomeCategory = v ?? 'Stipendio';
                      }
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
if (isExpense) ...[
  const SizedBox(height: 12),
  DropdownButtonFormField<ExpenseImpact>(
    initialValue: _expenseImpact,
    items: const [
      DropdownMenuItem(
        value: ExpenseImpact.daily,
        child: Text('Giornaliera'),
      ),
      DropdownMenuItem(
        value: ExpenseImpact.weekly,
        child: Text('Settimanale'),
      ),
      DropdownMenuItem(
        value: ExpenseImpact.cycle,
        child: Text('Straordinaria (tutto il ciclo)'),
      ),
    ],
    onChanged: (v) {
      if (v == null) return;
      setState(() => _expenseImpact = v);
    },
    decoration: const InputDecoration(
      labelText: 'Come deve pesare sul budget?',
    ),
  ),
],
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (opzionale)'),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(999),
    gradient: const LinearGradient(
      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
    ),
  ),
  child: ElevatedButton.icon(
    onPressed: _save,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    icon: const Icon(Icons.save, color: Colors.white),
    label: Text(
      widget.editing == null ? 'Salva' : 'Salva modifiche',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
      ),
    ),
  ),
)
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    ],
  ),
),
);
  }
}