import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'screens/signup_screen.dart';
import 'screens/add_recipe_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'pages/recipes_page.dart';
import 'pages/conversion_table_page.dart';
import 'pages/timer_page.dart';
import 'pages/stopwatch_page.dart';
import 'models/recipe.dart';
import 'pages/profile_page.dart';
import 'screens/groups_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DefaultFirebaseOptions.loadEnv(); // Cargar variables de entorno
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurante App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF96B4D8),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF96B4D8),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: _themeMode,
      home: AuthWrapper(toggleTheme: toggleTheme),
      routes: {
        '/profile': (context) => ProfilePage(
              user: FirebaseAuth.instance.currentUser!,
            ),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const SignUpScreen(),
        '/groups': (context) => const GroupsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function toggleTheme;

  const AuthWrapper({super.key, required this.toggleTheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final user = snapshot.data;

        // Si no hay usuario, redirigir siempre al login
        if (user == null) {
          print('AuthWrapper: Usuario no autenticado, redirigiendo a login');
          return const LoginPage();
        }

        // Verificar si el email está verificado para usuarios de email/password
        // Los usuarios de Google ya vienen verificados
        if (!user.emailVerified &&
            !user.providerData
                .any((provider) => provider.providerId == 'google.com')) {
          print('AuthWrapper: Email no verificado, cerrando sesión');
          // Cerrar sesión y redirigir al login con mensaje
          FirebaseAuth.instance.signOut();
          // Mostrar mensaje después de que la página se construya
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Por favor, verifica tu email antes de iniciar sesión'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return const LoginPage();
        }

        print(
            'AuthWrapper: Usuario autenticado y verificado, accediendo a HomeScreen');
        return HomeScreen(
          userId: user.uid,
          userEmail: user.email ?? 'No disponible',
          userName: user.displayName ?? 'Usuario',
          toggleTheme: toggleTheme,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  final String userName;
  final Function toggleTheme;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.toggleTheme,
  });

  // Definimos los colores como constantes estáticas
  static const Color primaryColor = Color(0xFF96B4D8);
  static const Color secondaryColor = Color(0xFFD6E3BB);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool isDarkMode = false;

  // Lista de páginas/widgets para cada elemento del menú
  final List<Widget> _pages = [
    const RecipesPage(),
    const ConversionTablePage(),
    const TimerPage(),
    const StopwatchPage(),
  ];

  final List<String> _pageTitles = [
    'Recetas',
    'Conversión',
    'Temporizador',
    'Cronómetro',
  ];

  @override
  void initState() {
    super.initState();
    print('HomeScreen initState llamado');
    // Inicializar el tema inmediatamente
    isDarkMode =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      widget.toggleTheme();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Usar los colores definidos en HomeScreen
  Color get primaryColor => HomeScreen.primaryColor;
  Color get secondaryColor => HomeScreen.secondaryColor;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen build llamado');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.white,
            ),
            onPressed: toggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Comunidades'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/groups');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Conversión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Temporizador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timelapse),
            label: 'Cronómetro',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: secondaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddRecipeScreen(),
                  ),
                );
              },
            )
          : null,
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final secondaryTextColor =
        theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87;
    final backgroundColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    final userInfoBackgroundColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.grey[200];

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipe.description ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: userInfoBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creado por: ${recipe.creatorName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            recipe.creatorEmail,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 20,
                          color: HomeScreen.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recipe.cookingTime.inMinutes} min',
                          style: TextStyle(
                            fontSize: 14,
                            color: HomeScreen.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: HomeScreen.secondaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${recipe.ingredients.length} ing.',
                            style: TextStyle(
                              fontSize: 10,
                              color: HomeScreen.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
