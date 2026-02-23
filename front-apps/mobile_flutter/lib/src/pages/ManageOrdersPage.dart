import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart'; // O Model atualizado

class ManageOrdersPage extends StatefulWidget {
  final String id; // ID do Restaurante via rota

  const ManageOrdersPage({super.key, required this.id});

  @override
  State<ManageOrdersPage> createState() => _ManageOrdersPageState();
}

class _ManageOrdersPageState extends State<ManageOrdersPage> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _error = '';
  int? _processingId;

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
      final url = Uri.parse('http://localhost:3003/api/orders/restaurant/${widget.id}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final List<dynamic> decodedJson = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _orders = decodedJson.map((json) => OrderModel.fromJson(json)).toList();
            _error = '';
          });
        }
      } else {
        throw Exception("Falha ao carregar");
      }
    } catch (err) {
      debugPrint("Erro ao buscar pedidos: $err");
      if (mounted) setState(() { _error = 'Não foi possível carregar a lista de pedidos.'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleUpdateStatus(int orderId, String newStatus) async {
    // Alerta de Confirmação se for entregar ao motoboy
    if (newStatus == 'DELIVERING') {
      final bool? isConfirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirmar Retirada"),
          content: const Text("O entregador informou o código correto e retirou o pedido?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Confirmar"),
            ),
          ],
        ),
      );
      if (isConfirmed != true) return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _processingId = orderId; });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/$orderId/status');
      await http.patch(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'status': newStatus}),
      );

      // Atualiza localmente e remove da tela se for pra 'DELIVERING'
      setState(() {
        if (newStatus == 'DELIVERING') {
          _orders.removeWhere((o) => o.id == orderId);
        } else {
          final index = _orders.indexWhere((o) => o.id == orderId);
          if (index != -1) {
            // Recria o objeto com o novo status
            final old = _orders[index];
            _orders[index] = OrderModel(
              id: old.id, restaurantId: old.restaurantId, restaurantName: old.restaurantName,
              totalAmount: old.totalAmount, status: newStatus, deliveryCode: old.deliveryCode,
              createdAt: old.createdAt, items: old.items, pickupCode: old.pickupCode,
            );
          }
        }
      });
    } catch (err) {
      debugPrint("Erro ao atualizar status: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar status."), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _processingId = null; });
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));

    // Separa as listas
    final pendingOrders = _orders.where((o) => o.status == 'PENDING').toList();
    final preparingOrders = _orders.where((o) => o.status == 'PREPARING').toList();
    final preparedOrders = _orders.where((o) => o.status == 'PREPARED').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // Cabeçalho
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/my-restaurants'),
                    ),
                    const SizedBox(width: 8),
                    const Text('Gerenciar Pedidos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),

                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),

                // --- SESSÃO 1: PENDENTES ---
                _buildSectionTitle('Novos Pedidos', pendingOrders.length, Colors.orange, Icons.notifications),
                _buildOrderGrid(pendingOrders),
                const Divider(height: 40),

                // --- SESSÃO 2: EM PREPARO ---
                _buildSectionTitle('Em Preparo', preparingOrders.length, Colors.cyan, Icons.local_fire_department),
                _buildOrderGrid(preparingOrders),
                const Divider(height: 40),

                // --- SESSÃO 3: PRONTOS ---
                _buildSectionTitle('Aguardando Retirada', preparedOrders.length, Colors.green, Icons.inventory_2),
                _buildOrderGrid(preparedOrders, isPreparedSection: true),
                const SizedBox(height: 40),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- COMPONENTES AUXILIARES ---

  Widget _buildSectionTitle(String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text('$title ($count)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildOrderGrid(List<OrderModel> orderList, {bool isPreparedSection = false}) {
    if (orderList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Text('Nenhum pedido nesta etapa.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450, // bootstrap col-md-6
        mainAxisExtent: 330, // Altura do card base
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orderList.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orderList[index], isPreparedSection);
      },
    );
  }

  // O componente "OrderCard" do React
  Widget _buildOrderCard(OrderModel order, bool isPreparedSection) {
    Color themeColor;
    if (order.status == 'PENDING') {
      themeColor = Colors.orange;
    } else if (order.status == 'PREPARING') {
      themeColor = Colors.cyan;
    } else {
      themeColor = Colors.green;
    }

    return Column(
      children: [
        // Tag Extra em cima se estiver aguardando o motoboy
        if (isPreparedSection)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.motorcycle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text('Aguardando motoboy', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('CÓDIGO: ${order.pickupCode ?? '---'}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: themeColor, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  color: themeColor,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pedido #${order.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(_formatTime(order.createdAt), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Lista de Itens (com scroll interno se for mt grande)
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final item = order.items[i];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.quantity}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.dishName ?? 'Prato #${item.dishId}')),
                            const SizedBox(width: 8),
                            Text(
                              "R\$ ${(item.unitPrice * item.quantity).toStringAsFixed(2).replaceAll('.', ',')}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Rodapé (Total e Botão)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total do Pedido', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            "R\$ ${order.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      
                      // Botões Dinâmicos
                      if (order.status == 'PENDING')
                        ElevatedButton.icon(
                          onPressed: _processingId == order.id ? null : () => _handleUpdateStatus(order.id, 'PREPARING'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black87),
                          icon: _processingId == order.id ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check, size: 18),
                          label: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else if (order.status == 'PREPARING')
                        ElevatedButton.icon(
                          onPressed: _processingId == order.id ? null : () => _handleUpdateStatus(order.id, 'PREPARED'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white),
                          icon: _processingId == order.id ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.inventory_2, size: 18),
                          label: const Text('Pronto', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else if (order.status == 'PREPARED')
                        OutlinedButton.icon(
                          onPressed: _processingId == order.id ? null : () => _handleUpdateStatus(order.id, 'DELIVERING'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                          icon: _processingId == order.id ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.motorcycle, size: 18),
                          label: const Text('Confirmar Retirada', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}