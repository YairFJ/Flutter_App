import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/screens/recipe_detail_screen.dart';

class UserRecipesScreen extends StatelessWidget {
  const UserRecipesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las recetas'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data?.docs.map((doc) {
            return Recipe.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList() ?? [];

          if (recipes.isEmpty) {
            return const Center(
              child: Text('No has creado ninguna receta aún'),
            );
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return RecipeCard(
                recipe: recipes[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailScreen(
                        recipe: recipes[index],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-recipe');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 