import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ingrediente_tabla.dart';

class IngredientTableWidget extends StatefulWidget {
  final List<IngredienteTabla> ingredientes;
  final Function(List<IngredienteTabla>) onIngredientsChanged;
  final bool showAddButton;
  final bool isEnglish;

  const IngredientTableWidget({
    super.key,
    required this.ingredientes,
    required this.onIngredientsChanged,
    this.showAddButton = true,
    this.isEnglish = false,
  });

  @override
  State<IngredientTableWidget> createState() => _IngredientTableWidgetState();
}

class _IngredientTableWidgetState extends State<IngredientTableWidget> {
  late final List<IngredienteTabla> _ingredientes;

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

  final Map<String, Map<String, String>> _unidadesCompletas = {
    'gr': {'es': 'Gramo', 'en': 'Gram'},
    'kg': {'es': 'Kilogramo', 'en': 'Kilogram'},
    'mg': {'es': 'Miligramos', 'en': 'Milligrams'},
    'ml': {'es': 'Mililitros', 'en': 'Milliliters'},
    'l': {'es': 'Litro', 'en': 'Liter'},
    'cl': {'es': 'Centilitros', 'en': 'Centiliters'},
    'tz': {'es': 'Taza', 'en': 'Cup'},
    'tbsp': {'es': 'Cucharada', 'en': 'Tablespoon'},
    'tsp': {'es': 'Cucharadita', 'en': 'Teaspoon'},
    'oz': {'es': 'Onza', 'en': 'Ounce'},
    'lb': {'es': 'Libra', 'en': 'Pound'},
    'fl oz': {'es': 'Onza líquida', 'en': 'Fluid ounce'},
    'pint': {'es': 'Pinta', 'en': 'Pint'},
    'c-gal': {'es': 'Cuarto galón', 'en': 'Quart'},
    'gal': {'es': 'Galón', 'en': 'Gallon'},
  };

  // Agregar listas de FocusNode para cada campo
  final List<FocusNode> _nombreFocusNodes = [];
  final List<FocusNode> _cantidadFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _ingredientes = widget.ingredientes.toList();
    // Inicializar los FocusNode
    for (var i = 0; i < _ingredientes.length; i++) {
      _nombreFocusNodes.add(FocusNode());
      _cantidadFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final node in _nombreFocusNodes) {
      node.dispose();
    }
    for (final node in _cantidadFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _actualizarIngredientes() {
    bool hayIngredienteVacio =
        _ingredientes.any((ing) => ing.nombre.trim().isEmpty);
    if (hayIngredienteVacio) {
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Cannot save empty ingredients. Complete or remove empty fields.'
                : 'No se pueden guardar ingredientes vacíos. Complete o elimine los campos vacíos.',
          ),
        ),
      );*/
    }
    widget.onIngredientsChanged(_ingredientes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    widget.isEnglish ? 'INGREDIENT' : 'INGREDIENTE',
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    widget.isEnglish ? 'QUANTITY' : 'CANTIDAD',
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
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    widget.isEnglish ? 'UNIT' : 'UNIDAD',
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
              ),
            ],
          ),
        ),

        ..._ingredientes.map((ingrediente) => _buildIngredientRow(ingrediente)),

        if (widget.showAddButton)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _ingredientes.add(IngredienteTabla(
                    nombre: '',
                    cantidad: 0.0,
                    unidad: 'gr',
                    cantidadController: TextEditingController(text: ''),
                    cantidadOriginal: 0.0,
                    unidadOriginal: 'gr',
                  ));
                  // Agregar FocusNodes correspondientes
                  _nombreFocusNodes.add(FocusNode());
                  _cantidadFocusNodes.add(FocusNode());
                  _actualizarIngredientes();
                });
              },
              icon: const Icon(Icons.add),
              label: Text(widget.isEnglish ? 'Manage Ingredients' : 'Gestionar Ingredientes'),
            ),
          ),
      ],
    );
  }

  Widget _buildIngredientRow(IngredienteTabla ingrediente) {
    final idx = _ingredientes.indexOf(ingrediente);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: TextField(
              controller: ingrediente.nombreController,
              focusNode: _nombreFocusNodes[idx],
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
                hintText: widget.isEnglish ? 'Enter ingredient' : 'Ingrese ingrediente',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
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
              onEditingComplete: null,
              onSubmitted: null,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: TextField(
              controller: ingrediente.cantidadController,
              focusNode: _cantidadFocusNodes[idx],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
                hintText: widget.isEnglish ? 'Quantity' : 'Cantidad',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onTap: () {
                if (ingrediente.cantidadController.text == '0,0') {
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
                  } catch (c) {
                    cantidad = 1.0;
                  }
                  ingrediente.cantidad = cantidad;
                },
              onEditingComplete: null,
              onSubmitted: null,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: DropdownButtonFormField<String>(
              value: _unidadesDisponibles.contains(ingrediente.unidad) ? ingrediente.unidad : 'gr',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                isDense: true,
              ),
              items: _unidadesDisponibles.map((String unidad) {
                return DropdownMenuItem<String>(
                  value: unidad,
                  child: Tooltip(
                    message: _unidadesCompletas[unidad]?[widget.isEnglish ? 'en' : 'es'] ?? unidad,
                    child: Text(unidad, style: const TextStyle(fontSize: 13)),
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    ingrediente.unidad = value;
                    _actualizarIngredientes();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Agregar listeners a los FocusNode si no existen
    for (var i = 0; i < _ingredientes.length; i++) {
      if (_nombreFocusNodes[i].hasListeners == false) {
        _nombreFocusNodes[i].addListener(() {
          if (!_nombreFocusNodes[i].hasFocus) {
            // Solo llamar a _actualizarIngredientes() al perder el foco
            // El valor ya se actualizó con onChanged
            _actualizarIngredientes();
          }
        });
      }
      if (_cantidadFocusNodes[i].hasListeners == false) {
        _cantidadFocusNodes[i].addListener(() {
          if (!_cantidadFocusNodes[i].hasFocus) {
            // Solo llamar a _actualizarIngredientes() al perder el foco
            // El valor ya se actualizó con onChanged
            _actualizarIngredientes();
          }
        });
      }
    }
  }
}
