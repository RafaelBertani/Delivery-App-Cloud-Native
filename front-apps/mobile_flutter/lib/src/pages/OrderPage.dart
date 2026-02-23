import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Modelos
import '../models/restaurant_model.dart';
import '../models/dish_model.dart';

const String defaultLogo = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";
const String defaultDish = "https://cdn-icons-png.flaticon.com/512/3014/3014520.png";

class OrderPage extends StatefulWidget {
  final String id; // Recebido via parâmetro da rota (GoRouter)

  const OrderPage({super.key, required this.id});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  RestaurantModel? _restaurant;
  List<DishModel> _dishes = [];
  bool _isLoading = true;
  String _error = '';
  bool _isCheckingOut = false;

  // Carrinho: Mapeia o ID do prato para a Quantidade
  Map<int, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _fetchMenuData();
  }

  // 1. Busca os Dados (Restaurante + Pratos em paralelo)
  Future<void> _fetchMenuData() async {
    setState(() { _isLoading = true; });

    try {
      // 10.0.2.2 no Emulador Android
      final String baseUrl = 'http://localhost:3002/api/restaurants';
      
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/${widget.id}')),
        http.get(Uri.parse('$baseUrl/${widget.id}/list-all-dishes')),
      ]);

      final restResponse = responses[0];
      final dishesResponse = responses[1];

      if (restResponse.statusCode == 200 && dishesResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            _restaurant = RestaurantModel.fromJson(jsonDecode(restResponse.body));
            
            // Decodifica os pratos e filtra os que estão disponíveis
            final List<dynamic> decodedDishes = jsonDecode(dishesResponse.body);
            _dishes = decodedDishes
                .map((json) => DishModel.fromJson(json))
                .where((dish) => dish.isAvailable)
                .toList();
          });
        }
      } else {
        throw Exception('Falha ao carregar dados');
      }
    } catch (err) {
      debugPrint("Erro ao carregar cardápio: $err");
      if (mounted) {
        setState(() { _error = "Não foi possível carregar o cardápio deste restaurante."; });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // 2. Funções do Carrinho
  void _handleAdd(int dishId) {
    setState(() {
      _cart[dishId] = (_cart[dishId] ?? 0) + 1;
    });
  }

  void _handleRemove(int dishId) {
    setState(() {
      if (_cart.containsKey(dishId)) {
        if (_cart[dishId]! > 1) {
          _cart[dishId] = _cart[dishId]! - 1;
        } else {
          _cart.remove(dishId);
        }
      }
    });
  }

  // 3. Cálculos do Carrinho
  double get _cartTotal {
    double total = 0.0;
    for (var dish in _dishes) {
      final quantity = _cart[dish.id] ?? 0;
      total += dish.price * quantity;
    }
    return total;
  }

  int get _totalItems {
    int count = 0;
    _cart.forEach((key, value) => count += value);
    return count;
  }

  // Helper para AlertDialog
  void _showAlert(String title, String message, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (onConfirm != null) onConfirm();
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // 4. Finalizar Pedido
  Future<void> _handleCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _showAlert("Atenção", "Você precisa estar logado para finalizar o pedido!", onConfirm: () {
        context.go('/signIn');
      });
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seu carrinho está vazio!")));
      return;
    }

    final List<Map<String, dynamic>> items = _cart.entries.map((entry) => {
      'dish_id': entry.key,
      'quantity': entry.value,
    }).toList();

    final payload = {
      'restaurant_id': int.parse(widget.id),
      'items': items,
    };

    setState(() { _isCheckingOut = true; });

    try {
      // NOVA VALIDAÇÃO PROATIVA DE ENDEREÇO
      try {
        final addressRes = await http.get(
          Uri.parse('http://localhost:3001/api/auth/addresses'),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (addressRes.statusCode == 200) {
          final List<dynamic> addresses = jsonDecode(addressRes.body);
          final bool hasActiveAddress = addresses.any((addr) => addr['is_active'] == true);
          
          if (!hasActiveAddress) {
            setState(() { _isCheckingOut = false; });
            _showAlert(
              "Endereço Necessário", 
              "Você precisa cadastrar e ativar um endereço de entrega antes de fazer um pedido.\n\nVamos redirecionar você para o seu perfil para adicionar um endereço agora.",
              onConfirm: () => context.go('/profile'), // Envia o cliente direto para o perfil
            );
            return; // Trava o envio do pedido
          }
        }
      } catch (addrErr) {
        debugPrint("Erro ao verificar endereço: $addrErr");
        _showAlert("Erro", "Não foi possível verificar seus endereços. Verifique sua conexão e tente novamente.");
        setState(() { _isCheckingOut = false; });
        return;
      }
      // ==========================================

      // Dispara a requisição para criar o pedido
      final response = await http.post(
        Uri.parse('http://localhost:3003/api/orders/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final String message = resData['message'];
        final order = resData['order'];
        final totalFormatado = double.parse(order['total_amount'].toString()).toStringAsFixed(2).replaceAll('.', ',');

        _showAlert(
          "Sucesso!", 
          "$message\n\nPedido Nº: #${order['id']}\nTotal Confirmado: R\$ $totalFormatado",
          onConfirm: () {
            setState(() { _cart.clear(); });
            context.go('/orders-list');
          }
        );
      } else {
        throw Exception(resData['message'] ?? "Erro ao processar pedido.");
      }

    } catch (error) {
      debugPrint("Erro ao finalizar pedido: $error");
      _showAlert("Erro", error.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() { _isCheckingOut = false; });
      }
    }
  }

  // --- RENDERIZAÇÃO ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _restaurant == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(_error.isNotEmpty ? _error : "Restaurante não encontrado.", style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao Início'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      
      bottomNavigationBar: _totalItems > 0 ? _buildCartBottomBar() : null,
      
      body: CustomScrollView(
        slivers: [
          
          // --- CABEÇALHO DO RESTAURANTE ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _restaurant!.logo ?? defaultLogo,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_restaurant!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(_restaurant!.description ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Text("${_restaurant!.street}, ${_restaurant!.city}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  const Text('Cardápio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // --- LISTA DE PRATOS ---
          if (_dishes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Nenhum prato disponível no momento.', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 450, // Quebra a linha em telas grandes
                  mainAxisExtent: 140, // Altura fixa do card
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final dish = _dishes[index];
                    final quantity = _cart[dish.id] ?? 0;

                    return Card(
                      elevation: 1,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Info do Prato
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text(dish.description, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                  Text(
                                    "R\$ ${dish.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Imagem e Controles
                            SizedBox(
                              width: 90,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(dish.image ?? defaultDish, width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                  
                                  // Controles de Quantidade
                                  Container(
                                    height: 30,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(Icons.remove, size: 16, color: quantity > 0 ? Colors.red : Colors.grey),
                                          onPressed: quantity > 0 ? () => _handleRemove(dish.id) : null,
                                        ),
                                        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.add, size: 16, color: Colors.green),
                                          onPressed: () => _handleAdd(dish.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _dishes.length,
                ),
              ),
            ),
            
            // Espaçamento no final para o conteúdo não ficar escondido pela barra do carrinho
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  // --- BARRA FIXA DO CARRINHO ---
  Widget _buildCartBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Resumo
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total com $_totalItems item(ns)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    "R\$ ${_cartTotal.toStringAsFixed(2).replaceAll('.', ',')}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              
              // Botão de Avançar
              ElevatedButton(
                onPressed: _isCheckingOut ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: _isCheckingOut
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Processando ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Fazer Pedido", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}