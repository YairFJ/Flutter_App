import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientConversion {
  final String nombre;
  double cantidadOriginal;
  String unidadOriginal;
  double cantidadNueva;
  String unidadNueva;
  bool modificado = false;

  IngredientConversion({
    required this.nombre,
    required this.cantidadOriginal,
    required this.cantidadNueva,
    required this.unidadOriginal,
    required this.unidadNueva,
  });
}

class ConversionTableDialog extends StatefulWidget {
  final List<Ingredient> originalIngredients;
  final bool standalone;

  const ConversionTableDialog({
    super.key,
    required this.originalIngredients,
    this.standalone = false,
  });

  @override
  State<ConversionTableDialog> createState() => _ConversionTableDialogState();
}

class _ConversionTableDialogState extends State<ConversionTableDialog> {
  late List<IngredientConversion> _ingredientes;

  @override
  void initState() {
    super.initState();
    _ingredientes = widget.originalIngredients.map((ing) {
      return IngredientConversion(
        nombre: ing.name,
        cantidadOriginal: ing.quantity,
        cantidadNueva: ing.quantity,
        unidadOriginal: ing.unit,
        unidadNueva: ing.unit,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
              shrinkWrap: true,
              itemCount: _ingredientes.length,
              itemBuilder: (context, index) {
                final ing = _ingredientes[index];
                return ListTile(
                  title: Text(ing.nombre),
                  subtitle: Text('${ing.cantidadOriginal} ${ing.unidadOriginal}'),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
} 