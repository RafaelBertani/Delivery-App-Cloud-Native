import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/restaurant_card.dart';

class SuggestedPage extends StatefulWidget {
  const SuggestedPage({super.key});

  @override
  State<SuggestedPage> createState() => _SuggestedPageState();
}

class _SuggestedPageState extends State<SuggestedPage> {
  List<dynamic> _restaurants = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchSuggestedRestaurants();
  }

  Future<void> _fetchSuggestedRestaurants() async {
    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/suggested');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _restaurants = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Falha na API');
      }
    } catch (err) {
      debugPrint("Erro ao buscar sugestões: $err");
      if (mounted) {
        setState(() {
          _error = 'Não foi possível carregar as sugestões no momento.';
          _isLoading = false;
        });
      }
    }
  }

  void _browseRestaurant(dynamic id) {
    // Simulação de verificação de login
    bool isUserLoggedIn = true; 

    if (!isUserLoggedIn) {
      context.go('/signIn');
    } else {
      context.go('/restaurant/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Cabeçalho da Página
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 30, left: 24, right: 24),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, color: Colors.blue, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Descubra Novos Sabores',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sugestões incríveis escolhidas aleatoriamente para você hoje.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),

                  // Mensagem de Erro
                  if (!_isLoading && _error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 30),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 10),
                          Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loading
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // Grid Vazio
          else if (_restaurants.isEmpty && _error.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'Nenhum restaurante disponível no momento.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            )

          // Grid de Restaurantes usando o novo Widget
          else if (_error.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return RestaurantCard(
                      restaurant: _restaurants[index],
                      onTap: () => _browseRestaurant(_restaurants[index]['id']),
                    );
                  },
                  childCount: _restaurants.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}