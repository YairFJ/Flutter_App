import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:share_plus/share_plus.dart';
import 'dart:io';

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
  double _valorOriginalRendimiento = 1.0;
  
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
    },
    'Kilogramo': {
      'Gramo': 1000,
      'Onza': 35.274,
      'Libra': 2.20462,
      'Mililitros': 1000.0, // 1kg = 1L = 1000ml
      'Litro': 1.0,        // 1kg = 1L (aproximado)
      'Porción': 4.0,      // 1kg = 4 porciones (250g = 1 porción)
    },
    'Onza': {
      'Gramo': 28.3495,
      'Kilogramo': 0.0283495,
      'Libra': 0.0625, // 1 onza = 1/16 libra
    },
    'Libra': {
      'Gramo': 453.592,
      'Kilogramo': 0.453592,
      'Onza': 16.0, // 1 libra = 16 onzas
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
    },
    'Centilitros': {
      'Mililitros': 10,
      'Litro': 0.01,
      'Cucharada': 0.666667,
      'Cucharadita': 2,
      'Taza': 0.0416667,
    },
    'Cucharada': {
      'Mililitros': 15,
      'Litro': 0.015,
      'Centilitros': 1.5,
      'Cucharadita': 3,
      'Taza': 0.0625,
    },
    'Cucharadita': {
      'Mililitros': 5,
      'Litro': 0.005,
      'Centilitros': 0.5,
      'Cucharada': 0.333333,
      'Taza': 0.0208333,
    },
    'Taza': {
      'Mililitros': 240,
      'Litro': 0.24,
      'Centilitros': 24,
      'Cucharada': 16,
      'Cucharadita': 48,
    },
    'Onza liquida': {
      'Mililitros': 29.5735,
      'Litro': 0.0295735,
      'Pinta': 0.0625,
      'Cuarto galon': 0.03125,
      'Galon': 0.0078125,
    },
    'Pinta': {
      'Mililitros': 473.176,
      'Litro': 0.473176,
      'Onza liquida': 16,
      'Cuarto galon': 0.5,
      'Galon': 0.125,
    },
    'Cuarto galon': {
      'Mililitros': 946.353,
      'Litro': 0.946353,
      'Onza liquida': 32,
      'Pinta': 2,
      'Galon': 0.25,
    },
    'Galon': {
      'Mililitros': 3785.41,
      'Litro': 3.78541,
      'Onza liquida': 128,
      'Pinta': 8,
      'Cuarto galon': 4,
    },
    'Porción': {
      'Gramo': 250.0,      // 1 porción = 250g
      'Kilogramo': 0.25,   // 1 porción = 0.25kg
      'Mililitros': 250.0, // 1 porción = 250ml
      'Litro': 0.25,      // 1 porción = 0.25L
    },
    'Miligramos': {
      'Gramo': 0.001,
      'Kilogramo': 0.000001,
    },
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
      print("Serving Size: ${widget.recipe.servingSize}");
      print("Ingredients: ${widget.recipe.ingredients}");

      final parts = widget.recipe.servingSize.trim().split(' ');
      if (parts.length >= 2) {
        _platosOrigen = double.tryParse(parts[0].replaceAll(',', '.')) ?? 1.0;
        _valorOriginalRendimiento = _platosOrigen;
        String unidadOriginalTemp = parts[1].toLowerCase();
        _unidadOriginal = _convertirUnidadAntigua[unidadOriginalTemp] ?? 'Persona';
        _unidadDestino = _unidadOriginal;
        _unidadActual = _unidadOriginal;
        
        // Inicializamos valores base de conversión
        if (_esTipoUnidadPeso(_unidadOriginal)) {
          _valorBaseGramos = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'peso');
        } else if (_esTipoUnidadVolumen(_unidadOriginal)) {
          _valorBaseMililitros = _convertirAUnidadBase(_platosOrigen, _unidadOriginal, 'volumen');
        }
      } else {
        _unidadOriginal = 'Persona';
        _unidadDestino = 'Persona';
        _unidadActual = 'Persona';
        _platosOrigen = 1.0;
        _valorOriginalRendimiento = 1.0;
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
      // Comprobemos primero si la conversión es válida
      if (!_esConversionValida(ingrediente.unidad, nuevaUnidad)) {
        print("ADVERTENCIA: No hay una conversión válida de ${ingrediente.unidad} a $nuevaUnidad");
        // Podríamos mostrar un diálogo al usuario aquí
        return;
      }

      setState(() {
        // Convertir la cantidad ACTUAL a la nueva unidad (no la cantidad base)
        double nuevaCantidad = _convertirRendimiento(
          ingrediente.cantidad, 
          ingrediente.unidad, 
          nuevaUnidad
        );
        
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
