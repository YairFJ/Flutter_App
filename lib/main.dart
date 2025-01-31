import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'models/pigeon_user_detail.dart';
import 'screens/signup_screen.dart';
import 'screens/add_recipe_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'pages/recipes_page.dart';
import 'pages/conversion_table_page.dart';
import 'pages/timer_page.dart';
import 'pages/stopwatch_page.dart';
import 'models/recipe.dart';
import 'pages/profile_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Remover el signOut automático
    // await FirebaseAuth.instance.signOut();  // Eliminar esta línea
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurante App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/profile': (context) => ProfilePage(user: FirebaseAuth.instance.currentUser!),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const SignUpScreen(),
      },
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
        if (user == null) {
          return const LoginPage();
        }

        return HomeScreen(userData: PigeonUserDetail.fromUser(user));
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final PigeonUserDetail userData;

  const HomeScreen({super.key, required this.userData});

  // Definimos los colores como constantes estáticas
  static const Color primaryColor = Color(0xFF96B4D8);
  static const Color secondaryColor = Color(0xFFD6E3BB);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Lista de páginas/widgets para cada elemento del menú
  final List<Widget> _pages = [
    const RecipesPage(),
    const ConversionTablePage(),
    const TimerPage(),
    const StopwatchPage(),
  ];

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          'Recetas',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Eliminar o comentar esta parte
          // IconButton(
          //   icon: const Icon(Icons.search),
          //   onPressed: () {
          //     // ...
          //   },
          // ),
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
                    FirebaseAuth.instance.currentUser?.email ?? 'Usuario',
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
            if (FirebaseAuth.instance.currentUser != null) ...[
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
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Mostrar la página seleccionada
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
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
            icon: Icon(Icons.timer_outlined),
            label: 'Cronómetro',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecipeScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30, // Aumenté el tamaño para mejor visibilidad
        ),
      ) : null,
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            //ClipRRect(
              //borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              //child: Image.network(
                //recipe.imageUrl ?? 'https://via.placeholder.com/150',
                //height: 160,
                //width: double.infinity,
                //fit: BoxFit.cover,
                //errorBuilder: (context, error, stackTrace) {
                  //return Container(
                    //height: 160,
                    //color: HomeScreen.secondaryColor.withOpacity(0.3),
                    //child: const Icon(
                      //Icons.restaurant,
                      //size: 40,
                      //color: HomeScreen.primaryColor
                    //),
                  //);
                //},
              //),
            //),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
