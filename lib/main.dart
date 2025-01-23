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

class HomeScreen extends StatelessWidget {
  final PigeonUserDetail userData;

  const HomeScreen({super.key, required this.userData});

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas'),
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay recetas disponibles'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final recipe = Recipe.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id as int,
              );

              return RecipeCard(recipe: recipe);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRecipeScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
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
            //if (recipe.imageUrl != null)
              //Image.network(
                //recipe.imageUrl!,
                //height: 200,
                //width: double.infinity,
                //fit: BoxFit.cover,
                //errorBuilder: (context, error, stackTrace) {
                  //return Container(
                    //height: 200,
                    //color: Colors.grey[300],
                    //child: const Icon(Icons.error),
                  //);
                //},
              //),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text('${recipe.cookingTime.inMinutes} minutos'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
