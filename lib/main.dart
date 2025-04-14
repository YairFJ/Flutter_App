import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
import 'services/language_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DefaultFirebaseOptions.loadEnv();
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
  final _languageService = LanguageService();
  final _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _languageService),
        ChangeNotifierProvider.value(value: _themeService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
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
            themeMode:
                themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthWrapper(),
            routes: {
              '/profile': (context) =>
                  ProfilePage(user: FirebaseAuth.instance.currentUser!),
              '/login': (context) => const LoginPage(),
              '/register': (context) => const SignUpScreen(),
              '/groups': (context) => const GroupsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          toggleTheme:
              Provider.of<ThemeService>(context, listen: false).toggleTheme,
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
  late bool isDarkMode;
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    print('HomeScreen initState llamado');
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final languageService =
        Provider.of<LanguageService>(context, listen: false);
    isDarkMode = themeService.isDarkMode;
    isEnglish = languageService.isEnglish;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeService = Provider.of<ThemeService>(context);
    final languageService = Provider.of<LanguageService>(context);
    if (isDarkMode != themeService.isDarkMode) {
      setState(() {
        isDarkMode = themeService.isDarkMode;
      });
    }
    if (isEnglish != languageService.isEnglish) {
      setState(() {
        isEnglish = languageService.isEnglish;
      });
    }
  }

  void toggleTheme() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleTheme();
  }

  void toggleLanguage() {
    final languageService =
        Provider.of<LanguageService>(context, listen: false);
    languageService.toggleLanguage();
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

  void _navigateToAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecipeScreen(isEnglish: isEnglish),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen build llamado');

    // Lista de páginas/widgets para cada elemento del menú
    final List<Widget> _pages = [
      RecipesPage(isEnglish: isEnglish),
      ConversionTablePage(isEnglish: isEnglish),
      const TimerPage(),
      StopwatchPage(isEnglish: isEnglish),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text(
          isEnglish ? 'Recipes' : 'Recetas',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isEnglish ? Icons.language : Icons.translate,
              color: Colors.white,
            ),
            onPressed: toggleLanguage,
            tooltip: isEnglish ? 'Cambiar a Español' : 'Switch to English',
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: Colors.white,
            ),
            onPressed: toggleTheme,
            tooltip:
                isDarkMode ? 'Cambiar a modo claro' : 'Switch to dark mode',
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
              title: Text(isEnglish ? 'Home' : 'Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(isEnglish ? 'My Profile' : 'Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      user: FirebaseAuth.instance.currentUser!,
                      isEnglish: isEnglish,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: Text(isEnglish ? 'Communities' : 'Comunidades'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupsScreen(isEnglish: isEnglish),
                  ),
                );
              },
            ),
            if (FirebaseAuth.instance.currentUser != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: Text(isEnglish ? 'Log Out' : 'Cerrar Sesión'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu),
            label: isEnglish ? 'Recipes' : 'Recetas',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate),
            label: isEnglish ? 'Conversion' : 'Conversión',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timer),
            label: isEnglish ? 'Timer' : 'Temporizador',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timer_outlined),
            label: isEnglish ? 'Stopwatch' : 'Cronómetro',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToAddRecipe,
              backgroundColor: primaryColor,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            )
          : null,
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isEnglish;

  const RecipeCard({super.key, required this.recipe, this.isEnglish = false});

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
              builder: (context) => RecipeDetailScreen(
                recipe: recipe,
                isEnglish: isEnglish,
              ),
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
                            isEnglish
                                ? 'Created by: ${recipe.creatorName}'
                                : 'Creado por: ${recipe.creatorName}',

                            /// posible error
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
                            '${recipe.ingredients.length} ${isEnglish ? 'ingr.' : 'ing.'}',
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
