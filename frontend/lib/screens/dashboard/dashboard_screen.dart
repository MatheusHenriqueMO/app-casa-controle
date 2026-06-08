import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/balance_summary.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final House house;
  const DashboardScreen({super.key, required this.house});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  BalanceSummary? _summary;
  bool _loading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    try {
      final summary = await context.read<ApiService>().getSummary(
            widget.house.id,
            year: _selectedMonth.year,
            month: _selectedMonth.month,
          );
      setState(() => _summary = summary);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Mês
        Container(
          color: colors.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
                  ? const Center(child: Text('Sem dados'))
                  : _buildContent(colors),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme colors) {
    final s = _summary!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total do mês
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Total do mês', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${s.totalMonth.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfico por categoria
        if (s.totalByCategory.isNotEmpty) ...[
          Text('Por categoria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(s.totalByCategory, colors),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: s.totalByCategory.entries.map((e) {
              return Chip(
                label: Text('${e.key}: R\$ ${e.value.toStringAsFixed(2)}'),
                avatar: const Icon(Icons.circle, size: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Quanto cada um pagou
        Text('Pagamentos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...widget.house.memberIds.map((uid) {
          final name = widget.house.memberNames[uid] ?? uid;
          final paid = s.paidByMember[uid] ?? 0;
          final owed = s.owedByMember[uid] ?? 0;
          final balance = paid - owed;
          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text('Pagou: R\$ ${paid.toStringAsFixed(2)} · Deve: R\$ ${owed.toStringAsFixed(2)}'),
              trailing: Text(
                '${balance >= 0 ? '+' : ''}R\$ ${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: balance >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Acertos
        if (s.settlements.isNotEmpty) ...[
          Text('Acertos necessários', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...s.settlements.map((d) => Card(
            color: colors.errorContainer.withOpacity(0.3),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text('${d.fromName} → ${d.toName}'),
              trailing: Text(
                'R\$ ${d.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )),
        ] else
          Card(
            color: Colors.green.withOpacity(0.1),
            child: const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Tudo certo! Sem acertos necessários.'),
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(
      Map<String, double> data, ColorScheme colors) {
    final palette = [
      colors.primary, colors.secondary, colors.tertiary,
      Colors.orange, Colors.purple, Colors.teal,
      Colors.red, Colors.indigo, Colors.amber, Colors.cyan,
    ];
    final total = data.values.fold(0.0, (a, b) => a + b);
    int i = 0;
    return data.entries.map((e) {
      final pct = total > 0 ? (e.value / total * 100) : 0.0;
      return PieChartSectionData(
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: palette[i++ % palette.length],
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
    }).toList();
  }
}
