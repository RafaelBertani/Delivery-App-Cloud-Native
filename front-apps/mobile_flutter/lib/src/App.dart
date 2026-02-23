import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Importe suas páginas
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

// Importe o seu menu lateral
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
    // O ShellRoute cria o layout base (Header + Options + Main) para as rotas filhas
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        
        // Simulação do seu usuário vindo do AuthContext
        final mockUser = UserModel(isDelivery: true, hasRestaurant: false);
        final bool isUserLoggedIn = false; // Simulação de estado de login
        final String userName = "Rafael"; // Simulação de nome de usuário

        return Scaffold(
          // O AppBar substitui o <Header /> do React
          appBar: AppBar(
            toolbarHeight: 130, // Equivale ao seu height: 130px no CSS
            backgroundColor: const Color.fromRGBO(174, 10, 10, 1.0),
            iconTheme: const IconThemeData(color: Colors.white), 
            
            // Logo centralizada
            centerTitle: true,
            title: Image.asset(
              'assets/images/genericLogo.png', // <-- Novo caminho limpo
              height: 80,
              errorBuilder: (context, error, stackTrace) => const Text('Logo', style: TextStyle(color: Colors.white)), 
            ),

            // O actions substitui a sua div "box-buttons"
            actions: [
              if (isUserLoggedIn) ...[
                // Div de apresentação
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
                
                // Botão de Sair
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Lógica de logout aqui no futuro
                        context.go('/');
                      },
                      icon: const Icon(Icons.logout, color: Colors.black, size: 16),
                      label: const Text('Sair', style: TextStyle(color: Colors.black)),
                      style: _btnHeaderStyle(),
                    ),
                  ),
                ),
              ] else ...[
                // Botões de Login e Cadastro
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
          
          // Aqui entra o seu componente importado de opções laterais
          drawer: OptionsDrawer(user: mockUser),
          
          // Onde as rotas (pages) serão renderizadas, equivalente ao <main> no React
          body: Container(
            color: Colors.white, // Substitui a classe "back1"
            child: child,
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/signIn',
          builder: (context, state) => const SignInPage(),
        ),
        GoRoute(
          path: '/signUp',
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: '/suggested',
          builder: (context, state) => const SuggestedPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/my-restaurants',
          builder: (context, state) => const RestaurantsPage(),
        ),
        GoRoute(
          path: '/restaurant/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrderPage(id: id);
          },
        ),
        GoRoute(
          path: '/orders-list',
          builder: (context, state) => const OrderListPage(),
        ),
        GoRoute(
          path: '/delivery-panel',
          builder: (context, state) => const DeliveryPanelPage(),
        ),
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

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Lógica futura de autenticação
  }

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