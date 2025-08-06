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
    final screenSize = MediaQuery.of(context).size;
    
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    
    return Dialog(
      insetPadding: EdgeInsets.all(isUltraWide ? 16.0 : (isLargeTablet ? 12.0 : (isTablet ? 8.0 : 4.0))),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * (isUltraWide ? 0.85 : 0.95),
          maxWidth: MediaQuery.of(context).size.width * (isUltraWide ? 0.98 : 0.99),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header del modal
            Container(
              padding: EdgeInsets.all(isUltraWide ? 20.0 : (isLargeTablet ? 16.0 : (isTablet ? 14.0 : 12.0))),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                  topRight: Radius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).primaryColor,
                    size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                  ),
                  SizedBox(width: isUltraWide ? 16 : (isLargeTablet ? 12 : (isTablet ? 10 : 8))),
                  Expanded(
                    child: Text(
                      isEnglish ? 'Manage Ingredients' : 'Gestionar Ingredientes',
                      style: TextStyle(
                        fontSize: isUltraWide ? 22 : (isLargeTablet ? 20 : (isTablet ? 18 : 16)),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  // Botón cerrar
                  IconButton(
                    onPressed: () => _cerrarModal(),
                    icon: Icon(
                      Icons.close, 
                      size: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))
                    ),
                    padding: EdgeInsets.all(isUltraWide ? 8 : (isLargeTablet ? 6 : (isTablet ? 5 : 4))),
                    constraints: BoxConstraints(
                      minWidth: isUltraWide ? 48 : (isLargeTablet ? 40 : (isTablet ? 36 : 32)),
                      minHeight: isUltraWide ? 48 : (isLargeTablet ? 40 : (isTablet ? 36 : 32)),
                    ),
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
                padding: EdgeInsets.all(isUltraWide ? 8.0 : (isLargeTablet ? 6.0 : (isTablet ? 5.0 : 4.0))),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: isUltraWide ? 1200 : (isLargeTablet ? 800 : (isTablet ? 600 : 420)),
                    child: Column(
                      children: [
                        // Títulos de columnas
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isUltraWide ? 8.0 : (isLargeTablet ? 6.0 : (isTablet ? 5.0 : 4.0)),
                            vertical: isUltraWide ? 12.0 : (isLargeTablet ? 10.0 : (isTablet ? 8.0 : 6.0)),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                              width: isUltraWide ? 2 : (isLargeTablet ? 1.5 : 1),
                            ),
                          ),
                          child: Row(
                                                         children: [
                               Expanded(
                                 flex: isUltraWide ? 5 : (isLargeTablet ? 4 : 3),
                                child: Text(
                                  isEnglish ? 'INGREDIENT' : 'INGREDIENTE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                                                             Expanded(
                                 flex: isUltraWide ? 2 : (isLargeTablet ? 2 : 1),
                                 child: Text(
                                   isEnglish ? 'QUANTITY' : 'CANTIDAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                                                             Expanded(
                                 flex: isUltraWide ? 2 : (isLargeTablet ? 2 : 1),
                                 child: Text(
                                   isEnglish ? 'UNIT' : 'UNIDAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
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
                        SizedBox(height: isUltraWide ? 4 : (isLargeTablet ? 3 : (isTablet ? 2 : 1))),
                        // Lista de ingredientes
                        Expanded(
                          child: _ingredientes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: isUltraWide ? 64 : (isLargeTablet ? 56 : (isTablet ? 48 : 40)),
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: isUltraWide ? 16 : (isLargeTablet ? 12 : (isTablet ? 10 : 8))),
                                      Text(
                                        isEnglish 
                                            ? 'No ingredients added yet' 
                                            : 'Aún no hay ingredientes',
                                        style: TextStyle(
                                          fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
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
                        SizedBox(height: isUltraWide ? 8 : (isLargeTablet ? 6 : (isTablet ? 5 : 4))),
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _agregarIngrediente,
                                icon: Icon(
                                  Icons.add, 
                                  size: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))
                                ),
                                label: Text(
                                  isEnglish ? 'Add Ingredient' : 'Agregar Ingrediente',
                                  style: TextStyle(
                                    fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 13)),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 8)),
                                    horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isUltraWide ? 8 : (isLargeTablet ? 6 : (isTablet ? 5 : 4))),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _guardarCambios,
                                icon: Icon(
                                  Icons.save, 
                                  size: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))
                                ),
                                label: Text(
                                  isEnglish ? 'Save Changes' : 'Guardar Cambios',
                                  style: TextStyle(
                                    fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 13)),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 8)),
                                    horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                                  ),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                                  ),
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
    final screenSize = MediaQuery.of(context).size;
    
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    
    // Modo edición - campos editables compactos
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isUltraWide ? 8.0 : (isLargeTablet ? 6.0 : (isTablet ? 5.0 : 4.0)),
        vertical: isUltraWide ? 4.0 : (isLargeTablet ? 3.0 : (isTablet ? 2.5 : 2.0)),
      ),
               child: Row(
           children: [
             // Campo nombre - más ancho
             Expanded(
               flex: isUltraWide ? 5 : (isLargeTablet ? 4 : 3),
                         child: TextField(
               controller: ingrediente.nombreController,
               style: TextStyle(
                 fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
               ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isUltraWide ? 8 : (isLargeTablet ? 6 : 4)),
                ),
                                 contentPadding: EdgeInsets.symmetric(
                   horizontal: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 10 : 4)),
                   vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 10 : 6)),
                 ),
                isDense: true,
                hintText: isEnglish ? 'Ingredient' : 'Ingrediente',
                hintStyle: TextStyle(
                  fontSize: isUltraWide ? 14 : (isLargeTablet ? 12 : (isTablet ? 11 : 10)),
                ),
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
          SizedBox(width: isUltraWide ? 4 : (isLargeTablet ? 3 : (isTablet ? 2.5 : 2))),
                     // Campo cantidad - más pequeño
           Expanded(
             flex: isUltraWide ? 2 : (isLargeTablet ? 2 : 1),
                         child: TextField(
               controller: ingrediente.cantidadController,
               style: TextStyle(
                 fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
               ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isUltraWide ? 8 : (isLargeTablet ? 6 : 4)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 6 : 2)),
                  vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 10 : 6)),
                ),
                isDense: true,
                hintText: isEnglish ? 'Qty' : 'Cant',
                hintStyle: TextStyle(
                  fontSize: isUltraWide ? 14 : (isLargeTablet ? 12 : (isTablet ? 11 : 10)),
                ),
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
          SizedBox(width: isUltraWide ? 4 : (isLargeTablet ? 3 : (isTablet ? 2.5 : 2))),
                     // Dropdown unidad - más pequeño
           Expanded(
             flex: isUltraWide ? 2 : (isLargeTablet ? 2 : 1),
                         child: DropdownButtonFormField<String>(
               value: _unidadesDisponibles.contains(ingrediente.unidad) ? ingrediente.unidad : 'gr',
               style: TextStyle(
                 fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                 color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
               ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isUltraWide ? 8 : (isLargeTablet ? 6 : 4)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 6 : 2)),
                  vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 10 : 6)),
                ),
                isDense: true,
              ),
              items: _unidadesDisponibles.map((String unidad) {
                                 return DropdownMenuItem<String>(
                   value: unidad,
                   child: Text(
                     unidad,
                     style: TextStyle(
                       fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                       color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                     ),
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
