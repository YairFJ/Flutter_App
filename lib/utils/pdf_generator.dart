import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recipe.dart'; // Asegúrate de que la ruta y el modelo sean correctos.
import 'package:flutter/material.dart';

/// Genera un PDF a partir de la información de una receta.
Future<Uint8List> generateRecipePdf(Recipe recipe, bool isDarkMode) async {
  final doc = pw.Document();
  final borderColor = PdfColors.grey400;

  doc.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              recipe.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: borderColor),
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Ingrediente',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Cantidad',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Unidad',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Ingredient rows
                ...recipe.ingredients.map((ingredient) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(ingredient.name, textAlign: pw.TextAlign.left),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(ingredient.quantity.toString(), textAlign: pw.TextAlign.center),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(ingredient.unit, textAlign: pw.TextAlign.center),
                    ),
                  ],
                )).toList(),
              ],
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}
