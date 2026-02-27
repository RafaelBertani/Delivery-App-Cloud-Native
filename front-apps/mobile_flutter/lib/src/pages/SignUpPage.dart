import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // O FormKey é como o Joi no Flutter, ele gerencia o estado de validação de todo o formulário
  final _formKey = GlobalKey<FormState>();

  // Controllers substituem o "useState" para os inputs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _errorMessage = '';
  bool _isLoading = false;

  // Lógica de envio (equivalente ao handleSubmit)
  Future<void> handleSubmit() async {
    setState(() {
      _errorMessage = '';
    });

    // 1. Valida todos os campos baseados nas regras que definimos lá embaixo
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final formData = {
      "name": _nameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "confirmPassword": _confirmPasswordController.text,
    };

    try {
      final url = Uri.parse('http://localhost:3001/api/auth/signup'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!'), backgroundColor: Colors.green),
          );
          context.go('/signIn');
        }
      } else {
        // Erro retornado pela API
        setState(() {
          _errorMessage = responseData['error'] ?? 'Erro no cadastro. Tente novamente.';
        });
      }
    } catch (error) {
      // Erro de conexão (servidor fora do ar, etc)
      setState(() {
        _errorMessage = 'Erro de conexão. Verifique se o backend está rodando.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Limpa os controllers da memória quando a tela for fechada
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center( // Centraliza a caixa na tela
      child: SingleChildScrollView( // Permite rolar a tela se o teclado abrir
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(40), // padding: 40px
          decoration: BoxDecoration(
            color: const Color.fromRGBO(213, 153, 153, 1.0), // background-color: rgb(213, 153, 153)
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26, // rgba(0,0,0,0.2)
                blurRadius: 20, // 20px
                offset: Offset(0, 8), // 8px para baixo
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Faz os inputs ocuparem toda a largura
              children: [
                const Text(
                  'Criar conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Campo Nome
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Nome',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Nome é obrigatório.';
                    if (value.length < 3) return 'Nome deve ter no mínimo 3 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Email
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email é obrigatório.';
                    if (!value.contains('@') || !value.contains('.')) return 'Email inválido.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Senha
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Senha é obrigatória.';
                    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Campo Confirmar Senha
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar Senha',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Confirmação de senha é obrigatória.';
                    if (value != _passwordController.text) return 'As senhas não conferem.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Botão de Envio
                ElevatedButton(
                  onPressed: _isLoading ? null : handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(179, 72, 72, 1.0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Registrar', style: TextStyle(fontSize: 16)),
                ),

                // Mensagem de Erro do Backend
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 20),

                // Link para Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já tem conta? ', style: TextStyle(color: Colors.white, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.go('/signIn'),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar para criar os inputs (replicando o estilo .box input do CSS)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white, // Fundo branco dos inputs
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14), // padding: 10px
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), // border-radius: 6px
          borderSide: BorderSide.none, // border: none
        ),
        errorStyle: const TextStyle(color: Color.fromARGB(255, 126, 17, 10), fontWeight: FontWeight.bold),
      ),
    );
  }
}