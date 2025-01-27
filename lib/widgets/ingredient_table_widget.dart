import 'package:flutter/material.dart';
import '../models/ingrediente_tabla.dart';

class IngredientTableWidget extends StatefulWidget {
  final List<IngredienteTabla> ingredientes;
  final Function(List<IngredienteTabla>) onIngredientsChanged;
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
  late final List<IngredienteTabla> _ingredientes;

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
    _ingredientes = widget.ingredientes.toList();
  }

  void _actualizarIngredientes() {
    widget.onIngredientsChanged(_ingredientes);
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