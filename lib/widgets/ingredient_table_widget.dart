import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientTableWidget extends StatefulWidget {
  final List<Ingredient> ingredientes;
  final Function(List<Ingredient>) onIngredientsChanged;
  final bool showAddButton;

  const IngredientTableWidget({
    super.key,
    required this.ingredientes,
    required this.onIngredientsChanged,
    this.showAddButton = true,
  });

  @override
  State<IngredientTableWidget> createState() => _IngredientTableWidgetState();
}

class _IngredientTableWidgetState extends State<IngredientTableWidget> {
  late List<IngredienteTabla> _ingredientes;

  final List<String> _unidadesDisponibles = [
    'g',    // gramos
    'kg',   // kilogramos
    'ml',   // mililitros
    'l',    // litros
    'tz',   // taza
    'cda',  // cucharada
    'cdta', // cucharadita
    'u',    // unidad
    'oz',   // onzas
    'lb',   // libras
  ];

  final Map<String, String> _unidadesCompletas = {
    'g': 'gramos',
    'kg': 'kilogramos',
    'ml': 'mililitros',
    'l': 'litros',
    'tz': 'taza',
    'cda': 'cucharada',
    'cdta': 'cucharadita',
    'u': 'unidad',
    'oz': 'onzas',
    'lb': 'libras',
  };

  @override
  void initState() {
    super.initState();
    _initializeIngredientes();
  }

  void _initializeIngredientes() {
    _ingredientes = widget.ingredientes.map((ing) => IngredienteTabla(
      nombre: ing.name,
      cantidad: ing.quantity,
      unidad: _convertirUnidadAntigua(ing.unit),
    )).toList();
  }

  String _convertirUnidadAntigua(String unidadAntigua) {
    final Map<String, String> conversion = {
      'gr': 'g',
      'kg': 'kg',
      'ml': 'ml',
      'l': 'l',
      'taza': 'tz',
      'cucharada': 'cda',
      'cucharadita': 'cdta',
      'unidad': 'u',
      'oz': 'oz',
      'lb': 'lb',
    };
    return conversion[unidadAntigua] ?? 'g';
  }

  void _actualizarIngredientes() {
    final ingredientesActualizados = _ingredientes.map((ing) => Ingredient(
      name: ing.nombre,
      quantity: ing.cantidad,
      unit: ing.unidad,
    )).toList();
    widget.onIngredientsChanged(ingredientesActualizados);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezados
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'INGREDIENTE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'CANTIDAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'UNIDAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Filas de ingredientes
        ..._ingredientes.map((ingrediente) => _buildIngredientRow(ingrediente)),

        // Botón para agregar ingrediente
        if (widget.showAddButton)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _ingredientes.add(IngredienteTabla(
                    nombre: '',
                    cantidad: 0,
                    unidad: 'g',
                  ));
                  _actualizarIngredientes();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar ingrediente'),
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    try {
                      ingrediente.cantidad = double.parse(value);
                      _actualizarIngredientes();
                    } catch (e) {
                      // Manejar error
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
                value: ingrediente.unidad,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  isDense: true,
                ),
                items: _unidadesDisponibles.map((String unidad) {
                  return DropdownMenuItem<String>(
                    value: unidad,
                    child: Tooltip(
                      message: _unidadesCompletas[unidad] ?? unidad,
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

class IngredienteTabla {
  String nombre;
  double cantidad;
  String unidad;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;

  IngredienteTabla({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
  }) : nombreController = TextEditingController(text: nombre),
       cantidadController = TextEditingController(text: cantidad.toString());
} 