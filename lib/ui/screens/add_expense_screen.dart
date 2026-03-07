import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/format.dart';

class AddExpenseScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback onDone;
  const AddExpenseScreen({super.key, required this.state, required this.onDone});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _categories = const ['Spesa', 'Caffè/Bar', 'Carburante', 'Casa', 'Svago', 'Altro'];
  String _category = 'Spesa';
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
    final e = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      category: _category,
      date: _date,
      note: _noteCtrl.text.trim(),
    );

    await widget.state.addExpense(e);

    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() {
      _category = _categories.first;
      _date = DateTime.now();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spesa aggiunta ✅')));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aggiungi spesa', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Importo',
                      prefixIcon: Icon(Icons.euro),
                      hintText: 'es. 12,50',
                    ),
                    validator: (v) {
                      final x = (v ?? '').trim();
                      if (x.isEmpty) return 'Inserisci un importo';
                      final parsed = double.tryParse(x.replaceAll(',', '.'));
                      if (parsed == null) return 'Formato non valido';
                      if (parsed <= 0) return 'Deve essere > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Data: ${dateLabel(_date)}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opzionale)',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add),
                      label: const Text('Salva'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      ),
    ),
    );
  }
}
