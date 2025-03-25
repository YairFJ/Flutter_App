import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recipe.dart'; // Asegúrate de que la ruta y el modelo sean correctos.

/// Genera un PDF a partir de la información de una receta.
Future<Uint8List> generateRecipePdf(Recipe receta) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) => [
        pw.Center(
          child: pw.Text(
            receta.title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          receta.description ?? '',
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 20),
<<<<<<< Updated upstream
        pw.Text(
          'Rendimiento: ${receta.servingSize} ',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
=======
        
>>>>>>> Stashed changes
        pw.SizedBox(height: 20),
        pw.Text(
          "Ingredientes:",
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Ingrediente', 'Cantidad', 'Unidad'],
          data: receta.ingredients.map((ing) {
            return [
              ing.name,
              ing.quantity.toString(),
              ing.unit,
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellHeight: 30,
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          "Instrucciones:",
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: receta.steps
              .where((step) => step.trim().isNotEmpty)
              .map((step) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('* ', style: pw.TextStyle(fontSize: 12)),
                        pw.Expanded(
                          child: pw.Text(
                            step.trim(),
                            style: pw.TextStyle(fontSize: 12),
                            textAlign: pw.TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    ),
  );

  return pdf.save();
}
