import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConversionTablePage extends StatefulWidget {
  final bool isEnglish;
  final bool showBackButton;
  
  const ConversionTablePage({
    super.key,
    required this.isEnglish,
    this.showBackButton = false,
  });

  @override
  State<ConversionTablePage> createState() => _ConversionTablePageState();
}

class _ConversionTablePageState extends State<ConversionTablePage> {
  final TextEditingController _cantidadController = TextEditingController();
  String _unidadOrigen = 'g';
  String _unidadDestino = 'kg';
  double _resultado = 0.0;
  String _categoriaSeleccionada = 'Peso';
  late bool isEnglish;

  final Map<String, List<String>> _unidadesPorCategoria = {
    'Peso': ['g', 'kg', 'oz', 'lb'],
    'Volumen': ['ml', 'l', 'tz', 'cda', 'cdta'],
    'Temperatura': ['°C', '°F', 'K'],
  };
  
  // Mapeo de nombres de categorías en inglés
  final Map<String, String> _categoryTranslations = {
    'Peso': 'Weight',
    'Volumen': 'Volume',
    'Temperatura': 'Temperature',
  };

  // Mapeo de unidades en inglés
  final Map<String, String> _unitTranslations = {
    'g': 'g',
    'kg': 'kg',
    'oz': 'oz',
    'lb': 'lb',
    'ml': 'ml',
    'l': 'l',
    'tz': 'cup',
    'cda': 'tbsp',
    'cdta': 'tsp',
    '°C': '°C',
    '°F': '°F',
    'K': 'K',
  };
  
  // Obtener nombre de categoría según el idioma seleccionado
  String _getCategoryName(String categoria) {
    return isEnglish ? _categoryTranslations[categoria] ?? categoria : categoria;
  }

  // Obtener nombre de unidad según el idioma seleccionado
  String _getUnitName(String unidad) {
    return isEnglish ? _unitTranslations[unidad] ?? unidad : unidad;
  }

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

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  @override
  void didUpdateWidget(ConversionTablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
  }

