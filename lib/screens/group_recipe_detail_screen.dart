import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/group.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_group_recipe_screen.dart';
import 'conversion_calculator_screen.dart';
import 'package:printing/printing.dart';
import '../utils/pdf_generator.dart';

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
  bool get isEnglish => widget.isEnglish;

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

  String _getPluralSuffix(String servingSize) {
    try {
      int size = int.parse(servingSize);
      return size == 1 ? 'porción' : 'porciones';
    } catch (e) {
      return 'porciones';
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
                    builder: (context) => EditGroupRecipeScreen(
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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pdfBytes = await generateRecipePdf(widget.recipe);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${widget.recipe.title}.pdf',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                          'Rendimiento: ${widget.recipe.servingSize} ${_getPluralSuffix(widget.recipe.servingSize)}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Ingredientes:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Ingrediente',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Cantidad',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Unidad',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.recipe.steps[index],
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
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