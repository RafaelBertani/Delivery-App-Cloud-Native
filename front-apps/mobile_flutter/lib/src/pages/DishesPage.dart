import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo
import '../models/dish_model.dart';

const String defaultDishImg = "https://cdn-icons-png.flaticon.com/512/3014/3014520.png";

class DishesPage extends StatefulWidget {
  final String id; // Recebe o restaurantId da rota

  const DishesPage({super.key, required this.id});

  @override
  State<DishesPage> createState() => _DishesPageState();
}

class _DishesPageState extends State<DishesPage> {
  // --- ESTADOS ---
  List<DishModel> _dishes = [];
  bool _isLoading = true;
  
  // Estado do Formulário
  bool _isEditing = false;
  int? _editingId;
  bool _isSubmitting = false;
  String _imagePreview = '';
  String _imageBase64 = '';
  bool _isAvailable = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  
  // Controlador para o scroll (equivalente ao formRef do React)
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDishes();
  }

  // Helper Toast
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green)
    );
  }

  // --- 1. CARREGAR PRATOS ---
  Future<void> _fetchDishes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/${widget.id}/list-dishes');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final List<dynamic> decodedJson = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _dishes = decodedJson.map((json) => DishModel.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      debugPrint("Erro ao buscar pratos: $error");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // --- 2. MANIPULAÇÃO DO FORMULÁRIO ---
  Future<void> _handleImageChange() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final File file = File(image.path);
      final int fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        _showToast("Imagem muito grande! Máximo 2MB.", isError: true);
        return;
      }

      final bytes = await file.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      setState(() {
        _imageBase64 = base64String;
        _imagePreview = base64String;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _nameCtrl.clear();
      _descCtrl.clear();
      _priceCtrl.clear();
      _imageBase64 = '';
      _imagePreview = '';
      _isAvailable = true;
      _isEditing = false;
      _editingId = null;
    });
  }

  // --- 3. ENVIAR (CRIAR/EDITAR) ---
  Future<void> _handleSubmit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      _showToast("Nome e Preço são obrigatórios.", isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isSubmitting = true; });

    final formData = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'is_available': _isAvailable,
    };
    if (_imageBase64.isNotEmpty) {
      formData['image'] = _imageBase64;
    }

    try {
      http.Response response;
      if (_isEditing) {
        response = await http.patch(
          Uri.parse('http://localhost:3002/api/restaurants/edit-dish/$_editingId'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(formData),
        );
      } else {
        response = await http.post(
          Uri.parse('http://localhost:3002/api/restaurants/${widget.id}/create-dish'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode(formData),
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showToast(_isEditing ? "Prato atualizado com sucesso!" : "Prato criado com sucesso!");
        _resetForm();
        _fetchDishes(); // Recarrega a lista
      } else {
        throw Exception("Erro na API");
      }
    } catch (error) {
      debugPrint("Erro ao salvar prato: $error");
      _showToast("Erro ao salvar prato.", isError: true);
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  // --- 4. AÇÕES NOS CARDS ---
  void _handleEditClick(DishModel dish) {
    setState(() {
      _isEditing = true;
      _editingId = dish.id;
      _nameCtrl.text = dish.name;
      _descCtrl.text = dish.description;
      _priceCtrl.text = dish.price.toStringAsFixed(2);
      _imagePreview = dish.image ?? '';
      _isAvailable = dish.isAvailable;
    });
    // Rola para o topo (onde está o formulário)
    _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> _handleToggleAvailability(DishModel dish) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final newState = !dish.isAvailable;

    // Atualização Otimista
    setState(() {
      final index = _dishes.indexWhere((d) => d.id == dish.id);
      if (index != -1) {
        _dishes[index] = DishModel(
          id: dish.id, name: dish.name, description: dish.description, 
          price: dish.price, image: dish.image, isAvailable: newState
        );
      }
    });

    try {
      await http.patch(
        Uri.parse('http://localhost:3002/api/restaurants/edit-dish/${dish.id}'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'is_available': newState}),
      );
    } catch (error) {
      debugPrint("Erro ao mudar disponibilidade: $error");
      _showToast("Erro ao mudar disponibilidade.", isError: true);
      _fetchDishes(); // Reverte
    }
  }

  Future<void> _handleDelete(int id) async {
    // Confirmação de exclusão
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Prato"),
        content: const Text("Tem certeza que deseja excluir este prato?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3002/api/restaurants/delete-dish/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _dishes.removeWhere((d) => d.id == id);
        });
        _showToast("Prato excluído.");
      }
    } catch (error) {
      _showToast("Erro ao deletar.", isError: true);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(
            controller: _scrollController, // Acopla o controlador de rolagem
            //padding: const EdgeInsets.all(24),
            slivers: [
              
              // --- CABEÇALHO ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go('/my-restaurants/${widget.id}/settings'),
                      ),
                      const SizedBox(width: 8),
                      const Text('Gerenciar Cardápio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // --- FORMULÁRIO (ADD/EDIT) ---
              SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _isEditing ? Colors.orange : Colors.blue, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: _isEditing ? Colors.orange : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          children: [
                            Icon(_isEditing ? Icons.edit : Icons.add_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isEditing ? 'Editar Prato' : 'Adicionar Novo Prato',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Upload de Imagem
                            Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 24),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imagePreview.isNotEmpty && _imagePreview.startsWith('data:image')
                                        ? Image.memory(base64Decode(_imagePreview.split(',').last), height: 120, width: double.infinity, fit: BoxFit.cover)
                                        : _imagePreview.isNotEmpty
                                            ? Image.network(_imagePreview, height: 120, width: double.infinity, fit: BoxFit.cover)
                                            : Image.network(defaultDishImg, height: 120, width: double.infinity, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: _handleImageChange,
                                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                                    child: const Text('Escolher Foto', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Campos de Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Nome do Prato *', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Ex: X-Bacon Especial', border: OutlineInputBorder(), isDense: true)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Preço (R\$) *', style: TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            TextField(controller: _priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: '0.00', border: OutlineInputBorder(), isDense: true)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Ingredientes, tamanho, etc...', border: OutlineInputBorder(), isDense: true)),
                                  
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_isEditing)
                                        TextButton(onPressed: _resetForm, child: const Text('Cancelar Edição', style: TextStyle(color: Colors.grey))),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: _isSubmitting ? null : _handleSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isEditing ? Colors.orange : Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                        child: Text(_isSubmitting ? 'Salvando...' : (_isEditing ? 'Atualizar Prato' : 'Cadastrar Prato'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
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
              ),

              // --- TÍTULO DA LISTA ---
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(Icons.list, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Pratos Cadastrados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // --- LISTA DE PRATOS ---
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_dishes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('Nenhum prato cadastrado ainda. Use o formulário acima.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisExtent: 380, // Altura do Card
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final dish = _dishes[index];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: dish.isAvailable ? Colors.green.shade200 : Colors.red.shade200, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Imagem e Preço
                            Stack(
                              children: [
                                Opacity(
                                  opacity: dish.isAvailable ? 1.0 : 0.6,
                                  child: Image.network(
                                    dish.image != null && dish.image!.isNotEmpty ? dish.image! : defaultDishImg,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      "R\$ ${dish.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Detalhes
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dish.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 6),
                                    Expanded(child: Text(dish.description.isEmpty ? "Sem descrição." : dish.description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis)),
                                    const Divider(),
                                    
                                    // Ações Inferiores
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Switch Disponibilidade
                                        Row(
                                          children: [
                                            Switch(
                                              value: dish.isAvailable,
                                              activeColor: Colors.green,
                                              inactiveThumbColor: Colors.red,
                                              onChanged: (val) => _handleToggleAvailability(dish),
                                            ),
                                            Text(
                                              dish.isAvailable ? 'DISPONÍVEL' : 'ESGOTADO',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dish.isAvailable ? Colors.green : Colors.red),
                                            ),
                                          ],
                                        ),
                                        
                                        // Botões Editar/Excluir
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                              onPressed: () => _handleEditClick(dish),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.all(4),
                                              onPressed: () => _handleDelete(dish.id),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _dishes.length,
                  ),
                ),
                
            ],
          ),
        ),
      ),
    );
  }
}