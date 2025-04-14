import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class ConversionCalculatorScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isEnglish;

  const ConversionCalculatorScreen({
    super.key,
    required this.recipe,
    this.isEnglish = false,
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
  double _valorOriginalRendimiento = 1.0;
  late bool isEnglish;
  
  // Valores base para conversiones consistentes
  double _valorBaseGramos = 0.0;
  double _valorBaseMililitros = 0.0;
  
  late List<IngredienteTabla> _ingredientesTabla;
  String _unidadOriginal = 'Persona';
  String _unidadDestino = 'Persona';
  String _unidadActual = 'Persona'; // Para mantener la unidad actual

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
      'Porción': 0.004,   // 1g = 0.004 porciones (250g = 1 porción)
      'Miligramos': 1000.0, // 1g = 1000mg
      'Centilitros': 0.1,   // 1g = 0.1cl (asumiendo agua)
      'Cucharada': 0.0666667, // 1g = 0.067 cdas (15g = 1 cda)
      'Cucharadita': 0.2,     // 1g = 0.2 cdtas (5g = 1 cdta)
      'Taza': 0.00416667,     // 1g = 0.004167 tazas (240g = 1 taza)
      'Onza liquida': 0.033814, // 1g = 0.033814 oz líq
      'Pinta': 0.00211338,      // 1g = 0.00211338 pintas
      'Cuarto galon': 0.00105669, // 1g = 0.00105669 cuartos
      'Galon': 0.000264172,       // 1g = 0.000264172 galones
    },
    'Kilogramo': {
      'Gramo': 1000,
      'Onza': 35.274,
      'Libra': 2.20462,
      'Mililitros': 1000.0, // 1kg = 1L = 1000ml
      'Litro': 1.0,        // 1kg = 1L (aproximado)
      'Porción': 4.0,      // 1kg = 4 porciones (250g = 1 porción)
      'Miligramos': 1000000.0, // 1kg = 1,000,000mg
      'Centilitros': 100.0,    // 1kg = 100cl (asumiendo agua)
      'Cucharada': 66.6667,    // 1kg = 66.67 cdas
      'Cucharadita': 200.0,    // 1kg = 200 cdtas
      'Taza': 4.16667,         // 1kg = 4.17 tazas
      'Onza liquida': 33.814,  // 1kg = 33.814 oz líq
      'Pinta': 2.11338,        // 1kg = 2.11338 pintas
      'Cuarto galon': 1.05669, // 1kg = 1.05669 cuartos
      'Galon': 0.264172,       // 1kg = 0.264172 galones
    },
    'Onza': {
      'Gramo': 28.3495,
      'Kilogramo': 0.0283495,
      'Libra': 0.0625, // 1 onza = 1/16 libra
      'Mililitros': 28.3495, // 1oz = 28.35ml (asumiendo agua)
      'Litro': 0.0283495,   // 1oz = 0.028L
      'Porción': 0.113398,  // 1oz = 0.113 porciones
      'Miligramos': 28349.5, // 1oz = 28349.5mg
      'Centilitros': 2.83495, // 1oz = 2.83cl
      'Cucharada': 1.89,     // 1oz = 1.89 cdas
      'Cucharadita': 5.67,   // 1oz = 5.67 cdtas
      'Taza': 0.118123,      // 1oz = 0.118 tazas
      'Onza liquida': 0.96,  // 1oz = 0.96 oz líq (aproximación)
      'Pinta': 0.06,         // 1oz = 0.06 pintas
      'Cuarto galon': 0.03,  // 1oz = 0.03 cuartos
      'Galon': 0.0075,       // 1oz = 0.0075 galones
    },
    'Libra': {
      'Gramo': 453.592,
      'Kilogramo': 0.453592,
      'Onza': 16.0, // 1 libra = 16 onzas
      'Mililitros': 453.592, // 1lb = 453.59ml (asumiendo agua)
      'Litro': 0.453592,     // 1lb = 0.45L
      'Porción': 1.81437,    // 1lb = 1.81 porciones
      'Miligramos': 453592.0, // 1lb = 453,592mg
      'Centilitros': 45.3592, // 1lb = 45.36cl
      'Cucharada': 30.2395,  // 1lb = 30.24 cdas
      'Cucharadita': 90.7184, // 1lb = 90.72 cdtas
      'Taza': 1.88997,        // 1lb = 1.89 tazas
      'Onza liquida': 15.34,  // 1lb = 15.34 oz líq (aproximación)
      'Pinta': 0.959,         // 1lb = 0.959 pintas
      'Cuarto galon': 0.4795, // 1lb = 0.48 cuartos
      'Galon': 0.119875,      // 1lb = 0.12 galones
    },
    'Miligramos': {
      'Gramo': 0.001,
      'Kilogramo': 0.000001,
      'Onza': 0.000035274,
      'Libra': 0.00000220462,
      'Mililitros': 0.001, // 1mg = 0.001ml (asumiendo agua)
      'Litro': 0.000001,   // 1mg = 0.000001L
      'Porción': 0.000004, // 1mg = 0.000004 porciones
      'Centilitros': 0.0001, // 1mg = 0.0001cl
      'Cucharada': 0.0000666667, // 1mg = 0.000067 cdas
      'Cucharadita': 0.0002,     // 1mg = 0.0002 cdtas
      'Taza': 0.00000416667,     // 1mg = 0.0000042 tazas
      'Onza liquida': 0.000033814, // 1mg = 0.000034 oz líq
      'Pinta': 0.00000211338,     // 1mg = 0.0000021 pintas
      'Cuarto galon': 0.00000105669, // 1mg = 0.0000011 cuartos
      'Galon': 0.000000264172,      // 1mg = 0.00000026 galones
    },
    'Mililitros': {
      'Gramo': 1.0,
      'Kilogramo': 0.001,
      'Litro': 0.001,
      'Porción': 0.004,    // 1ml = 0.004 porciones (250ml = 1 porción)
      'Centilitros': 0.1,
      'Cucharada': 0.0666667,
      'Cucharadita': 0.2,
      'Taza': 0.00416667,
      'Onza liquida': 0.033814,
      'Pinta': 0.00211338,
      'Cuarto galon': 0.00105669,
      'Galon': 0.000264172,
      'Onza': 0.035274, // 1ml = 0.035274 oz (asumiendo agua)
      'Libra': 0.00220462, // 1ml = 0.00220462 lb (asumiendo agua)
      'Miligramos': 1000.0, // 1ml = 1000mg (asumiendo agua)
    },
    'Litro': {
      'Mililitros': 1000,
      'Gramo': 1000.0,
      'Kilogramo': 1.0,
      'Porción': 4.0,      // 1L = 4 porciones (250ml = 1 porción)
      'Centilitros': 100,
      'Cucharada': 66.6667,
      'Cucharadita': 200,
      'Taza': 4.16667,
      'Onza liquida': 33.814,
      'Pinta': 2.11338,
      'Cuarto galon': 1.05669,
      'Galon': 0.264172,
      'Onza': 35.274, // 1L = 35.274 oz (asumiendo agua)
      'Libra': 2.20462, // 1L = 2.20462 lb (asumiendo agua)
      'Miligramos': 1000000.0, // 1L = 1,000,000mg (asumiendo agua)
    },
    'Centilitros': {
      'Mililitros': 10,
      'Litro': 0.01,
      'Cucharada': 0.666667,
      'Cucharadita': 2,
      'Taza': 0.0416667,
      'Gramo': 10.0, // 1cl = 10g (asumiendo agua)
      'Kilogramo': 0.01, // 1cl = 0.01kg (asumiendo agua)
      'Onza': 0.35274, // 1cl = 0.35274 oz (asumiendo agua)
      'Libra': 0.0220462, // 1cl = 0.022 lb (asumiendo agua)
      'Porción': 0.04, // 1cl = 0.04 porciones
      'Onza liquida': 0.33814, // 1cl = 0.338 oz líq
      'Pinta': 0.0211338, // 1cl = 0.021 pintas
      'Cuarto galon': 0.0105669, // 1cl = 0.011 cuartos
      'Galon': 0.00264172, // 1cl = 0.0026 galones
      'Miligramos': 10000.0, // 1cl = 10,000mg (asumiendo agua)
    },
    'Cucharada': {
      'Mililitros': 15,
      'Litro': 0.015,
      'Centilitros': 1.5,
      'Cucharadita': 3,
      'Taza': 0.0625,
      'Gramo': 15.0, // 1cda = 15g (asumiendo agua)
      'Kilogramo': 0.015, // 1cda = 0.015kg (asumiendo agua)
      'Onza': 0.5291, // 1cda = 0.5291 oz (asumiendo agua)
      'Libra': 0.0330693, // 1cda = 0.033 lb (asumiendo agua)
      'Porción': 0.06, // 1cda = 0.06 porciones
      'Onza liquida': 0.507211, // 1cda = 0.51 oz líq
      'Pinta': 0.0317007, // 1cda = 0.032 pintas
      'Cuarto galon': 0.0158503, // 1cda = 0.016 cuartos
      'Galon': 0.00396258, // 1cda = 0.004 galones
      'Miligramos': 15000.0, // 1cda = 15,000mg (asumiendo agua)
    },
    'Cucharadita': {
      'Mililitros': 5,
      'Litro': 0.005,
      'Centilitros': 0.5,
      'Cucharada': 0.333333,
      'Taza': 0.0208333,
      'Gramo': 5.0, // 1cdta = 5g (asumiendo agua)
      'Kilogramo': 0.005, // 1cdta = 0.005kg (asumiendo agua)
      'Onza': 0.176367, // 1cdta = 0.176 oz (asumiendo agua)
      'Libra': 0.0110231, // 1cdta = 0.011 lb (asumiendo agua)
      'Porción': 0.02, // 1cdta = 0.02 porciones
      'Onza liquida': 0.16907, // 1cdta = 0.169 oz líq
      'Pinta': 0.0105669, // 1cdta = 0.011 pintas
      'Cuarto galon': 0.00528345, // 1cdta = 0.005 cuartos
      'Galon': 0.00132086, // 1cdta = 0.001 galones
      'Miligramos': 5000.0, // 1cdta = 5,000mg (asumiendo agua)
    },
    'Taza': {
      'Mililitros': 240,
      'Litro': 0.24,
      'Centilitros': 24,
      'Cucharada': 16,
      'Cucharadita': 48,
      'Gramo': 240.0, // 1tz = 240g (asumiendo agua)
      'Kilogramo': 0.24, // 1tz = 0.24kg (asumiendo agua)
      'Onza': 8.46575, // 1tz = 8.466 oz (asumiendo agua)
      'Libra': 0.529109, // 1tz = 0.529 lb (asumiendo agua)
      'Porción': 0.96, // 1tz = 0.96 porciones
      'Onza liquida': 8.11537, // 1tz = 8.115 oz líq
      'Pinta': 0.507211, // 1tz = 0.507 pintas
      'Cuarto galon': 0.253605, // 1tz = 0.254 cuartos
      'Galon': 0.0634013, // 1tz = 0.063 galones
      'Miligramos': 240000.0, // 1tz = 240,000mg (asumiendo agua)
    },
    'Onza liquida': {
      'Mililitros': 29.5735,
      'Litro': 0.0295735,
      'Pinta': 0.0625,
      'Cuarto galon': 0.03125,
      'Galon': 0.0078125,
      'Gramo': 29.5735, // 1 oz líq = 29.57g (asumiendo agua)
      'Kilogramo': 0.0295735, // 1 oz líq = 0.0296kg (asumiendo agua)
      'Onza': 1.043176, // 1 oz líq = 1.04 oz (asumiendo agua)
      'Libra': 0.0651985, // 1 oz líq = 0.065 lb (asumiendo agua)
      'Porción': 0.118294, // 1 oz líq = 0.118 porciones
      'Centilitros': 2.95735, // 1 oz líq = 2.96cl
      'Cucharada': 1.97157, // 1 oz líq = 1.97 cdas
      'Cucharadita': 5.91471, // 1 oz líq = 5.91 cdtas
      'Taza': 0.123223, // 1 oz líq = 0.123 tazas
      'Miligramos': 29573.5, // 1 oz líq = 29,573.5mg (asumiendo agua)
    },
    'Pinta': {
      'Mililitros': 473.176,
      'Litro': 0.473176,
      'Onza liquida': 16,
      'Cuarto galon': 0.5,
      'Galon': 0.125,
      'Gramo': 473.176, // 1 pinta = 473.18g (asumiendo agua)
      'Kilogramo': 0.473176, // 1 pinta = 0.473kg (asumiendo agua)
      'Onza': 16.6908, // 1 pinta = 16.69 oz (asumiendo agua)
      'Libra': 1.04317, // 1 pinta = 1.04 lb (asumiendo agua)
      'Porción': 1.89271, // 1 pinta = 1.89 porciones
      'Centilitros': 47.3176, // 1 pinta = 47.32cl
      'Cucharada': 31.5451, // 1 pinta = 31.55 cdas
      'Cucharadita': 94.6352, // 1 pinta = 94.64 cdtas
      'Taza': 1.97157, // 1 pinta = 1.97 tazas
      'Miligramos': 473176.0, // 1 pinta = 473,176mg (asumiendo agua)
    },
    'Cuarto galon': {
      'Mililitros': 946.353,
      'Litro': 0.946353,
      'Onza liquida': 32,
      'Pinta': 2,
      'Galon': 0.25,
      'Gramo': 946.353, // 1 cuarto = 946.35g (asumiendo agua)
      'Kilogramo': 0.946353, // 1 cuarto = 0.946kg (asumiendo agua)
      'Onza': 33.3815, // 1 cuarto = 33.38 oz (asumiendo agua)
      'Libra': 2.08635, // 1 cuarto = 2.09 lb (asumiendo agua)
      'Porción': 3.78541, // 1 cuarto = 3.79 porciones
      'Centilitros': 94.6353, // 1 cuarto = 94.64cl
      'Cucharada': 63.0902, // 1 cuarto = 63.09 cdas
      'Cucharadita': 189.271, // 1 cuarto = 189.27 cdtas
      'Taza': 3.94314, // 1 cuarto = 3.94 tazas
      'Miligramos': 946353.0, // 1 cuarto = 946,353mg (asumiendo agua)
    },
    'Galon': {
      'Mililitros': 3785.41,
      'Litro': 3.78541,
      'Onza liquida': 128,
      'Pinta': 8,
      'Cuarto galon': 4,
      'Gramo': 3785.41, // 1 galón = 3785.41g (asumiendo agua)
      'Kilogramo': 3.78541, // 1 galón = 3.79kg (asumiendo agua)
      'Onza': 133.526, // 1 galón = 133.53 oz (asumiendo agua)
      'Libra': 8.34538, // 1 galón = 8.35 lb (asumiendo agua)
      'Porción': 15.1416, // 1 galón = 15.14 porciones
      'Centilitros': 378.541, // 1 galón = 378.54cl
      'Cucharada': 252.361, // 1 galón = 252.36 cdas
      'Cucharadita': 757.082, // 1 galón = 757.08 cdtas
      'Taza': 15.7726, // 1 galón = 15.77 tazas
      'Miligramos': 3785410.0, // 1 galón = 3,785,410mg (asumiendo agua)
    },
    'Porción': {
      'Gramo': 250.0,      // 1 porción = 250g
      'Kilogramo': 0.25,   // 1 porción = 0.25kg
      'Mililitros': 250.0, // 1 porción = 250ml
      'Litro': 0.25,      // 1 porción = 0.25L
      'Onza': 8.81849,    // 1 porción = 8.82 oz
      'Libra': 0.551156,  // 1 porción = 0.55 lb
      'Centilitros': 25.0, // 1 porción = 25cl
      'Cucharada': 16.6667, // 1 porción = 16.67 cdas
      'Cucharadita': 50.0,   // 1 porción = 50 cdtas
      'Taza': 1.04167,       // 1 porción = 1.04 tazas
      'Onza liquida': 8.4535, // 1 porción = 8.45 oz líq
      'Pinta': 0.528345,      // 1 porción = 0.53 pintas
      'Cuarto galon': 0.264172, // 1 porción = 0.26 cuartos
      'Galon': 0.066043,        // 1 porción = 0.066 galones
      'Miligramos': 250000.0,   // 1 porción = 250,000mg
    },
  };

  // Mapeo de plurales para las unidades
  final Map<String, String> _unidadesPlural = {
    'Persona': 'Personas',
    'Porción': 'Porciones',
    'Ración': 'Raciones',
    'Plato': 'Platos',
    'Unidad': 'Unidades',
  };

  // Mapeo de unidades en inglés
  final Map<String, String> _unidadesEnIngles = {
    'Gramo': 'Gram',
    'Kilogramo': 'Kilogram',
    'Miligramos': 'Milligrams',
    'Onza': 'Ounce',
    'Libra': 'Pound',
    'Mililitros': 'Milliliters',
    'Litro': 'Liter',
    'Centilitros': 'Centiliters',
    'Cucharada': 'Tablespoon',
    'Cucharadita': 'Teaspoon',
    'Taza': 'Cup',
    'Onza liquida': 'Fluid ounce',
    'Pinta': 'Pint',
    'Cuarto galon': 'Quart',
    'Galon': 'Gallon',
    'Persona': 'Person',
    'Personas': 'People',
    'Porción': 'Serving',
    'Porciones': 'Servings',
    'Ración': 'Portion',
    'Raciones': 'Portions',
    'Plato': 'Plate',
    'Platos': 'Plates',
    'Unidad': 'Unit',
    'Unidades': 'Units'
  };

  // Método para obtener la unidad traducida y formateada
  String _getUnidadFormateada(String unidad, {bool abreviada = false}) {
    String unidadTraducida = isEnglish ? (_unidadesEnIngles[unidad] ?? unidad) : unidad;
    return abreviada ? (_unidadesAbreviadas[unidadTraducida] ?? unidadTraducida) : unidadTraducida;
  }

  // Método para obtener la unidad en plural
  String _getUnidadPlural(String unidad, double cantidad) {
    if (cantidad <= 1) return _getUnidadFormateada(unidad);
    
    if (isEnglish) {
      // En inglés, generalmente se agrega 's' al final
      String unidadTraducida = _unidadesEnIngles[unidad] ?? unidad;
      return '${unidadTraducida}s';
    } else {
      // En español, usamos el mapa de plurales
      return _unidadesPlural[unidad] ?? '${unidad}s';
    }
  }

  @override
  void initState() {
    super.initState();
    isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
    
    // Obtener el valor y unidad de servingSize
    String servingSize = widget.recipe.servingSize;
    final parts = servingSize.split(' ');
    
    // Valor por defecto en caso de que el formato no sea el esperado
    double cantidad = 1.0;
    String unidad = "Porción";
    
    if (parts.length >= 2) {
      cantidad = double.tryParse(parts[0].replaceAll(',', '.')) ?? 1.0;
      unidad = parts[1].toLowerCase();
    }
    
    _platosOrigen = cantidad;
    _valorOriginalRendimiento = _platosOrigen;
    _unidadOriginal = _convertirUnidadAntigua[unidad] ?? 'Persona';
    _unidadDestino = _unidadOriginal;
    _unidadActual = _unidadOriginal;
    
    // Inicializamos valores base de conversión
    if (_esTipoUnidadPeso(_unidadOriginal)) {
      _valorBaseGramos = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'peso');
    } else if (_esTipoUnidadVolumen(_unidadOriginal)) {
      _valorBaseMililitros = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'volumen');
    }

    // Inicialización segura de controladores
    _cantidadController = TextEditingController(text: _formatearNumero(_platosOrigen));
    _destinoController = TextEditingController(text: _formatearNumero(_platosOrigen));
    _platosDestino = _platosOrigen;

    // Inicialización segura de ingredientes
    if (widget.recipe.ingredients.isNotEmpty) {
      _ingredientesTabla = widget.recipe.ingredients.map((ingrediente) {
        try {
          String unidadOriginal = ingrediente.unit.toLowerCase() ?? 'gr';
          String unidadConvertida = _convertirUnidadAntigua[unidadOriginal] ?? 'Gramo';
          print("Unidad original: $unidadOriginal, Unidad convertida: $unidadConvertida");

          return IngredienteTabla(
            nombre: ingrediente.name ?? '',
            cantidad: (ingrediente.quantity ?? 0).toDouble(),
            unidad: unidadConvertida,
          );
        } catch (e) {
          print("Error al convertir ingrediente: $e");
          return IngredienteTabla(
            nombre: '',
            cantidad: 0.0,
            unidad: 'Gramo',
          );
        }
      }).toList();
    } else {
      _ingredientesTabla = [];
    }

    _calcularConversion();
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
          // Calculamos el valor real para comparar correctamente
          double valorOriginalEnBase;
          double valorDestinoEnBase;
          
          // Determinar qué unidad base usar
          String unidadBase = "";
          if (['Gramo', 'Kilogramo', 'Onza', 'Libra'].contains(_unidadOriginal) ||
              ['Gramo', 'Kilogramo', 'Onza', 'Libra'].contains(_unidadDestino)) {
            unidadBase = "Gramo";
            valorOriginalEnBase = _convertirRendimiento(_platosOrigen, _unidadOriginal, unidadBase);
            valorDestinoEnBase = _convertirRendimiento(_platosDestino, _unidadDestino, unidadBase);
          } else if (['Mililitros', 'Litro'].contains(_unidadOriginal) ||
                     ['Mililitros', 'Litro'].contains(_unidadDestino)) {
            unidadBase = "Mililitros";
            valorOriginalEnBase = _convertirRendimiento(_platosOrigen, _unidadOriginal, unidadBase);
            valorDestinoEnBase = _convertirRendimiento(_platosDestino, _unidadDestino, unidadBase);
          } else {
            // Para otro tipo de unidades como porciones
            valorOriginalEnBase = _platosOrigen;
            valorDestinoEnBase = _platosDestino;
          }
          
          // Calculamos el factor de escala basado en los valores en unidad base
          double factorEscala = valorDestinoEnBase / valorOriginalEnBase;
          
          print("DIAGNÓSTICO: Rendimiento original: $_platosOrigen $_unidadOriginal");
          print("DIAGNÓSTICO: Rendimiento nuevo: $_platosDestino $_unidadDestino");
          print("DIAGNÓSTICO: En unidad base ($unidadBase): Original=$valorOriginalEnBase, Nuevo=$valorDestinoEnBase");
          print("DIAGNÓSTICO: Factor de escala: $factorEscala");

          // Actualizamos todos los ingredientes con el factor de escala
          for (var ingrediente in _ingredientesTabla) {
            // Usamos ingrediente.cantidadOriginal para el cálculo
            double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
            
            print("DIAGNÓSTICO: Ingrediente ${ingrediente.nombre}:");
            print("  - Cantidad original guardada: ${ingrediente.cantidadOriginal} ${ingrediente.unidad}");
            print("  - Cantidad actual: ${ingrediente.cantidad} ${ingrediente.unidad}");
            print("  - Nueva cantidad (con factor $factorEscala): $nuevaCantidad ${ingrediente.unidad}");
            
            // Actualizamos el ingrediente
            ingrediente.cantidad = nuevaCantidad;
            // Formateamos el número correctamente
            ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
          }
          
          // Actualizamos los valores en unidades base
          if (['Gramo', 'Kilogramo', 'Onza', 'Libra'].contains(_unidadDestino)) {
            _valorBaseGramos = valorDestinoEnBase;
          } else if (['Mililitros', 'Litro'].contains(_unidadDestino)) {
            _valorBaseMililitros = valorDestinoEnBase;
          }
          
          _unidadActual = _unidadDestino;
          _resultado = _platosDestino;
        }
      });
            } catch (e) {
      print("Error en cálculo de conversión: $e");
    }
  }

  void _actualizarCantidadIngrediente(int index, String nuevoValor) {
    if (nuevoValor.trim().endsWith('.')) return;

    try {
      // Manejo seguro de entrada
      double cantidadNueva = 0.0;
      try {
        cantidadNueva = double.parse(nuevoValor.replaceAll(',', '.'));
      } catch (e) {
        print("Error al convertir '$nuevoValor' a número: $e");
        return;
      }

      if (cantidadNueva <= 0) {
        print("Advertencia: cantidad debe ser mayor que cero");
        cantidadNueva = 0.01; // Valor mínimo para evitar divisiones por cero
      }

      final ingredienteModificado = _ingredientesTabla[index];
      
      // Calculamos el factor de cambio para este ingrediente específico
      double factorCambio = cantidadNueva / ingredienteModificado.cantidad;
      
      print("DIAGNÓSTICO: Actualización manual de ingrediente ${ingredienteModificado.nombre}");
      print("  - Cantidad anterior: ${ingredienteModificado.cantidad} ${ingredienteModificado.unidad}");
      print("  - Nueva cantidad: $cantidadNueva ${ingredienteModificado.unidad}");
      print("  - Factor de cambio: $factorCambio");
      
      setState(() {
        // Actualizamos el ingrediente modificado
        ingredienteModificado.cantidad = cantidadNueva;
        ingredienteModificado.cantidadController.text = _formatearNumero(cantidadNueva);
        
        // IMPORTANTE: Actualizamos también la cantidad original para futuros cálculos
        ingredienteModificado.cantidadOriginal = cantidadNueva;

        // Actualizar todos los demás ingredientes con el mismo factor
        for (var i = 0; i < _ingredientesTabla.length; i++) {
          if (i != index) {
            var ingrediente = _ingredientesTabla[i];
            double nuevaCantidadIngrediente = ingrediente.cantidad * factorCambio;
            
            ingrediente.cantidad = nuevaCantidadIngrediente;
            // Actualizamos también la cantidad original para mantener la referencia
            ingrediente.cantidadOriginal = nuevaCantidadIngrediente;
            ingrediente.cantidadController.text = _formatearNumero(nuevaCantidadIngrediente);
            
            print("  - Actualizado: ${ingrediente.nombre} de ${ingrediente.cantidad / factorCambio} a $nuevaCantidadIngrediente ${ingrediente.unidad}");
          }
        }

        // Actualizar solo el rendimiento nuevo con el mismo factor, manteniendo el original fijo
        double nuevoRendimiento = _platosDestino * factorCambio;
        _platosDestino = nuevoRendimiento;
        // NO actualizamos _platosOrigen para mantenerlo como referencia original
        _destinoController.text = _formatearNumero(nuevoRendimiento);
        _resultado = nuevoRendimiento;
        
        print("  - Rendimiento nuevo actualizado de ${_platosDestino / factorCambio} a $nuevoRendimiento $_unidadDestino");
        print("  - Rendimiento original mantenido en: $_platosOrigen $_unidadOriginal");
      });
    } catch (e) {
      print("Error al actualizar cantidad: $e");
    }
  }

  // Método para validar conversiones seguras
  bool _esConversionValida(String desde, String hasta) {
    // Comprueba si hay un camino directo o indirecto para convertir entre estas unidades
    if (desde == hasta) return true;
    
    if (_factoresRendimiento.containsKey(desde) && _factoresRendimiento[desde]!.containsKey(hasta)) {
      return true; // Conversión directa disponible
    }
    
    if (_factoresRendimiento.containsKey(hasta) && _factoresRendimiento[hasta]!.containsKey(desde)) {
      return true; // Conversión inversa disponible
    }
    
    // Verifiquemos si podemos convertir a través de una unidad base
    String unidadBase = "";
    if (['Gramo', 'Kilogramo', 'Onza', 'Libra', 'Miligramos'].contains(desde) ||
        ['Gramo', 'Kilogramo', 'Onza', 'Libra', 'Miligramos'].contains(hasta)) {
      unidadBase = 'Gramo';
    } else if (['Mililitros', 'Litro', 'Centilitros', 'Cucharada', 'Cucharadita', 
                'Taza', 'Onza liquida', 'Pinta', 'Cuarto galon', 'Galon'].contains(desde) ||
               ['Mililitros', 'Litro', 'Centilitros', 'Cucharada', 'Cucharadita',
                'Taza', 'Onza liquida', 'Pinta', 'Cuarto galon', 'Galon'].contains(hasta)) {
      unidadBase = 'Mililitros';
        } else {
      return false; // No podemos determinar una unidad base común
    }
    
    // Comprobamos si podemos convertir desde y hacia la unidad base
    bool desdeABase = (_factoresRendimiento.containsKey(desde) && _factoresRendimiento[desde]!.containsKey(unidadBase)) ||
                       (_factoresRendimiento.containsKey(unidadBase) && _factoresRendimiento[unidadBase]!.containsKey(desde));
    
    bool baseAHasta = (_factoresRendimiento.containsKey(unidadBase) && _factoresRendimiento[unidadBase]!.containsKey(hasta)) ||
                       (_factoresRendimiento.containsKey(hasta) && _factoresRendimiento[hasta]!.containsKey(unidadBase));
    
    return desdeABase && baseAHasta;
  }

  void _actualizarUnidad(int index, String nuevaUnidad) {
    final ingrediente = _ingredientesTabla[index];
    if (ingrediente.unidad == nuevaUnidad) return;

    try {
      setState(() {
        // Convertir la cantidad ACTUAL a la nueva unidad usando conversiones directas
        double nuevaCantidad;
        
        // CONVERSIONES DIRECTAS PARA INGREDIENTES
        // DE PESO A PESO
        if (ingrediente.unidad == "Gramo" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad / 1000.0;
        } 
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Gramo") {
          nuevaCantidad = ingrediente.cantidad * 1000.0;
        }
        else if (ingrediente.unidad == "Gramo" && nuevaUnidad == "Onza") {
          nuevaCantidad = ingrediente.cantidad / 28.3495;
        }
        else if (ingrediente.unidad == "Onza" && nuevaUnidad == "Gramo") {
          nuevaCantidad = ingrediente.cantidad * 28.3495;
        }
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Onza") {
          nuevaCantidad = ingrediente.cantidad * 35.274;
        }
        else if (ingrediente.unidad == "Onza" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad / 35.274;
        }
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Libra") {
          nuevaCantidad = ingrediente.cantidad * 2.20462;
        }
        else if (ingrediente.unidad == "Libra" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad / 2.20462;
        }
        else if (ingrediente.unidad == "Gramo" && nuevaUnidad == "Libra") {
          nuevaCantidad = ingrediente.cantidad / 453.592;
        }
        else if (ingrediente.unidad == "Libra" && nuevaUnidad == "Gramo") {
          nuevaCantidad = ingrediente.cantidad * 453.592;
        }
        else if (ingrediente.unidad == "Onza" && nuevaUnidad == "Libra") {
          nuevaCantidad = ingrediente.cantidad / 16.0;
        }
        else if (ingrediente.unidad == "Libra" && nuevaUnidad == "Onza") {
          nuevaCantidad = ingrediente.cantidad * 16.0;
        }
        else if (ingrediente.unidad == "Miligramos" && nuevaUnidad == "Gramo") {
          nuevaCantidad = ingrediente.cantidad / 1000.0;
        }
        else if (ingrediente.unidad == "Gramo" && nuevaUnidad == "Miligramos") {
          nuevaCantidad = ingrediente.cantidad * 1000.0;
        }
        else if (ingrediente.unidad == "Miligramos" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad / 1000000.0;
        }
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Miligramos") {
          nuevaCantidad = ingrediente.cantidad * 1000000.0;
        }
        else if (ingrediente.unidad == "Miligramos" && nuevaUnidad == "Onza") {
          nuevaCantidad = ingrediente.cantidad / 28349.5;
        }
        else if (ingrediente.unidad == "Onza" && nuevaUnidad == "Miligramos") {
          nuevaCantidad = ingrediente.cantidad * 28349.5;
        }
        else if (ingrediente.unidad == "Miligramos" && nuevaUnidad == "Libra") {
          nuevaCantidad = ingrediente.cantidad / 453592.0;
        }
        else if (ingrediente.unidad == "Libra" && nuevaUnidad == "Miligramos") {
          nuevaCantidad = ingrediente.cantidad * 453592.0;
        }
        
        // DE VOLUMEN A VOLUMEN
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad / 1000.0;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 1000.0;
        }
        else if (ingrediente.unidad == "Centilitros" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 10.0;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Centilitros") {
          nuevaCantidad = ingrediente.cantidad / 10.0;
        }
        else if (ingrediente.unidad == "Centilitros" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad / 100.0;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Centilitros") {
          nuevaCantidad = ingrediente.cantidad * 100.0;
        }
        else if (ingrediente.unidad == "Cucharada" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 15.0;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Cucharada") {
          nuevaCantidad = ingrediente.cantidad / 15.0;
        }
        else if (ingrediente.unidad == "Cucharadita" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 5.0;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Cucharadita") {
          nuevaCantidad = ingrediente.cantidad / 5.0;
        }
        else if (ingrediente.unidad == "Taza" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 240.0;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Taza") {
          nuevaCantidad = ingrediente.cantidad / 240.0;
        }
        else if (ingrediente.unidad == "Onza liquida" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 29.5735;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Onza liquida") {
          nuevaCantidad = ingrediente.cantidad / 29.5735;
        }
        else if (ingrediente.unidad == "Onza liquida" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad * 0.0295735;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Onza liquida") {
          nuevaCantidad = ingrediente.cantidad * 33.814;
        }
        else if (ingrediente.unidad == "Pinta" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 473.176;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Pinta") {
          nuevaCantidad = ingrediente.cantidad / 473.176;
        }
        else if (ingrediente.unidad == "Pinta" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad * 0.473176;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Pinta") {
          nuevaCantidad = ingrediente.cantidad * 2.11338;
        }
        else if (ingrediente.unidad == "Cuarto galon" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 946.353;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Cuarto galon") {
          nuevaCantidad = ingrediente.cantidad / 946.353;
        }
        else if (ingrediente.unidad == "Cuarto galon" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad * 0.946353;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Cuarto galon") {
          nuevaCantidad = ingrediente.cantidad * 1.05669;
        }
        else if (ingrediente.unidad == "Galon" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 3785.41;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Galon") {
          nuevaCantidad = ingrediente.cantidad / 3785.41;
        }
        else if (ingrediente.unidad == "Galon" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad * 3.78541;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Galon") {
          nuevaCantidad = ingrediente.cantidad * 0.264172;
        }
        
        // CONVERSIONES ENTRE TAZAS, CUCHARADAS Y CUCHARADITAS
        else if (ingrediente.unidad == "Taza" && nuevaUnidad == "Cucharada") {
          nuevaCantidad = ingrediente.cantidad * 16.0;
        }
        else if (ingrediente.unidad == "Cucharada" && nuevaUnidad == "Taza") {
          nuevaCantidad = ingrediente.cantidad / 16.0;
        }
        else if (ingrediente.unidad == "Taza" && nuevaUnidad == "Cucharadita") {
          nuevaCantidad = ingrediente.cantidad * 48.0;
        }
        else if (ingrediente.unidad == "Cucharadita" && nuevaUnidad == "Taza") {
          nuevaCantidad = ingrediente.cantidad / 48.0;
        }
        else if (ingrediente.unidad == "Cucharada" && nuevaUnidad == "Cucharadita") {
          nuevaCantidad = ingrediente.cantidad * 3.0;
        }
        else if (ingrediente.unidad == "Cucharadita" && nuevaUnidad == "Cucharada") {
          nuevaCantidad = ingrediente.cantidad / 3.0;
        }
        
        // CONVERSIONES ENTRE PESO Y VOLUMEN (aproximadas)
        else if ((ingrediente.unidad == "Gramo" && nuevaUnidad == "Mililitros") ||
                 (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Gramo")) {
          nuevaCantidad = ingrediente.cantidad; // 1g = 1ml aproximadamente
        }
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Mililitros") {
          nuevaCantidad = ingrediente.cantidad * 1000.0;
        }
        else if (ingrediente.unidad == "Mililitros" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad / 1000.0;
        }
        else if (ingrediente.unidad == "Kilogramo" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad; // 1kg = 1L aproximadamente
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Kilogramo") {
          nuevaCantidad = ingrediente.cantidad; // 1L = 1kg aproximadamente
        }
        else if (ingrediente.unidad == "Gramo" && nuevaUnidad == "Litro") {
          nuevaCantidad = ingrediente.cantidad / 1000.0;
        }
        else if (ingrediente.unidad == "Litro" && nuevaUnidad == "Gramo") {
          nuevaCantidad = ingrediente.cantidad * 1000.0;
        }
        
        // OTROS VOLÚMENES
        else if (ingrediente.unidad == "Cucharada" && nuevaUnidad == "Onza liquida") {
          nuevaCantidad = ingrediente.cantidad / 2.0; // 1 oz líquida = 2 cdas aprox
        }
        else if (ingrediente.unidad == "Onza liquida" && nuevaUnidad == "Cucharada") {
          nuevaCantidad = ingrediente.cantidad * 2.0;
        }
        else if (ingrediente.unidad == "Onza liquida" && nuevaUnidad == "Pinta") {
          nuevaCantidad = ingrediente.cantidad / 16.0;
        }
        else if (ingrediente.unidad == "Pinta" && nuevaUnidad == "Onza liquida") {
          nuevaCantidad = ingrediente.cantidad * 16.0;
        }
        else if (ingrediente.unidad == "Pinta" && nuevaUnidad == "Cuarto galon") {
          nuevaCantidad = ingrediente.cantidad / 2.0;
        }
        else if (ingrediente.unidad == "Cuarto galon" && nuevaUnidad == "Pinta") {
          nuevaCantidad = ingrediente.cantidad * 2.0;
        }
        else if (ingrediente.unidad == "Cuarto galon" && nuevaUnidad == "Galon") {
          nuevaCantidad = ingrediente.cantidad / 4.0;
        }
        else if (ingrediente.unidad == "Galon" && nuevaUnidad == "Cuarto galon") {
          nuevaCantidad = ingrediente.cantidad * 4.0;
        }
        
        // Si no hay una conversión directa definida, intentamos usar el método _convertirRendimiento
        else {
          print("Intentando conversión a través de factores para ${ingrediente.nombre}: ${ingrediente.cantidad} ${ingrediente.unidad} a $nuevaUnidad");
          nuevaCantidad = _convertirRendimiento(ingrediente.cantidad, ingrediente.unidad, nuevaUnidad);
        }
        
        print("DIAGNÓSTICO: Cambio de unidad en ingrediente ${ingrediente.nombre}");
        print("  - Unidad anterior: ${ingrediente.unidad}");
        print("  - Nueva unidad: $nuevaUnidad");
        print("  - Cantidad actual: ${ingrediente.cantidad} ${ingrediente.unidad}");
        print("  - Cantidad convertida: $nuevaCantidad $nuevaUnidad");

        // Actualizar el ingrediente con los nuevos valores
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.unidad = nuevaUnidad;
        ingrediente.cantidadOriginal = nuevaCantidad; // Actualizar también la base de referencia
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      });
    } catch (e) {
      print("Error al actualizar unidad: $e");
    }
  }

  // Método para formatear números con precisión adecuada
  String _formatearNumero(double numero) {
    try {
      // Manejo de NaN o infinito
      if (numero.isNaN || numero.isInfinite) {
        return "0";
      }

      // Para valores muy pequeños, mostrar más decimales
      if (numero.abs() < 0.01 && numero.abs() > 0) {
        return numero.toStringAsFixed(4).replaceAll(RegExp(r'\.?0+$'), '');
      }
      
      // Para valores normales
      if (numero == numero.roundToDouble()) {
        return numero.toInt().toString();
      }
      
      String resultado = numero.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return resultado;
    } catch (e) {
      print("Error al formatear número: $e");
      return "0";
    }
  }

  double _convertirRendimiento(double cantidad, String desde, String hasta) {
    try {
      // Manejo de casos especiales
      if (cantidad.isNaN || cantidad.isInfinite) {
        print("Error: cantidad no válida para conversión");
        return 0.0;
      }

      // Si es la misma unidad, devolvemos la misma cantidad
      if (desde == hasta) return cantidad;

      // Convertimos a minúsculas y eliminamos espacios para normalizar
      String desdeNorm = desde.trim();
      String hastaNorm = hasta.trim();

      // Casos especiales de depuración
      print("Convirtiendo $cantidad $desdeNorm a $hastaNorm");

      // Si tenemos una conversión directa, la usamos
      if (_factoresRendimiento.containsKey(desdeNorm) &&
          _factoresRendimiento[desdeNorm]!.containsKey(hastaNorm)) {
        double resultado = cantidad * _factoresRendimiento[desdeNorm]![hastaNorm]!;
        print("Conversión directa: $cantidad $desdeNorm a $hastaNorm = $resultado");
        return resultado;
      }

      // Si tenemos la conversión inversa, la invertimos
      if (_factoresRendimiento.containsKey(hastaNorm) &&
          _factoresRendimiento[hastaNorm]!.containsKey(desdeNorm)) {
        double resultado = cantidad / _factoresRendimiento[hastaNorm]![desdeNorm]!;
        print("Conversión inversa: $cantidad $desdeNorm a $hastaNorm = $resultado");
        return resultado;
      }

      // Si no hay conversión directa, intentamos convertir a través de una unidad base
      String unidadBase;
      
      // Determinar la unidad base adecuada
      if (['Gramo', 'Kilogramo', 'Onza', 'Libra', 'Miligramos'].contains(desdeNorm) ||
          ['Gramo', 'Kilogramo', 'Onza', 'Libra', 'Miligramos'].contains(hastaNorm)) {
        unidadBase = 'Gramo';  // Para unidades de peso
      } else {
        unidadBase = 'Mililitros';  // Para unidades de volumen
      }
      
      // Convertimos a través de la unidad base
      print("Conversión a través de $unidadBase: $cantidad $desdeNorm -> $unidadBase -> $hastaNorm");
      double cantidadBase;
      
      // Desde -> Unidad Base
      if (_factoresRendimiento.containsKey(desdeNorm) && _factoresRendimiento[desdeNorm]!.containsKey(unidadBase)) {
        cantidadBase = cantidad * _factoresRendimiento[desdeNorm]![unidadBase]!;
      } else if (_factoresRendimiento.containsKey(unidadBase) && _factoresRendimiento[unidadBase]!.containsKey(desdeNorm)) {
        cantidadBase = cantidad / _factoresRendimiento[unidadBase]![desdeNorm]!;
      } else {
        print("No se pudo convertir $desdeNorm a $unidadBase");
        return cantidad;
      }
      
      // Unidad Base -> Hasta
      double resultado;
      if (_factoresRendimiento.containsKey(unidadBase) && _factoresRendimiento[unidadBase]!.containsKey(hastaNorm)) {
        resultado = cantidadBase * _factoresRendimiento[unidadBase]![hastaNorm]!;
      } else if (_factoresRendimiento.containsKey(hastaNorm) && _factoresRendimiento[hastaNorm]!.containsKey(unidadBase)) {
        resultado = cantidadBase / _factoresRendimiento[hastaNorm]![unidadBase]!;
      } else {
        print("No se pudo convertir $unidadBase a $hastaNorm");
        return cantidad;
      }
      
      print("Resultado final de conversión: $cantidad $desdeNorm -> $cantidadBase $unidadBase -> $resultado $hastaNorm");
      return resultado;
    } catch (e) {
      print("Error en conversión: $e");
      // En caso de error, devolvemos la misma cantidad
      return cantidad;
    }
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

  // Método para generar y compartir el PDF
  Future<void> _generarPDF() async {
    try {
    final pdf = pw.Document();
      
      // Obtener el tema actual
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      // Definir colores según el tema
      final fontColor = isDark ? PdfColors.white : PdfColors.black;
      final backgroundColor = isDark ? PdfColors.blueGrey800 : PdfColors.white;
      final headerColor = isDark ? PdfColors.blue200 : PdfColors.blue700;

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
            return pw.Container(
              color: backgroundColor,
              child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      isEnglish ? 'Recipe Conversion' : 'Conversión de Receta',
                style: pw.TextStyle(
                        color: headerColor,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${widget.recipe.title}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: fontColor,
                ),
              ),
              pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
              pw.Text(
                        isEnglish ? 'Original: $_platosOrigen $_unidadOriginal' : 'Original: $_platosOrigen $_unidadOriginal',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: fontColor,
                        ),
              ),
              pw.Text(
                        isEnglish ? 'New: $_platosDestino $_unidadDestino' : 'Nuevo: $_platosDestino $_unidadDestino',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: fontColor,
                        ),
                      ),
                    ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                    isEnglish ? 'Ingredients' : 'Ingredientes',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                      color: fontColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                              isEnglish ? 'Ingredient' : 'Ingrediente',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                              isEnglish ? 'Quantity' : 'Cantidad',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                              isEnglish ? 'Unit' : 'Unidad',
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
                              padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            ingrediente.nombre,
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                                _formatearNumero(ingrediente.cantidad),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                                ingrediente.unidad,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    );
                      }).toList(),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    isEnglish ? 'Steps' : 'Pasos',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: fontColor,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: widget.recipe.steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 10),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 25,
                              height: 25,
                              decoration: pw.BoxDecoration(
                                color: headerColor,
                                shape: pw.BoxShape.circle,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                '${index + 1}',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Expanded(
                              child: pw.Text(
                                step,
                                style: pw.TextStyle(color: fontColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Footer(
                    title: pw.Text(
                      isEnglish ? 'Generated with Recipe App' : 'Generado con la App de Recetas',
                      style: pw.TextStyle(
                        color: fontColor,
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
          );
        },
      ),
    );

      // Guardar el PDF en un archivo temporal
    final output = await getTemporaryDirectory();
      final file = File('${output.path}/receta_convertida.pdf');
    await file.writeAsBytes(await pdf.save());

      // Compartir el PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: isEnglish ? 'Converted Recipe: ${widget.recipe.title}' : 'Receta Convertida: ${widget.recipe.title}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish ? 'Error generating PDF: $e' : 'Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTextoTraducido('Calculadora de Conversión', 'Conversion Calculator')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _mostrarTablaEquivalencias,
            tooltip: _getTextoTraducido('Ver tabla de equivalencias', 'View conversion table'),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generarPDF,
            tooltip: _getTextoTraducido('Generar PDF', 'Generate PDF'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            _getTextoTraducido('CALCULADORA DE CONVERSIÓN', 'CONVERSION CALCULATOR'),
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
                Text(
                  _getTextoTraducido('RENDIMIENTO', 'YIELD'),
                  style: const TextStyle(
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            _getTextoTraducido('ORIGINAL', 'ORIGINAL'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            _getTextoTraducido('UNIDAD', 'UNIT'),
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            _getTextoTraducido('NUEVO', 'NEW'),
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
                                _unidadesAbreviadas[_getUnidadTraducida(_unidadOriginal)] ?? 
                                _getUnidadTraducida(_unidadOriginal),
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
                                          
                                          // Solo convertimos si la unidad realmente cambió
                                          if (unidadAnterior != value) {
                                            double cantidadActual = _platosDestino;
                                            
                                            // IMPLEMENTACIÓN FORZADA DE CONVERSIONES EXACTAS
                                            // Usamos conversiones directas y explícitas para evitar problemas
                                            double nuevaCantidad = 0.0;
                                            
                                            // DE PESO A PESO
                                            if (unidadAnterior == "Gramo" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual / 1000.0;
                                            } 
                                            else if (unidadAnterior == "Kilogramo" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual * 1000.0;
                                            }
                                            else if (unidadAnterior == "Gramo" && value == "Onza") {
                                              nuevaCantidad = cantidadActual / 28.3495;
                                            }
                                            else if (unidadAnterior == "Onza" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual * 28.3495;
                                            }
                                            else if (unidadAnterior == "Kilogramo" && value == "Onza") {
                                              nuevaCantidad = cantidadActual * 35.274;
                                            }
                                            else if (unidadAnterior == "Onza" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual / 35.274;
                                            }
                                            else if (unidadAnterior == "Kilogramo" && value == "Libra") {
                                              nuevaCantidad = cantidadActual * 2.20462;
                                            }
                                            else if (unidadAnterior == "Libra" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual / 2.20462;
                                            }
                                            else if (unidadAnterior == "Gramo" && value == "Libra") {
                                              nuevaCantidad = cantidadActual / 453.592;
                                            }
                                            else if (unidadAnterior == "Libra" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual * 453.592;
                                            }
                                            else if (unidadAnterior == "Onza" && value == "Libra") {
                                              nuevaCantidad = cantidadActual / 16.0;
                                            }
                                            else if (unidadAnterior == "Libra" && value == "Onza") {
                                              nuevaCantidad = cantidadActual * 16.0;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual / 1000.0;
                                            }
                                            else if (unidadAnterior == "Gramo" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 1000.0;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual / 1000000.0;
                                            }
                                            else if (unidadAnterior == "Kilogramo" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 1000000.0;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Onza") {
                                              nuevaCantidad = cantidadActual / 28349.5;
                                            }
                                            else if (unidadAnterior == "Onza" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 28349.5;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Libra") {
                                              nuevaCantidad = cantidadActual / 453592.0;
                                            }
                                            else if (unidadAnterior == "Libra" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 453592.0;
                                            }
                                            
                                            // DE VOLUMEN A VOLUMEN
                                            else if (unidadAnterior == "Mililitros" && value == "Litro") {
                                              nuevaCantidad = cantidadActual / 1000.0;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 1000.0;
                                            }
                                            else if (unidadAnterior == "Centilitros" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 10.0;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Centilitros") {
                                              nuevaCantidad = cantidadActual / 10.0;
                                            }
                                            else if (unidadAnterior == "Centilitros" && value == "Litro") {
                                              nuevaCantidad = cantidadActual / 100.0;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Centilitros") {
                                              nuevaCantidad = cantidadActual * 100.0;
                                            }
                                            else if (unidadAnterior == "Cucharada" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 15.0;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Cucharada") {
                                              nuevaCantidad = cantidadActual / 15.0;
                                            }
                                            else if (unidadAnterior == "Cucharadita" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 5.0;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Cucharadita") {
                                              nuevaCantidad = cantidadActual / 5.0;
                                            }
                                            else if (unidadAnterior == "Taza" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 240.0;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Taza") {
                                              nuevaCantidad = cantidadActual / 240.0;
                                            }
                                            
                                            // PORCIONES
                                            else if (unidadAnterior == "Porción" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual * 250.0;
                                            }
                                            else if (unidadAnterior == "Gramo" && value == "Porción") {
                                              nuevaCantidad = cantidadActual / 250.0;
                                            }
                                            else if (unidadAnterior == "Porción" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual * 0.25;
                                            }
                                            else if (unidadAnterior == "Kilogramo" && value == "Porción") {
                                              nuevaCantidad = cantidadActual * 4.0;
                                            }
                                            else if (unidadAnterior == "Porción" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 250.0;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Porción") {
                                              nuevaCantidad = cantidadActual / 250.0;
                                            }
                                            else if (unidadAnterior == "Porción" && value == "Litro") {
                                              nuevaCantidad = cantidadActual * 0.25;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Porción") {
                                              nuevaCantidad = cantidadActual * 4.0;
                                            }
                                            
                                            // ONZAS LÍQUIDAS
                                            else if (unidadAnterior == "Onza liquida" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 29.5735;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Onza liquida") {
                                              nuevaCantidad = cantidadActual / 29.5735;
                                            }
                                            else if (unidadAnterior == "Onza liquida" && value == "Litro") {
                                              nuevaCantidad = cantidadActual * 0.0295735;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Onza liquida") {
                                              nuevaCantidad = cantidadActual * 33.814;
                                            }
                                            
                                            // CONVERSIONES ADICIONALES
                                            else if (unidadAnterior == "Pinta" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 473.176;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Pinta") {
                                              nuevaCantidad = cantidadActual / 473.176;
                                            }
                                            else if (unidadAnterior == "Pinta" && value == "Litro") {
                                              nuevaCantidad = cantidadActual * 0.473176;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Pinta") {
                                              nuevaCantidad = cantidadActual * 2.11338;
                                            }
                                            else if (unidadAnterior == "Cuarto galon" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 946.353;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Cuarto galon") {
                                              nuevaCantidad = cantidadActual / 946.353;
                                            }
                                            else if (unidadAnterior == "Cuarto galon" && value == "Litro") {
                                              nuevaCantidad = cantidadActual * 0.946353;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Cuarto galon") {
                                              nuevaCantidad = cantidadActual * 1.05669;
                                            }
                                            else if (unidadAnterior == "Galon" && value == "Mililitros") {
                                              nuevaCantidad = cantidadActual * 3785.41;
                                            }
                                            else if (unidadAnterior == "Mililitros" && value == "Galon") {
                                              nuevaCantidad = cantidadActual / 3785.41;
                                            }
                                            else if (unidadAnterior == "Galon" && value == "Litro") {
                                              nuevaCantidad = cantidadActual * 3.78541;
                                            }
                                            else if (unidadAnterior == "Litro" && value == "Galon") {
                                              nuevaCantidad = cantidadActual * 0.264172;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Gramo") {
                                              nuevaCantidad = cantidadActual / 1000.0;
                                            }
                                            else if (unidadAnterior == "Gramo" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 1000.0;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Kilogramo") {
                                              nuevaCantidad = cantidadActual / 1000000.0;
                                            }
                                            else if (unidadAnterior == "Kilogramo" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 1000000.0;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Onza") {
                                              nuevaCantidad = cantidadActual / 28349.5;
                                            }
                                            else if (unidadAnterior == "Onza" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 28349.5;
                                            }
                                            else if (unidadAnterior == "Miligramos" && value == "Libra") {
                                              nuevaCantidad = cantidadActual / 453592.0;
                                            }
                                            else if (unidadAnterior == "Libra" && value == "Miligramos") {
                                              nuevaCantidad = cantidadActual * 453592.0;
                                            }
                                            
                                            // Caso por defecto: mantenemos la cantidad si no tenemos una conversión específica
                                            else {
                                              print("⚠️ No se encontró conversión directa de $unidadAnterior a $value, manteniendo valor");
                                              nuevaCantidad = cantidadActual;
                                            }
                                            
                                            print("DEBUG: Conversión de $cantidadActual $unidadAnterior a $nuevaCantidad $value");
                                            
                                            // Actualizamos SOLO el rendimiento destino
                                            _platosDestino = nuevaCantidad;
                                            _destinoController.text = _formatearNumero(nuevaCantidad);
                                            _resultado = nuevaCantidad;
                                            
                                            // Actualizamos los valores base también
                                            if (_esTipoUnidadPeso(value)) {
                                              _valorBaseGramos = _convertirAUnidadBase(nuevaCantidad, value, 'peso');
                                            } else if (_esTipoUnidadVolumen(value)) {
                                              _valorBaseMililitros = _convertirAUnidadBase(nuevaCantidad, value, 'volumen');
                                            }
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
                        isEnglish ? 'Result: ' : 'Resultado: ',
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
            _getTextoTraducido('TABLA DE INGREDIENTES', 'INGREDIENTS TABLE'),
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
                      _getTextoTraducido('INGREDIENTE', 'INGREDIENT'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _getTextoTraducido('CANTIDAD', 'QUANTITY'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _getTextoTraducido('UNIDAD', 'UNIT'),
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                                      isDarkMode ? Colors.white : const Color.fromARGB(255, 26, 22, 22),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generarPDF,
        icon: const Icon(Icons.share),
        label: Text(isEnglish ? 'Share PDF' : 'Compartir PDF'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // Nuevos métodos para simplificar la comprobación de tipo de unidad
  bool _esTipoUnidadPeso(String unidad) {
    return ['Gramo', 'Kilogramo', 'Onza', 'Libra', 'Miligramos'].contains(unidad);
  }
  
  bool _esTipoUnidadVolumen(String unidad) {
    return ['Mililitros', 'Litro', 'Centilitros', 'Cucharada', 'Cucharadita', 
            'Taza', 'Onza liquida', 'Pinta', 'Cuarto galon', 'Galon'].contains(unidad);
  }
  
  // Método para convertir a unidad base (gramos o mililitros)
  double _convertirAUnidadBase(double cantidad, String unidad, String tipo) {
    if (tipo == 'peso') {
      return _convertirRendimiento(cantidad, unidad, 'Gramo');
    } else if (tipo == 'volumen') {
      return _convertirRendimiento(cantidad, unidad, 'Mililitros');
    }
    return cantidad;
  }
  
  // Método para convertir desde unidad base
  double _convertirDesdeUnidadBase(double cantidadBase, String unidadDestino, String tipo) {
    if (tipo == 'peso') {
      return _convertirRendimiento(cantidadBase, 'Gramo', unidadDestino);
    } else if (tipo == 'volumen') {
      return _convertirRendimiento(cantidadBase, 'Mililitros', unidadDestino);
    }
    return cantidadBase;
  }

  void _mostrarTablaEquivalencias() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isEnglish ? 'Conversion Table' : 'Tabla de Equivalencias',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEquivalenciasSection(
                  isEnglish ? 'WEIGHT UNITS' : 'UNIDADES DE PESO',
                  isEnglish ? [
                    '1 Kilogram (kg) = 1000 Grams (g)',
                    '1 Gram (g) = 1000 Milligrams (mg)',
                    '1 Pound (lb) = 453.6 Grams (g)',
                    '1 Pound (lb) = 16 Ounces (oz)',
                    '1 Ounce (oz) = 28.35 Grams (g)',
                  ] : [
                    '1 Kilogramo (kg) = 1000 Gramos (g)',
                    '1 Gramo (g) = 1000 Miligramos (mg)',
                    '1 Libra (lb) = 453.6 Gramos (g)',
                    '1 Libra (lb) = 16 Onzas (oz)',
                    '1 Onza (oz) = 28.35 Gramos (g)',
                  ]
                ),
                const SizedBox(height: 12),
                _buildEquivalenciasSection(
                  isEnglish ? 'VOLUME UNITS' : 'UNIDADES DE VOLUMEN',
                  isEnglish ? [
                    '1 Liter (L) = 1000 Milliliters (ml)',
                    '1 Liter (L) = 100 Centiliters (cl)',
                    '1 Centiliter (cl) = 10 Milliliters (ml)',
                    '1 Cup = 240 Milliliters (ml)',
                    '1 Tablespoon (tbsp) = 15 Milliliters (ml)',
                    '1 Teaspoon (tsp) = 5 Milliliters (ml)',
                    '1 Cup = 16 Tablespoons (tbsp)',
                    '1 Tablespoon (tbsp) = 3 Teaspoons (tsp)',
                    '1 Fluid ounce = 29.57 Milliliters (ml)',
                    '1 Pint = 473.2 Milliliters (ml)',
                    '1 Quart = 946.4 Milliliters (ml)',
                    '1 Gallon = 3.785 Liters (L)',
                  ] : [
                    '1 Litro (L) = 1000 Mililitros (ml)',
                    '1 Litro (L) = 100 Centilitros (cl)',
                    '1 Centilitro (cl) = 10 Mililitros (ml)',
                    '1 Taza = 240 Mililitros (ml)',
                    '1 Cucharada (cda) = 15 Mililitros (ml)',
                    '1 Cucharadita (cdta) = 5 Mililitros (ml)',
                    '1 Taza = 16 Cucharadas (cda)',
                    '1 Cucharada (cda) = 3 Cucharaditas (cdta)',
                    '1 Onza líquida = 29.57 Mililitros (ml)',
                    '1 Pinta = 473.2 Mililitros (ml)',
                    '1 Cuarto galón = 946.4 Mililitros (ml)',
                    '1 Galón = 3.785 Litros (L)',
                  ]
                ),
                const SizedBox(height: 12),
                _buildEquivalenciasSection(
                  isEnglish ? 'SERVINGS' : 'PORCIONES',
                  isEnglish ? [
                    '1 Serving = 250 Grams (g)',
                    '1 Serving = 0.25 Kilograms (kg)',
                    '1 Serving = 250 Milliliters (ml)',
                    '1 Serving = 8.8 Ounces (oz)',
                    '1 Serving = 0.55 Pounds (lb)',
                    '1 Kilogram (kg) = 4 Servings',
                    '1 Liter (L) = 4 Servings',
                  ] : [
                    '1 Porción = 250 Gramos (g)',
                    '1 Porción = 0.25 Kilogramos (kg)',
                    '1 Porción = 250 Mililitros (ml)',
                    '1 Porción = 8.8 Onzas (oz)',
                    '1 Porción = 0.55 Libras (lb)',
                    '1 Kilogramo (kg) = 4 Porciones',
                    '1 Litro (L) = 4 Porciones',
                  ]
                ),
                const SizedBox(height: 12),
                _buildEquivalenciasSection(
                  isEnglish ? 'WEIGHT-VOLUME (approx.)' : 'PESO-VOLUMEN (aprox.)',
                  isEnglish ? [
                    '1 Gram (g) = 1 Milliliter (ml) of water',
                    '1 Kilogram (kg) = 1 Liter (L) of water',
                    '1 Pound (lb) = 454 Milliliters (ml) of water',
                    '1 Ounce (oz) = 28.4 Milliliters (ml) of water',
                  ] : [
                    '1 Gramo (g) = 1 Mililitro (ml) de agua',
                    '1 Kilogramo (kg) = 1 Litro (L) de agua',
                    '1 Libra (lb) = 454 Mililitros (ml) de agua',
                    '1 Onza (oz) = 28.4 Mililitros (ml) de agua',
                  ]
                ),
                const SizedBox(height: 8),
                Text(
                  isEnglish 
                    ? 'Note: Weight to volume conversions are approximate and valid mainly for water.'
                    : 'Nota: Las conversiones entre peso y volumen son aproximadas y válidas principalmente para agua.',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isEnglish ? 'Close' : 'Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEquivalenciasSection(String title, List<String> equivalencias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blueGrey.shade800 
              : Colors.blue.shade100,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        ...equivalencias.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(e, style: const TextStyle(fontSize: 14)),
        )),
      ],
    );
  }

  @override
  void didUpdateWidget(ConversionCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
  }

  // Método para obtener el texto traducido
  String _getTextoTraducido(String textoEspanol, String textoIngles) {
    return isEnglish ? textoIngles : textoEspanol;
  }

  // Método para obtener la unidad traducida
  String _getUnidadTraducida(String unidad) {
    return _getUnidadFormateada(unidad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageService = Provider.of<LanguageService>(context);
    if (isEnglish != languageService.isEnglish) {
      setState(() {
        isEnglish = languageService.isEnglish;
      });
    }
  }
}

class IngredienteTabla {
  String nombre;
  double cantidad;
  String unidad;
  String tipoMedida;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;
  double cantidadOriginal;
  final String unidadOriginal;
  final double _cantidadBase; // Nueva propiedad para mantener la cantidad en unidad base

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
