import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';

class FavoriteRecipesScreen extends StatelessWidget {
  final bool isEnglish;
  
  const FavoriteRecipesScreen({super.key, this.isEnglish = false});

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
            SnackBar(
              content: Text(isEnglish ? 'Recipe removed from favorites' : 'Receta eliminada de favoritos'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'Error updating favorites' : 'Error al actualizar favoritos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Center(child: Text(isEnglish ? 'No authenticated user' : 'No hay usuario autenticado'));

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'Favorite Recipes' : 'Recetas Favoritas'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('favoritedBy', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(isEnglish ? 'Error loading recipes' : 'Error al cargar las recetas'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data?.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Recipe.fromMap(data, doc.id);
          }).toList() ?? [];

          if (recipes.isEmpty) {
            return Center(
              child: Text(isEnglish ? 'You don\'t have favorite recipes' : 'No tienes recetas favoritas'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isTablet ? 16 : 8),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final size = MediaQuery.of(context).size;
              final isTablet = size.width > 600;

              return Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromRGBO(28, 28, 34, 1)
                    : Colors.grey[100],
                margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Stack(
                  children: [
                    InkWell(
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
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 16 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 6 : 4),
                            Text(
                              recipe.description ?? '',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 12,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: isTablet ? 18 : 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    SizedBox(width: isTablet ? 6 : 4),
                                    Text(
                                      '${recipe.cookingTime.inMinutes} min',
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Divider(height: isTablet ? 20 : 16),
                            Container(
                              padding: EdgeInsets.all(isTablet ? 12 : 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color.fromRGBO(28, 28, 34, 1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: isTablet ? 18 : 16,
                                    color: const Color(0xFF96B4D8),
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe.creatorName,
                                          style: TextStyle(
                                            fontSize: isTablet ? 15 : 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          recipe.creatorEmail,
                                          style: TextStyle(
                                            fontSize: isTablet ? 13 : 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: isTablet ? 12 : 8,
                      right: isTablet ? 12 : 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.favorite,
                            size: isTablet ? 24 : 20,
                            color: Colors.red,
                          ),
                          onPressed: () => _toggleFavorite(context, recipe),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 