import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../screens/recipe_detail_screen.dart';

class FavoriteRecipesScreen extends StatelessWidget {
<<<<<<< HEAD
  const FavoriteRecipesScreen({Key? key}) : super(key: key);
=======
  const FavoriteRecipesScreen({super.key});
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
<<<<<<< HEAD
        title: const Text('Mis Favoritos'),
=======
        title: const Text('Recetas Favoritas'),
>>>>>>> main
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('favoritedBy', arrayContains: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
<<<<<<< HEAD
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las recetas'));
          }

=======
>>>>>>> main
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

<<<<<<< HEAD
          final recipes = snapshot.data?.docs.map((doc) {
            return Recipe.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList() ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('No tienes recetas favoritas aún'),
=======
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final recipes = snapshot.data?.docs.map((doc) {
            return Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList() ?? [];

          if (recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, 
                    size: 64, 
                    color: Colors.grey[400]
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes recetas favoritas',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
>>>>>>> main
            );
          }

          return ListView.builder(
<<<<<<< HEAD
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(
                recipe: recipes[index],
=======
            padding: const EdgeInsets.all(8),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
>>>>>>> main
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
<<<<<<< HEAD
                      builder: (context) => RecipeDetailScreen(
                        recipe: recipes[index],
                      ),
=======
                      builder: (context) => RecipeDetailScreen(recipe: recipe),
>>>>>>> main
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 