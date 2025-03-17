import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import 'ingredient_table_widget.dart';
import '../models/ingrediente_tabla.dart';

class AddIngredientDialog extends StatefulWidget {
  final List<IngredienteTabla> ingredientes;
  final List<String> unidades;

  const AddIngredientDialog({
    Key? key,
    required this.ingredientes,
    required this.unidades,
  }) : super(key: key);

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final List<IngredienteTabla> _tempIngredients = [];
  final List<IngredienteTabla> _ingredients = [];
  final bool _isAdding = false; // Variable para controlar el estado del botón

  @override
  void initState() {
    super.initState();
    _tempIngredients
        .addAll(widget.ingredientes); // Initialize with passed ingredients
    _ingredients
        .addAll(widget.ingredientes); // Initialize the main ingredients list
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agregar Ingredientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(<Ingredient>[]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: IngredientTableWidget(
                  ingredientes: _tempIngredients,
                  onIngredientsChanged: (ingredients) {
                    setState(() {
                      _tempIngredients
                        ..clear()
                        ..addAll(ingredients);
                    });
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(<Ingredient>[]),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Check for duplicates before adding
                      final newIngredients = _tempIngredients.where((newIng) {
                        return !_ingredients.any((existingIng) =>
                            existingIng.nombre == newIng.nombre &&
                            existingIng.unidad == newIng.unidad);
                      }).toList();

                      if (newIngredients.isNotEmpty) {
                        // Convert IngredienteTabla to Ingredient
                        final ingredientsToReturn = newIngredients.map((ing) {
                          return Ingredient(
                            name: ing.nombre,
                            quantity: double.parse(ing.cantidadController.text
                                .replaceAll(',', '.')),
                            unit: ing.unidad,
                          );
                        }).toList();

                        Navigator.of(context).pop(
                            ingredientsToReturn); // Return the correct type
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Este ingrediente ya existe.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Agregar'),
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
