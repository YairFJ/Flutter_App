import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'group_recipe_form_screen.dart';
import '../constants/categories.dart';
import '../utils/pdf_generator.dart';
import '../screens/conversion_calculator_screen.dart';

class GroupRecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final Group group;
  final bool isEnglish;

  const GroupRecipeDetailScreen({
    super.key, 
    required this.recipe,
    required this.group,
    this.isEnglish = false,
  });

  @override
  State<GroupRecipeDetailScreen> createState() => _GroupRecipeDetailScreenState();
}

class _GroupRecipeDetailScreenState extends State<GroupRecipeDetailScreen> {
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  Future<void> _deleteRecipe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Recipe' : 'Eliminar Receta'),
        content: Text(isEnglish ? 'Are you sure you want to delete this recipe?' : '¿Estás seguro de que deseas eliminar esta receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 235, 6, 6),
            ),
            child: Text(isEnglish ? 'Delete' : 'Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.id)
            .collection('recipes')
            .doc(widget.recipe.id)
            .delete();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish ? 'Recipe deleted successfully' : 'Receta eliminada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish ? 'Error deleting recipe' : 'Error al eliminar la receta'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConversionCalculatorScreen(
                        recipe: widget.recipe,
                        isEnglish: isEnglish,
                      ),
                ),
              );
            },
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedRecipe = await Navigator.push<Recipe>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupRecipeFormScreen(
                      recipe: widget.recipe,
                      group: widget.group,
                      isEnglish: isEnglish,
                    ),
                  ),
                );
                if (updatedRecipe != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupRecipeDetailScreen(
                        recipe: updatedRecipe,
                        group: widget.group,
                        isEnglish: isEnglish,
                      ),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRecipe(context),
            ),
          ],
          
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              Text(RecipeCategories.getTranslatedCategory(widget.recipe.category, isEnglish)),
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
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black87,
                            fontFamily:
                                Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isEnglish 
                                ? 'Yield: ${widget.recipe.servingSize} '
                                : 'Rendimiento: ${widget.recipe.servingSize} ',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isEnglish ? 'Ingredients:' : 'Ingredientes:',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(
                              label: Text(
                                isEnglish ? 'Ingredient' : 'Ingrediente',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                isEnglish ? 'Quantity' : 'Cantidad',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                isEnglish ? 'Unit' : 'Unidad',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: widget.recipe.ingredients.map((ingredient) {
                            String formattedQuantity;
                            if (ingredient.quantity % 1 == 0) {
                              formattedQuantity =
                                  ingredient.quantity.toInt().toString();
                            } else {
                              formattedQuantity = ingredient.quantity.toString();
                            }
                            return DataRow(cells: [
                              DataCell(Text(ingredient.name)),
                              DataCell(Text(formattedQuantity)),
                              DataCell(Text(ingredient.unit)),
                            ]);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isEnglish ? 'Steps:' : 'Pasos:',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.recipe.steps.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.recipe.steps[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white 
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 80), // Espacio para el botón flotante
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20.0,
            bottom: 20.0,
            child: ElevatedButton(
              onPressed: () async {
                final pdfBytes = await generateRecipePdf(widget.recipe, isEnglish: isEnglish);
                await Printing.sharePdf(
                  bytes: pdfBytes,
                  filename: '${widget.recipe.title}.pdf',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5CAE9),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share, 
                    size: 16,
                    color: const Color.fromARGB(255, 76, 117, 250),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isEnglish ? 'Share PDF' : 'Compartir PDF',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}