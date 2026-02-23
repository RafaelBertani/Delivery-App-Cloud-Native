import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    
    if (userStr == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    setState(() {
      _user = jsonDecode(userStr);
    });
  }

  // Equivalente ao window.confirm do React
  Future<bool?> _showConfirmationDialog(String action, String label) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: Text('Tem certeza que deseja $action o modo $label?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Retorna false
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Retorna true
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // Função para alternar configurações no Servidor
  Future<void> _handleServerToggle(String field, bool currentValue) async {
    final label = field == 'is_delivery' ? 'Entregador' : 'Dono de Restaurante';
    final action = currentValue ? 'desativar' : 'ativar';

    // 1. Pede confirmação
    final bool? confirmed = await _showConfirmationDialog(action, label);
    if (confirmed != true) return; // Se clicou fora ou em Cancelar, aborta

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final newValue = !currentValue;
      
      // Lembre-se: Use '10.0.2.2' se estiver no Emulador Android
      final url = Uri.parse('http://localhost:3001/api/auth/edit');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({field: newValue}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        final userAtualizado = responseData['user'];

        // Atualiza o SharedPreferences e o Estado local
        await prefs.setString('user', jsonEncode(userAtualizado));
        setState(() { _user = userAtualizado; });

      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Erro ao atualizar configuração.');
      }

    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent, // Deixa ver o fundo
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500), // maxWidth: '500px'
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // Cabeçalho
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    const Text('Configurações', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(thickness: 1),
                ),

                // Slider: Entregador
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.motorcycle, size: 20),
                              SizedBox(width: 8),
                              Text('Sou Entregador', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('Habilita o painel de entregas', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _user!['is_delivery'] == true,
                      activeColor: Colors.blue,
                      onChanged: _isLoading ? null : (val) => _handleServerToggle('is_delivery', _user!['is_delivery'] == true),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(thickness: 1),
                ),

                // Slider: Restaurante
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, size: 20),
                              SizedBox(width: 8),
                              Text('Tenho Restaurante', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('Gerenciar meus restaurantes', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _user!['has_restaurant'] == true,
                      activeColor: Colors.blue,
                      onChanged: _isLoading ? null : (val) => _handleServerToggle('has_restaurant', _user!['has_restaurant'] == true),
                    ),
                  ],
                ),

                // Indicador de Carregamento (Loading)
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text('Salvando alterações...', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}