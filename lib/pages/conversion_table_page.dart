import 'package:flutter/material.dart';

class ConversionTablePage extends StatefulWidget {
  const ConversionTablePage({super.key});

  @override
  State<ConversionTablePage> createState() => _ConversionTablePageState();
}

class _ConversionTablePageState extends State<ConversionTablePage> {
  final TextEditingController _cantidadController = TextEditingController();
  String _unidadOrigen = 'g';
  String _unidadDestino = 'kg';
  double _resultado = 0.0;
  String _categoriaSeleccionada = 'Peso';

  final Map<String, List<String>> _unidadesPorCategoria = {
    'Peso': ['g', 'kg', 'oz', 'lb'],
    'Volumen': ['ml', 'l', 'tz', 'cda', 'cdta'],
    'Temperatura': ['°C', '°F', 'K'],
  };

  final Map<String, Map<String, double>> _factoresConversion = {
    'g': {
      'kg': 0.001,
      'oz': 0.035274,
      'lb': 0.00220462,
    },
    'ml': {
      'l': 0.001,
      'tz': 0.00416667,
      'cda': 0.0666667,
      'cdta': 0.2,
    },
    'l': {
      'ml': 1000,
      'tz': 4.16667,
      'cda': 66.6667,
      'cdta': 200,
    },
    'tz': {
      'ml': 240,
      'l': 0.24,
      'cda': 16,
      'cdta': 48,
    },
    'cda': {
      'ml': 15,
      'l': 0.015,
      'tz': 0.0625,
      'cdta': 3,
    },
  };

  void _calcularConversion() {
    if (_cantidadController.text.isEmpty) return;

    try {
      double cantidad = double.parse(_cantidadController.text);
      
      if (_categoriaSeleccionada == 'Temperatura') {
        setState(() {
          _resultado = _convertirTemperatura(cantidad, _unidadOrigen, _unidadDestino);
        });
      } else {
        double factor = _obtenerFactorConversion(_unidadOrigen, _unidadDestino);
        setState(() {
          _resultado = cantidad * factor;
        });
      }
    } catch (e) {
      // Manejar error de conversión
    }
  }

  double _convertirTemperatura(double valor, String desde, String hasta) {
    // Primero convertir a Celsius como temperatura base
    double celsius;
    switch (desde) {
      case '°C':
        celsius = valor;
        break;
      case '°F':
        celsius = (valor - 32) * 5 / 9;
        break;
      case 'K':
        celsius = valor - 273.15;
        break;
      default:
        return valor;
    }

    // Luego convertir de Celsius a la unidad objetivo
    switch (hasta) {
      case '°C':
        return celsius;
      case '°F':
        return (celsius * 9 / 5) + 32;
      case 'K':
        return celsius + 273.15;
      default:
        return celsius;
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

    return 1;
  }

  void _cambiarCategoria(String categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
      _unidadOrigen = _unidadesPorCategoria[categoria]![0];
      _unidadDestino = _unidadesPorCategoria[categoria]![1];
      _cantidadController.clear();
      _resultado = 0.0;
    });
  }

  String _formatearResultado(double valor) {
    // Si el número es entero (no tiene decimales), mostrar sin decimales
    if (valor == valor.roundToDouble()) {
      return valor.toInt().toString();
    }
    // Si tiene decimales, mostrar hasta 3 decimales
    return valor.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCategoryButton('Peso', Icons.scale),
              _buildCategoryButton('Volumen', Icons.water_drop),
              _buildCategoryButton('Temperatura', Icons.thermostat),
            ],
          ),
          const SizedBox(height: 24),
          Table(
            border: TableBorder.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'CANTIDAD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'DE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        filled: true,
                      ),
                      onChanged: (value) => _calcularConversion(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      value: _unidadOrigen,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        filled: true,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: _unidadesPorCategoria[_categoriaSeleccionada]!
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButtonFormField<String>(
                      value: _unidadDestino,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                        filled: true,
                      ),
                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      items: _unidadesPorCategoria[_categoriaSeleccionada]!
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Resultado: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${_formatearResultado(_resultado)} $_unidadDestino',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String categoria, IconData icono) {
    bool isSelected = _categoriaSeleccionada == categoria;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton.icon(
      icon: Icon(
        icono,
        color: isSelected 
            ? Colors.white 
            : (isDarkMode ? Colors.grey.shade300 : Colors.grey),
      ),
      label: Text(
        categoria,
        style: TextStyle(
          color: isSelected 
              ? Colors.white 
              : (isDarkMode ? Colors.grey.shade300 : Colors.grey),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Colors.blue 
            : (isDarkMode ? Colors.grey.shade800 : Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected 
                ? Colors.blue 
                : (isDarkMode ? Colors.grey.shade600 : Colors.grey),
          ),
        ),
      ),
      onPressed: () => _cambiarCategoria(categoria),
    );
  }
} 

