import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'models/pigeon_user_detail.dart';
import 'screens/signup_screen.dart';
import 'models/recipe.dart';
import 'screens/add_recipe_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/profile_page.dart';
import 'constants/categories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Reiniciar Firebase Auth
    await FirebaseAuth.instance.signOut();
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
      home: const AuthWrapper(),
      routes: {
        //'/': (context) => const HomePage(),
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
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Comprobar si hay datos en el snapshot
        if (snapshot.hasData && snapshot.data != null) {
          // Convertir User de Firebase a PigeonUserDetail
          final PigeonUserDetail userData = PigeonUserDetail.fromUser(snapshot.data!);

          // Pasar userData a HomeScreen
          return HomeScreen(userData: userData);
        }

        return const LoginPage();
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
  // Usar los colores definidos en HomeScreen
  Color get primaryColor => HomeScreen.primaryColor;
  Color get secondaryColor => HomeScreen.secondaryColor;

  final TextEditingController _searchController = TextEditingController();

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  Widget _buildCategoryCarousel(String category, List<Recipe> recipes) {
    final categoryRecipes = category == RecipeCategories.sinCategoria
        ? recipes.where((recipe) => 
            recipe.category.isEmpty || 
            !RecipeCategories.categories.contains(recipe.category)
          ).toList()
        : recipes.where((recipe) => recipe.category == category).toList();

    if (categoryRecipes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    RecipeCategories.getIconForCategory(category),
                    color: RecipeCategories.getColorForCategory(category),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${categoryRecipes.length} recetas',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // Altura del carrusel
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categoryRecipes.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200, // Ancho de cada tarjeta
                child: Card(
                  margin: const EdgeInsets.all(4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(
                            recipe: categoryRecipes[index],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //ClipRRect(
                          //borderRadius: const BorderRadius.vertical(
                            //top: Radius.circular(16),
                          //),
                         // child: Image.network(
                           // categoryRecipes[index].imageUrl ?? 
                                //'https://via.placeholder.com/150',
                            //height: 150,
                            //width: double.infinity,
                            //fit: BoxFit.cover,
                          //),
                        //),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                categoryRecipes[index].title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                categoryRecipes[index].description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${categoryRecipes[index].cookingTime.inMinutes} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final recipes = snapshot.data?.docs.map((doc) {
          return Recipe.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList() ?? [];

        // Filtrar por búsqueda si hay texto
        if (_searchController.text.isNotEmpty) {
          final searchTerm = _searchController.text.toLowerCase();
          recipes.removeWhere((recipe) =>
            !recipe.title.toLowerCase().contains(searchTerm) &&
            !recipe.description.toLowerCase().contains(searchTerm)
          );
        }

        if (recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, 
                  size: 64, 
                  color: Colors.grey[400]
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay recetas disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          children: RecipeCategories.categories.map((category) {
            return _buildCategoryCarousel(category, recipes);
          }).toList(),
        );
      },
    );
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
          IconButton(
            onPressed: () {
              // Implementar función de búsqueda
            },
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: secondaryColor,
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 24,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
              leading: const Icon(Icons.person, size: 26),
              title: const Text(
                'Mi Perfil',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      user: FirebaseAuth.instance.currentUser!,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, size: 26),
              title: const Text(
                'Favoritos',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                // Navegar a favoritos
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, size: 26),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16),
              ),
              onTap: signUserOut,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar recetas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {}); // Actualizar la lista al buscar
              },
            ),
          ),
          // Lista de recetas por categoría
          Expanded(
            child: _buildRecipeList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecipeScreen(),
            ),
          );
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white, size: 24),
        label: const Text(
          'Nueva Receta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
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
            color: Colors.grey.withOpacity(0.1),
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
