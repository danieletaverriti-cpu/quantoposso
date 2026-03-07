import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';

class AddIncomeScreen extends StatefulWidget {
  final AppState state;
  const AddIncomeScreen({super.key, required this.state});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'Stipendio';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final cleaned = raw.trim().replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
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

  @override
  Widget build(BuildContext context) {
    final categories = ['Stipendio', 'Straordinari', 'Bonus', 'Rimborso', 'Altro'];

    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi entrata')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Importo',
              prefixText: '€ ',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'Stipendio'),
            decoration: const InputDecoration(labelText: 'Categoria'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Data'),
            subtitle: Text('${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
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
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
              onPressed: () async {
                final amount = _parseAmount(_amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci un importo valido')),
                  );
                  return;
                }

                final id = 'i_${DateTime.now().millisecondsSinceEpoch}';

                final income = Income(
                  id: id,
                  amount: amount,
                  category: _category,
                  date: _date,
                  note: _noteCtrl.text.trim(),
                );

                await widget.state.addIncome(income);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}