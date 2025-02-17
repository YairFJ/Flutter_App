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
    // Recorremos la lista de ingredientes y comprobamos que el nombre no esté vacío.
    bool hayIngredienteVacio = _ingredientes.any((ing) => ing.nombre.trim().isEmpty);
    if (hayIngredienteVacio) {
      // Si existe al menos uno con nombre vacío, se muestra un mensaje de error y no se llama al callback.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pueden guardar ingredientes vacíos. Complete o elimine los campos vacíos.',
          ),
        ),
      );
      return;
    }
    // Si todos tienen nombre, se actualiza la lista.
    widget.onIngredientsChanged(_ingredientes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Encabezados
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800] // Fondo oscuro para modo oscuro
                : Colors.grey[200], // Fondo claro para modo claro
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade600 // Borde más oscuro para modo oscuro
                  : Colors.grey.shade300, // Borde claro para modo claro
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'INGREDIENTE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // Texto claro para modo oscuro
                          : Colors.black, // Texto oscuro para modo claro
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'CANTIDAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // Texto claro para modo oscuro
                          : Colors.black, // Texto oscuro para modo claro
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'UNIDAD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // Texto claro para modo oscuro
                          : Colors.black, // Texto oscuro para modo claro
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
                      // Manejar error de conversión si es necesario.
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