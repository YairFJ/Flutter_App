import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import '../utils/pdf_calculator_generator.dart';
import '../models/ingrediente_tabla.dart';
import '../utils/pdf_generator.dart' as custom_pdf;
import 'package:flutter/services.dart';

class ConversionCalculatorScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isEnglish; // Añadir este parámetro

  const ConversionCalculatorScreen({
    super.key,
    required this.recipe,
    this.isEnglish = false, // Definir con valor por defecto
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
  
  // Variables para almacenar los valores originales para reinicio
  double _platosOrigenOriginal = 1.0;
  double _platosDestinoOriginal = 1.0;
  
  // Valores base para conversiones consistentes
  double _valorBaseGramos = 0.0;
  double _valorBaseMililitros = 0.0;
  
  // Contador para reinicio automático de seguridad
  int _contadorConversiones = 0;
  final int _maxConversionesAntesDeReinicio = 50;
  
  // Flag para indicar si se acaba de realizar un reinicio del sistema
  bool _sistemaPurificado = false;
  
  late bool isEnglish; // Declarar variable de estado
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
    //'Unidad',
  ];

  // Mapa de conversión de unidades antiguas a nuevas
  final Map<String, String> _convertirUnidadAntigua = {
    // Peso
    'gr': 'Gramo',
    'g': 'Gramo',
    'kg': 'Kilogramo',
    'mg': 'Miligramos',
    'oz': 'Onza',
    'lb': 'Libra',
    // Volumen
    'l': 'Litro',
    'ml': 'Mililitros',
    'cl': 'Centilitros',
    'cda': 'Cucharada',      // <-- Añadido
    'cucharada': 'Cucharada',   // <-- Añadido
    'cdta': 'Cucharadita',   // <-- Añadido
    'cucharadita': 'Cucharadita', // <-- Añadido
    'tz': 'Taza',            // <-- Añadido
    'taza': 'Taza',          // <-- Añadido
    'oz liq': 'Onza liquida', // <-- Añadido
    'onza liquida': 'Onza liquida', // <-- Añadido
    'pinta': 'Pinta',        // <-- Añadido
    'c-galon': 'Cuarto galon', // <-- Añadido
    'cuarto galon': 'Cuarto galon', // <-- Añadido
    'galon': 'Galon',        // <-- Añadido
    // Unidades de Rendimiento (Persona, Porción, etc.)
    
    'porcion': 'Porción',
    'porciones': 'Porción',
    'racion': 'Ración',
    'raciones': 'Ración',
    'plato': 'Plato',
    'platos': 'Plato',
    // Unidad Genérica
    'unidad': 'Unidad',
    'unidades': 'Unidad',
    'und': 'Unidad',
    'u': 'Unidad',
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
    'Onza liquida': 'oz liq',  // Cambiado de 'oz liquida' a 'oz liq' para evitar confusión
    'Pinta': 'pinta',
    'Cuarto galon': 'c-galon',  // Cambiado de 'cuarto galon' a 'c-galon' para que sea más corto
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
      'Gramo': 240.0, // 1 taza = 240g (asumiendo agua)
      'Kilogramo': 0.24, // 1 taza = 0.24kg (asumiendo agua)
      'Onza': 8.47, // 1 taza = 8.47oz (asumiendo agua)
      'Libra': 0.529, // 1 taza = 0.529lb (asumiendo agua)
      'Porción': 0.96, // 1 taza = 0.96 porciones (250ml = 1 porción)
    },
    'Onza liquida': {
      'Mililitros': 29.5735,
      'Litro': 0.0295735,
      'Centilitros': 2.95735,
      'Taza': 0.123223,
      'Cucharada': 2,
      'Cucharadita': 6,
      'Pinta': 0.0625,
      'Cuarto galon': 0.03125,
      'Galon': 0.0078125,
      'Gramo': 29.5735, // 1 oz líq = 29.57g (asumiendo agua)
      'Kilogramo': 0.0295735, // 1 oz líq = 0.0296kg (asumiendo agua)
      'Onza': 1.04, // 1 oz líq = 1.04oz (asumiendo agua)
      'Libra': 0.065, // 1 oz líq = 0.065lb (asumiendo agua)
      'Porción': 0.118, // 1 oz líq = 0.118 porciones (250ml = 1 porción)
    },
    'Pinta': {
      'Mililitros': 473.176,
      'Litro': 0.473176,
      'Centilitros': 47.3176,
      'Taza': 2,
      'Cucharada': 32,
      'Cucharadita': 96,
      'Onza liquida': 16,
      'Cuarto galon': 0.5,
      'Galon': 0.125,
      'Gramo': 473.176, // 1 pinta = 473.18g (asumiendo agua)
      'Kilogramo': 0.473176, // 1 pinta = 0.473kg (asumiendo agua)
      'Onza': 16.7, // 1 pinta = 16.7oz (asumiendo agua)
      'Libra': 1.04, // 1 pinta = 1.04lb (asumiendo agua)
      'Porción': 1.89, // 1 pinta = 1.89 porciones (250ml = 1 porción)
    },
    'Cuarto galon': {
      'Mililitros': 946.353,
      'Litro': 0.946353,
      'Centilitros': 94.6353,
      'Taza': 4,
      'Cucharada': 64,
      'Cucharadita': 192,
      'Onza liquida': 32,
      'Pinta': 2,
      'Galon': 0.25,
      'Gramo': 946.353, // 1 cuarto = 946.35g (asumiendo agua)
      'Kilogramo': 0.946353, // 1 cuarto = 0.946kg (asumiendo agua)
      'Onza': 33.4, // 1 cuarto = 33.4oz (asumiendo agua)
      'Libra': 2.09, // 1 cuarto = 2.09lb (asumiendo agua)
      'Porción': 3.79, // 1 cuarto = 3.79 porciones (250ml = 1 porción)
    },
    'Galon': {
      'Mililitros': 3785.41,
      'Litro': 3.78541,
      'Centilitros': 378.541,
      'Taza': 16,
      'Cucharada': 256,
      'Cucharadita': 768,
      'Onza liquida': 128,
      'Pinta': 8,
      'Cuarto galon': 4,
      'Gramo': 3785.41, // 1 galón = 3785.41g (asumiendo agua)
      'Kilogramo': 3.78541, // 1 galón = 3.79kg (asumiendo agua)
      'Onza': 133.53, // 1 galón = 133.53oz (asumiendo agua)
      'Libra': 8.35, // 1 galón = 8.35lb (asumiendo agua)
      'Porción': 15.14, // 1 galón = 15.14 porciones (250ml = 1 porción)
    },
    'Porción': {
      'Gramo': 250.0, // 1 porción = 250g
      'Kilogramo': 0.25, // 1 porción = 0.25kg
      'Onza': 8.82, // 1 porción = 8.82oz
      'Libra': 0.551, // 1 porción = 0.551lb
      'Mililitros': 250.0, // 1 porción = 250ml
      'Litro': 0.25, // 1 porción = 0.25L
      'Centilitros': 25.0, // 1 porción = 25cl
      'Cucharada': 16.67, // 1 porción = 16.67 cucharadas
      'Cucharadita': 50.0, // 1 porción = 50 cucharaditas
      'Taza': 1.04, // 1 porción = 1.04 tazas
      'Onza liquida': 8.45, // 1 porción = 8.45 oz líquidas
      'Pinta': 0.53, // 1 porción = 0.53 pintas
      'Cuarto galon': 0.264, // 1 porción = 0.264 cuartos
      'Galon': 0.066, // 1 porción = 0.066 galones
      'Miligramos': 250000.0, // 1 porción = 250,000 mg
    },
  };

  // Mapa de plurales para las unidades
  final Map<String, String> _unidadesPlural = {
    'Porción': 'Porciones',
    'Ración': 'Raciones',
    'Plato': 'Platos',
    'Unidad': 'Unidades',
  };

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    try {
      print("Iniciando configuración...");
      print("Serving Size: ${widget.recipe.servingSize}");
      print("Ingredients: ${widget.recipe.ingredients}");

      final parts = widget.recipe.servingSize.trim().split(' ');
      if (parts.length >= 2) {
        _platosOrigen = double.tryParse(parts[0].replaceAll(',', '.')) ?? 1.0;
        _valorOriginalRendimiento = _platosOrigen;
        _platosOrigenOriginal = _platosOrigen;
        
        String unidadOriginalTemp = parts[1].toLowerCase();
        String unidadNormalizada = _convertirUnidadAntigua[unidadOriginalTemp] ?? 'Porción';
        
        // Asegurarnos que la unidad normalizada esté en la lista de unidades de rendimiento
        if (!_unidadesRendimiento.contains(unidadNormalizada)) {
          unidadNormalizada = 'Porción';
        }
        
        _unidadOriginal = unidadNormalizada;
        _unidadDestino = unidadNormalizada;
        _unidadActual = unidadNormalizada;
        
        print("Valores iniciales:");
        print("  - Platos origen: $_platosOrigen");
        print("  - Valor original rendimiento: $_valorOriginalRendimiento");
        print("  - Unidad original: $_unidadOriginal");
        
        // Inicializamos valores base de conversión
        if (_esTipoUnidadPeso(_unidadOriginal)) {
          _valorBaseGramos = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'peso');
          print("  - Valor base en gramos: $_valorBaseGramos");
        } else if (_esTipoUnidadVolumen(_unidadOriginal)) {
          _valorBaseMililitros = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'volumen');
          print("  - Valor base en mililitros: $_valorBaseMililitros");
        }
      } else {
        print("No se encontraron partes suficientes en el serving size, usando valores predeterminados");
        _unidadOriginal = 'Porción';
        _unidadDestino = 'Porción';
        _unidadActual = 'Porción';
        _platosOrigen = 1.0;
        _valorOriginalRendimiento = 1.0;
        _platosOrigenOriginal = 1.0;
      }

      // Inicialización segura de controladores
      _cantidadController = TextEditingController(text: _formatearNumero(_platosOrigen));
      _destinoController = TextEditingController(text: _formatearNumero(_platosOrigen));
      _platosDestino = _platosOrigen;
      _platosDestinoOriginal = _platosOrigen; // Guardar el valor original

      // Inicialización segura de ingredientes
      _inicializarIngredientes();

      // Verificar y corregir posibles valores iniciales inválidos
      _verificarYCorregirIngredientes();

      // Asegurarnos de tener los valores originales guardados
      if (_platosOrigenOriginal <= 0) {
        _platosOrigenOriginal = _platosOrigen > 0 ? _platosOrigen : 1.0;
        print("Corrigiendo _platosOrigenOriginal a $_platosOrigenOriginal");
      }
      
      print("Configuración inicial completada");
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
    // Si el sistema acaba de ser purificado, esperamos la siguiente interacción del usuario
    if (_sistemaPurificado) {
      _sistemaPurificado = false;
      return;
    }

    // Incrementar contador de conversiones
    _contadorConversiones++;
    
    print("\n🔄 INICIANDO CÁLCULO DE CONVERSIÓN");
    print("Estado actual:");
    print("  - Platos origen: $_platosOrigen ${_unidadOriginal}");
    print("  - Platos destino: $_platosDestino ${_unidadDestino}");
    print("  - Valor original rendimiento: $_valorOriginalRendimiento");
    
    // Si hemos alcanzado el límite de conversiones, reiniciamos los valores base
    if (_contadorConversiones >= _maxConversionesAntesDeReinicio) {
      print("🔄 Reiniciando valores base después de $_contadorConversiones conversiones");
      _contadorConversiones = 0;
      _sistemaPurificado = true;
      
      // Reiniciamos los ingredientes a sus valores originales y los recalculamos
      for (var ingrediente in _ingredientesTabla) {
        ingrediente.cantidad = ingrediente.cantidadOriginal;
        ingrediente.modificadoManualmente = false;
        ingrediente.cantidadController.text = _formatearNumero(ingrediente.cantidad);
      }
      
      // Reiniciamos las variables de rendimiento
      _platosOrigen = _platosOrigenOriginal > 0 ? _platosOrigenOriginal : 0.01;
      _platosDestino = _platosDestinoOriginal > 0 ? _platosDestinoOriginal : 0.01;
      _cantidadController.text = _formatearNumero(_platosOrigen);
      _destinoController.text = _formatearNumero(_platosDestino);
      
      return;
    }

    // Validar que las cantidades de rendimiento sean positivas
    if (_platosOrigen <= 0) {
      print("⚠️ Platos origen inválido: $_platosOrigen. Corrigiendo a 0.01");
      _platosOrigen = 0.01;
      _cantidadController.text = _formatearNumero(_platosOrigen);
    }
    
    if (_platosDestino <= 0) {
      print("⚠️ Platos destino inválido: $_platosDestino. Corrigiendo a 0.01");
      _platosDestino = 0.01;
      _destinoController.text = _formatearNumero(_platosDestino);
    }

    // Calculamos el factor de escala directamente
    double factorEscala = _platosDestino / _valorOriginalRendimiento;
    
    print("\nCálculo de factor de escala:");
    print("  - Platos destino: $_platosDestino");
    print("  - Valor original rendimiento: $_valorOriginalRendimiento");
    print("  - Factor de escala calculado: $factorEscala");
    
    // Validar el factor de escala
    if (factorEscala.isNaN || factorEscala.isInfinite || factorEscala <= 0) {
      print("⚠️ Factor de escala inválido: $factorEscala. Usando 1.0");
      factorEscala = 1.0;
    }
    
    // Limitar el factor de escala a un rango razonable
    if (factorEscala < 0.001) {
      print("⚠️ Factor de escala muy pequeño: $factorEscala. Limitando a 0.001");
      factorEscala = 0.001;
    } else if (factorEscala > 1000) {
      print("⚠️ Factor de escala muy grande: $factorEscala. Limitando a 1000");
      factorEscala = 1000;
    }
    
    setState(() {
      // Aplicar la conversión a cada ingrediente
      for (int i = 0; i < _ingredientesTabla.length; i++) {
        IngredienteTabla ingrediente = _ingredientesTabla[i];
        
        // Si el ingrediente fue modificado manualmente, no lo alteramos
        if (ingrediente.modificadoManualmente) {
          print("ℹ️ Ingrediente '${ingrediente.nombre}' modificado manualmente, conservando valor ${ingrediente.cantidad}");
          continue;
        }
        
        // Validar que la cantidad original sea razonable
        if (ingrediente.cantidadOriginal.isNaN || ingrediente.cantidadOriginal.isInfinite || ingrediente.cantidadOriginal <= 0) {
          print("⚠️ Cantidad original inválida para '${ingrediente.nombre}': ${ingrediente.cantidadOriginal}. Reiniciando");
          ingrediente.cantidadOriginal = 0.01;
        }
        
        // Calcular la nueva cantidad aplicando el factor de escala
        double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
        
        // Validar el resultado
        if (nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
          print("⚠️ Resultado inválido para '${ingrediente.nombre}': $nuevaCantidad. Manteniendo valor anterior");
          continue;
        }
        
        // Asegurarnos que la cantidad no sea menor que 0.01
        if (nuevaCantidad < 0.01) {
          nuevaCantidad = 0.01;
        }
        
        // Aplicar el redondeo para evitar errores de punto flotante
        nuevaCantidad = _redondearPrecision(nuevaCantidad);
        
        // Actualizar la cantidad del ingrediente
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
        
        print("  • '${ingrediente.nombre}': ${ingrediente.cantidadOriginal} ${ingrediente.unidad} → $nuevaCantidad ${ingrediente.unidad}");
      }
      
      // Actualizar resultado para visualización
      _resultado = _platosDestino;
    });
    
    print("\nConversión completada");
  }

  // Método auxiliar para redondear con precisión controlada y evitar errores de punto flotante
  double _redondearPrecision(double valor) {
    // Aumentamos la precisión interna para cálculos
    if (valor.abs() < 0.01) {
      return double.parse(valor.toStringAsFixed(6));
    } else if (valor.abs() < 1) {
      return double.parse(valor.toStringAsFixed(4));
    } else if (valor.abs() < 10) {
      return double.parse(valor.toStringAsFixed(3));
    } else {
      return double.parse(valor.toStringAsFixed(2));
    }
  }

  void _actualizarCantidadIngrediente(int index, String value) {
    print("\n🔄 ACTUALIZANDO CANTIDAD DE INGREDIENTE #$index");
    print("Valor ingresado: '$value'");
    
    // Verificar que el índice sea válido
    if (index < 0 || index >= _ingredientesTabla.length) {
      print("❌ Índice inválido: $index");
      return;
    }
    
    try {
      // Obtener el ingrediente a actualizar
      final ingrediente = _ingredientesTabla[index];
      
      // Guardar el valor anterior para referencia
      final cantidadAnterior = ingrediente.cantidad;
      
      if (value.isEmpty) {
        print("⚠️ Valor vacío, manteniendo cantidad anterior: $cantidadAnterior");
        ingrediente.cantidadController.text = _formatearNumero(cantidadAnterior);
        return;
      }
      
      // Convertir el valor de texto a número
      double nuevaCantidad = double.parse(value.replaceAll(',', '.'));
      
      // Validar la nueva cantidad
      if (nuevaCantidad <= 0 || nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
        print("⚠️ Cantidad inválida: $nuevaCantidad. Usando 0.01");
        nuevaCantidad = 0.01;
      }
      
      // Aplicar redondeo para evitar imprecisiones
      nuevaCantidad = _redondearPrecision(nuevaCantidad);
      
      setState(() {
        // Marcar que este ingrediente ha sido modificado manualmente
        ingrediente.modificadoManualmente = true;
        
        // Actualizar la cantidad
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
        
        print("Ingrediente actualizado manualmente:");
        print("  - Nombre: ${ingrediente.nombre}");
        print("  - Cantidad anterior: $cantidadAnterior ${ingrediente.unidad}");
        print("  - Nueva cantidad: $nuevaCantidad ${ingrediente.unidad}");
        print("  - Marcado como modificado manualmente: ${ingrediente.modificadoManualmente}");
      });
      
    } catch (e) {
      print("❌ Error al actualizar cantidad: $e");
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

  // Actualiza la unidad del ingrediente y hace la conversión necesaria
  void _actualizarUnidad(int index, String nuevaUnidad) {
    print("\n🔄 ACTUALIZANDO UNIDAD DEL INGREDIENTE #$index");
    
    // ... (Validación de índice igual)
    if (index < 0 || index >= _ingredientesTabla.length) {
      print("❌ Índice inválido: $index");
      return;
    }
    
    final ingrediente = _ingredientesTabla[index];
    final unidadAnterior = ingrediente.unidad;
    
    // ... (Comprobación si unidad cambió igual)
    if (unidadAnterior == nuevaUnidad) {
      print("ℹ️ La unidad no cambió");
      return;
    }
    
    print("Unidad anterior: $unidadAnterior");
    print("Nueva unidad seleccionada: $nuevaUnidad");
    
    // Guardar el valor base antes de la conversión
    double? valorBaseOriginal;
    if (_esTipoUnidadPeso(unidadAnterior)) {
      valorBaseOriginal = ingrediente.valorBaseGramos;
    } else if (_esTipoUnidadVolumen(unidadAnterior)) {
      valorBaseOriginal = ingrediente.valorBaseMililitros;
    }
    
    double cantidadActual = ingrediente.cantidad;
    double nuevaCantidad;

    if (_esConversionValida(unidadAnterior, nuevaUnidad)) {
      // Si tenemos un valor base, usarlo para la conversión
      if (valorBaseOriginal != null) {
        if (_esTipoUnidadPeso(nuevaUnidad)) {
          nuevaCantidad = _convertirDesdeUnidadBase(valorBaseOriginal, nuevaUnidad, 'peso');
        } else if (_esTipoUnidadVolumen(nuevaUnidad)) {
          nuevaCantidad = _convertirDesdeUnidadBase(valorBaseOriginal, nuevaUnidad, 'volumen');
        } else {
          nuevaCantidad = _convertirRendimiento(cantidadActual, unidadAnterior, nuevaUnidad);
        }
      } else {
        nuevaCantidad = _convertirRendimiento(cantidadActual, unidadAnterior, nuevaUnidad);
      }
    } else {
        print("  ⚠️ Conversión no válida entre '$unidadAnterior' y '$nuevaUnidad'. Manteniendo cantidad anterior.");
        nuevaCantidad = cantidadActual;
    }

    if (nuevaCantidad.isNaN || nuevaCantidad.isInfinite || nuevaCantidad <= 0) {
      print("⚠️ Resultado de conversión inválido: $nuevaCantidad. Manteniendo cantidad anterior.");
      nuevaCantidad = ingrediente.cantidad;
    }
    
    nuevaCantidad = _redondearPrecision(nuevaCantidad);
    
    setState(() {
      ingrediente.modificadoManualmente = true;
      ingrediente.unidad = nuevaUnidad;
      ingrediente.cantidad = nuevaCantidad;
      ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      
      // Actualizar el valor base después de la conversión
      if (_esTipoUnidadPeso(nuevaUnidad)) {
        ingrediente.valorBaseGramos = _convertirAUnidadBase(nuevaCantidad, nuevaUnidad, 'peso');
        ingrediente.valorBaseMililitros = null;
      } else if (_esTipoUnidadVolumen(nuevaUnidad)) {
        ingrediente.valorBaseMililitros = _convertirAUnidadBase(nuevaCantidad, nuevaUnidad, 'volumen');
        ingrediente.valorBaseGramos = null;
      }
      
      print("Ingrediente actualizado:");
      print("  - Nombre: ${ingrediente.nombre}");
      print("  - Cantidad recalculada: $nuevaCantidad $nuevaUnidad");
      print("  - Marcado como modificado manualmente: ${ingrediente.modificadoManualmente}");
      print("  - Valor base en gramos: ${ingrediente.valorBaseGramos}");
      print("  - Valor base en mililitros: ${ingrediente.valorBaseMililitros}");
    });
  }

  // Método para verificar y corregir valores inválidos en ingredientes
  void _corregirValoresIngrediente(IngredienteTabla ingrediente) {
    bool requiereCorreccionCantidad = false;
    bool requiereCorreccionUnidad = false;

    print("\n--- Verificando ingrediente: ${ingrediente.nombre} ---");
    print("  Estado inicial: Cant=${ingrediente.cantidad}, Unidad='${ingrediente.unidad}', CantOrig=${ingrediente.cantidadOriginal}, UnidadOrig='${ingrediente.unidadOriginal}'");

    // --- 1. Corregir Cantidad --- 
    if (ingrediente.cantidad.isNaN || ingrediente.cantidad.isInfinite || ingrediente.cantidad <= 0) {
      print("  ⚠️ Cantidad inválida (${ingrediente.cantidad}). Corrigiendo a 0.01");
      ingrediente.cantidad = 0.01;
      requiereCorreccionCantidad = true;
    }
    if (ingrediente.cantidadOriginal.isNaN || ingrediente.cantidadOriginal.isInfinite || ingrediente.cantidadOriginal <= 0) {
      print("  ⚠️ Cantidad original inválida (${ingrediente.cantidadOriginal}). Corrigiendo a ${ingrediente.cantidad}");
      ingrediente.cantidadOriginal = ingrediente.cantidad;
    }

    // --- 2. Determinar Unidad Final Válida --- 
    String unidadFinal = '';
    String unidadActualInput = ingrediente.unidad.trim();
    String unidadOriginalInput = ingrediente.unidadOriginal.trim();

    print("  >> Intentando normalizar unidad ACTUAL: '$unidadActualInput'");
    String unidadActualNormalizada = _normalizarUnidad(unidadActualInput);
    print("  >> Resultado normalización ACTUAL: '$unidadActualNormalizada'");

    if (_unidadesIngredientes.contains(unidadActualNormalizada)) {
      print("  ✅ Unidad actual normalizada ('$unidadActualNormalizada') es VÁLIDA. Se usará esta.");
      unidadFinal = unidadActualNormalizada;
    } else {
      print("  ⚠️ Unidad actual ('$unidadActualInput' -> '$unidadActualNormalizada') NO es válida. Intentando con la ORIGINAL de receta: '$unidadOriginalInput'");
      String unidadOriginalNormalizada = _normalizarUnidad(unidadOriginalInput);
      print("  >> Resultado normalización ORIGINAL: '$unidadOriginalNormalizada'");

      if (_unidadesIngredientes.contains(unidadOriginalNormalizada)) {
        print("  ✅ Unidad ORIGINAL normalizada ('$unidadOriginalNormalizada') es VÁLIDA. Se usará esta.");
        unidadFinal = unidadOriginalNormalizada;
      } else {
        // --- CORRECTED FALLBACK ---
        print("  ⚠️ Ni la unidad actual ni la original son directamente válidas tras normalización.");
        // Asignar un valor por defecto AHORA si AMBAS normalizaciones fallaron
        print("  🚨 Forzando a la primera unidad válida: '${_unidadesIngredientes[0]}'.");
        unidadFinal = _unidadesIngredientes[0]; // Default to 'Gramo' or the first valid unit
        requiereCorreccionUnidad = true; // Marcar que se necesitó corrección porque ninguna unidad original era válida
        // --- END CORRECTED FALLBACK ---
      }
    }

    print("  ==> Unidad Final Determinada: '$unidadFinal'");

    // --- 3. Asignar Unidad Final y Marcar si Hubo Cambio --- 
    if (ingrediente.unidad != unidadFinal) {
       print("  ⚙️ Asignando unidad final: '$unidadFinal' (era '${ingrediente.unidad}')");
       ingrediente.unidad = unidadFinal;
       // Marcar como corrección si la unidad asignada es diferente a la que ya tenía
       requiereCorreccionUnidad = true; 
    } else {
       print("  👍 Unidad final '$unidadFinal' coincide con la actual. No se requiere cambio de unidad.");
    }

    // --- 4. Actualizar Controlador de Texto si es Necesario --- 
    if (requiereCorreccionCantidad || requiereCorreccionUnidad) {
      String textoActualizado = _formatearNumero(ingrediente.cantidad);
      print("  🔄 Actualizando TextField a: '$textoActualizado' (Cantidad: ${ingrediente.cantidad}, Unidad: ${ingrediente.unidad})");
      // Comprobar si el controlador necesita actualización para evitar bucles
      if (ingrediente.cantidadController.text != textoActualizado) {
          ingrediente.cantidadController.text = textoActualizado;
      }
    } else {
      print("  No se requieren actualizaciones en el TextField.");
    }
    print("--- Fin verificación: ${ingrediente.nombre} ---");
  }

  // Helper para normalizar unidad (busca en mapa y lista, case-insensitive)
  String _normalizarUnidad(String unidadInput) {
    String unidadTrimmed = unidadInput.trim();
    if (unidadTrimmed.isEmpty) return ''; // Devolver vacío si el input es vacío
    
    String unidadLower = unidadTrimmed.toLowerCase();
    
    // 1. Buscar en mapa de abreviaturas
    if (_convertirUnidadAntigua.containsKey(unidadLower)) {
      return _convertirUnidadAntigua[unidadLower]!;
    }
    
    // 2. Buscar coincidencia (case-insensitive) en lista de unidades válidas
    for (String unidadValida in _unidadesIngredientes) {
      if (unidadLower == unidadValida.toLowerCase()) {
        return unidadValida; // Devolver la versión con mayúsculas correcta
      }
    }
    
    // 3. Si no se encontró, devolver el input original (sin normalizar, pero trimmeado)
    return unidadTrimmed;
  }

  // Método para verificar y corregir todas las cantidades de ingredientes
  void _verificarYCorregirIngredientes() {
    print("SISTEMA: Verificando y corrigiendo todas las cantidades de ingredientes");
    
    try {
      for (var ingrediente in _ingredientesTabla) {
        _corregirValoresIngrediente(ingrediente);
      }
    } catch (e) {
      print("Error al verificar ingredientes: $e");
    }
  }

  // Método para formatear números con precisión adecuada
  String _formatearNumero(double numero) {
    try {
      // Manejo de NaN o infinito
      if (numero.isNaN || numero.isInfinite) {
        return "0";
      }

      // Convertir a cadena con máxima precisión necesaria
      String numeroStr = numero.toString();
      
      // Si es un número entero, mostrar sin decimales
      if (numero == numero.roundToDouble()) {
        return numero.toInt().toString();
      }
      
      // Para números decimales, determinar la precisión necesaria
      if (numero.abs() < 0.01) {
        // Para valores muy pequeños, mostrar hasta 4 decimales significativos
        String result = numero.toStringAsFixed(4);
        return result.replaceAll(RegExp(r'\.?0+$'), '');
      } else if (numero.abs() < 1) {
        // Para valores menores a 1, mostrar hasta 3 decimales
        String result = numero.toStringAsFixed(3);
        return result.replaceAll(RegExp(r'\.?0+$'), '');
      } else {
        // Para el resto de valores, mostrar hasta 2 decimales
        String result = numero.toStringAsFixed(2);
        return result.replaceAll(RegExp(r'\.?0+$'), '');
      }

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

  Future<void> _generarPDF() async {
    final pdfBytes = await generateCalculatorPdf(
      ingredientes: _ingredientesTabla,
      rendimiento: _platosDestino,
      unidad: _unidadDestino,
      detalles: widget.recipe.description ?? '',
      pasos: widget.recipe.steps,
      tituloReceta: widget.recipe.title, // Añadir el título de la receta original
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/conversion_receta.pdf');
    await file.writeAsBytes(pdfBytes);
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Define un estilo de decoración de entrada para consistencia
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Bordes más redondeados
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      filled: true,
      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Conversiones'),
        elevation: 1, // Sombra sutil
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _mostrarTablaEquivalencias,
            tooltip: 'Ver tabla de equivalencias',
          ),
        
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0), // Padding general
        children: [
          Text(
            'CALCULADORA DE CONVERSIÓN',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600), // Estilo de título
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // --- Sección Rendimiento con Card ---
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 24), // Espacio después de la card
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RENDIMIENTO',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), // Título de sección
                  ),
                  const SizedBox(height: 16),
                  // Encabezados de la tabla
                  Row(
                    children: [
                      Expanded(child: Text('ORIGINAL', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                      Expanded(child: Text('UNIDAD', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('NUEVO', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Fila de datos de rendimiento
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cantidad Original (TextField deshabilitado)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: TextField(
                            controller: _cantidadController,
                            enabled: false,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                            decoration: inputDecoration.copyWith(
                              fillColor: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                            ),
                          ),
                        ),
                      ),
                      // Unidad Original (Container con texto)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            height: 40, // Altura consistente
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              // *** CORREGIDO: Mostrar abreviatura también para la unidad original ***
                              _unidadesAbreviadas[_unidadOriginal] ?? _unidadOriginal,
                              // _unidadesAbreviadas[_getUnidadPlural(_unidadOriginal, _platosOrigen)] ??
                              //     _getUnidadPlural(_unidadOriginal, _platosOrigen),
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      // Nuevo Rendimiento (Campo + Dropdown)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4.0, right: 2.0),
                                child: TextField(
                                  controller: _destinoController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium,
                                  decoration: inputDecoration,
                                  onChanged: (value) { /* Lógica existente */ },
                                  onEditingComplete: () {
                                      // ... (Lógica onEditingComplete existente sin cambios) ...
                                      final controller = _destinoController;
                                      String valorTexto = controller.text;

                                      print("\n✅ Edición completada para Rendimiento (_buildTextFieldDestino)");
                                      print("Texto actual en el campo: '$valorTexto'");

                                      double valorNumerico;

                                      try {
                                          if (valorTexto.isEmpty) {
                                              print("⚠️ Campo de rendimiento vacío detectado. Usando valor mínimo 0.01");
                                              valorNumerico = 0.01;
                                          } else {
                                              valorNumerico = double.parse(valorTexto.replaceAll(',', '.'));
                                              if (valorNumerico <= 0 || valorNumerico.isNaN || valorNumerico.isInfinite) {
                                                  print("⚠️ Valor numérico de rendimiento inválido: $valorNumerico. Usando valor mínimo 0.01");
                                                  valorNumerico = 0.01;
                                              }
                                          }
                                      } catch (e) {
                                          print("❌ Error al parsear rendimiento '$valorTexto'. Usando valor mínimo 0.01. Error: $e");
                                          valorNumerico = 0.01;
                                      }
                                      
                                      String valorFormateado = _formatearNumero(valorNumerico);
                                      controller.text = valorFormateado;
                                      print("Valor de rendimiento formateado y actualizado en el campo: $valorFormateado");

                                      _actualizarRendimientoManualmente(valorFormateado);
                                      
                                      FocusScope.of(context).unfocus();
                                    
                                  },
                                ),
                              ),
                            ),
                            // Dropdown Unidad Destino
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 2.0),
                                child: DropdownButtonFormField<String>(
                                  value: _unidadDestino,
                                  isExpanded: true,
                                  style: textTheme.bodyMedium,
                                  decoration: inputDecoration.copyWith(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, size: 20, color: textTheme.bodyMedium?.color),
                                  items: _unidadesRendimiento.map((String unidad) {
                                    return DropdownMenuItem<String>(
                                      value: unidad,
                                      child: Text(
                                        _unidadesAbreviadas[unidad] ?? unidad,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
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
                                          // Usamos conversión directa al cambiar unidades
                                          double factorConversion = 1.0;
                                          
                                          // Intentamos una conversión directa usando el mapa de factores
                                          if (_factoresRendimiento.containsKey(unidadAnterior) && 
                                              _factoresRendimiento[unidadAnterior]!.containsKey(value)) {
                                            factorConversion = _factoresRendimiento[unidadAnterior]![value]!;
                                          }
                                          // Si no hay conversión directa, intentamos conversión inversa
                                          else if (_factoresRendimiento.containsKey(value) && 
                                                   _factoresRendimiento[value]!.containsKey(unidadAnterior)) {
                                            factorConversion = 1.0 / _factoresRendimiento[value]![unidadAnterior]!;
                                          }
                                          // Si ninguna funciona, intentamos a través de una unidad base
                                          else {
                                            // Determinar la unidad base adecuada
                                            String unidadBase = "";
                                            if (_esTipoUnidadPeso(unidadAnterior) || _esTipoUnidadPeso(value)) {
                                              unidadBase = "Gramo";
                                            } else if (_esTipoUnidadVolumen(unidadAnterior) || _esTipoUnidadVolumen(value)) {
                                              unidadBase = "Mililitros";
                                            }
                                            
                                            // Verificar si podemos hacer la conversión a través de la unidad base
                                            if (unidadBase.isNotEmpty) {
                                              double aBase = _convertirRendimiento(1.0, unidadAnterior, unidadBase);
                                              double desdeBase = _convertirRendimiento(1.0, unidadBase, value);
                                              
                                              if (!aBase.isNaN && !desdeBase.isNaN && aBase > 0 && desdeBase > 0) {
                                                factorConversion = aBase * desdeBase;
                                              }
                                            }
                                          }
                                          
                                          // Calcular la nueva cantidad usando el factor de conversión
                                          double nuevaCantidad = _platosDestino * factorConversion;
                                          
                                          print("⭐ CAMBIO DE UNIDAD DE RENDIMIENTO:");
                                          print("  - De: $_platosDestino $unidadAnterior");
                                          print("  - Factor: $factorConversion");
                                          print("  - A: $nuevaCantidad $value");
                                          
                                          // Verificar que la nueva cantidad sea válida
                                          if (nuevaCantidad.isNaN || nuevaCantidad.isInfinite || nuevaCantidad <= 0) {
                                            print("⚠️ Valor inválido: $nuevaCantidad. Usando el valor anterior");
                                            nuevaCantidad = _platosDestino;
                                          }
                                          
                                          // Actualizar los valores con redondeo para evitar errores de punto flotante
                                          _platosDestino = _redondearPrecision(nuevaCantidad);
                                          _destinoController.text = _formatearNumero(_platosDestino);
                                          _resultado = _platosDestino;
                                          
                                          // Recalcular todos los ingredientes basándose en el nuevo factor de unidad
                                          // No se aplica proporcionalidad aquí para no alterar la receta
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sección Resultado
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer, // Usar color del tema
                        borderRadius: BorderRadius.circular(30), // Más redondeado
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Resultado: ',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${_formatearNumero(_platosDestino)} ${_unidadesAbreviadas[_unidadDestino] ?? _unidadDestino}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), // Fin Card Rendimiento

          // --- Inicio Sección Tabla Ingredientes con Card ---
          Text(
            'TABLA DE INGREDIENTES',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), // Título de sección
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // Encabezado de la tabla de ingredientes
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('INGREDIENTE', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                      Expanded(child: Text('CANTIDAD', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                      Expanded(child: Text('UNIDAD', style: textTheme.labelMedium, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                // Filas de ingredientes
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredientesTabla.length,
                  itemBuilder: (context, index) {
                    final ingrediente = _ingredientesTabla[index];
                    // Usar Divider para separación visual entre filas
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Nombre Ingrediente (TextField deshabilitado)
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: TextField(
                                    controller: ingrediente.nombreController,
                                    readOnly: true,
                                    style: textTheme.bodyMedium,
                                    decoration: inputDecoration.copyWith(
                                      fillColor: isDarkMode ? Colors.black26 : Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ),
                              // Cantidad Ingrediente (TextField habilitado)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: TextField(
                                    controller: ingrediente.cantidadController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                    ],
                                    textAlign: TextAlign.center, // Centrar cantidad
                                    style: textTheme.bodyMedium,
                                    decoration: inputDecoration,
                                    onChanged: (value) { /* Lógica existente */ },
                                    onEditingComplete: () {
                                      // ... (Lógica onEditingComplete existente sin cambios) ...
                                      final index = _ingredientesTabla.indexOf(ingrediente);
                                      final controller = ingrediente.cantidadController;
                                      String valorTexto = controller.text;

                                      print("\n✅ Edición completada para ingrediente #$index");
                                      print("Texto actual en el campo: '$valorTexto'");

                                      double valorNumerico;
                                      
                                      // Intentar parsear el valor
                                      try {
                                          if (valorTexto.isEmpty) {
                                              print("⚠️ Campo vacío detectado. Usando valor mínimo 0.01");
                                              valorNumerico = 0.01;
                                          } else {
                                              valorNumerico = double.parse(valorTexto.replaceAll(',', '.'));
                                              if (valorNumerico <= 0 || valorNumerico.isNaN || valorNumerico.isInfinite) {
                                                  print("⚠️ Valor numérico inválido: $valorNumerico. Usando valor mínimo 0.01");
                                                  valorNumerico = 0.01;
                                              }
                                          }
                                      } catch (e) {
                                          print("❌ Error al parsear '$valorTexto'. Usando valor mínimo 0.01. Error: $e");
                                          valorNumerico = 0.01;
                                      }
                                      
                                      // Formatear el valor numérico válido y actualizar el campo de texto
                                      String valorFormateado = _formatearNumero(valorNumerico);
                                      controller.text = valorFormateado;
                                      print("Valor formateado y actualizado en el campo: $valorFormateado");

                                      // Ahora, llamar a la lógica principal de actualización con el valor validado/formateado
                                      // Usamos el valor formateado para asegurar consistencia
                                      _actualizarRecetaPorIngrediente(index, valorFormateado);
                                      
                                      // Quitar foco para cerrar teclado
                                      FocusScope.of(context).unfocus();
                                    },
                                  ),
                                ),
                              ),
                              // Unidad Ingrediente (Dropdown o Texto fijo)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: (_normalizarUnidad(ingrediente.unidadOriginal) == 'Unidad')
                                      ? Container(
                                          height: 40, // Altura consistente
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.black26 : Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _unidadesAbreviadas['Unidad'] ?? 'Unidad',
                                            style: textTheme.bodyMedium?.copyWith(color: Colors.grey), // Estilo deshabilitado
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      : DropdownButtonFormField<String>(
                                          value: ingrediente.unidad,
                                          isExpanded: true,
                                          style: textTheme.bodyMedium,
                                          decoration: inputDecoration.copyWith(
                                             contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Ajuste padding
                                          ),
                                          icon: Icon(Icons.arrow_drop_down, size: 20, color: textTheme.bodyMedium?.color),
                                          items: _unidadesIngredientes.map((String unidad) {
                                            return DropdownMenuItem<String>(
                                              value: unidad,
                                              child: Text(
                                                _unidadesAbreviadas[unidad] ?? unidad,
                                                style: textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? value) {
                                            // ... (Lógica onChanged existente sin cambios) ...
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
                        ),
                        // Añadir un Divider si no es el último elemento
                        if (index < _ingredientesTabla.length - 1)
                          Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withOpacity(0.3)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ), // Fin Card Tabla Ingredientes

          // Botón para compartir PDF (estilo igual al ejemplo)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _generarPDF();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5CAE9),
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share,
                      size: 16,
                      color: const Color.fromARGB(255, 76, 117, 250),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Compartir PDF',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUnidadPlural(String unidad, double cantidad) {
    if (cantidad <= 1) return unidad;
    return _unidadesPlural[unidad] ?? '${unidad}s';
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
          title: const Text('Tabla de Equivalencias',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEquivalenciasSection('UNIDADES DE PESO', [
                  '1 Kilogramo (kg) = 1000 Gramos (g)',
                  '1 Gramo (g) = 1000 Miligramos (mg)',
                  '1 Libra (lb) = 453.6 Gramos (g)',
                  '1 Libra (lb) = 16 Onzas (oz)',
                  '1 Onza (oz) = 28.35 Gramos (g)',
                ]),
                const SizedBox(height: 12),
                _buildEquivalenciasSection('UNIDADES DE VOLUMEN', [
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
                ]),
                const SizedBox(height: 12),
                _buildEquivalenciasSection('PORCIONES', [
                  '1 Porción = 250 Gramos (g)',
                  '1 Porción = 0.25 Kilogramos (kg)',
                  '1 Porción = 250 Mililitros (ml)',
                  '1 Porción = 8.8 Onzas (oz)',
                  '1 Porción = 0.55 Libras (lb)',
                  '1 Kilogramo (kg) = 4 Porciones',
                  '1 Litro (L) = 4 Porciones',
                ]),
                const SizedBox(height: 12),
                _buildEquivalenciasSection('PESO-VOLUMEN (aprox.)', [
                  '1 Gramo (g) = 1 Mililitro (ml) de agua',
                  '1 Kilogramo (kg) = 1 Litro (L) de agua',
                  '1 Libra (lb) = 454 Mililitros (ml) de agua',
                  '1 Onza (oz) = 28.4 Mililitros (ml) de agua',
                ]),
                const SizedBox(height: 8),
                const Text('Nota: Las conversiones entre peso y volumen son aproximadas y válidas principalmente para agua.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
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
        )).toList(),
      ],
    );
  }

  // Método para reiniciar valores base y prevenir acumulación de errores
  void _reiniciarValoresBase() {
    print("SISTEMA: Reiniciando valores base para prevenir acumulación de errores");
    
    // Restablecer contador
    _contadorConversiones = 0;
    _sistemaPurificado = true;
    
    try {
      // Guardar valores actuales importantes
      double platosDestinoActual = _platosDestino;
      String unidadDestinoActual = _unidadDestino;
      
      // Reconstruir la estructura de datos completamente
      setState(() {
        // Reconstrucción completa de ingredientes
        for (var ingrediente in _ingredientesTabla) {
          // Nos aseguramos que la cantidad sea válida
          if (ingrediente.cantidad.isNaN || ingrediente.cantidad.isInfinite || ingrediente.cantidad <= 0) {
            ingrediente.cantidad = 0.01;
          }
          
          // Para ingredientes modificados manualmente, mantenemos su estado
          if (ingrediente.modificadoManualmente) {
            ingrediente.cantidadOriginal = ingrediente.cantidad;
          } else {
            // Sincronizamos cantidadOriginal con cantidad actual
            ingrediente.cantidadOriginal = ingrediente.cantidad;
          }
          
          // Reconstruir controladores de texto con valores correctos
          ingrediente.cantidadController.text = _formatearNumero(ingrediente.cantidad);
        }
        
        // Actualizar los valores de rendimiento
        _platosDestino = platosDestinoActual;
        _destinoController.text = _formatearNumero(_platosDestino);
        
        // Recalcular valores base para futuras referencias
        if (_esTipoUnidadPeso(unidadDestinoActual)) {
          _valorBaseGramos = _convertirRendimiento(_platosDestino, unidadDestinoActual, 'Gramo');
        } else if (_esTipoUnidadVolumen(unidadDestinoActual)) {
          _valorBaseMililitros = _convertirRendimiento(_platosDestino, unidadDestinoActual, 'Mililitros');
        }
      });
      
      print("SISTEMA: Reinicio completado. Sistema estabilizado.");
    } catch (e) {
      print("Error al reiniciar valores base: $e");
    }
  }

  // Método para actualizar ingredientes cuando cambia el rendimiento
  void _actualizarIngredientesAlCambiarRendimiento(double factorEscala) {
    print("🔄 ACTUALIZANDO INGREDIENTES CON FACTOR DE ESCALA: $factorEscala");
    
    for (var ingrediente in _ingredientesTabla) {
      // Si el ingrediente fue modificado manualmente, no lo alteramos
      if (ingrediente.modificadoManualmente) {
        print("ℹ️ Ingrediente '${ingrediente.nombre}' modificado manualmente, conservando valor");
        continue;
      }
      
      // Validar que cantidadOriginal sea válida
      if (ingrediente.cantidadOriginal <= 0 || ingrediente.cantidadOriginal.isNaN || ingrediente.cantidadOriginal.isInfinite) {
        print("⚠️ cantidadOriginal inválida para '${ingrediente.nombre}': ${ingrediente.cantidadOriginal}. Reiniciando");
        ingrediente.cantidadOriginal = 0.01;
      }
      
      // Calcular la nueva cantidad usando cantidadOriginal como base
      double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
      
      // Validar que la nueva cantidad sea válida
      if (nuevaCantidad <= 0 || nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
        print("⚠️ Nueva cantidad inválida para '${ingrediente.nombre}': $nuevaCantidad. Usando valor mínimo");
        nuevaCantidad = 0.01;
      }
      
      // Aplicar redondeo para evitar imprecisiones numéricas
      nuevaCantidad = _redondearPrecision(nuevaCantidad);
      
      print("  • '${ingrediente.nombre}': ${ingrediente.cantidadOriginal} ${ingrediente.unidadOriginal} → $nuevaCantidad ${ingrediente.unidad}");
      
      // Actualizar la cantidad manteniendo la unidad original
      setState(() {
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      });
    }
  }

  // Método para cambiar la unidad de un ingrediente
  void _cambiarUnidadIngrediente(int index, String nuevaUnidad) {
    final ingrediente = _ingredientesTabla[index];
    if (ingrediente.unidad == nuevaUnidad) return;
    
    // Realizamos la conversión de la cantidad actual a la nueva unidad
    double nuevaCantidad;
    
    // Si es conversión entre unidades de peso
    if (_esTipoUnidadPeso(ingrediente.unidad) && _esTipoUnidadPeso(nuevaUnidad)) {
      // Convertir entre kg, g, etc.
      if (ingrediente.unidad == 'Kilogramo' && nuevaUnidad == 'Gramo') {
        nuevaCantidad = ingrediente.cantidad * 1000;
      } else if (ingrediente.unidad == 'Gramo' && nuevaUnidad == 'Kilogramo') {
        nuevaCantidad = ingrediente.cantidad / 1000;
      } else {
        // Otras conversiones de peso (implementar según necesidad)
        nuevaCantidad = ingrediente.cantidad;
      }
    } 
    // Si es conversión entre unidades de volumen
    else if (_esTipoUnidadVolumen(ingrediente.unidad) && _esTipoUnidadVolumen(nuevaUnidad)) {
      // Convertir entre l, ml, etc.
      if (ingrediente.unidad == 'Litro' && nuevaUnidad == 'Mililitro') {
        nuevaCantidad = ingrediente.cantidad * 1000;
      } else if (ingrediente.unidad == 'Mililitro' && nuevaUnidad == 'Litro') {
        nuevaCantidad = ingrediente.cantidad / 1000;
      } else {
        // Otras conversiones de volumen (implementar según necesidad)
        nuevaCantidad = ingrediente.cantidad;
      }
    } else {
      // Si las unidades no son del mismo tipo, mantenemos la cantidad
      nuevaCantidad = ingrediente.cantidad;
    }
    
    // Actualizamos el ingrediente con la nueva unidad y cantidad
    setState(() {
      ingrediente.cantidad = nuevaCantidad;
      ingrediente.unidad = nuevaUnidad;
      ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      
      // Marcamos que este ingrediente ha sido modificado manualmente
      ingrediente.modificadoManualmente = true;
    });
  }

  // Método para verificar la coherencia de las unidades (para diagnóstico)
  void _verificarCoherenciaUnidades() {
    for (var ingrediente in _ingredientesTabla) {
      print("Ingrediente: ${ingrediente.nombre}, Cantidad: ${ingrediente.cantidad}, Unidad: ${ingrediente.unidad}");
      
      // Verificar que la unidad sea válida
      if (!_unidadesIngredientes.contains(ingrediente.unidad)) {
        print("⚠️ Unidad inválida detectada: ${ingrediente.unidad}");
      }
      
      // Verificar que la cantidad sea adecuada para la unidad
      if (ingrediente.unidad == 'Gramo' && ingrediente.cantidad > 10000) {
        print("⚠️ Cantidad muy grande para gramos: ${ingrediente.cantidad}g");
      }
      
      if (ingrediente.unidad == 'Kilogramo' && ingrediente.cantidad < 0.01) {
        print("⚠️ Cantidad muy pequeña para kilogramos: ${ingrediente.cantidad}kg");
      }
    }
  }

  void _inicializarIngredientes() {
    print("Inicializando ingredientes de la receta...");
    
    _ingredientesTabla = widget.recipe.ingredients.map((ingredient) {
      // Validar la cantidad para asegurar que no sea 0
      double cantidad = ingredient.quantity;
      if (cantidad <= 0) {
        print("⚠️ Cantidad inválida (${cantidad}) para '${ingredient.name}'. Corrigiendo a 0.01");
        cantidad = 0.01;
      }
      
      // *** Normalizar la unidad ANTES de usarla ***
      String unidadNormalizada = _normalizarUnidad(ingredient.unit);
      // Si la normalización falla y devuelve vacío, usar valor por defecto
      if (unidadNormalizada.isEmpty){
         print("🚨 Unidad inicial '${ingredient.unit}' no pudo ser normalizada a una válida para '${ingredient.name}'. Usando 'Gramo' por defecto.");
         unidadNormalizada = 'Gramo'; // Usar la primera unidad válida por defecto
      }

      // Crear el controlador de texto con el formato adecuado
      final cantidadController = TextEditingController(text: _formatearNumero(cantidad));
      
      // Crear el ingrediente usando la unidad normalizada
      final ingrediente = IngredienteTabla(
        nombre: ingredient.name,
        cantidad: cantidad,
        unidad: unidadNormalizada, // <-- Usar unidad normalizada
        cantidadController: cantidadController,
        cantidadOriginal: cantidad, // Guardar la cantidad original
        unidadOriginal: unidadNormalizada, // <-- Guardar unidad normalizada también como original
        modificadoManualmente: false,
        // Calcular y asignar el valor base inicial
        valorBaseGramos: _esTipoUnidadPeso(unidadNormalizada)
            ? _convertirAUnidadBase(cantidad, unidadNormalizada, 'peso')
            : null,
        valorBaseMililitros: _esTipoUnidadVolumen(unidadNormalizada)
            ? _convertirAUnidadBase(cantidad, unidadNormalizada, 'volumen')
            : null,
      );
      
      print("Ingrediente inicializado: '${ingrediente.nombre}' - ${ingrediente.cantidad} ${ingrediente.unidad} (Original: ${ingrediente.cantidadOriginal} ${ingrediente.unidadOriginal}) -> BaseG: ${ingrediente.valorBaseGramos}, BaseMl: ${ingrediente.valorBaseMililitros}");
      return ingrediente;
    }).toList();
  }

  void _actualizarRendimiento(double nuevoRendimiento) {
    // Validar que el nuevo rendimiento sea válido
    if (nuevoRendimiento <= 0) {
      print("⚠️ Rendimiento inválido: $nuevoRendimiento. Usando valor mínimo");
      nuevoRendimiento = 0.01;
    }
    
    // Guardar el valor original antes de actualizar
    double rendimientoAnterior = _platosDestino;
    
    // Calcular el factor de escala basado en el rendimiento original
    double factorEscala = nuevoRendimiento / _platosOrigen;
    
    print("🔄 ACTUALIZANDO RENDIMIENTO:");
    print("  - Rendimiento original: $_platosOrigen");
    print("  - Rendimiento anterior: $rendimientoAnterior");
    print("  - Nuevo rendimiento: $nuevoRendimiento");
    print("  - Factor de escala: $factorEscala");
    
    setState(() {
      // Actualizar el rendimiento destino
      _platosDestino = nuevoRendimiento;
      _destinoController.text = _formatearNumero(nuevoRendimiento);
      
      // Actualizar los ingredientes manteniendo sus unidades originales
      for (var ingrediente in _ingredientesTabla) {
        // Si el ingrediente fue modificado manualmente, no lo alteramos
        if (ingrediente.modificadoManualmente) {
          print("ℹ️ Ingrediente '${ingrediente.nombre}' modificado manualmente, conservando valor");
          continue;
        }
        
        // Calcular la nueva cantidad basada en la cantidad original
        double nuevaCantidad = ingrediente.cantidadOriginal * factorEscala;
        
        // Validar y redondear la nueva cantidad
        if (nuevaCantidad <= 0 || nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
          print("⚠️ Cantidad inválida para '${ingrediente.nombre}': $nuevaCantidad. Usando valor mínimo");
          nuevaCantidad = 0.01;
        }
        
        nuevaCantidad = _redondearPrecision(nuevaCantidad);
        
        print("  • '${ingrediente.nombre}': ${ingrediente.cantidadOriginal} ${ingrediente.unidad} → $nuevaCantidad ${ingrediente.unidad}");
        
        // Actualizar la cantidad manteniendo la unidad original
        ingrediente.cantidad = nuevaCantidad;
        ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
      }
    });
  }

  // Método para convertir cualquier unidad a gramos
  double _convertirAGramos(double cantidad, String unidad) {
    try {
      // Si ya está en gramos, devolver la cantidad
      if (unidad == 'Gramo') return cantidad;
      
      // Si es una unidad de peso, usar factores de conversión directos
      if (_esTipoUnidadPeso(unidad)) {
        switch (unidad) {
          case 'Kilogramo':
            return cantidad * 1000;
          case 'Miligramos':
            return cantidad / 1000;
          case 'Onza':
            return cantidad * 28.3495;
          case 'Libra':
            return cantidad * 453.592;
          default:
            return cantidad;
        }
      }
      
      // Si es una unidad de volumen, asumir densidad de agua (1g = 1ml)
      if (_esTipoUnidadVolumen(unidad)) {
        // Primero convertir a mililitros
        double mililitros = _convertirAMililitros(cantidad, unidad);
        // Luego asumir 1ml = 1g (densidad del agua)
        return mililitros;
      }
      
      // Si no es una unidad reconocida, devolver la cantidad original
      return cantidad;
    } catch (e) {
      print("Error al convertir a gramos: $e");
      return cantidad;
    }
  }

  // Método auxiliar para convertir a mililitros
  double _convertirAMililitros(double cantidad, String unidad) {
    switch (unidad) {
      case 'Mililitros':
        return cantidad;
      case 'Litro':
        return cantidad * 1000;
      case 'Centilitros':
        return cantidad * 10;
      case 'Cucharada':
        return cantidad * 15;
      case 'Cucharadita':
        return cantidad * 5;
      case 'Taza':
        return cantidad * 240;
      case 'Onza liquida':
        return cantidad * 29.5735;
      case 'Pinta':
        return cantidad * 473.176;
      case 'Cuarto galon':
        return cantidad * 946.353;
      case 'Galon':
        return cantidad * 3785.41;
      default:
        return cantidad;
    }
  }

  void _actualizarRendimientoReceta() {
    try {
      print("Iniciando conversión de rendimiento...");
      print("Rendimiento original: ${_platosOrigen}");
      print("Nuevo rendimiento: $_platosDestino");
      
      // Validar el nuevo rendimiento
      if (_platosDestino <= 0) {
        print("❌ Error: El nuevo rendimiento debe ser mayor que 0");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nuevo rendimiento debe ser mayor que 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Calcular el factor de conversión
      final factor = _platosDestino / _platosOrigen;
      print("Factor de conversión calculado: $factor");
      
      // Actualizar cada ingrediente
      for (var ingrediente in _ingredientesTabla) {
        try {
          // Calcular la nueva cantidad manteniendo la unidad original
          double nuevaCantidad = ingrediente.cantidadOriginal * factor;
          
          // Validar y redondear la nueva cantidad
          if (nuevaCantidad <= 0 || nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
            print("⚠️ Cantidad inválida para '${ingrediente.nombre}': $nuevaCantidad. Usando valor mínimo");
            nuevaCantidad = 0.01;
          }
          
          nuevaCantidad = _redondearPrecision(nuevaCantidad);
          
          // Actualizar el controlador y la cantidad
          ingrediente.cantidadController.text = _formatearNumero(nuevaCantidad);
          ingrediente.cantidad = nuevaCantidad;
          
          print("Ingrediente actualizado: ${ingrediente.nombre} - ${ingrediente.cantidadOriginal} ${ingrediente.unidad} → $nuevaCantidad ${ingrediente.unidad}");
        } catch (e) {
          print("❌ Error al actualizar ingrediente ${ingrediente.nombre}: $e");
        }
      }
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendimiento convertido exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print("❌ Error en _actualizarRendimientoReceta: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al convertir rendimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método llamado cuando la cantidad de un ingrediente es modificada manualmente
  void _actualizarRecetaPorIngrediente(int index, String nuevaCantidadTexto) {
    print("\n🔄 ACTUALIZACIÓN PROPORCIONAL POR INGREDIENTE #$index"); // Nombre ajustado
    print("Valor ingresado: '$nuevaCantidadTexto'");

    if (index < 0 || index >= _ingredientesTabla.length) {
      print("❌ Índice inválido: $index");
      return;
    }

    try {
      final ingredienteModificado = _ingredientesTabla[index];
      double nuevaCantidad = double.parse(nuevaCantidadTexto.replaceAll(',', '.'));

      if (nuevaCantidad <= 0 || nuevaCantidad.isNaN || nuevaCantidad.isInfinite) {
        print("⚠️ Cantidad inválida: $nuevaCantidad. Usando 0.01");
        nuevaCantidad = 0.01;
      }
      nuevaCantidad = _redondearPrecision(nuevaCantidad);

      // --- Lógica Restaurada y Corregida ---
      double cantidadAnterior = ingredienteModificado.cantidad;
      if (cantidadAnterior <= 0 || cantidadAnterior.isNaN || cantidadAnterior.isInfinite) {
          print("⚠️ Cantidad anterior inválida para '${ingredienteModificado.nombre}': $cantidadAnterior. No se puede escalar.");
          // Solo actualizar el ingrediente modificado sin escalar nada más
          setState(() {
              ingredienteModificado.cantidad = nuevaCantidad;
              ingredienteModificado.cantidadController.text = _formatearNumero(nuevaCantidad);
              ingredienteModificado.modificadoManualmente = true;
          });
          return;
      }

      // Calcular factor de escala RELATIVO al cambio actual
      double factorEscala = nuevaCantidad / cantidadAnterior;
      print("Factor de escala relativo calculado: $factorEscala (Nueva: $nuevaCantidad / Anterior: $cantidadAnterior)");

      if (factorEscala.isNaN || factorEscala.isInfinite || factorEscala <= 0) {
          print("⚠️ Factor de escala relativo inválido: $factorEscala. Abortando.");
          // Restablecer campo de texto
          ingredienteModificado.cantidadController.text = _formatearNumero(cantidadAnterior);
          return;
      }

      setState(() {
          // 1. Actualizar el ingrediente modificado y marcarlo
          ingredienteModificado.cantidad = nuevaCantidad;
          ingredienteModificado.cantidadController.text = _formatearNumero(nuevaCantidad);
          ingredienteModificado.modificadoManualmente = true;
          print("  ✅ Ingrediente '${ingredienteModificado.nombre}' actualizado a $nuevaCantidad ${ingredienteModificado.unidad} (marcado manual)");

          // 2. Actualizar el rendimiento total (_platosDestino) usando el factor RELATIVO
          double rendimientoAnterior = _platosDestino;
          double nuevoRendimiento = rendimientoAnterior * factorEscala;
          if (nuevoRendimiento <= 0 || nuevoRendimiento.isNaN || nuevoRendimiento.isInfinite) {
              nuevoRendimiento = 0.01;
          }
          _platosDestino = _redondearPrecision(nuevoRendimiento);
          _destinoController.text = _formatearNumero(_platosDestino);
          print("  ✅ Rendimiento actualizado de $rendimientoAnterior a $_platosDestino $_unidadDestino");

          // 3. Actualizar los OTROS ingredientes 
          //    basándose en sus cantidades ACTUALES y el factor RELATIVO.
          // --- CORRECCIÓN: Aplicar a TODOS los otros ingredientes --- 
          for (var i = 0; i < _ingredientesTabla.length; i++) {
              if (i == index) continue; // Saltar el ingrediente que inició el cambio

              final otroIngrediente = _ingredientesTabla[i];

              // --- Escalado basado en VALOR BASE --- 
              double? valorBaseAnterior = null;
              String? tipoUnidadOtro = null;

              if (otroIngrediente.valorBaseGramos != null) {
                 tipoUnidadOtro = 'peso';
                 valorBaseAnterior = otroIngrediente.valorBaseGramos;
              } else if (otroIngrediente.valorBaseMililitros != null) {
                 tipoUnidadOtro = 'volumen';
                 valorBaseAnterior = otroIngrediente.valorBaseMililitros;
              }

              if (valorBaseAnterior != null && tipoUnidadOtro != null) {
                 // Escalar el valor base
                 double nuevoValorBase = valorBaseAnterior * factorEscala;
                 nuevoValorBase = _redondearPrecision(nuevoValorBase); // Redondear base

                 if (tipoUnidadOtro == 'peso') {
                    otroIngrediente.valorBaseGramos = nuevoValorBase;
                 } else {
                    otroIngrediente.valorBaseMililitros = nuevoValorBase;
                 }

                 // Recalcular la cantidad visible desde la nueva base
                 double cantidadCalculada = _convertirDesdeUnidadBase(nuevoValorBase, otroIngrediente.unidad, tipoUnidadOtro);
                 if (cantidadCalculada <= 0 || cantidadCalculada.isNaN || cantidadCalculada.isInfinite) {
                     cantidadCalculada = 0.01;
                 }
                 cantidadCalculada = _redondearPrecision(cantidadCalculada);

                 otroIngrediente.cantidad = cantidadCalculada;
                 otroIngrediente.cantidadController.text = _formatearNumero(cantidadCalculada);
                 print("  ✅ Ingrediente '${otroIngrediente.nombre}' actualizado (Base: $nuevoValorBase -> Cant: $cantidadCalculada ${otroIngrediente.unidad})");
              } else {
                // --- INICIO CAMBIO ---
                // Escalar usando cantidadOriginal si no hay valor base (para 'Unidad', etc.)
                print("  ℹ️ Escalando '${otroIngrediente.nombre}' usando cantidad original (sin valor base).");
                if (otroIngrediente.cantidadOriginal > 0 && !otroIngrediente.cantidadOriginal.isNaN && !otroIngrediente.cantidadOriginal.isInfinite) {
                   double cantidadCalculada = otroIngrediente.cantidadOriginal * factorEscala;
                   if (cantidadCalculada <= 0 || cantidadCalculada.isNaN || cantidadCalculada.isInfinite) {
                       cantidadCalculada = 0.01;
                   }
                   cantidadCalculada = _redondearPrecision(cantidadCalculada);

                   // Actualizar cantidad y controlador
                   otroIngrediente.cantidad = cantidadCalculada;
                   otroIngrediente.cantidadController.text = _formatearNumero(cantidadCalculada);
                   // Mantener la unidad original (no hay base para recalcular)
                   print("  ✅ Ingrediente '${otroIngrediente.nombre}' actualizado a $cantidadCalculada ${otroIngrediente.unidad} (escalado por original)");
                } else {
                   print("  ⚠️ No se pudo escalar '${otroIngrediente.nombre}' porque su cantidad original es inválida (${otroIngrediente.cantidadOriginal}).");
                }
                // --- FIN CAMBIO ---
              }
              // --- Fin Escalado basado en VALOR BASE ---
          }
      });
      // --- Fin Lógica Restaurada y Corregida ---

    } catch (e) {
      print("❌ Error en _actualizarRecetaPorIngrediente: $e");
      // Considerar restablecer el campo de texto problemático
      final ingrediente = _ingredientesTabla[index];
      ingrediente.cantidadController.text = _formatearNumero(ingrediente.cantidad);
    }
  }

  // Método llamado cuando se cambia la cantidad del rendimiento manualmente
  void _actualizarRendimientoManualmente(String nuevoValorTexto) {
     print("\n🔄 ACTUALIZACIÓN MANUAL DEL RENDIMIENTO (Valor: '$nuevoValorTexto' en Unidad: $_unidadDestino)");
     try {
       double nuevoValor = double.parse(nuevoValorTexto.replaceAll(',', '.'));
       if (nuevoValor <= 0) {
         print("⚠️ Valor inválido: $nuevoValor. Usando 0.01");
         nuevoValor = 0.01;
       }
       nuevoValor = _redondearPrecision(nuevoValor);

       // --- Inicio de la nueva lógica de cálculo de factor ---
       // Convertir el nuevo valor (que está en _unidadDestino) de vuelta a la _unidadOriginal de la receta
       double nuevoValorEnUnidadOriginal = _convertirRendimiento(nuevoValor, _unidadDestino, _unidadOriginal);

       if (nuevoValorEnUnidadOriginal.isNaN || nuevoValorEnUnidadOriginal.isInfinite || nuevoValorEnUnidadOriginal <= 0) {
            print("⚠️ Error al convertir el nuevo valor ($nuevoValor $_unidadDestino) a la unidad original ($_unidadOriginal). Abortando.");
            _destinoController.text = _formatearNumero(_platosDestino); // Revertir texto del campo
            return;
       }
       print("Nuevo valor convertido a unidad original: $nuevoValorEnUnidadOriginal $_unidadOriginal");

       // Validar el valor y la unidad originales de la receta
       if (_platosOrigenOriginal <= 0 || _platosOrigenOriginal.isNaN || _platosOrigenOriginal.isInfinite) {
          print("⚠️ Rendimiento original base ($_platosOrigenOriginal $_unidadOriginal) inválido. No se puede escalar.");
          // Solo actualizar el valor del rendimiento destino sin escalar ingredientes
          setState(() {
             _platosDestino = nuevoValor; // Mantener el valor en la unidad actual
             _destinoController.text = _formatearNumero(nuevoValor);
          });
          return;
       }

       // Calcular el factor de escala basado en los valores *originales*
       double factorEscala = nuevoValorEnUnidadOriginal / _platosOrigenOriginal;
       print("Factor de escala calculado: $factorEscala (Nuevo en Unidad Orig: $nuevoValorEnUnidadOriginal / Base Original: $_platosOrigenOriginal)");
       // --- Fin de la nueva lógica de cálculo de factor ---

       if (factorEscala.isNaN || factorEscala.isInfinite || factorEscala <= 0) {
         print("⚠️ Factor de escala inválido: $factorEscala. Abortando.");
         _destinoController.text = _formatearNumero(_platosDestino); // Revertir texto
         return;
       }

       setState(() {
         // Actualizar el valor del rendimiento destino (en su unidad actual)
         _platosDestino = nuevoValor;
         _destinoController.text = _formatearNumero(nuevoValor);
         print("  ✅ Rendimiento actualizado a $_platosDestino $_unidadDestino");

         // Escalar ingredientes usando el factor calculado, BASADO EN VALORES ORIGINALES
         for (var ingrediente in _ingredientesTabla) {
           // Usar cantidadOriginal del ingrediente
           if (ingrediente.cantidadOriginal <= 0 || ingrediente.cantidadOriginal.isNaN || ingrediente.cantidadOriginal.isInfinite) {
             print("  ⚠️ Cantidad original inválida para '${ingrediente.nombre}': ${ingrediente.cantidadOriginal}. No se actualiza.");
             continue;
           }

           // Calcular cantidad basada en la original
           double cantidadCalculada = ingrediente.cantidadOriginal * factorEscala;
           if (cantidadCalculada <= 0 || cantidadCalculada.isNaN || cantidadCalculada.isInfinite) {
             cantidadCalculada = 0.01;
           }
           cantidadCalculada = _redondearPrecision(cantidadCalculada);

           // --- Actualizar cantidad Y RESTABLECER a unidad ORIGINAL ---
           ingrediente.cantidad = cantidadCalculada;
           ingrediente.unidad = ingrediente.unidadOriginal; // <-- RESTABLECER UNIDAD
           ingrediente.cantidadController.text = _formatearNumero(cantidadCalculada);
           // Resetear flag manual, ya que el cambio de rendimiento anula ajustes previos
           ingrediente.modificadoManualmente = false; 

           // --- Recalcular y actualizar valor base DESPUÉS de escalar cantidad/unidad originales ---
           if (_esTipoUnidadPeso(ingrediente.unidadOriginal)) {
              ingrediente.valorBaseGramos = _convertirAUnidadBase(cantidadCalculada, ingrediente.unidadOriginal, 'peso');
              ingrediente.valorBaseMililitros = null; // Asegurar que el otro sea null
           } else if (_esTipoUnidadVolumen(ingrediente.unidadOriginal)) {
              ingrediente.valorBaseMililitros = _convertirAUnidadBase(cantidadCalculada, ingrediente.unidadOriginal, 'volumen');
              ingrediente.valorBaseGramos = null; // Asegurar que el otro sea null
           } else {
              // Si es 'Unidad' u otra no convertible, limpiar bases
              ingrediente.valorBaseGramos = null;
              ingrediente.valorBaseMililitros = null;
           }

           print("  ✅ Ingrediente '${ingrediente.nombre}' actualizado a $cantidadCalculada ${ingrediente.unidad} (BaseG: ${ingrediente.valorBaseGramos}, BaseMl: ${ingrediente.valorBaseMililitros})"); // Log actualizado
         }
       });

     } catch (e) {
       print("❌ Error al actualizar rendimiento manualmente: $e");
       _destinoController.text = _formatearNumero(_platosDestino); // Revertir texto
     }
  }

  Widget _buildTextFieldDestino() {
    return SizedBox(
      width: 80,
      height: 40,
      child: TextField(
        controller: _destinoController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        ],
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onChanged: (value) {
          // Usar nuestro nuevo método para actualización manual del rendimiento
          if (value.isNotEmpty) {
            _actualizarRendimientoManualmente(value);
          }
        },
        // También actualizar onEditingComplete si es necesario
        onEditingComplete: () {
          if (_destinoController.text.isEmpty) {
            _destinoController.text = _formatearNumero(0.01);
            _actualizarRendimientoManualmente("0.01");
          } else {
             try {
                double valor = double.parse(_destinoController.text.replaceAll(',', '.'));
                if (valor <= 0) valor = 0.01;
                _destinoController.text = _formatearNumero(valor); 
                _actualizarRendimientoManualmente(_destinoController.text); 
             } catch (e) {
                print("Error al actualizar rendimiento manualmente en onEditingComplete: $e");
                _destinoController.text = _formatearNumero(_platosDestino); 
             }
          }
          FocusScope.of(context).unfocus(); 
        },
      ),
    );
  }
}