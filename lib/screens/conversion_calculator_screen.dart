import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'add_recipe_screen.dart';

class ConversionCalculatorScreen extends StatefulWidget {
  final Recipe recipe;

  const ConversionCalculatorScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<ConversionCalculatorScreen> createState() =>
      _ConversionCalculatorScreenState();
}

class _ConversionCalculatorScreenState
    extends State<ConversionCalculatorScreen> {
  late final TextEditingController _cantidadController;
  late final TextEditingController _destinoController;
  double _resultado = 1.0;
  double _platosOrigen = 1.0;
  double _platosDestino = 1.0;
  late List<IngredienteTabla> _ingredientesTabla;
  String _unidadOriginal = 'Persona';
  String _unidadDestino = 'Persona';

  // Lista de unidades para RENDIMIENTO
  final List<String> _unidadesRendimiento = [
    'Gramo',
    'Kilogramo',
    'Onza',
    'Libra',
    'Mililitros',
    'Litro', 
    'Porción',
  ];

  // Lista de unidades para la TABLA DE INGREDIENTES
  final List<String> _unidadesIngredientes = [
    'Gramo',
    'Kilogramo',
    'Miligramos',
    'Onza',
    'Libra',
    'Mililitros',
    'Litro',
    'Centilitros',
    'Cucharada',
    'Cucharadita',
    'Taza',
    'Onza liquida',
    'Pinta',
    'Cuarto galon',
    'Galon',
  ];

  // Mapa de conversión de unidades antiguas a nuevas
  final Map<String, String> _convertirUnidadAntigua = {
    'gr': 'Gramo',
    'kg': 'Kilogramo',
    'mg': 'Miligramos',
    'oz': 'Onza',
    'lb': 'Libra',
    'l': 'Litro',
    'ml': 'Mililitros',
    'persona': 'Persona',
    'personas': 'Persona',
    'porcion': 'Porción',
    'porciones': 'Porción',
    'racion': 'Ración',
    'raciones': 'Ración',
    'plato': 'Plato',
    'platos': 'Plato',
    'unidad': 'Unidad',
    'unidades': 'Unidad',
    
  };

  // Mapa de unidades completas a abreviadas
  final Map<String, String> _unidadesAbreviadas = {
    'Gramo': 'gr',
    'Kilogramo': 'kg',
    'Miligramos': 'mg',
    'Onza': 'oz',
    'Libra': 'lb',
    'Mililitros': 'ml',
    'Litro': 'l',
    'Centilitros': 'cl',
    'Cucharada': 'cda',
    'Cucharadita': 'cdta',
    'Taza': 'tz',
    'Onza liquida': 'oz liquida',
    'Pinta': 'pinta',
    'Cuarto galon': 'cuarto galon',
    'Galon': 'galon',
    'Persona': 'pers',
    'Porción': 'porc',
    'Ración': 'rac',
    'Plato': 'plato',
    'Unidad': 'und'
  };

  // Factores de conversión para el rendimiento
  final Map<String, Map<String, double>> _factoresRendimiento = {
    'Gramo': {
      'Kilogramo': 0.001,
      'Onza': 0.035274,
      'Libra': 0.00220462,
      'Mililitros': 1.0,  // Asumiendo densidad de agua (1g = 1ml)
      'Litro': 0.001,     // 1g = 0.001L
      'Porción': 0.004,   // Asumiendo que 250g = 1 porción
    },
    'Kilogramo': {
      'Gramo': 1000,
      'Onza': 35.274,
      'Libra': 2.20462,
      'Mililitros': 1000.0, // 1kg = 1L = 1000ml
      'Litro': 1.0,        // 1kg = 1L (aproximado)
      'Porción': 4.0,      // Asumiendo que 250g = 1 porción
    },
    'Mililitros': {
      'Gramo': 1.0,
      'Kilogramo': 0.001,
      'Litro': 0.001,
      'Porción': 0.004,    // Asumiendo que 250ml = 1 porción
    },
    'Litro': {
      'Mililitros': 1000,
      'Gramo': 1000.0,
      'Kilogramo': 1.0,
      'Porción': 4.0,      // Asumiendo que 250ml = 1 porción
    },
    'Porción': {
      'Gramo': 250.0,      // 1 porción = 250g
      'Kilogramo': 0.25,   // 1 porción = 0.25kg
      'Mililitros': 250.0, // 1 porción = 250ml
      'Litro': 0.25,      // 1 porción = 0.25L
    }
  };

  // Mapa de plurales para las unidades
  final Map<String, String> _unidadesPlural = {
    'Persona': 'Personas',
    'Porción': 'Porciones',
    'Ración': 'Raciones',
    'Plato': 'Platos',
    'Unidad': 'Unidades',
  };

  @override
  void initState() {
    super.initState();
    try {
      print("Serving Size: ${widget.recipe.servingSize}"); // Debug print
      print("Ingredients: ${widget.recipe.ingredients}"); // Debug print

      // Extraer cantidad y unidad del servingSize
      final parts = widget.recipe.servingSize.trim().split(' ');
      if (parts.length >= 2) {
        // Asegurarnos de que la conversión sea a double
        _platosOrigen = double.tryParse(parts[0].replaceAll(',', '.')) ?? 1.0;
        String unidadOriginalTemp = parts[1].toLowerCase();
        _unidadOriginal = _convertirUnidadAntigua[unidadOriginalTemp] ?? 'Persona';
        _unidadDestino = _unidadOriginal;
      } else {
        _unidadOriginal = 'Persona';
        _unidadDestino = 'Persona';
        _platosOrigen = 1.0; // Asegurarnos de que sea double
      }

      // Inicialización segura de controladores
      _cantidadController = TextEditingController(text: _formatearNumero(_platosOrigen));
      _destinoController = TextEditingController(text: _formatearNumero(_platosOrigen));
      _platosDestino = _platosOrigen;

      // Inicialización segura de ingredientes
      if (widget.recipe.ingredients.isNotEmpty) {
        _ingredientesTabla = widget.recipe.ingredients.map((ingrediente) {
          try {
            String unidadOriginal = ingrediente.unit?.toLowerCase() ?? 'gr';
            String unidadConvertida = _convertirUnidadAntigua[unidadOriginal] ?? 'Gramo';
            print("Unidad original: $unidadOriginal, Unidad convertida: $unidadConvertida");

            return IngredienteTabla(
              nombre: ingrediente.name ?? '',
              cantidad: (ingrediente.quantity ?? 0).toDouble(), // Asegurarnos de que sea double
              unidad: unidadConvertida,
            );
          } catch (e) {
            print("Error al convertir ingrediente: $e");
            return IngredienteTabla(
              nombre: '',
              cantidad: 0.0, // Asegurarnos de que sea double
              unidad: 'Gramo',
            );
          }
        }).toList();
      } else {
        _ingredientesTabla = [];
      }

      _calcularConversion();
    } catch (e) {
      print("Error en initState: $e");
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _destinoController.dispose();
    super.dispose();
  }

  void _calcularConversion() {
    try {
      setState(() {
        if (_platosOrigen > 0 && _platosDestino > 0) {
          // Mantenemos el valor en la unidad destino sin convertir de nuevo
          _resultado = _platosDestino;

          // Calculamos el factor de escala basado en las cantidades originales
          double factorEscala = _platosDestino / _platosOrigen;
          if (_unidadDestino != _unidadOriginal) {
            factorEscala = _convertirRendimiento(_platosDestino, _unidadDestino, _unidadOriginal) / _platosOrigen;
          }

          // Actualizamos todos los ingredientes con el factor de escala
          for (var ingrediente in _ingredientesTabla) {
            double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
            ingrediente.cantidad = nuevaCantidad;
            ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
          }
        }
      });
    } catch (e) {
      print("Error en cálculo de conversión: $e");
    }
  }

  void _actualizarCantidadIngrediente(int index, String nuevoValor) {
    if (nuevoValor.trim().endsWith('.')) return;

    try {
      double cantidadNueva = double.parse(nuevoValor.replaceAll(',', '.'));
      final ingredienteModificado = _ingredientesTabla[index];
      
      // Calcular el factor de escala basado en el ingrediente modificado
      double factorEscala = cantidadNueva / ingredienteModificado.cantidadOriginal;
      
      setState(() {
        // Actualizar el ingrediente modificado
        ingredienteModificado.cantidad = cantidadNueva;
        ingredienteModificado.cantidadController.text = _formatearNumero(cantidadNueva);

        // Actualizar todos los demás ingredientes
        for (var i = 0; i < _ingredientesTabla.length; i++) {
          if (i != index) {
            var ingrediente = _ingredientesTabla[i];
            double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
            ingrediente.cantidad = nuevaCantidad;
            ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
          }
        }

        // Actualizar el rendimiento
        _platosDestino = _platosOrigen * factorEscala;
        _destinoController.text = _formatearNumero(_platosDestino);
        _resultado = _platosDestino;
      });
    } catch (e) {
      print("Error al actualizar cantidad: $e");
    }
  }

  String _getTipoUnidad(String unit) {
    if (['gr', 'kg', 'oz', 'lb'].contains(unit)) return 'peso';
    if (['ml', 'l', 'tz', 'cda', 'cdta'].contains(unit)) return 'volumen';
    return 'unidad';
  }

  double _obtenerFactorConversion(String desde, String hasta) {
    if (desde == hasta) return 1;

    if (_factoresRendimiento.containsKey(desde) &&
        _factoresRendimiento[desde]!.containsKey(hasta)) {
      return _factoresRendimiento[desde]![hasta]!;
    }

    if (_factoresRendimiento.containsKey(hasta) &&
        _factoresRendimiento[hasta]!.containsKey(desde)) {
      return 1 / _factoresRendimiento[hasta]![desde]!;
    }

    return 1; // Si no hay conversión disponible
  }

  String _formatResult(double value) {
    String numero = _formatearPlatoDestino(value);
    return numero;
  }

  String _formatearPlatoDestino(double valor) {
    if (valor < 0.1) return "0";

    // Si el valor es muy cercano a un entero (diferencia menor a 0.1)
    if ((valor - valor.roundToDouble()).abs() < 0.1) {
      return valor.round().toString();
    }

    // Para valores decimales, mostrar con dos decimales
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatQuantity(double quantity) {
    // Si el número es entero, mostrar sin decimales
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    // Si tiene decimales, mostrar con 2 decimales
    return quantity.toStringAsFixed(2);
  }

  Future<void> _generarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CALCULADORA DE CONVERSIÓN',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Rendimiento Nuevo: $_platosDestino ${_getUnidadPlural(_unidadDestino, _platosDestino)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'TABLA DE INGREDIENTES',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'INGREDIENTE',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'CANTIDAD',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'UNIDAD',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ..._ingredientesTabla.map((ingrediente) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            ingrediente.nombre,
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _formatQuantity(ingrediente.cantidad),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _unidadesAbreviadas[ingrediente.unidad] ??
                                ingrediente.unidad,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/conversion_receta.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Conversión de Receta',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Conversiones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generarPDF,
            tooltip: 'Generar PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'CALCULADORA DE CONVERSIÓN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const Text(
                  'RENDIMIENTO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            'ORIGINAL',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            'UNIDAD',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            'NUEVO',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _cantidadController,
                              enabled: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(
                                    color: isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.black,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                filled: true,
                                fillColor: isDarkMode ? const Color.fromRGBO(21, 21, 21, 1.0) : Colors.grey[200],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color.fromRGBO(21, 21, 21, 1.0) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _unidadesAbreviadas[_getUnidadPlural(_unidadOriginal, _platosOrigen)] ?? 
                                _getUnidadPlural(_unidadOriginal, _platosOrigen),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 48,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _destinoController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      filled: true,
                                      fillColor: isDarkMode ? const Color.fromRGBO(21, 21, 21, 1.0) : Colors.grey[200],
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        value = '1';
                                      }
                                      setState(() {
                                        _platosDestino = double.tryParse(value.replaceAll(',', '.')) ?? 1.0;
                                        _calcularConversion();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _unidadDestino,
                                    isExpanded: true,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      isDense: true,
                                      filled: true,
                                      fillColor: isDarkMode ? const Color.fromRGBO(21, 21, 21, 1.0) : Colors.grey[200],
                                    ),
                                    icon: Icon(Icons.arrow_drop_down,
                                        size: 20,
                                        color: isDarkMode ? Colors.white : Colors.black),
                                    items: _unidadesRendimiento
                                        .map((String unidad) {
                                      return DropdownMenuItem<String>(
                                        value: unidad,
                                        child: Text(
                                          _unidadesAbreviadas[unidad] ?? unidad,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.white : Colors.black,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setState(() {
                                          String unidadAnterior = _unidadDestino;
                                          _unidadDestino = value;
                                          
                                          // Convertir la cantidad actual a la nueva unidad
                                          if (unidadAnterior != value) {
                                            double cantidadConvertida = _convertirRendimiento(_platosDestino, unidadAnterior, value);
                                            _platosDestino = cantidadConvertida;
                                            _destinoController.text = _formatearNumero(cantidadConvertida);
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
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
                    color: isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDarkMode ? Colors.blueGrey.shade700 : Colors.blue.shade200),
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
                        _formatResult(_resultado),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.lightBlueAccent : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'TABLA DE INGREDIENTES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey[200],
              border: Border.all(
                  color:
                      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'INGREDIENTE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'UNIDAD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._ingredientesTabla.map((ingrediente) => Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                    left: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                    right: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
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
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            isDense: true,
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          controller: ingrediente.cantidadController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            isDense: true,
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.white,
                          ),
                          onChanged: (value) {
                            _actualizarCantidadIngrediente(
                              _ingredientesTabla.indexOf(ingrediente),
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
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: isDarkMode ? Colors.grey.shade400 : Colors.black,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            isDense: true,
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.white,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          items: _unidadesIngredientes.map((String unidad) {
                            return DropdownMenuItem<String>(
                              value: unidad,
                              child: Text(
                                _unidadesAbreviadas[unidad] ?? unidad,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              _actualizarUnidad(
                                _ingredientesTabla.indexOf(ingrediente),
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

  void _actualizarUnidad(int index, String nuevaUnidad) {
    final ingrediente = _ingredientesTabla[index];
    if (ingrediente.unidad == nuevaUnidad) return;

    try {
      setState(() {
        // Convertir la cantidad a la nueva unidad usando la cantidad base
        double nuevaCantidad = IngredienteTabla._convertirDesdeBase(
          ingrediente._cantidadBase,
          nuevaUnidad,
        );

        // Actualizar el ingrediente con los nuevos valores
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.unidad = nuevaUnidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      });
    } catch (e) {
      print("Error al actualizar unidad: $e");
    }
  }

  double _convertirRendimiento(double cantidad, String desde, String hasta) {
    if (desde == hasta) return cantidad;

    // Si tenemos una conversión directa, la usamos
    if (_factoresRendimiento.containsKey(desde) &&
        _factoresRendimiento[desde]!.containsKey(hasta)) {
      return cantidad * _factoresRendimiento[desde]![hasta]!;
    }

    // Si tenemos la conversión inversa, la invertimos
    if (_factoresRendimiento.containsKey(hasta) &&
        _factoresRendimiento[hasta]!.containsKey(desde)) {
      return cantidad / _factoresRendimiento[hasta]![desde]!;
    }

    // Si no hay conversión directa, intentamos convertir a través de una unidad base
    String unidadBase = _determinarUnidadBase(desde);
    if (unidadBase != desde && unidadBase != hasta) {
      // Primero convertimos a la unidad base
      double cantidadBase = _convertirRendimiento(cantidad, desde, unidadBase);
      // Luego convertimos de la unidad base a la unidad destino
      return _convertirRendimiento(cantidadBase, unidadBase, hasta);
    }

    return cantidad; // Si no se puede convertir, retornamos la cantidad original
  }

  String _determinarUnidadBase(String unidad) {
    if (['Gramo', 'Kilogramo', 'Onza', 'Libra'].contains(unidad)) {
      return 'Gramo';
    }
    if (['Mililitros', 'Litro'].contains(unidad)) {
      return 'Mililitros';
    }
    return unidad;
  }

  String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _getUnidadPlural(String unidad, double cantidad) {
    if (cantidad <= 1) return unidad;
    return _unidadesPlural[unidad] ?? '${unidad}s';
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
  double _cantidadBase; // Nueva propiedad para mantener la cantidad en unidad base

  IngredienteTabla({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
  })  : cantidadOriginal = cantidad,
        unidadOriginal = unidad,
        nombreController = TextEditingController(text: nombre),
        cantidadController = TextEditingController(text: _formatearNumero(cantidad)),
        tipoMedida = _determinarTipoMedida(unidad),
        _cantidadBase = _convertirABase(cantidad, unidad); // Inicializar cantidad base

  // Método para convertir a unidad base
  static double _convertirABase(double cantidad, String unidad) {
    final factoresABase = {
      // Peso (base: gramos)
      'Gramo': 1,
      'Kilogramo': 1000,
      'Miligramos': 0.001,
      'Onza': 28.35,
      'Libra': 453.592,
      // Volumen (base: mililitros)
      'Mililitros': 1,
      'Litro': 1000,
      'Centilitros': 10,
      'Taza': 240,
      'Cucharada': 15,
      'Cucharadita': 5,
      'Onza liquida': 29.5735,
      'Pinta': 473.176,
      'Cuarto galon': 946.353,
      'Galon': 3785.41,
    };

    String tipoMedida = _determinarTipoMedida(unidad);
    if (tipoMedida == 'unidad') return cantidad;
    
    return cantidad * (factoresABase[unidad] ?? 1);
  }

  // Método para convertir desde unidad base
  static double _convertirDesdeBase(double cantidadBase, String unidadDestino) {
    final factoresDesdeBase = {
      // Peso (base: gramos)
      'Gramo': 1,
      'Kilogramo': 0.001,
      'Miligramos': 1000,
      'Onza': 0.035274,
      'Libra': 0.00220462,
      // Volumen (base: mililitros)
      'Mililitros': 1,
      'Litro': 0.001,
      'Centilitros': 0.1,
      'Taza': 0.00416667,
      'Cucharada': 0.0666667,
      'Cucharadita': 0.2,
      'Onza liquida': 0.033814,
      'Pinta': 0.00211338,
      'Cuarto galon': 0.00105669,
      'Galon': 0.000264172,
    };

    String tipoMedida = _determinarTipoMedida(unidadDestino);
    if (tipoMedida == 'unidad') return cantidadBase;
    
    return cantidadBase * (factoresDesdeBase[unidadDestino] ?? 1);
  }

  static String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toString();
  }

  static String _determinarTipoMedida(String unidad) {
    if (['Gramo', 'Kilogramo', 'Miligramos', 'Onza', 'Libra'].contains(unidad)) {
      return 'peso';
    }
    if ([
      'Mililitros',
      'Litro',
      'Centilitros',
      'Cucharada',
      'Cucharadita',
      'Taza',
      'Onza liquida',
      'Pinta',
      'Cuarto galon',
      'Galon'
    ].contains(unidad)) {
      return 'volumen';
    }
    return 'unidad';
  }
}
