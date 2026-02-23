import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo
import '../models/restaurant_model.dart';

const String defaultLogo = "https://cdn-icons-png.flaticon.com/512/1046/1046784.png";

class ManageRestaurantPage extends StatefulWidget {
  final String id; // Recebe o ID da URL

  const ManageRestaurantPage({super.key, required this.id});

  @override
  State<ManageRestaurantPage> createState() => _ManageRestaurantPageState();
}

class _ManageRestaurantPageState extends State<ManageRestaurantPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';

  // Estados do Formulário
  String _logoPreview = defaultLogo;
  String _logoBase64 = ''; // Guarda a nova imagem se o usuário trocar
  bool _isOpen = true;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _zipCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) context.go('/my-restaurants');
      return;
    }

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/${widget.id}/settings');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restaurant = RestaurantModel.fromJson(data);

        if (mounted) {
          setState(() {
            // Preenche os controllers com os dados do banco
            _nameCtrl.text = restaurant.name;
            _descCtrl.text = restaurant.description ?? '';
            _streetCtrl.text = restaurant.street;
            _cityCtrl.text = restaurant.city;
            _stateCtrl.text = restaurant.state;
            _zipCtrl.text = restaurant.zipCode;
            _countryCtrl.text = restaurant.country;
            
            _isOpen = restaurant.isOpen;
            
            if (restaurant.logo != null && restaurant.logo!.isNotEmpty) {
              _logoPreview = restaurant.logo!;
            }
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Erro ao carregar dados do restaurante.');
      }
    } catch (err) {
      debugPrint("Erro: $err");
      if (mounted) {
        setState(() {
          _error = "Erro ao carregar dados do restaurante.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogoChange() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image != null) {
      final File file = File(image.path);
      final int fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A imagem é muito grande! Escolha uma menor que 2MB.")));
        return;
      }

      final bytes = await file.readAsBytes();
      final base64String = "data:image/jpeg;base64,${base64Encode(bytes)}";
      
      setState(() {
        _logoBase64 = base64String;
        _logoPreview = base64String; // Atualiza o preview na tela
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_nameCtrl.text.trim().isEmpty || _streetCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nome, Rua e Cidade são obrigatórios.")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isSaving = true; });

    final formData = {
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'street': _streetCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'zip_code': _zipCtrl.text,
      'country': _countryCtrl.text,
      'is_open': _isOpen,
    };

    // Só envia o logo se o usuário tiver alterado a imagem
    if (_logoBase64.isNotEmpty) {
      formData['logo'] = _logoBase64;
    }

    try {
      final url = Uri.parse('http://localhost:3002/api/restaurants/${widget.id}/settings');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dados atualizados com sucesso!"), backgroundColor: Colors.green));
          context.go('/my-restaurants');
        }
      } else {
        final resData = jsonDecode(response.body);
        throw Exception(resData['message'] ?? "Erro ao atualizar restaurante.");
      }
    } catch (err) {
      debugPrint("Erro ao salvar: $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString().replaceAll('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
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
    if (_isLoading) return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // --- CABEÇALHO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/my-restaurants'),
                        ),
                        const SizedBox(width: 8),
                        const Text('Editar Dados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.go('/my-restaurants/${widget.id}/edit-menu'),
                          icon: const Icon(Icons.restaurant_menu, size: 18),
                          label: const Text('Pratos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/my-restaurants/${widget.id}/manage-orders'),
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('Pedidos'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                      ],
                    )
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

                // --- NOVO CARD: Status de Operação ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _isOpen ? Colors.green : Colors.red, width: 2),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_isOpen ? Icons.door_front_door : Icons.meeting_room, color: _isOpen ? Colors.green : Colors.red),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Status do Restaurante',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isOpen ? Colors.green : Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text('Controle se os clientes podem fazer pedidos neste momento.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _isOpen ? 'Aberto' : 'Fechado',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isOpen ? Colors.green : Colors.red),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _isOpen,
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                              inactiveTrackColor: Colors.red.shade200,
                              onChanged: (val) => setState(() => _isOpen = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // --- CARD 1: Identidade Visual e Básicos ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.badge, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Informações Básicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo Upload
                            Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 30),
                              child: Column(
                                children: [
                                  const Text('Logotipo', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 3)),
                                        child: ClipOval(
                                          child: _logoPreview.startsWith('data:image')
                                              ? Image.memory(base64Decode(_logoPreview.split(',').last), width: 140, height: 140, fit: BoxFit.cover)
                                              : Image.network(_logoPreview, width: 140, height: 140, fit: BoxFit.cover),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _handleLogoChange,
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Max: 2MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            
                            // Campos de Texto
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nome do Restaurante *', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(controller: _nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
                                  const SizedBox(height: 16),
                                  const Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Conte um pouco sobre seu restaurante...')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- CARD 2: Endereço ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                        child: const Row(
                          children: [
                            Icon(Icons.map, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Endereço e Localização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(flex: 2, child: _buildLabeledInput('Rua / Avenida / Número *', _streetCtrl)),
                                const SizedBox(width: 16),
                                Expanded(flex: 1, child: _buildLabeledInput('CEP', _zipCtrl)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(flex: 5, child: _buildLabeledInput('Cidade *', _cityCtrl)),
                                const SizedBox(width: 16),
                                Expanded(flex: 3, child: _buildLabeledInput('Estado', _stateCtrl)),
                                const SizedBox(width: 16),
                                Expanded(flex: 4, child: _buildLabeledInput('País', _countryCtrl)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- BOTÕES DE AÇÃO ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/my-restaurants'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para não repetir código nos campos de endereço
  Widget _buildLabeledInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true)),
      ],
    );
  }
}