import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/SignInPage.dart';
import 'pages/SignUpPage.dart';
import 'pages/ProfilePage.dart';
import 'pages/SettingsPage.dart';
import 'pages/RestaurantsPage.dart';
import 'pages/ManageRestaurantPage.dart';
import 'pages/DishesPage.dart';
import 'pages/SuggestedPage.dart';
import 'pages/OrderPage.dart';
import 'pages/OrderListPage.dart';
import 'pages/ManageOrdersPage.dart';
import 'pages/SearchPage.dart';
import 'pages/DeliveryPanelPage.dart';

// Importa menu lateral
import './components/options_drawer.dart';

// Função auxiliar para o estilo dos botões do header
ButtonStyle _btnHeaderStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color.fromRGBO(229, 175, 175, 1.0),
    foregroundColor: Colors.black, // Cor do texto/ícone
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: Colors.transparent, width: 0.5), 
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.hovered)) {
        return const Color.fromRGBO(228, 94, 94, 1.0);
      }
      return const Color.fromRGBO(229, 175, 175, 1.0);
    }),
    side: WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.hovered)) {
        return const BorderSide(color: Colors.white, width: 0.5);
      }
      return const BorderSide(color: Colors.transparent, width: 0.5);
    }),
  );
}

// Chaves para gerenciar o estado da navegação
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SearchPage()),
        GoRoute(path: '/signIn', builder: (context, state) => const SignInPage()),
        GoRoute(path: '/signUp', builder: (context, state) => const SignUpPage()),
        GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
        GoRoute(path: '/suggested', builder: (context, state) => const SuggestedPage()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
        GoRoute(path: '/my-restaurants', builder: (context, state) => const RestaurantsPage()),
        GoRoute(
          path: '/restaurant/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrderPage(id: id);
          },
        ),
        GoRoute(path: '/orders-list', builder: (context, state) => const OrderListPage()),
        GoRoute(path: '/delivery-panel', builder: (context, state) => const DeliveryPanelPage()),
        GoRoute(
          path: '/my-restaurants/:id/settings',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ManageRestaurantPage(id: id);
          },
        ),
        GoRoute(
          path: '/my-restaurants/:id/edit-menu',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DishesPage(id: id);
          },
        ),
        GoRoute(
          path: '/my-restaurants/:id/manage-orders',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ManageOrdersPage(id: id);
          },
        ),
      ],
    ),
  ],
);

class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool isUserLoggedIn = false;
  String userName = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Lê os dados do SharedPreferences uma única vez ao montar o layout
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      try {
        final userData = jsonDecode(userString);
        setState(() {
          isUserLoggedIn = true;
          userName = userData['name'] ?? userData['nome'] ?? 'Usuário';
        });
      } catch (e) {
        print('Erro ao decodificar JSON do usuário: $e');
      }
    }
  }

  // Função para limpar os dados e sair
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user'); // Apaga o cache
    setState(() {
      isUserLoggedIn = false;
      userName = "";
    });
    if (mounted) {
      context.go('/'); // Redireciona para a home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 130,
        backgroundColor: const Color.fromRGBO(174, 10, 10, 1.0),
        iconTheme: const IconThemeData(color: Colors.white), 
        centerTitle: true,
        title: Image.asset(
          'assets/images/genericLogo.png',
          height: 80,
          errorBuilder: (context, error, stackTrace) => const Text('Logo', style: TextStyle(color: Colors.white)), 
        ),
        actions: [
          if (isUserLoggedIn) ...[
            Center(
              child: Text(
                'Olá, $userName',
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _logout, // Chama a nova função de logout
                  icon: const Icon(Icons.logout, color: Colors.black, size: 16),
                  label: const Text('Sair', style: TextStyle(color: Colors.black)),
                  style: _btnHeaderStyle(),
                ),
              ),
            ),
          ] else ...[
            Center(
              child: ElevatedButton(
                onPressed: () => context.go('/signIn'),
                style: _btnHeaderStyle(),
                child: const Text('Login', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(width: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: ElevatedButton(
                  onPressed: () => context.go('/signUp'),
                  style: _btnHeaderStyle(),
                  child: const Text('Cadastro', style: TextStyle(color: Colors.black)),
                ),
              ),
            ),
          ],
        ],
      ),
      // Instancia a gaveta já arrumada na etapa anterior
      drawer: const OptionsDrawer(),
      body: Container(
        color: Colors.white,
        child: widget.child, // Aqui as páginas são renderizadas
      ),
    );
  }
}

// =========================================================================
// COMPONENTE APP (Raiz)
// =========================================================================
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Delivery App',
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}