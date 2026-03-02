import 'dart:convert'; // Necessário para decodificar o JSON
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionsDrawer extends StatelessWidget {
  const OptionsDrawer({super.key});

  // Função assíncrona que vai buscar o usuário no SharedPreferences
  Future<Map<String, dynamic>?> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    
    if (userString != null) {
      try {
        // Transforma a String JSON de volta em um Mapa/Objeto legível
        return jsonDecode(userString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(255, 0, 0, 1.0),     // rgb(255, 0, 0)
              Color.fromRGBO(131, 55, 55, 1.0),   // rgb(131, 55, 55)
            ],
          ),
        ),
        // O FutureBuilder "espera" o SharedPreferences carregar sem quebrar a tela
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            
            // Lendo as chaves do JSON com segurança (ajuste caso o seu backend use snake_case)
            final bool isDelivery = userData?['isDelivery'] == true || userData?['is_delivery'] == true;
            final bool hasRestaurant = userData?['hasRestaurant'] == true || userData?['has_restaurant'] == true;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    // Fundo transparente para herdar o gradiente
                    color: Colors.transparent, 
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.fastfood, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Menu de Opções',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ],
                  ),
                ),
                
                // Botões do Menu
                _buildMenuItem(context, Icons.search, 'Pesquisar', '/search'),
                _buildMenuItem(context, Icons.lightbulb, 'Sugeridos', '/suggested'),
                _buildMenuItem(context, Icons.inventory_2, 'Pedidos', '/orders-list'),
                
                if (isDelivery)
                  _buildMenuItem(context, Icons.motorcycle, 'Painel Entregas', '/delivery-panel'),
                  
                if (hasRestaurant)
                  _buildMenuItem(context, Icons.store, 'Meus Restaurantes', '/my-restaurants'),
                  
                const Divider(color: Colors.white54), // Um separador visual
                
                _buildMenuItem(context, Icons.person, 'Conta', '/profile'),
                _buildMenuItem(context, Icons.settings, 'Configurações', '/settings'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      hoverColor: const Color.fromRGBO(179, 72, 72, 1.0),
      onTap: () {
        Navigator.pop(context); // Fecha a gaveta primeiro
        context.go(route);      // Depois navega
      },
    );
  }
}