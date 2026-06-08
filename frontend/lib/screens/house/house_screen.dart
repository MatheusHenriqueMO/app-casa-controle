import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/house.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../expense/expense_list_screen.dart';

class HouseScreen extends StatefulWidget {
  const HouseScreen({super.key});

  @override
  State<HouseScreen> createState() => _HouseScreenState();
}

class _HouseScreenState extends State<HouseScreen> {
  House? _house;
  bool _loading = true; // começa carregando para tentar restaurar a casa

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreHouse();
  }

  Future<void> _restoreHouse() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHouseId = prefs.getString('house_id');
    if (savedHouseId != null) {
      try {
        final house = await context.read<ApiService>().getHouse(savedHouseId);
        if (mounted) setState(() => _house = house);
        return;
      } catch (_) {
        // casa não existe mais, limpa o cache
        await prefs.remove('house_id');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveHouse(House house) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('house_id', house.id);
    setState(() => _house = house);
  }

  Future<void> _createHouse() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);
    try {
      final house = await context.read<ApiService>().createHouse(name);
      await _saveHouse(house);
    } catch (e) {
      _showError('Erro ao criar casa: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _joinHouse() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final house = await context.read<ApiService>().joinHouse(code);
      await _saveHouse(house);
    } catch (e) {
      _showError('Código inválido ou casa não encontrada');
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_house != null) {
      return ExpenseListScreen(house: _house!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casa Controle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('house_id');
              if (context.mounted) context.read<AuthService>().signOut();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie uma nova casa ou entre em uma existente.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // Criar casa
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Criar nova casa',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome da casa',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _createHouse,
                              child: const Text('Criar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou'),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),

                  // Entrar em casa
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entrar em uma casa',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _codeController,
                            decoration: const InputDecoration(
                              labelText: 'Código de convite',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 6,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              onPressed: _joinHouse,
                              child: const Text('Entrar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
