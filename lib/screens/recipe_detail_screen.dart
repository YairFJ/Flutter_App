import 'package:flutter/material.dart';
import '../models/recipe.dart';
//import '../models/ingredient.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_recipe_screen.dart';
import 'conversion_calculator_screen.dart';
// import '../widgets/conversion_table_dialog.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Future<void> _deleteRecipe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Receta'),
        content: const Text('¿Estás seguro de que deseas eliminar esta receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipe.id)
            .delete();
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta eliminada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar la receta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.recipe.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: isOwner ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedRecipe = await Navigator.push<Recipe>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRecipeScreen(recipe: widget.recipe),
                ),
              );
              if (updatedRecipe != null && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(recipe: updatedRecipe),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteRecipe(context),
          ),
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversionCalculatorScreen(
                    ingredientes: widget.recipe.ingredients,
                  ),
                ),
              );
            },
          ),
        ] : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [/*
            if (widget.recipe.imageUrl != null)
              Image.network(
                widget.recipe.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),*/
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer, size: 20),
                          const SizedBox(width: 4),
                          Text('${widget.recipe.cookingTime.inMinutes} min'),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category, size: 20),
                          const SizedBox(width: 4),
                          Text(widget.recipe.category),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.justify,
                    text: TextSpan(
                      text: widget.recipe.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0.2,
                        wordSpacing: 1.2,
                        color: Colors.black87,
                        fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredientes:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.recipe.ingredients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                widget.recipe.ingredients[index].toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pasos:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.recipe.steps.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                textAlign: TextAlign.justify,
                                text: TextSpan(
                                  text: widget.recipe.steps[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                    wordSpacing: 1.2,
                                    color: Colors.black87,
                                    fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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