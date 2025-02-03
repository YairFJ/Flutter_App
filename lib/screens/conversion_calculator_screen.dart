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

  // Mapa de conversión de unidades antiguas a nuevas
  final Map<String, String> _convertirUnidadAntigua = {
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

  // Añade este mapa para las referencias de unidades
  final Map<String, String> _referenciasUnidades = {
    'g': '1 gramo',
    'kg': '1000 gramos',
    'ml': '1 mililitro',
    'l': '1000 mililitros',
    'tz': '240 mililitros',
    'cda': '15 mililitros',
    'cdta': '5 mililitros',
    'oz': '28.35 gramos',
    'lb': '453.59 gramos',
    'u': '1 unidad',
  };

  // Agregar cerca de las otras variables de clase
  final Map<String, List<String>> _unidadesPorTipo = {
    'peso': ['g', 'kg', 'oz', 'lb'],
    'volumen': ['ml', 'l', 'tz', 'cda', 'cdta'],
    'unidad': ['u'],
  };

  @override
  void initState() {
    super.initState();
    // Convertir las unidades antiguas a nuevas al inicializar
    _ingredientes = widget.ingredientes.map((ing) => IngredienteTabla(
      nombre: ing.name,
      cantidad: ing.quantity,
      unidad: _convertirUnidadAntigua[ing.unit] ?? 'g', // Unidad por defecto si no se encuentra
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

  String _formatResult(double value, String unit) {
    if (value == 0) return '0 $unit';
    
    // Si el número es entero, no mostrar decimales
    if (value == value.roundToDouble()) {
      return '${value.toInt()} $unit';
    }
    
    // Si el número es menor que 0.01, mostrar 4 decimales
    if (value.abs() < 0.01) {
      return '${value.toStringAsFixed(4)} $unit';
    }
    
    // Si el número es menor que 1, mostrar 3 decimales
    if (value.abs() < 1) {
      return '${value.toStringAsFixed(3)} $unit';
    }
    
    // Para otros números, mostrar solo 2 decimales
    return '${value.toStringAsFixed(2)} $unit';
  }

  void _actualizarCantidadIngrediente(int index, String nuevoValor) {
    try {
      double nuevaCantidad = double.parse(nuevoValor);
      double cantidadOriginal = _ingredientes[index].cantidadOriginal;
      double porcentajeCambio = (nuevaCantidad - cantidadOriginal) / cantidadOriginal;

      setState(() {
        _ingredientes[index].cantidad = nuevaCantidad;
        
        // Actualizar proporcionalmente los demás ingredientes
        for (var i = 0; i < _ingredientes.length; i++) {
          if (i != index) {
            double nuevaCantidadOtro = _ingredientes[i].cantidadOriginal * (1 + porcentajeCambio);
            _ingredientes[i].cantidad = nuevaCantidadOtro;
            _ingredientes[i].cantidadController.text = _formatearNumero(nuevaCantidadOtro);
          }
        }
      });
    } catch (e) {
      // Manejar error de conversión
    }
  }

  String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _actualizarUnidad(int index, String nuevaUnidad) {
    final ingrediente = _ingredientes[index];
    if (ingrediente.unidad == nuevaUnidad) return;

    try {
      setState(() {
        // Convertir la cantidad a la nueva unidad
        double nuevaCantidad = _convertirUnidad(
          ingrediente.cantidad,
          ingrediente.unidad,
          nuevaUnidad,
        );
        
        // Actualizar el ingrediente con los nuevos valores
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.unidad = nuevaUnidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);

        // No modificar las unidades ni cantidades de los demás ingredientes
        // Solo se actualiza el ingrediente que se está modificando
      });
    } catch (e) {
      // Si hay error en la conversión, restaurar valores originales
      setState(() {
        ingrediente.cantidad = ingrediente.cantidadOriginal;
        ingrediente.unidad = ingrediente.unidadOriginal;
        ingrediente.cantidadController.text = _formatearNumero(ingrediente.cantidadOriginal);
      });
    }
  }

  double _convertirUnidad(double cantidad, String desde, String hasta) {
    if (desde == hasta) return cantidad;

    // Definir unidades base por tipo
    final unidadesBase = {
      'peso': 'g',
      'volumen': 'ml',
    };

    // Obtener tipo de medida y unidad base
    String tipoMedida = _determinarTipoMedida(desde);
    String unidadBase = unidadesBase[tipoMedida] ?? desde;  // Usar la variable

    // Factores de conversión a unidad base
    final factoresABase = {
      // Peso
      'g': 1,
      'kg': 1000,
      'oz': 28.35,
      'lb': 453.592,
      // Volumen
      'ml': 1,
      'l': 1000,
      'tz': 240,
      'cda': 15,
      'cdta': 5,
    };

    // Convertir a unidad base
    double cantidadBase = cantidad * (factoresABase[desde] ?? 1);

    // Convertir de unidad base a unidad destino
    return cantidadBase / (factoresABase[hasta] ?? 1);
  }

  String _determinarTipoMedida(String unidad) {
    final unidadesVolumen = {'ml', 'l', 'tz', 'cda', 'cdta'};
    final unidadesPeso = {'g', 'kg', 'oz', 'lb'};
    
    if (unidadesVolumen.contains(unidad)) return 'volumen';
    if (unidadesPeso.contains(unidad)) return 'peso';
    return 'unidad';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Conversiones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'CALCULADORA DE CONVERSIÓN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // Calculadora existente con padding horizontal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
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
                        _formatResult(_resultado, _unidadDestino),
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
                const Text(
                  'TABLA DE INGREDIENTES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
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
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'INGREDIENTE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'CANTIDAD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'UNIDAD',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filas de ingredientes
          ..._ingredientes.map((ingrediente) => Container(
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
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        isDense: true,
                      ),
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
                        _actualizarCantidadIngrediente(
                          _ingredientes.indexOf(ingrediente),
                          value,
                        );
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
                      items: _unidadesPorTipo[ingrediente.tipoMedida]!.map((String unidad) {
                        return DropdownMenuItem<String>(
                          value: unidad,
                          child: Text(unidad),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          _actualizarUnidad(
                            _ingredientes.indexOf(ingrediente),
                            value,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class IngredienteTabla {
  String nombre;
  double cantidad;
  String unidad;
  String tipoMedida;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;
  final double cantidadOriginal;
  final String unidadOriginal;

  IngredienteTabla({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
  }) : 
    cantidadOriginal = cantidad,
    unidadOriginal = unidad,
    nombreController = TextEditingController(text: nombre),
    cantidadController = TextEditingController(text: _formatearNumero(cantidad)),
    tipoMedida = _determinarTipoMedida(unidad);

  static String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toString();
  }

  static String _determinarTipoMedida(String unidad) {
    if (['g', 'kg', 'oz', 'lb'].contains(unidad)) return 'peso';
    if (['ml', 'l', 'tz', 'cda', 'cdta'].contains(unidad)) return 'volumen';
    return 'unidad';
  }
}
