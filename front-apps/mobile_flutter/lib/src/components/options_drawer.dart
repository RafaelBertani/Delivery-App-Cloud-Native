import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Aqui estou simulando a sua classe de Usuário que viria do Contexto/Provider.
// Você pode substituir pela sua classe de modelo real depois.
class UserModel {
  final bool isDelivery;
  final bool hasRestaurant;

  UserModel({this.isDelivery = false, this.hasRestaurant = false});
}

class OptionsDrawer extends StatelessWidget {
  final UserModel? user; // Recebe o usuário para fazer a lógica condicional

  const OptionsDrawer({super.key, this.user});

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
        child: ListView(
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
            
            if (user?.isDelivery == true)
              _buildMenuItem(context, Icons.motorcycle, 'Painel Entregas', '/delivery-panel'),
              
            if (user?.hasRestaurant == true)
              _buildMenuItem(context, Icons.store, 'Meus Restaurantes', '/my-restaurants'),
              
            const Divider(color: Colors.white54), // Um separador visual
            
            _buildMenuItem(context, Icons.person, 'Conta', '/profile'),
            _buildMenuItem(context, Icons.settings, 'Configurações', '/settings'),
          ],
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
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}