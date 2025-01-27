import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import 'ingredient_table_widget.dart';
import '../models/ingrediente_tabla.dart';

class AddIngredientDialog extends StatefulWidget {
  const AddIngredientDialog({super.key});

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final List<IngredienteTabla> _tempIngredients = <IngredienteTabla>[];

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
                      if (_tempIngredients.every((ing) => ing.isValid())) {
                        final updatedIngredients = _tempIngredients.map((ing) => Ingredient(
                          name: ing.nombre,
                          quantity: double.parse(ing.cantidadController.text),
                          unit: ing.unidad,
                        )).toList();
                        Navigator.of(context).pop(updatedIngredients);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor, complete todos los campos correctamente'),
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