import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  final House house;
  const ExpenseListScreen({super.key, required this.house});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Expense> _expenses = [];
  bool _loading = true;
  int _selectedIndex = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _loading = true);
    try {
      final expenses = await context.read<ApiService>().listExpenses(
            widget.house.id,
            year: _selectedMonth.year,
            month: _selectedMonth.month,
          );
      setState(() => _expenses = expenses);
    } catch (e) {
      debugPrint('Erro: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir gasto?'),
        content: Text('Deseja excluir "${expense.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<ApiService>().deleteExpense(widget.house.id, expense.id);
      _loadExpenses();
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadExpenses();
  }

  String get _formattedMonth => DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth);

  double get _total => _expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentUid = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.house.name),
            Text(
              'Código: ${widget.house.inviteCode}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, _) => IconButton(
              icon: Icon(themeService.isDark ? Icons.light_mode : Icons.dark_mode),
              tooltip: themeService.isDark ? 'Tema claro' : 'Tema escuro',
              onPressed: themeService.toggle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar código',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.house.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Código copiado!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Gastos'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Resumo'),
            ],
          ),
        ),
      ),
      body: _selectedIndex == 0 ? _buildExpenseList(currentUid, colors) : DashboardScreen(house: widget.house),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(house: widget.house),
                  ),
                );
                if (added == true) _loadExpenses();
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo gasto'),
            )
          : null,
    );
  }

  Widget _buildExpenseList(String? currentUid, ColorScheme colors) {
    return Column(
      children: [
        // Seletor de mês + total
        Container(
          color: colors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Expanded(
                child: Text(
                  _formattedMonth,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
              Text(
                'R\$ ${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: colors.outlineVariant),
                          const SizedBox(height: 16),
                          const Text('Nenhum gasto este mês'),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadExpenses,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: _expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          final icon = kCategoryIcons[expense.category] ?? '📦';
                          final isOwn = expense.paidByUid == currentUid;

                          return Card(
                            child: ListTile(
                              leading: Text(icon, style: const TextStyle(fontSize: 28)),
                              title: Text(expense.description),
                              subtitle: Text(
                                '${expense.paidByName} · ${DateFormat('dd/MM').format(expense.date)}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'R\$ ${expense.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOwn ? colors.primary : colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        expense.category,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: expense.isFixed
                                              ? colors.secondaryContainer
                                              : colors.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          expense.isFixed ? 'Fixo' : 'Variável',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: expense.isFixed
                                                ? colors.onSecondaryContainer
                                                : colors.onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onLongPress: isOwn ? () => _deleteExpense(expense) : null,
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
