import 'package:flutter/material.dart';
import 'package:quantoposso/app/state.dart';
import 'package:quantoposso/data/models.dart';
import '../widgets/format.dart';

class FixedScreen extends StatelessWidget {
  final AppState state;
  const FixedScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.fixed.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spese fisse mensili',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text('${state.fixed.length} voci'),
                    ],
                  ),
                ),
                Text(
                  euro(total),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _AddEditFixedDialog(
                onSave: state.addFixed, // ✅ upsert = add + edit
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi spesa fissa'),
          ),
        ),
        const SizedBox(height: 12),

        ...state.fixed.map(
          (e) => _FixedRow(
            expense: e,
            onDelete: state.deleteFixed,
            onEdit: () => showDialog(
              context: context,
              builder: (_) => _AddEditFixedDialog(
                existing: e, // ✅ EDIT
                onSave: state.addFixed, // ✅ upsert
              ),
            ),
          ),
        ),

        const SizedBox(height: 80),
      ],
    ),
      ),
    ),
    );
  }
}

class _FixedRow extends StatelessWidget {
  final FixedExpense expense;
  final void Function(String id) onDelete;
  final VoidCallback onEdit;

  const _FixedRow({
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      onDismissed: (_) => onDelete(expense.id),
      child: Card(
        child: ListTile(
          onTap: onEdit, // ✅ TAP = MODIFICA
          leading: const Icon(Icons.attach_money_outlined),
          title: Text(
            expense.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('Tocca per modificare'),
          trailing: Text(
            euro(expense.amount),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _AddEditFixedDialog extends StatefulWidget {
  final FixedExpense? existing;
  final Future<void> Function(FixedExpense e) onSave;

  const _AddEditFixedDialog({
    required this.onSave,
    this.existing,
  });

  @override
  State<_AddEditFixedDialog> createState() => _AddEditFixedDialogState();
}

class _AddEditFixedDialogState extends State<_AddEditFixedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _amount = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.amount.toStringAsFixed(
              widget.existing!.amount == widget.existing!.amount.roundToDouble()
                  ? 0
                  : 2,
            ).replaceAll('.', ','),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final fixed = FixedExpense(
      // ✅ se edit: tieni lo stesso id (così diventa update)
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      amount: double.parse(_amount.text.trim().replaceAll(',', '.')),
    );

    await widget.onSave(fixed);

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit ? 'Spesa fissa aggiornata ✅' : 'Spesa fissa aggiunta ✅'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifica spesa fissa' : 'Nuova spesa fissa'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci un nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo',
                hintText: 'es. 19,99',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}