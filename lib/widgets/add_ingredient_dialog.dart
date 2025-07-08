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
  final List<IngredienteTabla> _ingredientes = [];
  late bool isEnglish;

  // Lista completa de unidades disponibles para ingredientes
  final List<String> _unidadesDisponibles = [
    'gr',
    'kg',
    'mg',
    'oz',
    'lb',
    'ml',
    'l',
    'cl',
    'tbsp',
    'tsp',
    'cup',
    'fl oz',
    'pint',
    'c-gal',
    'gal',
    'un',
  ];

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _ingredientes.addAll(widget.ingredientes);
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

  void _agregarIngrediente() {
    setState(() {
      _ingredientes.add(IngredienteTabla(
        nombre: '',
        cantidad: 0.0,
        unidad: 'gr',
        cantidadController: TextEditingController(text: '0.0'),
        cantidadOriginal: 0.0,
        unidadOriginal: 'gr',
      ));
    });
  }

  void _removeIngrediente(int index) {
    setState(() {
      _ingredientes.removeAt(index);
    });
  }

  void _guardarCambios() {
    // Sincronizar los valores de los controladores con el modelo
    for (var ing in _ingredientes) {
      ing.nombre = ing.nombreController.text.trim();
      ing.cantidad = double.tryParse(ing.cantidadController.text.replaceAll(',', '.')) ?? 0.0;
    }
    
    // Filtrar ingredientes válidos (con nombre no vacío)
    final validIngredients = _ingredientes.where((ing) => ing.nombre.trim().isNotEmpty).toList();

    if (validIngredients.isNotEmpty) {
      // Convertir IngredienteTabla a Ingredient
      final ingredientsToReturn = validIngredients.map((ing) {
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
              ? 'Please enter at least one ingredient.'
              : 'Por favor ingresa al menos un ingrediente.'
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cerrarModal() {
    // Sincronizar los valores de los controladores con el modelo
    for (var ing in _ingredientes) {
      ing.nombre = ing.nombreController.text.trim();
      ing.cantidad = double.tryParse(ing.cantidadController.text.replaceAll(',', '.')) ?? 0.0;
    }
    
    // Filtrar ingredientes válidos (con nombre no vacío)
    final validIngredients = _ingredientes.where((ing) => ing.nombre.trim().isNotEmpty).toList();
    
    // Convertir IngredienteTabla a Ingredient
    final ingredientsToReturn = validIngredients.map((ing) {
      return Ingredient(
        name: ing.nombre,
        quantity: ing.cantidad,
        unit: ing.unidad,
      );
    }).toList();
    
    Navigator.of(context).pop(ingredientsToReturn);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
          maxWidth: MediaQuery.of(context).size.width * 0.99,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEnglish ? 'Manage Ingredients' : 'Gestionar Ingredientes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  // Botón cerrar
                  IconButton(
                    onPressed: () => _cerrarModal(),
                    icon: const Icon(Icons.close, size: 18),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            // Área de contenido
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 420, // Puedes ajustar este valor según el mínimo necesario
                    child: Column(
                      children: [
                        // Títulos de columnas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  isEnglish ? 'INGREDIENT' : 'INGREDIENTE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isEnglish ? 'QUANTITY' : 'CANTIDAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isEnglish ? 'UNIT' : 'UNIDAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Lista de ingredientes
                        Expanded(
                          child: _ingredientes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        isEnglish 
                                            ? 'No ingredients added yet' 
                                            : 'Aún no hay ingredientes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _ingredientes.length,
                                  itemBuilder: (context, index) {
                                    final ingrediente = _ingredientes[index];
                                    return _buildViewModeIngredient(ingrediente, index);
                                  },
                                ),
                        ),
                        const SizedBox(height: 4),
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _agregarIngrediente,
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                  isEnglish ? 'Add Ingredient' : 'Agregar Ingrediente',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _guardarCambios,
                                icon: const Icon(Icons.save, size: 16),
                                label: Text(
                                  isEnglish ? 'Save Changes' : 'Guardar Cambios',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeIngredient(IngredienteTabla ingrediente, int index) {
    // Modo edición - campos editables compactos
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          // Campo nombre - más ancho
          Expanded(
            flex: 3,
            child: TextField(
              controller: ingrediente.nombreController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                isDense: true,
                hintText: isEnglish ? 'Ingredient' : 'Ingrediente',
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  // Capitalizar la primera letra
                  final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                  if (capitalizedValue != value) {
                    ingrediente.nombreController.text = capitalizedValue;
                    ingrediente.nombreController.selection = TextSelection.fromPosition(
                      TextPosition(offset: capitalizedValue.length),
                    );
                  }
                }
                ingrediente.nombre = value;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 2),
          // Campo cantidad - más pequeño
          Expanded(
            flex: 1,
            child: TextField(
              controller: ingrediente.cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                isDense: true,
                hintText: isEnglish ? 'Qty' : 'Cant',
              ),
              onTap: () {
                // Borrar automáticamente el 0.0 al hacer tap
                if (ingrediente.cantidadController.text == '0.0') {
                  setState(() {
                    ingrediente.cantidadController.clear();
                  });
                }
              },
              onChanged: (value) {
                double cantidad = 0.0;
                try {
                  cantidad = double.parse(value.replaceAll(',', '.'));
                  if (cantidad <= 0 || cantidad.isNaN || cantidad.isInfinite) {
                    cantidad = 1.0;
                  }
                } catch (e) {
                  cantidad = 1.0;
                }
                ingrediente.cantidad = cantidad;
              },
            ),
          ),
          const SizedBox(width: 2),
          // Dropdown unidad - más pequeño
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _unidadesDisponibles.contains(ingrediente.unidad) ? ingrediente.unidad : 'gr',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                isDense: true,
              ),
              items: _unidadesDisponibles.map((String unidad) {
                return DropdownMenuItem<String>(
                  value: unidad,
                  child: Text(
                    unidad,
                    style: const TextStyle(fontSize: 14), // Agrandado para mejor legibilidad
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  ingrediente.unidad = value;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
