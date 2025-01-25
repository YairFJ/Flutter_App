import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class ConversionCalculatorScreen extends StatefulWidget {
  final List<Ingredient> ingredientes;

  const ConversionCalculatorScreen({
    super.key,
    required this.ingredientes,
  });

  @override
  State<ConversionCalculatorScreen> createState() => _ConversionCalculatorScreenState();
}

class _ConversionCalculatorScreenState extends State<ConversionCalculatorScreen> {
  final TextEditingController _cantidadController = TextEditingController();
  String _unidadOrigen = 'gr';
  String _unidadDestino = 'kg';
  double _resultado = 0.0;

  late List<IngredienteTabla> _ingredientes;

  // Lista fija de unidades disponibles
  final List<String> _unidadesDisponibles = [
    'gr',
    'kg',
    'ml',
    'l',
    'taza',
    'cucharada',
    'cucharadita',
    'unidad',
    'oz',
    'lb',
  ];

  @override
  void initState() {
    super.initState();
    // Convertimos los ingredientes de la receta al formato de la tabla
    _ingredientes = widget.ingredientes.map((ing) => IngredienteTabla(
      nombre: ing.name,
      cantidad: ing.quantity,
      unidad: ing.unit,
    )).toList();
  }

  final Map<String, Map<String, double>> _factoresConversion = {
    'gr': {
      'kg': 0.001,
      'oz': 0.035274,
      'lb': 0.00220462,
    },
    'kg': {
      'gr': 1000,
      'oz': 35.274,
      'lb': 2.20462,
    },
    'ml': {
      'l': 0.001,
      'taza': 0.00416667,
      'cucharada': 0.0666667,
      'cucharadita': 0.2,
    },
    'l': {
      'ml': 1000,
      'taza': 4.16667,
      'cucharada': 66.6667,
      'cucharadita': 200,
    },
    'taza': {
      'ml': 240,
      'l': 0.24,
      'cucharada': 16,
      'cucharadita': 48,
    },
    'cucharada': {
      'ml': 15,
      'l': 0.015,
      'taza': 0.0625,
      'cucharadita': 3,
    },
  };

  void _calcularConversion() {
    if (_cantidadController.text.isEmpty) return;

    try {
      double cantidad = double.parse(_cantidadController.text);
      double factor = _obtenerFactorConversion(_unidadOrigen, _unidadDestino);
      
      setState(() {
        _resultado = cantidad * factor;
      });
    } catch (e) {
      // Manejar error de conversión
    }
  }

  double _obtenerFactorConversion(String desde, String hasta) {
    if (desde == hasta) return 1;

    if (_factoresConversion.containsKey(desde) &&
        _factoresConversion[desde]!.containsKey(hasta)) {
      return _factoresConversion[desde]![hasta]!;
    }

    if (_factoresConversion.containsKey(hasta) &&
        _factoresConversion[hasta]!.containsKey(desde)) {
      return 1 / _factoresConversion[hasta]![desde]!;
    }

    return 1; // Si no hay conversión disponible
  }

  List<String> _obtenerUnidadesCompatibles(String unidad) {
    Set<String> unidades = {unidad};
    
    if (_factoresConversion.containsKey(unidad)) {
      unidades.addAll(_factoresConversion[unidad]!.keys);
    }

    _factoresConversion.forEach((key, value) {
      if (value.containsKey(unidad)) {
        unidades.add(key);
      }
    });

    return unidades.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Conversiones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calculadora existente
            const Text(
              'CALCULADORA DE CONVERSIÓN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            // Tabla de conversión
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                // Encabezados
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'CANTIDAD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'DE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'A',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Fila de entrada
                TableRow(
                  children: [
                    // Cantidad
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) => _calcularConversion(),
                      ),
                    ),
                    // Unidad origen
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: _unidadOrigen,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: _obtenerUnidadesCompatibles(_unidadDestino)
                            .map((String unidad) {
                          return DropdownMenuItem<String>(
                            value: unidad,
                            child: Text(unidad),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _unidadOrigen = value;
                              _calcularConversion();
                            });
                          }
                        },
                      ),
                    ),
                    // Unidad destino
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: _unidadDestino,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: _obtenerUnidadesCompatibles(_unidadOrigen)
                            .map((String unidad) {
                          return DropdownMenuItem<String>(
                            value: unidad,
                            child: Text(unidad),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _unidadDestino = value;
                              _calcularConversion();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Resultado
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Resultado: ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_resultado.toStringAsFixed(3)} $_unidadDestino',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Nueva tabla de ingredientes
            const Text(
              'TABLA DE INGREDIENTES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),  // Ingrediente
                1: FlexColumnWidth(1),  // Cantidad
                2: FlexColumnWidth(1),  // Unidad
              },
              children: [
                // Encabezados
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'INGREDIENTE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'CANTIDAD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'UNIDAD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Filas de ingredientes
                ..._ingredientes.map((ingrediente) => TableRow(
                  children: [
                    // Nombre del ingrediente
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: ingrediente.nombreController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) => ingrediente.nombre = value,
                      ),
                    ),
                    // Cantidad
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: ingrediente.cantidadController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            try {
                              ingrediente.cantidad = double.parse(value);
                            } catch (e) {
                              // Manejar error
                            }
                          }
                        },
                      ),
                    ),
                    // Unidad
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DropdownButtonFormField<String>(
                        value: ingrediente.unidad,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        items: _unidadesDisponibles.map((String unidad) {
                          return DropdownMenuItem<String>(
                            value: unidad,
                            child: Text(unidad),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              ingrediente.unidad = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                )).toList(),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _ingredientes.add(IngredienteTabla(
              nombre: '',
              cantidad: 0.0,
              unidad: 'gr',
            ));
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Agregar ingrediente',
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