import 'package:flutter/material.dart';

class IngredienteTabla {
  String nombre;
  double? cantidad;
  String unidad;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;

  IngredienteTabla({
    required this.nombre,
    this.cantidad = 0.0, // Valor por defecto
    required this.unidad,
  })  : nombreController = TextEditingController(text: nombre),
        cantidadController = TextEditingController(
            text: cantidad == 0.0
                ? '0,0'
                : cantidad.toString().replaceAll('.', ','));

  bool isValid() {
    return nombre.trim().isNotEmpty &&
        cantidadController.text.trim().isNotEmpty &&
        double.tryParse(cantidadController.text.replaceAll(',', '.')) != null;
  }
}
