import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para os filtros de input
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Modelos
import '../models/user_model.dart';
import '../models/order_model.dart';

class DeliveryPanelPage extends StatefulWidget {
  const DeliveryPanelPage({super.key});

  @override
  State<DeliveryPanelPage> createState() => _DeliveryPanelPageState();
}

class _DeliveryPanelPageState extends State<DeliveryPanelPage> {
  UserModel? _user;

  // Estados Minhas Entregas
  List<OrderModel> _myDeliveries = [];
  bool _isLoadingMy = true;
  Map<int, String> _deliveryCodes = {}; // Guarda códigos digitados por ID do pedido
  int? _processingId; // ID do pedido sendo processado no momento

  // Estados da Busca
  final TextEditingController _searchController = TextEditingController();
  List<OrderModel> _availableDeliveries = [];
  bool _isLoadingSearch = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetch();
  }

  Future<void> _checkAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (userStr == null) {
      if (mounted) context.go('/');
      return;
    }

    final user = UserModel.fromJson(jsonDecode(userStr));

    if (!user.isDelivery) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Acesso negado. Apenas entregadores podem ver esta página."),
          backgroundColor: Colors.red,
        ));
        context.go('/');
      }
      return;
    }

    setState(() { _user = user; });
    _fetchMyDeliveries();
  }

  // Helper de Toast
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      )
    );
  }

  // 1. Minhas Entregas Ativas
  Future<void> _fetchMyDeliveries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isLoadingMy = true; });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/my-active');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _myDeliveries = decoded.map((json) => OrderModel.fromJson(json)).toList();
          });
        }
      }
    } catch (err) {
      debugPrint("Erro ao buscar minhas entregas: $err");
    } finally {
      if (mounted) setState(() { _isLoadingMy = false; });
    }
  }

  // 2. Buscar Novas Entregas
  Future<void> _handleSearchAvailable() async {
    if (_searchController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      _isLoadingSearch = true;
      _hasSearched = true;
    });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/available?city=${_searchController.text}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availableDeliveries = decoded.map((json) => OrderModel.fromJson(json)).toList();
          });
        }
      } else {
        _showToast("Erro ao buscar novas entregas.", isError: true);
      }
    } catch (err) {
      debugPrint("Erro ao buscar disponíveis: $err");
      _showToast("Erro de conexão.", isError: true);
    } finally {
      if (mounted) setState(() { _isLoadingSearch = false; });
    }
  }

  // 3. Aceitar Corrida
  Future<void> _handleAcceptDelivery(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _processingId = orderId; });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/$orderId/accept');
      final response = await http.post(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _availableDeliveries.removeWhere((d) => d.id == orderId);
        });
        _fetchMyDeliveries();
        _showToast("Corrida aceita! Vá até o restaurante retirar o pedido.");
      } else {
        final resData = jsonDecode(response.body);
        _showToast(resData['message'] ?? "Erro ao aceitar a corrida.", isError: true);
      }
    } catch (err) {
      debugPrint("Erro aceitar corrida: $err");
      _showToast("Erro de conexão.", isError: true);
    } finally {
      if (mounted) setState(() { _processingId = null; });
    }
  }

  // 4. Avisar Chegada
  Future<void> _handleMarkAsArrived(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _processingId = orderId; });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/$orderId/status');
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'status': 'ARRIVED'}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Atualiza o status localmente recarregando a lista
        _fetchMyDeliveries(); 
      } else {
        _showToast("Erro ao atualizar status.", isError: true);
      }
    } catch (err) {
      debugPrint("Erro ao avisar chegada: $err");
    } finally {
      if (mounted) setState(() { _processingId = null; });
    }
  }

  // 5. Concluir Entrega
  Future<void> _handleCompleteDelivery(int orderId) async {
    final code = _deliveryCodes[orderId] ?? '';
    
    if (code.length != 3) {
      _showToast("Digite o código de 3 dígitos fornecido pelo cliente.", isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _processingId = orderId; });

    try {
      final url = Uri.parse('http://localhost:3003/api/orders/$orderId/complete');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showToast("Entrega concluída com sucesso! Bom trabalho!");
        setState(() {
          _myDeliveries.removeWhere((d) => d.id == orderId);
          _deliveryCodes.remove(orderId);
        });
      } else {
        final resData = jsonDecode(response.body);
        _showToast(resData['message'] ?? "Código inválido ou erro ao concluir.", isError: true);
      }
    } catch (err) {
      debugPrint("Erro ao concluir: $err");
      _showToast("Erro de conexão.", isError: true);
    } finally {
      if (mounted) setState(() { _processingId = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            //padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            slivers: [
              // Cabeçalho Principal
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Icon(Icons.motorcycle, color: Colors.blue, size: 30),
                      SizedBox(width: 12),
                      Text('Painel do Entregador', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // SESSÃO 1: MINHAS ENTREGAS EM ANDAMENTO
              // ==========================================
              SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black87,
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            Icon(Icons.route, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Minhas Entregas Atuais', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      Container(
                        color: Colors.grey.shade50,
                        height: 450, // maxHeight: '450px'
                        child: _isLoadingMy
                            ? const Center(child: CircularProgressIndicator())
                            : _myDeliveries.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade400),
                                        const SizedBox(height: 16),
                                        const Text('Você não tem entregas em andamento.', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _myDeliveries.length,
                                    itemBuilder: (context, index) {
                                      final order = _myDeliveries[index];
                                      final bool isArrived = order.status == 'ARRIVED';
                                      final isProcessing = _processingId == order.id;

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: BorderSide(color: isArrived ? Colors.orange : Colors.blue, width: 2),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Pedido #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isArrived ? Colors.orange : Colors.blue.shade100,
                                                      borderRadius: BorderRadius.circular(50),
                                                    ),
                                                    child: Text(
                                                      isArrived ? 'Aguardando Cliente' : 'Em Rota',
                                                      style: TextStyle(
                                                        color: isArrived ? Colors.white : Colors.blue.shade900,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              
                                              // Endereços
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.store, size: 16, color: Colors.grey),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Coleta (Restaurante):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                        Text(order.restaurantAddress ?? 'Endereço Indisponível', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Entrega (Cliente):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                        Text('${order.deliveryStreet}, ${order.deliveryCity}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),

                                              // Botões e Código
                                              if (order.status == 'DELIVERING')
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: isProcessing ? null : () => _handleMarkAsArrived(order.id),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                                    icon: isProcessing ? const SizedBox() : const Icon(Icons.campaign),
                                                    label: Text(isProcessing ? 'Atualizando...' : 'Avisar que Cheguei', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                )
                                              else if (isArrived)
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.orange.shade200),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      const Text('O cliente deve fornecer um código de 3 dígitos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: TextField(
                                                              textAlign: TextAlign.center,
                                                              keyboardType: TextInputType.number,
                                                              maxLength: 3,
                                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Apenas números
                                                              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                                                              decoration: const InputDecoration(
                                                                counterText: "", // Esconde o contador "0/3"
                                                                hintText: "000",
                                                                filled: true,
                                                                fillColor: Colors.white,
                                                                border: OutlineInputBorder(),
                                                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                                                              ),
                                                              onChanged: (val) {
                                                                setState(() { _deliveryCodes[order.id] = val; });
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          ElevatedButton(
                                                            onPressed: isProcessing || (_deliveryCodes[order.id]?.length != 3) 
                                                                ? null 
                                                                : () => _handleCompleteDelivery(order.id),
                                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24)),
                                                            child: Text(isProcessing ? 'Validando' : 'Concluir', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
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

              // ==========================================
              // SESSÃO 2: BUSCAR NOVAS ENTREGAS
              // ==========================================
              const SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Buscar Novas Corridas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Digite a cidade (Ex: São Paulo)',
                            prefixIcon: const Icon(Icons.location_city, color: Colors.green),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          onSubmitted: (_) => _handleSearchAvailable(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoadingSearch ? null : _handleSearchAvailable,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(_isLoadingSearch ? 'Buscando...' : 'Buscar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),

              if (_hasSearched && !_isLoadingSearch)
                if (_availableDeliveries.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                      child: const Text('Nenhuma entrega disponível aguardando motoboy nesta cidade.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                else
                  SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: 220, // Altura do card de corrida
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = _availableDeliveries[index];
                        final isProcessing = _processingId == order.id;
                        
                        // Calcula ganhos de 4%
                        final earnings = (order.totalAmount * 0.04).toStringAsFixed(2).replaceAll('.', ',');

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.green.shade200)),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Pronto para Retirada', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    Text('R\$ $earnings', style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.store, size: 14, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(order.restaurantAddress ?? 'Endereço Indisponível', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('${order.deliveryStreet}, ${order.deliveryCity}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: isProcessing ? null : () => _handleAcceptDelivery(order.id),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green)),
                                    child: Text(isProcessing ? 'Aceitando...' : 'Aceitar Corrida', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _availableDeliveries.length,
                    ),
                  ),

            ],
          ),
        ),
      ),
    );
  }
}