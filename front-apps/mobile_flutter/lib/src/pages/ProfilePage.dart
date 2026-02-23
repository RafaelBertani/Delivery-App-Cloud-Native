import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart'; 

const String defaultAvatar = "https://cdn-icons-png.flaticon.com/512/149/149071.png";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;

  // Estados do Perfil
  bool _isLoading = false;
  String? _editingField;
  final TextEditingController _tempValueController = TextEditingController();

  // Estados de Endereço
  List<dynamic> _addresses = [];
  bool _isLoadingAddresses = true;
  bool _showAddressForm = false;

  // Controllers para o novo endereço
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _zipCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserAndAddresses();
  }

  Future<void> _loadUserAndAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    
    if (userStr == null) {
      if (mounted) context.go('/signIn');
      return;
    }

    setState(() {
      // 2. Mapeando a string do SharedPreferences para o UserModel
      _user = UserModel.fromJson(jsonDecode(userStr));
    });

    _fetchAddresses();
  }

  // ==========================================
  // FUNÇÕES DE PERFIL
  // ==========================================

  Future<bool> _saveToBackend(String field, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) context.go('/signIn');
      return false;
    }

    setState(() { _isLoading = true; });

    try {
      final url = Uri.parse('http://localhost:3001/api/auth/edit');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({field: value}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        final updatedUser = UserModel.fromJson(responseData['user']);
        
        setState(() { _user = updatedUser; });
        
        await prefs.setString('user', jsonEncode(updatedUser.toJson()));
        
        return true;
      } else {
        if (response.statusCode == 401) {
          await prefs.remove('token');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sessão expirada. Faça login novamente.")));
            context.go('/signIn');
          }
        } else {
          throw Exception('Erro ao atualizar');
        }
        return false;
      }
    } catch (e) {
      debugPrint("Erro: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao atualizar perfil.")));
      }
      return false;
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleImageChange() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image != null) {
      final File file = File(image.path);
      final int fileSize = await file.length();

      if (fileSize > 2 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A imagem é muito grande! Escolha uma menor que 2MB.")));
        return;
      }

      final bytes = await file.readAsBytes();
      final String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

      final success = await _saveToBackend('profile_pic', base64Image);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto atualizada com sucesso!")));
      }
    }
  }

  Future<void> _handleSave() async {
    if (_editingField == 'password' && _tempValueController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A senha deve ter no mínimo 6 caracteres.")));
      return;
    }
    if (_tempValueController.text.trim().isEmpty && _editingField != 'password') return;

    final success = await _saveToBackend(_editingField!, _tempValueController.text);
    if (success) {
      setState(() {
        _editingField = null;
        _tempValueController.clear();
      });
    }
  }

  Future<void> _fetchAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isLoadingAddresses = true; });

    try {
      final url = Uri.parse('http://localhost:3001/api/auth/addresses');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        setState(() {
          _addresses = jsonDecode(response.body);
        });
      }
    } catch (err) {
      debugPrint("Erro ao buscar endereços: $err");
    } finally {
      setState(() { _isLoadingAddresses = false; });
    }
  }

  Future<void> _handleSaveAddress() async {
    if (_nameCtrl.text.isEmpty || _streetCtrl.text.isEmpty || _cityCtrl.text.isEmpty || _stateCtrl.text.isEmpty || _zipCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos obrigatórios.")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() { _isLoading = true; });

    final newAddressData = {
      'name': _nameCtrl.text,
      'street': _streetCtrl.text,
      'city': _cityCtrl.text,
      'state': _stateCtrl.text,
      'zip_code': _zipCtrl.text,
    };

    try {
      final url = Uri.parse('http://localhost:3001/api/auth/addresses');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(newAddressData),
      );

      setState(() {
        _showAddressForm = false;
        _nameCtrl.clear();
        _streetCtrl.clear();
        _cityCtrl.clear();
        _stateCtrl.clear();
        _zipCtrl.clear();
      });
      _fetchAddresses();
    } catch (err) {
      debugPrint("Erro ao salvar endereço: $err");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao adicionar endereço.")));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleToggleActive(int addressId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Atualização Otimista
    setState(() {
      for (var addr in _addresses) {
        addr['is_active'] = (addr['id'] == addressId);
      }
    });

    try {
      final url = Uri.parse('http://localhost:3001/api/auth/addresses/$addressId/active');
      await http.put(url, headers: {'Authorization': 'Bearer $token'});
    } catch (err) {
      debugPrint("Erro ao ativar endereço: $err");
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // CABEÇALHO DO PERFIL
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              // 4. Usando o objeto _user
                              backgroundImage: NetworkImage(_user!.pic ?? defaultAvatar),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleImageChange,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _user!.name, // 5. Acesso via propriedade
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(50)),
                        child: Text(_user!.role ?? 'Cliente', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // DADOS CADASTRAIS
                    const Text('E-MAIL', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_user!.email, style: const TextStyle(fontSize: 16)), // 6. Acesso via propriedade
                    const SizedBox(height: 20),

                    const Text('SENHA', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('••••••••', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        if (_editingField != 'password')
                          TextButton.icon(
                            onPressed: _isLoading ? null : () => setState(() => _editingField = 'password'),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Alterar'),
                          )
                      ],
                    ),
                    
                    // Campo de Edição de Senha
                    if (_editingField == 'password')
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(
                          children: [
                            TextField(
                              controller: _tempValueController,
                              obscureText: true,
                              decoration: const InputDecoration(hintText: 'Nova senha', border: OutlineInputBorder(), isDense: true),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleSave,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Salvar'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _isLoading ? null : () { setState(() { _editingField = null; _tempValueController.clear(); }); },
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 40, thickness: 1),

                    // SESSÃO DE ENDEREÇOS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Meus Endereços', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        OutlinedButton(
                          onPressed: () => setState(() => _showAddressForm = !_showAddressForm),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                          child: Text(_showAddressForm ? 'Cancelar' : '+ Novo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Formulário de Novo Endereço
                    if (_showAddressForm)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(
                          children: [
                            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Nome (Ex: Casa, Trabalho)*', filled: true, fillColor: Colors.white, isDense: true)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(flex: 2, child: TextField(controller: _streetCtrl, decoration: const InputDecoration(hintText: 'Rua e Número*', filled: true, fillColor: Colors.white, isDense: true))),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: TextField(controller: _zipCtrl, decoration: const InputDecoration(hintText: 'CEP*', filled: true, fillColor: Colors.white, isDense: true))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(flex: 2, child: TextField(controller: _cityCtrl, decoration: const InputDecoration(hintText: 'Cidade*', filled: true, fillColor: Colors.white, isDense: true))),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: TextField(controller: _stateCtrl, decoration: const InputDecoration(hintText: 'Estado*', filled: true, fillColor: Colors.white, isDense: true))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSaveAddress,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text('Salvar Endereço', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Lista de Endereços
                    if (_isLoadingAddresses)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                    else if (_addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Você ainda não tem endereços cadastrados.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), 
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          final bool isActive = addr['is_active'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: isActive ? Colors.blue : Colors.grey.shade300, width: isActive ? 2 : 1),
                            ),
                            color: isActive ? Colors.blue.withOpacity(0.05) : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(addr['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            if (isActive)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('ATUAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text("${addr['street']}\n${addr['city']} - ${addr['state']}, ${addr['zip_code']}", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeColor: Colors.blue,
                                    onChanged: (val) => _handleToggleActive(addr['id']),
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
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.75),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}