import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';
import '../widgets/recipe_card.dart';

class FavoriteRecipesScreen extends StatelessWidget {
  const FavoriteRecipesScreen({super.key});

  Future<void> _toggleFavorite(BuildContext context, Recipe recipe) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final recipeRef = FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipe.id);

      // Obtener la receta actualizada
      final recipeDoc = await recipeRef.get();
      if (!recipeDoc.exists) return;

      List<String> favoritedBy = List<String>.from(recipeDoc.data()?['favoritedBy'] ?? []);

      if (favoritedBy.contains(currentUser.uid)) {
        // Quitar de favoritos
        favoritedBy.remove(currentUser.uid);
        await recipeRef.update({'favoritedBy': favoritedBy});
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta eliminada de favoritos'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar favoritos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('No hay usuario autenticado'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recetas Favoritas'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('favoritedBy', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las recetas'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data?.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Recipe.fromMap(data, doc.id);
          }).toList() ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('No tienes recetas favoritas'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return RecipeCard(
                recipe: recipe,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(recipe: recipe),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 