import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import 'ingredient_table_widget.dart';
import '../models/ingrediente_tabla.dart';

class AddIngredientDialog extends StatefulWidget {
  final List<IngredienteTabla> ingredientes;
  final List<String> unidades;
  final bool isEnglish;

  const AddIngredientDialog({
    super.key,
    required this.ingredientes,
    required this.unidades,
    this.isEnglish = false,
  });

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final List<IngredienteTabla> _tempIngredients = [];
  final List<IngredienteTabla> _ingredients = [];
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _tempIngredients.addAll(widget.ingredientes);
    _ingredients.addAll(widget.ingredientes);
  }

  @override
  void didUpdateWidget(AddIngredientDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
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
                  Text(
                    isEnglish ? 'Add Ingredients' : 'Agregar Ingredientes',
                    style: const TextStyle(
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
                  isEnglish: isEnglish,
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
                    child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Sincroniza los valores de los controladores con el modelo
                      for (var ing in _tempIngredients) {
                        ing.nombre = ing.nombreController.text.trim();
                        ing.cantidad = double.tryParse(ing.cantidadController.text.replaceAll(',', '.')) ?? 0.0;
                      }
                      
                      // Solo guarda ingredientes que no estaban en la lista original
                      final newIngredients = _tempIngredients.where((newIng) {
                        if (newIng.nombre.trim().isEmpty) return false;
                        return !_ingredients.any((existingIng) =>
                          existingIng.nombre == newIng.nombre &&
                          existingIng.unidad == newIng.unidad);
                      }).toList();

                      if (newIngredients.isNotEmpty) {
                        final ingredientsToReturn = newIngredients.map((ing) {
                          return Ingredient(
                            name: ing.nombre,
                            quantity: ing.cantidad,
                            unit: ing.unidad,
                          );
                        }).toList();

                        Navigator.of(context).pop(ingredientsToReturn);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEnglish 
                                ? 'Please enter at least one new ingredient.'
                                : 'Por favor ingresa al menos un ingrediente nuevo.'
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(isEnglish ? 'Add' : 'Agregar'),
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
