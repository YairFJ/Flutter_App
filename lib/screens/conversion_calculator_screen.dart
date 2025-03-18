import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
  int _platosOrigen = 1;
  int _platosDestino = 1;
  late List<IngredienteTabla> _ingredientesTabla;
  String _unidadOriginal = 'personas';
  String _unidadDestino = 'personas';

  // Lista de unidades para RENDIMIENTO
  final List<String> _unidadesRendimiento = [
    'Gramos',
    'Kilogramo',
    'Oz',
    'Lb',
    'Litros',
    'Ml',
    'Porciones',
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
  };

  // Mapa de conversión de unidades antiguas a nuevas
  final Map<String, String> _convertirUnidadAntigua = {
    'gr': 'Gramos',
    'kg': 'Kilogramo',
    'mg': 'Miligramos',
    'oz': 'Onza',
    'lb': 'Libra',
    'l': 'Litros',
    'ml': 'Mililitros',
    'porciones': 'Porciones'
  };

  // Factores de conversión
  final Map<String, Map<String, double>> _factoresConversion = {
    'Gramos': {
      'Kilogramo': 0.001,
      'Onza': 0.035274,
      'Libra': 0.00220462,
    },
    'Kilogramo': {
      'Gramos': 1000,
      'Onza': 35.274,
      'Libra': 2.20462,
    },
    'Mililitros': {
      'Litro': 0.001,
      'Centilitros': 0.1,
      'Taza': 0.00416667,
      'Cucharada': 0.0666667,
      'Cucharadita': 0.2,
      'Onza liquida': 0.033814,
      'Pinta': 0.00211338,
      'Cuarto galon': 0.00105669,
      'Galon': 0.000264172,
    },
    'Litro': {
      'Mililitros': 1000,
      'Centilitros': 100,
      'Taza': 4.16667,
      'Cucharada': 66.6667,
      'Cucharadita': 200,
      'Onza liquida': 33.814,
      'Pinta': 2.11338,
      'Cuarto galon': 1.05669,
      'Galon': 0.264172,
    },
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
        _platosOrigen = int.tryParse(parts[0]) ?? 1;
        String unidadOriginalTemp = parts[1];
        // Convertir la unidad antigua a la nueva si existe en el mapa
        _unidadOriginal =
            _convertirUnidadAntigua[unidadOriginalTemp] ?? 'Gramos';
        _unidadDestino = _unidadOriginal; // Usar la misma unidad convertida
      }

      // Inicialización segura de controladores
      _cantidadController =
          TextEditingController(text: _platosOrigen.toString());
      _destinoController =
          TextEditingController(text: _platosOrigen.toString());
      _platosDestino = _platosOrigen;

      // Inicialización segura de ingredientes
      if (widget.recipe.ingredients.isNotEmpty) {
        _ingredientesTabla = widget.recipe.ingredients.map((ingrediente) {
          try {
            String unidadOriginal = ingrediente.unit ?? 'Gramos';
            // Convertir la unidad antigua a la nueva si existe en el mapa
            String unidadConvertida =
                _convertirUnidadAntigua[unidadOriginal] ?? 'Gramos';
            print(
                "Unidad original: $unidadOriginal, Unidad convertida: $unidadConvertida"); // Debug

            return IngredienteTabla(
              nombre: ingrediente.name ?? '',
              cantidad: ingrediente.quantity ?? 0,
              unidad: unidadConvertida,
            );
          } catch (e) {
            print("Error al convertir ingrediente: $e");
            return IngredienteTabla(
              nombre: '',
              cantidad: 0,
              unidad: 'Gramos',
            );
          }
        }).toList();
      } else {
        _ingredientesTabla = [];
      }

      _calcularConversion();
    } catch (e) {
      print("Error en initState: $e"); // Debug print
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
        final origen = _platosOrigen;
        final destino = _platosDestino;

        if (origen > 0 && destino > 0) {
          // Convertir la cantidad original y destino a una unidad base (gramos o mililitros)
          double cantidadOriginalBase =
              _convertirUnidad(origen.toDouble(), _unidadOriginal, 'Gramos');
          double cantidadDestinoBase =
              _convertirUnidad(destino.toDouble(), _unidadDestino, 'Gramos');

          // Calcular el factor de escala basado en las cantidades convertidas a la misma unidad
          double factorEscala = cantidadDestinoBase / cantidadOriginalBase;

          _resultado = destino.toDouble();

          // Actualizar la tabla de ingredientes
          _ingredientesTabla = widget.recipe.ingredients.map((ingrediente) {
            try {
              String unidadOriginal = ingrediente.unit ?? 'Gramos';
              String unidadConvertida =
                  _convertirUnidadAntigua[unidadOriginal] ?? 'Gramos';

              // Aplicar el factor de escala a la cantidad original
              double nuevaCantidad = (ingrediente.quantity ?? 0) * factorEscala;

              return IngredienteTabla(
                nombre: ingrediente.name ?? '',
                cantidad: nuevaCantidad,
                unidad: unidadConvertida,
              );
            } catch (e) {
              print("Error al convertir ingrediente: $e");
              return IngredienteTabla(
                nombre: '',
                cantidad: 0,
                unidad: 'Gramos',
              );
            }
          }).toList();
        }
      });
    } catch (e) {
      print("Error en _calcularConversion: $e");
    }
  }

  void _actualizarValor(String value, bool esOrigen) {
    if (value.isEmpty) {
      value = '1';
    }

    try {
      final numero = int.tryParse(value) ?? 1;
      if (numero > 0) {
        if (esOrigen) {
          _platosOrigen = numero;
          _cantidadController.text = numero.toString();
        } else {
          _platosDestino = numero;
          _destinoController.text = numero.toString();
        }
        _calcularConversion();
      }
    } catch (e) {
      // Si hay error, mantener el valor anterior
      if (esOrigen) {
        _cantidadController.text = _platosOrigen.toString();
      } else {
        _destinoController.text = _platosDestino.toString();
      }
    }
  }

  String _getTipoUnidad(String unit) {
    if (['gr', 'kg', 'oz', 'lb'].contains(unit)) return 'peso';
    if (['ml', 'l', 'tz', 'cda', 'cdta'].contains(unit)) return 'volumen';
    return 'unidad';
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

  String _formatResult(double value) {
    String numero = _formatearPlatoDestino(value);
    return numero;
  }

  String _formatearPlatoDestino(double valor) {
    if (valor < 0.1) return "0";

    // Si el valor es muy cercano a un entero (diferencia menor a 0.1)
    if ((valor - valor.round()).abs() < 0.1) {
      return valor.round().toString();
    }

    // Para valores decimales, mostrar con un decimal
    return valor.toStringAsFixed(1).replaceAll('.', ',');
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
                'Rendimiento Original: $_platosOrigen $_unidadOriginal',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Rendimiento Nuevo: $_platosDestino $_unidadDestino',
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
          const Text(
            'CALCULADORA DE CONVERSIÓN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
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
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                      ),
                      children: const [
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
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                filled: true,
                                fillColor: Color(0xFFEEEEEE),
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
                                color: const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _unidadesAbreviadas[_unidadOriginal] ??
                                    _unidadOriginal,
                                style: const TextStyle(fontSize: 16),
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
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      if (value.isEmpty) {
                                        value = '1';
                                      }
                                      setState(() {
                                        _platosDestino =
                                            int.tryParse(value) ?? 1;
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                    icon: const Icon(Icons.arrow_drop_down,
                                        size: 20),
                                    items: _unidadesRendimiento
                                        .map((String unidad) {
                                      return DropdownMenuItem<String>(
                                        value: unidad,
                                        child: Text(
                                          _unidadesAbreviadas[unidad] ?? unidad,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 14),
                                        ),
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
                        _formatResult(_resultado),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
                            border: const OutlineInputBorder(),
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
                            border: const OutlineInputBorder(),
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
                            border: const OutlineInputBorder(),
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

  void _actualizarCantidadIngrediente(int index, String nuevoValor) {
    // Si el input termina en punto, se evita procesarlo
    if (nuevoValor.trim().endsWith('.')) {
      _ingredientesTabla[index].cantidadController.text = nuevoValor;
      return;
    }

    try {
      double cantidadNueva = double.parse(nuevoValor.replaceAll(',', '.'));
      final ingredienteModificado = _ingredientesTabla[index];

      // Actualizar el ingrediente modificado
      setState(() {
        ingredienteModificado.cantidad = cantidadNueva;
        ingredienteModificado.cantidadController.text =
            _formatearNumero(cantidadNueva);
      });
    } catch (e) {
      print("Error al actualizar la cantidad: $e");
    }
  }

  void _actualizarUnidad(int index, String nuevaUnidad) {
    final ingrediente = _ingredientesTabla[index];
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
      });
    } catch (e) {
      // Si hay error en la conversión, restaurar valores originales
      setState(() {
        ingrediente.cantidad = ingrediente.cantidadOriginal;
        ingrediente.unidad = ingrediente.unidadOriginal;
        ingrediente.cantidadController.text =
            _formatearNumero(ingrediente.cantidadOriginal);
      });
    }
  }

  double _convertirUnidad(double cantidad, String desde, String hasta) {
    if (desde == hasta) return cantidad;

    // Definir unidades base por tipo
    final unidadesBase = {
      'peso': 'Gramos',
      'volumen': 'Mililitros',
    };

    // Factores de conversión a unidad base
    final factoresABase = {
      // Peso
      'Gramos': 1,
      'Kilogramo': 1000,
      'Miligramos': 0.001,
      'Onza': 28.35,
      'Libra': 453.592,
      // Volumen
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

    // Obtener tipo de medida
    String tipoMedida = _determinarTipoMedida(desde);
    if (tipoMedida != _determinarTipoMedida(hasta)) {
      // Si las unidades son de diferentes tipos, no se puede convertir
      return cantidad;
    }

    if (tipoMedida == 'unidad') return cantidad;

    // Convertir a unidad base
    double cantidadBase = cantidad * (factoresABase[desde] ?? 1);

    // Convertir de unidad base a unidad destino
    return cantidadBase / (factoresABase[hasta] ?? 1);
  }

  String _determinarTipoMedida(String unidad) {
    final unidadesVolumen = {
      'Mililitros',
      'Litros',
      'Centilitros',
      'Cucharada',
      'Cucharadita',
      'Taza',
      'Onza liquida',
      'Pinta',
      'Cuarto galon',
      'Galon'
    };
    final unidadesPeso = {'Gramos', 'Kilogramo', 'Miligramos', 'Onza', 'Libra'};

    if (unidadesVolumen.contains(unidad)) return 'volumen';
    if (unidadesPeso.contains(unidad)) return 'peso';
    return 'unidad';
  }

  String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
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
  })  : cantidadOriginal = cantidad,
        unidadOriginal = unidad,
        nombreController = TextEditingController(text: nombre),
        cantidadController =
            TextEditingController(text: _formatearNumero(cantidad)),
        tipoMedida = _determinarTipoMedida(unidad);

  static String _formatearNumero(double numero) {
    if (numero == numero.roundToDouble()) {
      return numero.toInt().toString();
    }
    return numero.toString();
  }

  static String _determinarTipoMedida(String unidad) {
    if (['Gramos', 'Kilogramo', 'Miligramos', 'Onza', 'Libra'].contains(unidad)) {
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
