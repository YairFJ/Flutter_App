import 'package:flutter/material.dart';
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
    'cda',
    'cdta',
    'tz',
    'oz liq',
    'pinta',
    'c-galon',
    'galon',
    'u',
  ];

  final Map<String, Map<String, String>> _unidadesCompletas = {
    'gr': {'es': 'Gramo', 'en': 'Gram'},
    'kg': {'es': 'Kilogramo', 'en': 'Kilogram'},
    'mg': {'es': 'Miligramos', 'en': 'Milligrams'},
    'ml': {'es': 'Mililitros', 'en': 'Milliliters'},
    'l': {'es': 'Litro', 'en': 'Liter'},
    'cl': {'es': 'Centilitros', 'en': 'Centiliters'},
    'tz': {'es': 'Taza', 'en': 'Cup'},
    'cda': {'es': 'Cucharada', 'en': 'Tablespoon'},
    'cdta': {'es': 'Cucharadita', 'en': 'Teaspoon'},
    'oz': {'es': 'Onza', 'en': 'Ounce'},
    'lb': {'es': 'Libra', 'en': 'Pound'},
    'oz liq': {'es': 'Onza líquida', 'en': 'Fluid ounce'},
    'pinta': {'es': 'Pinta', 'en': 'Pint'},
    'c-galon': {'es': 'Cuarto galón', 'en': 'Quart'},
    'galon': {'es': 'Galón', 'en': 'Gallon'},
  };

  @override
  void initState() {
    super.initState();
    _ingredientes = widget.ingredientes.toList();
  }

  void _actualizarIngredientes() {
    bool hayIngredienteVacio =
        _ingredientes.any((ing) => ing.nombre.trim().isEmpty);
    if (hayIngredienteVacio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? 'Cannot save empty ingredients. Complete or remove empty fields.'
                : 'No se pueden guardar ingredientes vacíos. Complete o elimine los campos vacíos.',
          ),
        ),
      );
      return;
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
                    widget.isEnglish ? 'AMOUNT' : 'CANTIDAD',
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
                    cantidadController: TextEditingController(text: '0.0'),
                    cantidadOriginal: 0.0,
                    unidadOriginal: 'gr',
                  ));
                  _actualizarIngredientes();
                });
              },
              icon: const Icon(Icons.add),
              label: Text(widget.isEnglish ? 'Add ingredient' : 'Agregar ingrediente'),
            ),
          ),
      ],
    );
  }

  Widget _buildIngredientRow(IngredienteTabla ingrediente) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextField(
                controller: ingrediente.nombreController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                  hintText: widget.isEnglish ? 'Enter ingredient' : 'Ingrese ingrediente',
                ),
                onChanged: (value) {
                  ingrediente.nombre = value;
                  _actualizarIngredientes();
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextField(
                controller: ingrediente.cantidadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                  hintText: widget.isEnglish ? 'Amount' : 'Cantidad',
                ),
                onTap: () {
                  if (ingrediente.cantidadController.text == '0,0') {
                    setState(() {
                      ingrediente.cantidadController.clear();
                    });
                  }
                },
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    try {
                      ingrediente.cantidad = double.parse(value.replaceAll(',', '.'));
                      _actualizarIngredientes();
                    } catch (e) {
                      // Manejar error de conversión si es necesario
                    }
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: DropdownButtonFormField<String>(
                value: _unidadesDisponibles.contains(ingrediente.unidad) ? ingrediente.unidad : 'Gramo',
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                items: _unidadesDisponibles.map((String unidad) {
                  return DropdownMenuItem<String>(
                    value: unidad,
                    child: Tooltip(
                      message: _unidadesCompletas[unidad]?[widget.isEnglish ? 'en' : 'es'] ?? unidad,
                      child: Text(unidad),
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
      ),
    );
  }
}
