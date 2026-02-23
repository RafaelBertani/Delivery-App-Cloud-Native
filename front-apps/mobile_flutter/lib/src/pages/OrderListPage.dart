import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Importação para formatar data e moeda

// Modelo
import '../models/order_model.dart';

const String defaultLogo = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    try {
      setState(() { _isLoading = true; });
      
      // 10.0.2.2 no emulador
      final url = Uri.parse('http://localhost:3003/api/orders/my-orders');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final List<dynamic> decodedJson = jsonDecode(response.body);
            _orders = decodedJson.map((json) => OrderModel.fromJson(json)).toList();
            _error = '';
          });
        }
      } else {
        throw Exception('Falha ao carregar pedidos.');
      }
    } catch (err) {
      debugPrint("Erro ao buscar pedidos: $err");
      if (mounted) {
        setState(() { _error = 'Não foi possível carregar seu histórico de pedidos.'; });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Função para traduzir e colorir o status do pedido
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.white;
    IconData icon;
    String text;

    switch (status) {
      case 'PENDING':
        bgColor = Colors.amber;
        textColor = Colors.black87;
        icon = Icons.schedule;
        text = 'Aguardando Confirmação';
        break;
      case 'PREPARING':
        bgColor = Colors.cyan;
        textColor = Colors.black87;
        icon = Icons.local_fire_department;
        text = 'Preparando';
        break;
      case 'PREPARED':
        bgColor = Colors.grey.shade600;
        icon = Icons.inventory_2;
        text = 'Pedido Pronto';
        break;
      case 'DELIVERING':
        bgColor = Colors.blue;
        icon = Icons.motorcycle;
        text = 'Saiu para Entrega';
        break;
      case 'ARRIVED':
        bgColor = Colors.black87;
        icon = Icons.place;
        text = 'Chegou ao Destino';
        break;
      case 'DELIVERED':
        bgColor = Colors.green;
        icon = Icons.check_circle;
        text = 'Entregue';
        break;
      case 'CANCELLED':
        bgColor = Colors.red;
        icon = Icons.cancel;
        text = 'Cancelado';
        break;
      default:
        bgColor = Colors.grey;
        icon = Icons.help_outline;
        text = 'Desconhecido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ajusta o tamanho da Row ao conteúdo
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Formata a data para padrão brasileiro (ex: 25/10/2023 14:30)
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center( // O Center + ConstrainedBox equivale ao margin: 0 auto e maxWidth do CSS
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // Cabeçalho
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    const Text('Meus Pedidos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(thickness: 1),
                ),

                // Conteúdo
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Buscando seus pedidos...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : _error.isNotEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                                child: Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            )
                          : _orders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      const Text('Nenhum pedido encontrado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
                                      const SizedBox(height: 8),
                                      const Text('Você ainda não fez nenhum pedido.', style: TextStyle(color: Colors.black54)),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        onPressed: () => context.go('/'),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
                                        child: const Text('Ver Restaurantes', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _orders.length,
                                  itemBuilder: (context, index) {
                                    final order = _orders[index];

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            // Linha Superior: Logo, Info e Preço/Código
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Logo do Restaurante
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(50),
                                                  child: Image.network(
                                                    order.restaurantLogo ?? defaultLogo,
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Nome e Data
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(order.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                      const SizedBox(height: 4),
                                                      Text("Pedido #${order.id} • ${_formatDate(order.createdAt)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Preço e Código (Alinhados à direita)
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      "R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}",
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "Código: ${order.deliveryCode}",
                                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              child: Divider(height: 1),
                                            ),

                                            // Linha Inferior: Badge de Status e Botão
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                // O Widget Badge que criamos na função acima
                                                _buildStatusBadge(order.status),
                                                
                                                OutlinedButton(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Função de detalhes em breve!')));
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Colors.blue,
                                                    side: const BorderSide(color: Colors.blue),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                                  ),
                                                  child: const Text('Detalhes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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