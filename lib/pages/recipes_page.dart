import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../constants/categories.dart';
import '../screens/recipe_detail_screen.dart';
import 'dart:async';

class RecipesPage extends StatefulWidget {
  final bool isEnglish;

  const RecipesPage({super.key, this.isEnglish = false});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool get isEnglish => widget.isEnglish;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isEnglish ? 'Search recipes...' : 'Buscar recetas...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromRGBO(28, 28, 34, 1)
                  : Colors.white,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
            ],
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              if (value.isNotEmpty) {
                // Capitalizar la primera letra
                final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                if (capitalizedValue != value) {
                  _searchController.text = capitalizedValue;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: capitalizedValue.length),
                  );
                }
              }
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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

              final recipes = snapshot.data!.docs.map((doc) {
                return Recipe.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
              }).toList();

              // Filtrar las recetas según la búsqueda
              var filteredRecipes = recipes;
              if (_searchQuery.isNotEmpty) {
                filteredRecipes = recipes.where((recipe) {
                  final description = recipe.description?.toLowerCase() ?? '';
                  final translatedCategory =
                      RecipeCategories.getTranslatedCategory(
                              recipe.category, isEnglish)
                          .toLowerCase();
                  return recipe.title.toLowerCase().contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      translatedCategory.contains(_searchQuery);
                }).toList();
              }

              if (filteredRecipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish
                            ? 'No recipes available'
                            : 'No hay recetas disponibles',
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
                  return _buildCategoryCarousel(
                      category, filteredRecipes, context);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCarousel(
      String category, List<Recipe> recipes, BuildContext context) {
    final categoryRecipes = category == RecipeCategories.sinCategoria
        ? recipes
            .where((recipe) =>
                recipe.category.isEmpty ||
                recipe.category == RecipeCategories.sinCategoria)
            .toList()
        : recipes.where((recipe) => recipe.category == category).toList();

    if (categoryRecipes.isEmpty) return const SizedBox.shrink();

    final translatedCategory =
        RecipeCategories.getTranslatedCategory(category, isEnglish);

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
                    translatedCategory,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${categoryRecipes.length} '
                '${categoryRecipes.length == 1 ? (isEnglish ? 'recipe' : 'receta') : (isEnglish ? 'recipes' : 'recetas')}',
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
              final currentUser = FirebaseAuth.instance.currentUser;
              final isFavorite = currentUser != null && recipe.favoritedBy.contains(currentUser.uid);

              return StatefulBuilder(
                builder: (context, setState) {
                  return SizedBox(
                    width: 180,
                    child: Card(
                      margin: const EdgeInsets.all(4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
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
                                recipe.description ?? '',
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
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 18,
                                      color: isFavorite
                                          ? Colors.red
                                          : const Color.fromARGB(
                                              255, 158, 158, 158),
                                    ),
                                    onPressed: () async {
                                      await _toggleFavorite(context, recipe);
                                    },
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            recipe.creatorName,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).brightness ==
                                                      Brightness.dark
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
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(BuildContext context, Recipe recipe) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish
              ? 'You must log in to save favorites'
              : 'Debes iniciar sesión para guardar favoritos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final recipeRef =
        FirebaseFirestore.instance.collection('recipes').doc(recipe.id);

    try {
      if (recipe.favoritedBy.contains(currentUser.uid)) {
        // Eliminar de favoritos
        await recipeRef.update({
          'favoritedBy': FieldValue.arrayRemove([currentUser.uid])
        });
      } else {
        // Agregar a favoritos
        await recipeRef.update({
          'favoritedBy': FieldValue.arrayUnion([currentUser.uid])
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish
                ? 'Error updating favorites'
                : 'Error al actualizar favoritos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
