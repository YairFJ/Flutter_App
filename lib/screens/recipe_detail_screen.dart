import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../constants/categories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_recipe_screen.dart';
import 'conversion_calculator_screen.dart';
import 'package:printing/printing.dart';
import '../utils/pdf_generator.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isEnglish;

  const RecipeDetailScreen({super.key, required this.recipe, this.isEnglish = false});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isEnglish = false;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  @override
  void didUpdateWidget(RecipeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
  }

  Future<void> _deleteRecipe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Delete Recipe' : 'Eliminar Receta'),
        content:
            Text(isEnglish ? 'Are you sure you want to delete this recipe?' : '¿Estás seguro de que deseas eliminar esta receta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 255, 1, 1),
            ),
            child: Text(isEnglish ? 'Delete' : 'Eliminar'),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.recipe.userId;
    final screenSize = MediaQuery.of(context).size;
    
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;

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
                      ConversionCalculatorScreen(recipe: widget.recipe, isEnglish: isEnglish),
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
                    builder: (context) =>
                        EditRecipeScreen(
                          recipe: widget.recipe,
                          isEnglish: isEnglish,
                        ),
                  ),
                );
                if (updatedRecipe != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecipeDetailScreen(
                            recipe: updatedRecipe,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : (isTablet ? 32.0 : (isLargeTablet ? 48.0 : 64.0)),
          vertical: 32.0,
        ),
        child: _buildDetailContent(isDarkMode, isOwner, screenSize),
      ),
    );
  }

  Widget _buildDetailContent(bool isDarkMode, bool isOwner, Size screenSize) {
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de tiempo y categoría
            Wrap(
              spacing: isUltraWide ? 32 : (isLargeTablet ? 24 : (isTablet ? 20 : 16)),
              runSpacing: isUltraWide ? 16 : (isLargeTablet ? 12 : (isTablet ? 10 : 8)),
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer, 
                      size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20))
                    ),
                    SizedBox(width: isUltraWide ? 12 : (isLargeTablet ? 8 : (isTablet ? 6 : 4))),
                    Text(
                      '${widget.recipe.cookingTime.inMinutes} min',
                      style: TextStyle(
                        fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : null)),
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category, 
                      size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20))
                    ),
                    SizedBox(width: isUltraWide ? 12 : (isLargeTablet ? 8 : (isTablet ? 6 : 4))),
                    Text(
                      RecipeCategories.getTranslatedCategory(widget.recipe.category, isEnglish),
                      style: TextStyle(
                        fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : null)),
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: isUltraWide ? 32 : (isLargeTablet ? 28 : (isTablet ? 24 : 20))),
            
            // Descripción
            RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                text: widget.recipe.description,
                style: TextStyle(
                  fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
                  height: 1.6,
                  letterSpacing: 0.3,
                  wordSpacing: 1.5,
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
              ),
            ),
            
            SizedBox(height: isUltraWide ? 40 : (isLargeTablet ? 36 : (isTablet ? 32 : 28))),
            
            // Rendimiento
            Text(
              isEnglish ? 'Yield: ${widget.recipe.servingSize}' : 'Rendimiento: ${widget.recipe.servingSize}',
              style: TextStyle(
                fontSize: isUltraWide ? 22 : (isLargeTablet ? 20 : (isTablet ? 18 : 16)),
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            
            SizedBox(height: isUltraWide ? 40 : (isLargeTablet ? 36 : (isTablet ? 32 : 28))),
            
            // Título de ingredientes
            Text(
              isEnglish ? 'Ingredients:' : 'Ingredientes:',
              style: TextStyle(
                fontSize: isUltraWide ? 26 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            
            SizedBox(height: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))),
            
            // Tabla de ingredientes responsive
            Container(
              width: double.infinity,
              child: DataTable(
                columnSpacing: isUltraWide ? 64 : (isLargeTablet ? 48 : (isTablet ? 32 : 24)),
                horizontalMargin: 0,
                dataRowHeight: isUltraWide ? 72 : (isLargeTablet ? 64 : (isTablet ? 56 : 48)),
                headingRowHeight: isUltraWide ? 64 : (isLargeTablet ? 56 : (isTablet ? 48 : 40)),
                columns: [
                  DataColumn(
                    label: Expanded(
                      child: Text(
                        isEnglish ? 'Ingredient' : 'Ingrediente',
                        style: TextStyle(
                          fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      isEnglish ? 'Quantity' : 'Cantidad',
                      style: TextStyle(
                        fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      isEnglish ? 'Unit' : 'Unidad',
                      style: TextStyle(
                        fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
                rows: widget.recipe.ingredients.map((ingredient) {
                  String formattedQuantity;
                  if (ingredient.quantity % 1 == 0) {
                    formattedQuantity = ingredient.quantity.toInt().toString();
                  } else {
                    formattedQuantity = ingredient.quantity.toString();
                  }
                  return DataRow(cells: [
                    DataCell(
                      Expanded(
                        child: Text(
                          ingredient.name,
                          style: TextStyle(
                            fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      formattedQuantity,
                      style: TextStyle(
                        fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    )),
                    DataCell(Text(
                      ingredient.unit,
                      style: TextStyle(
                        fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    )),
                  ]);
                }).toList(),
              ),
            ),
            
            SizedBox(height: isUltraWide ? 40 : (isLargeTablet ? 36 : (isTablet ? 32 : 28))),
            
            // Título de pasos
            Text(
              isEnglish ? 'Steps:' : 'Pasos:',
              style: TextStyle(
                fontSize: isUltraWide ? 26 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            
            SizedBox(height: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))),
            
            // Lista de pasos
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.recipe.steps.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          right: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12))
                        ),
                        padding: EdgeInsets.all(
                          isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
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
                              fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
                              height: 1.6,
                              letterSpacing: 0.3,
                              wordSpacing: 1.5,
                              color: isDarkMode ? Colors.white : Colors.black,
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
            
            SizedBox(height: isUltraWide ? 140 : (isLargeTablet ? 120 : (isTablet ? 100 : 80))),
          ],
        ),
        
        // Botón de compartir PDF
        Positioned(
          right: isUltraWide ? 48.0 : (isLargeTablet ? 40.0 : (isTablet ? 32.0 : 20.0)),
          bottom: isUltraWide ? 80.0 : (isLargeTablet ? 60.0 : (isTablet ? 40.0 : 30.0)),
          child: ElevatedButton(
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              final userName = currentUser?.displayName ?? 'Usuario';
              final pdfBytes = await generateRecipePdf(
                widget.recipe,
                isEnglish: isEnglish,
                userName: widget.recipe.creatorName,
              );
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: '${widget.recipe.title}.pdf',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB5CAE9),
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              elevation: 2,
              padding: EdgeInsets.symmetric(
                horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)), 
                vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.share, 
                  size: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16)),
                  color: const Color.fromARGB(255, 76, 117, 250),
                ),
                SizedBox(width: isUltraWide ? 12 : (isLargeTablet ? 8 : (isTablet ? 6 : 4))),
                Text(
                  isEnglish ? 'Share PDF' : 'Compartir PDF',
                  style: TextStyle(
                    fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
