import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final House house;
  final Expense? expense; // não nulo = modo edição

  const AddExpenseScreen({super.key, required this.house, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  List<String>? _splitWith;
  bool _loading = false;
  late bool _isFixed;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _amountController = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _selectedCategory = e?.category ?? kCategories.first;
    _selectedDate = e?.date ?? DateTime.now();
    _isFixed = e?.isFixed ?? false;
    if (e != null && e.splitWith.isNotEmpty) {
      _splitWith = List.from(e.splitWith);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final description = _descriptionController.text.trim();
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      if (_isEditing) {
        await api.updateExpense(
          houseId: widget.house.id,
          expenseId: widget.expense!.id,
          description: description,
          amount: amount,
          category: _selectedCategory,
          splitWith: _splitWith,
          date: _selectedDate,
          isFixed: _isFixed,
        );
      } else {
        await api.createExpense(
          houseId: widget.house.id,
          description: description,
          amount: amount,
          category: _selectedCategory,
          splitWith: _splitWith,
          date: _selectedDate,
          isFixed: _isFixed,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar gasto' : 'Novo gasto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: kCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${kCategoryIcons[cat]} $cat'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),

            // Tipo: fixo ou variável
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFixed = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isFixed
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        border: Border.all(
                          color: !_isFixed
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up,
                              color: !_isFixed
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text('Variável',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isFixed
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFixed = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isFixed
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        border: Border.all(
                          color: _isFixed
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.repeat,
                              color: _isFixed
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey),
                          const SizedBox(height: 4),
                          Text('Fixo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isFixed
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Data'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Alterar')),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),

            // Dividir com
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people),
                        const SizedBox(width: 8),
                        const Text('Dividir com', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() => _splitWith = null),
                          child: Text(
                            _splitWith == null ? '✓ Todos' : 'Todos',
                            style: TextStyle(
                              color: _splitWith == null
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...widget.house.memberIds.map((uid) {
                      final name = widget.house.memberNames[uid] ?? uid;
                      final selected = _splitWith == null || _splitWith!.contains(uid);
                      return CheckboxListTile(
                        title: Text(name),
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (_splitWith == null) {
                              _splitWith = List.from(widget.house.memberIds);
                            }
                            if (v == true) {
                              _splitWith!.add(uid);
                            } else {
                              _splitWith!.remove(uid);
                            }
                            if (_splitWith!.toSet().containsAll(widget.house.memberIds.toSet())) {
                              _splitWith = null;
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Salvar alterações' : 'Salvar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
