import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import 'group_recipe_form_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;
  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentUser = FirebaseAuth.instance.currentUser!.uid;
    bool isMember = group.members.contains(currentUser);

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(group.description),
          ),
          if (!isMember)
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(group.id)
                    .update({
                  'members': FieldValue.arrayUnion([currentUser])
                });
                // También se puede mostrar un SnackBar informativo si se desea
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Te has unido a la comunidad')),
                );
              },
              child: const Text('Unirme al Grupo'),
            ),
          Expanded(
            child: isMember
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(group.id)
                        .collection('recipes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final recipes = snapshot.data!.docs
                          .map((doc) => Recipe.fromDocument(doc))
                          .toList();

                      if (recipes.isEmpty) {
                        return const Center(
                            child: Text('No hay recetas en este grupo.'));
                      }

                      return ListView.builder(
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return ListTile(
                            title: Text(recipe.title),
                            subtitle: Text(recipe.description ?? ''),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecipeDetailScreen(recipe: recipe),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(
                    child: Text('Únete al grupo para ver las recetas.'),
                  ),
          ),
        ],
      ),
      // Si el usuario es miembro, se muestra el botón para crear receta
      floatingActionButton: isMember
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupRecipeFormScreen(group: group),
                  ),
                );
              },
            )
          : null,
    );
  }
} 