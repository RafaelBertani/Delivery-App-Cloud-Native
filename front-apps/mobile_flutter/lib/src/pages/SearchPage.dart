import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importando o nosso novo widget!
import '../widgets/restaurant_card.dart'; 

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _restaurants = [];
  bool _isLoading = false;
  String _error = '';
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fetchInitial();
  }

  // Busca inicial dos sugeridos
  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/suggested');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _restaurants = jsonDecode(response.body);
          });
        }
      } else {
        throw Exception('Falha ao carregar sugestões');
      }
    } catch (err) {
      debugPrint("Erro ao buscar iniciais: $err");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Função disparada ao clicar em Buscar
  Future<void> _handleSearch() async {
    final searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = '';
      _hasSearched = true;
    });

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/search?q=$searchTerm');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _restaurants = jsonDecode(response.body);
          });
        }
      } else {
        throw Exception('Erro na API');
      }
    } catch (err) {
      debugPrint("Erro ao buscar restaurantes: $err");
      if (mounted) {
        setState(() {
          _error = 'Ocorreu um erro ao realizar a busca. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navegação para o restaurante
  Future<void> _browseRestaurant(dynamic id) async {
    // 1. Instancia o SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // 2. Busca o token (ou o 'user') salvo localmente
    final token = prefs.getString('token'); 
    
    // 3. Se o token existir, o usuário está logado
    final bool isUserLoggedIn = token != null; 

    // 4. Boa prática no Flutter: verifica se a tela ainda existe antes de navegar após um 'await'
    if (!mounted) return;

    if (!isUserLoggedIn) {
      context.go('/signIn');
    } else {
      context.go('/restaurant/$id');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: CustomScrollView(
        slivers: [
          // Área do Cabeçalho e Barra de Pesquisa
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, color: Colors.blue, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Encontre seu Restaurante',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Busque pelo nome do restaurante e descubra o que pedir hoje.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Barra de Pesquisa 
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 10),
                          child: Icon(Icons.search, color: Colors.blue),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Pizzaria, Burguer, Sushi...',
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _handleSearch(), 
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Título de Resultados
                  if (_hasSearched && !_isLoading && _error.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black12)),
                      ),
                      child: Text(
                        'Resultados para "${_searchController.text}" (${_restaurants.length} encontrados)',
                        style: const TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ),

                  // Mensagem de Erro
                  if (!_isLoading && _error.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
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

          // Loading (Spinner)
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // Grid Vazio
          else if (_restaurants.isEmpty && _hasSearched)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Nenhum restaurante encontrado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Tente buscar por outro nome ou termo.', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            )
            
          else
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