  void _calcularConversion() {
    if (_cantidadController.text.isEmpty) {
      setState(() {
        _resultado = 0.0;
      });
      return;
    }

    try {
      double cantidad = double.parse(_cantidadController.text);
      
      if (cantidad < 0) {
        throw Exception('La cantidad no puede ser negativa');
      }
      
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
      setState(() {
        _resultado = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la conversión: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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

    // Conversión de Peso
    if (_esTipoUnidadPeso(desde) && _esTipoUnidadPeso(hasta)) {
      // Primero convertir a gramos
      double cantidadEnGramos;
      switch (desde) {
        case 'g':
          cantidadEnGramos = 1;
          break;
        case 'kg':
          cantidadEnGramos = 1000;
          break;
        case 'oz':
          cantidadEnGramos = 28.3495;
          break;
        case 'lb':
          cantidadEnGramos = 453.592;
          break;
        default:
          cantidadEnGramos = 1;
      }

      // Luego convertir de gramos a la unidad destino
      switch (hasta) {
        case 'g':
          return cantidadEnGramos;
        case 'kg':
          return cantidadEnGramos / 1000;
        case 'oz':
          return cantidadEnGramos / 28.3495;
        case 'lb':
          return cantidadEnGramos / 453.592;
        default:
          return 1;
      }
    }

    // Conversión de Volumen
    if (_esTipoUnidadVolumen(desde) && _esTipoUnidadVolumen(hasta)) {
      // Primero convertir a mililitros
      double cantidadEnMl;
      switch (desde) {
        case 'ml':
          cantidadEnMl = 1;
          break;
        case 'l':
          cantidadEnMl = 1000;
          break;
        case 'tz':
          cantidadEnMl = 240;
          break;
        case 'cda':
          cantidadEnMl = 15;
          break;
        case 'cdta':
          cantidadEnMl = 5;
          break;
        default:
          cantidadEnMl = 1;
      }

      // Luego convertir de mililitros a la unidad destino
      switch (hasta) {
        case 'ml':
          return cantidadEnMl;
        case 'l':
          return cantidadEnMl / 1000;
        case 'tz':
          return cantidadEnMl / 240;
        case 'cda':
          return cantidadEnMl / 15;
        case 'cdta':
          return cantidadEnMl / 5;
        default:
          return 1;
      }
    }

    // Conversión de Temperatura
    if (_categoriaSeleccionada == 'Temperatura') {
      // Primero convertir a Celsius
      double cantidadEnCelsius;
      switch (desde) {
        case '°C':
          cantidadEnCelsius = 1;
          break;
        case '°F':
          cantidadEnCelsius = (1 - 32) * 5 / 9;
          break;
        case 'K':
          cantidadEnCelsius = 1 - 273.15;
          break;
        default:
          cantidadEnCelsius = 1;
      }

      // Luego convertir de Celsius a la unidad destino
      switch (hasta) {
        case '°C':
          return cantidadEnCelsius;
        case '°F':
          return (cantidadEnCelsius * 9 / 5) + 32;
        case 'K':
          return cantidadEnCelsius + 273.15;
        default:
          return 1;
      }
    }

    throw Exception('No se encontró factor de conversión entre $desde y $hasta');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    Widget appBarContent;
    if (widget.showBackButton) {
      appBarContent = Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            isEnglish ? 'Conversion Table' : 'Tabla de conversión',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      );
    } else {
      appBarContent = Text(
        isEnglish ? 'Conversion Table' : 'Tabla de conversión',
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarContent,
        backgroundColor: const Color(0xFF96B4D8),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Wrap(
                spacing: isSmallScreen ? 8.0 : 16.0,
                runSpacing: isSmallScreen ? 8.0 : 16.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildCategoryButton('Peso', Icons.scale),
                  _buildCategoryButton('Volumen', Icons.water_drop),
                  _buildCategoryButton('Temperatura', Icons.thermostat),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
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
                    children: [
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                        child: TextField(
                          controller: _cantidadController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                          decoration: InputDecoration(
                            labelText: isEnglish ? 'Amount' : 'Cantidad',
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 8,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            filled: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                              if (capitalizedValue != value) {
                                _cantidadController.text = capitalizedValue;
                                _cantidadController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: capitalizedValue.length),
                                );
                              }
                            }
                            _calcularConversion();
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                        child: DropdownButtonFormField<String>(
                          value: _unidadOrigen,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 8,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            filled: true,
                          ),
                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: isSmallScreen ? 14 : 16,
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
                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                        child: DropdownButtonFormField<String>(
                          value: _unidadDestino,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 8,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                            filled: true,
                          ),
                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontSize: isSmallScreen ? 14 : 16,
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
              SizedBox(height: isSmallScreen ? 16.0 : 24.0),
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
                      isEnglish ? 'Result: ' : 'Resultado: ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${_formatearResultado(_resultado)} $_unidadDestino',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
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
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String categoria, IconData icono) {
    bool isSelected = _categoriaSeleccionada == categoria;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    final displayName = _getCategoryName(categoria);

    return ElevatedButton.icon(
      icon: Icon(
        icono,
        size: isSmallScreen ? 20 : 24,
        color: isSelected 
            ? Colors.white 
            : (isDarkMode ? Colors.grey.shade300 : Colors.grey),
      ),
      label: Text(
        displayName,
        style: TextStyle(
          fontSize: isSmallScreen ? 12 : 14,
          color: isSelected 
              ? Colors.white 
              : (isDarkMode ? Colors.grey.shade300 : Colors.grey),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Colors.blue 
            : (isDarkMode ? Colors.grey.shade800 : Colors.white),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12,
        ),
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

  bool _esTipoUnidadPeso(String unidad) {
    return ['g', 'kg', 'oz', 'lb'].contains(unidad);
  }

  bool _esTipoUnidadVolumen(String unidad) {
    return ['ml', 'l', 'tz', 'cda', 'cdta'].contains(unidad);
  }
} 

