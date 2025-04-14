import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../services/language_service.dart';
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
                      final newIngredients = _tempIngredients.where((newIng) {
                        return !_ingredients.any((existingIng) =>
                            existingIng.nombre == newIng.nombre &&
                            existingIng.unidad == newIng.unidad);
                      }).toList();

                      if (newIngredients.isNotEmpty) {
                        final ingredientsToReturn = newIngredients.map((ing) {
                          return Ingredient(
                            name: ing.nombre,
                            quantity: double.parse(ing.cantidadController.text
                                .replaceAll(',', '.')),
                            unit: ing.unidad,
                          );
                        }).toList();

                        Navigator.of(context).pop(ingredientsToReturn);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEnglish 
                                ? 'This ingredient already exists.'
                                : 'Este ingrediente ya existe.'
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
