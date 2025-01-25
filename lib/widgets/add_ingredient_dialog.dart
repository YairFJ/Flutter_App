import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../utils/measurement_units.dart';

class AddIngredientDialog extends StatefulWidget {
  final Ingredient? initialIngredient;
  
  const AddIngredientDialog({
    super.key, 
    this.initialIngredient,
  });

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late String _selectedUnit;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    
    // Inicializar con valores existentes si hay un ingrediente inicial
    _nameController = TextEditingController(
      text: widget.initialIngredient?.name ?? ''
    );
    _quantityController = TextEditingController(
      text: widget.initialIngredient?.quantity.toString() ?? ''
    );

    // Inicializar categoría y unidad
    if (widget.initialIngredient != null) {
      // Encontrar la categoría que contiene la unidad del ingrediente
      _selectedCategory = MeasurementUnits.categories.entries
          .firstWhere(
            (entry) => entry.value.contains(widget.initialIngredient!.unit),
            orElse: () => MapEntry('Unidades', [widget.initialIngredient!.unit])
          )
          .key;
      _selectedUnit = widget.initialIngredient!.unit;
    } else {
      _selectedCategory = MeasurementUnits.categories.keys.first;
      _selectedUnit = MeasurementUnits.categories[_selectedCategory]!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Ingrediente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          
          // Nombre del ingrediente
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ingrediente',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant),
              hintText: 'Ej: Harina, Azúcar, Huevos',
            ),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Cantidad
          TextFormField(
            controller: _quantityController,
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              hintText: 'Ej: 100, 0.5, 2.5',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Categoría de unidad
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Categoría de medida',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            items: MeasurementUnits.categories.keys.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedCategory = value ?? '';
                _selectedUnit = ''; // Reset unit when category changes
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Unidad de medida
          if (_selectedCategory.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Unidad de medida',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              value: _selectedUnit.isEmpty ? null : _selectedUnit,
              items: MeasurementUnits.categories[_selectedCategory]!.map((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedUnit = value ?? '';
                });
              },
            ),
          
          const SizedBox(height: 24),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Imprimir valores para depuración
            print('Nombre: "${_nameController.text}"');
            print('Cantidad: "${_quantityController.text}"');
            print('Categoría: "$_selectedCategory"');
            print('Unidad: "$_selectedUnit"');

            // Validar nombre (eliminando espacios al inicio y final)
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa el nombre del ingrediente'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validar cantidad
            final quantityText = _quantityController.text.trim();
            if (quantityText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa la cantidad'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validar que la cantidad sea un número válido
            double quantity;
            try {
              // Reemplazar coma por punto para manejar decimales
              quantity = double.parse(quantityText.replaceAll(',', '.'));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa una cantidad válida'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Validar unidad
            if (_selectedUnit.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor selecciona una unidad de medida'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Si todas las validaciones pasan, crear el ingrediente
            final ingredient = Ingredient(
              name: name,
              quantity: quantity,
              unit: _selectedUnit,
            );
            
            print('Ingrediente creado: ${ingredient.toString()}');
            Navigator.pop(context, ingredient);
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
} 