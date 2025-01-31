import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../constants/categories.dart';
import '../screens/recipe_detail_screen.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
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

        final currentUser = FirebaseAuth.instance.currentUser;
        final recipes = snapshot.data!.docs.map((doc) {
          return Recipe.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).where((recipe) {
          return !recipe.isPrivate || recipe.userId == currentUser?.uid;
        }).toList();

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
            return _buildCategoryCarousel(category, recipes, context);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryCarousel(String category, List<Recipe> recipes, BuildContext context) {
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
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categoryRecipes.length,
            itemBuilder: (context, index) {
              final recipe = categoryRecipes[index];
<<<<<<< HEAD
=======
              final currentUser = FirebaseAuth.instance.currentUser;
              final isFavorite = currentUser != null && recipe.favoritedBy.contains(currentUser.uid);

>>>>>>> main
              return SizedBox(
                width: 180,
                child: Card(
                  margin: const EdgeInsets.all(4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
<<<<<<< HEAD
                  elevation: 4,
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(
                                recipe: recipe,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recipe.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
=======
                  elevation: 3,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recipe.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
>>>>>>> main
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe.cookingTime.inMinutes} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
<<<<<<< HEAD
                              const Spacer(),
                              // Información del usuario usando los datos de la receta
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: Text(
                                      recipe.creatorName.isNotEmpty 
                                          ? recipe.creatorName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      recipe.creatorName.isNotEmpty 
                                          ? recipe.creatorName 
                                          : 'Usuario',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón de favorito
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('favorites')
                                .doc(recipe.id)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final isFavorite = snapshot.hasData && snapshot.data!.exists;
                              
                              return IconButton(
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final userId = FirebaseAuth.instance.currentUser?.uid;
                                  if (userId == null) return;

                                  final favoriteRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('favorites')
                                      .doc(recipe.id);

                                  if (isFavorite) {
                                    await favoriteRef.delete();
                                  } else {
                                    await favoriteRef.set({
                                      'recipeId': recipe.id,
                                      'addedAt': FieldValue.serverTimestamp(),
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
=======
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: isFavorite ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => _toggleFavorite(context, recipe),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.creatorName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        recipe.creatorEmail,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
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
>>>>>>> main
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

<<<<<<< HEAD
  Future<void> createRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Guardar información del usuario si no existe
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'name': user.email?.split('@')[0] ?? 'Usuario',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Crear la receta con la información del usuario
      await FirebaseFirestore.instance
          .collection('recipes')
          .add({
        ...recipe.toMap(),
        'userId': user.uid,
        'creatorName': user.email?.split('@')[0] ?? 'Usuario',
        'creatorEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
=======
  Future<void> _toggleFavorite(BuildContext context, Recipe recipe) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar favoritos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final recipeRef = FirebaseFirestore.instance.collection('recipes').doc(recipe.id);
    
    try {
      if (recipe.favoritedBy.contains(currentUser.uid)) {
        await recipeRef.update({
          'favoritedBy': FieldValue.arrayRemove([currentUser.uid])
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta eliminada de favoritos'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } else {
        await recipeRef.update({
          'favoritedBy': FieldValue.arrayUnion([currentUser.uid])
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta guardada en favoritos'),
              backgroundColor: Colors.green,
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
>>>>>>> main
    }
  }
} 