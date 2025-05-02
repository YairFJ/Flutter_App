import 'package:flutter/material.dart';

class IngredienteTabla {
  String nombre;
  double cantidad;
  String unidad;
  final TextEditingController nombreController;
  final TextEditingController cantidadController;
  double cantidadOriginal;
  String unidadOriginal;
  bool modificadoManualmente;
  double? valorBaseGramos;
  double? valorBaseMililitros;

  IngredienteTabla({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.cantidadController,
    required this.cantidadOriginal,
    required this.unidadOriginal,
    this.modificadoManualmente = false,
    this.valorBaseGramos,
    this.valorBaseMililitros,
  }) : nombreController = TextEditingController(text: nombre);

  void actualizarValores(double nuevaCantidad, String nuevaUnidad) {
    cantidad = nuevaCantidad;
    unidad = nuevaUnidad;
    cantidadController.text = nuevaCantidad.toString();
  }

  bool isValid() {
    return nombre.isNotEmpty && cantidad > 0 && unidad.isNotEmpty;
  }
}
