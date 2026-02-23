import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importe o seu Model!
import '../models/restaurant_model.dart';

const String defaultLogo = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  List<RestaurantModel> _restaurants = [];
  bool _isLoadingList = true;
  String _error = '';

  // Estados do Formulário
  bool _isCreating = false;
  String _logoBase64 = '';
  
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _zipCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'Brasil');

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  void _goToManage(int id) {
    context.go('/my-restaurants/$id/settings');
  }

  Future<void> _fetchRestaurants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    setState(() {
      _isLoadingList = true;
      _error = '';
    });

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/list');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            final List<dynamic> decodedJson = jsonDecode(response.body);
            _restaurants = decodedJson.map((json) => RestaurantModel.fromJson(json)).toList();
          });
        }
      } else {
        throw Exception('Erro ao carregar restaurantes.');
      }
    } catch (err) {
      debugPrint("Erro: $err");
      if (mounted) {
        setState(() { _error = 'Erro ao carregar restaurantes.'; });
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingList = false; });
      }
    }
  }

  Future<void> _handleLogoChange() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image != null) {
      final File file = File(image.path);
      final int fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Imagem muito grande! Máximo 2MB.")));
        return;
      }

      final bytes = await file.readAsBytes();
      setState(() {
        _logoBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameCtrl.text.isEmpty || _streetCtrl.text.isEmpty || _cityCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha os campos obrigatórios (Nome, Rua, Cidade).")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isCreating = true; });

    final formData = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'street': _streetCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'zip_code': _zipCtrl.text,
      'country': _countryCtrl.text,
      'logo': _logoBase64,
    };

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/new');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(formData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurante criado com sucesso!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        
        _nameCtrl.clear();
        _descCtrl.clear();
        _streetCtrl.clear();
        _cityCtrl.clear();
        _stateCtrl.clear();
        _zipCtrl.clear();
        _countryCtrl.text = 'Brasil';
        setState(() { _logoBase64 = ''; });

        _fetchRestaurants();
      } else {
        final resData = jsonDecode(response.body);
        throw Exception(resData['message'] ?? 'Erro ao criar restaurante.');
      }
    } catch (err) {
      debugPrint("Erro ao criar: $err");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) {
        setState(() { _isCreating = false; });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- ÁREA 1: CADASTRAR NOVO RESTAURANTE ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias, 
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.add_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Novo Restaurante', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                    image: DecorationImage(
                                      image: _logoBase64.isNotEmpty 
                                          ? MemoryImage(base64Decode(_logoBase64.split(',').last)) as ImageProvider
                                          : const NetworkImage(defaultLogo),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: _handleLogoChange,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Carregar Logo', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nome do Restaurante *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(hintText: 'Ex: Pizzaria do João', border: OutlineInputBorder(), isDense: true),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _descCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(hintText: 'Ex: A melhor pizza da região...', border: OutlineInputBorder(), isDense: true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(flex: 2, child: TextField(controller: _streetCtrl, decoration: const InputDecoration(hintText: 'Rua / Avenida *', border: OutlineInputBorder(), isDense: true))),
                            const SizedBox(width: 10),
                            Expanded(flex: 1, child: TextField(controller: _cityCtrl, decoration: const InputDecoration(hintText: 'Cidade *', border: OutlineInputBorder(), isDense: true))),
                            const SizedBox(width: 10),
                            Expanded(flex: 1, child: TextField(controller: _stateCtrl, decoration: const InputDecoration(hintText: 'Estado', border: OutlineInputBorder(), isDense: true))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _zipCtrl, decoration: const InputDecoration(hintText: 'CEP', border: OutlineInputBorder(), isDense: true))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: _countryCtrl, decoration: const InputDecoration(hintText: 'País', border: OutlineInputBorder(), isDense: true))),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                                child: _isCreating 
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Cadastrar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // --- ÁREA 2: LISTA DE RESTAURANTES ---
            const Row(
              children: [
                Icon(Icons.store, color: Colors.blue),
                SizedBox(width: 8),
                Text('Meus Restaurantes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoadingList)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
            else if (_restaurants.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Icon(Icons.restaurant, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Nenhum restaurante encontrado.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Cadastre seu primeiro restaurante acima para começar!', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _restaurants.length,
                itemBuilder: (context, index) {
                  
                  // 3. AGORA USAMOS OS ATRIBUTOS DO OBJETO!
                  final RestaurantModel rest = _restaurants[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      border: Border(left: BorderSide(width: 5, color: rest.isOpen ? Colors.green : Colors.grey)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: rest.isOpen ? 1.0 : 0.5,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                rest.logo ?? defaultLogo,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rest.name, // rest.name
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: rest.isOpen ? Colors.green : Colors.grey.shade600,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(rest.isOpen ? Icons.check_circle : Icons.lock, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            rest.isOpen ? 'ABERTO' : 'FECHADO',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rest.description != null && rest.description!.length > 60
                                      ? '${rest.description!.substring(0, 60)}...'
                                      : rest.description ?? 'Sem descrição',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('${rest.city} - ${rest.state}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          OutlinedButton.icon(
                            onPressed: () => _goToManage(rest.id),
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('GERENCIAR'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}