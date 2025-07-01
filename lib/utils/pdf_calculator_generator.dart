import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recipe.dart'; // Asegúrate de que la ruta y el modelo sean correctos.
import 'package:flutter/material.dart';
import '../models/ingrediente_tabla.dart';

/// Genera un PDF a partir de la información de una receta.
Future<Uint8List> generateRecipePdf(Recipe receta) async {
  final pdf = pw.Document();
  
  // Definir colores según el tema
  // Definir colores según el tema
  final fontColor = PdfColors.black;
  final backgroundColor = PdfColors.white;
  final primaryColor = PdfColor.fromInt(0xFF2B4C8C); // Azul más fuerte
  final accentColor = PdfColor.fromInt(0xFF4C75FA); // Color del ícono de compartir

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
                  receta.title,
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${receta.description ?? ''}\n${receta.descriptionEn ?? ''}',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: fontColor,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Rendimiento / Yield: ${receta.servingSize}',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: fontColor,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Ingredientes / Ingredients',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Ingrediente / Ingredient',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Cantidad / Quantity',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          'Unidad / Unit',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...receta.ingredients.map((ingredient) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${ingredient.name}\n${ingredient.nameEn ?? ''}',
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            ingredient.quantity.toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            '${ingredient.unit}\n${ingredient.unitEn ?? ''}',
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
                'Pasos / Steps',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: receta.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final stepEn = receta.stepsEn?[index] ?? '';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 25,
                          height: 25,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
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
                            '$step\n$stepEn',
                            style: pw.TextStyle(color: fontColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

Future<Uint8List> generateCalculatorPdf({
  required List<IngredienteTabla> ingredientes,
  required double rendimiento,
  required String unidad,
  required String detalles,
  required List<String> pasos,
  required String tituloReceta,
  bool isEnglish = false,
}) async {
  final pdf = pw.Document();

  // Estilos y colores del archivo pdf_generator.dart
  final fontColor = PdfColors.black;
  final backgroundColor = PdfColors.white;
  final primaryColor = PdfColor.fromInt(0xFF2B4C8C); // Azul más fuerte
  final accentColor = PdfColor.fromInt(0xFF4C75FA); // Color del ícono de compartir

  // Textos traducidos
  final Map<String, String> translations = {
    'Yield': isEnglish ? 'Yield' : 'Rendimiento',
    'Ingredients': isEnglish ? 'Ingredients' : 'Ingredientes',
    'Ingredient': isEnglish ? 'Ingredient' : 'Ingrediente',
    'Quantity': isEnglish ? 'Quantity' : 'Cantidad',
    'Unit': isEnglish ? 'Unit' : 'Unidad',
    'Steps': isEnglish ? 'Steps' : 'Pasos',
    'Generated by': isEnglish ? 'Generated by' : 'Generado por',
  };

  // Mapa de unidades completas a abreviadas
  final Map<String, String> unidadesAbreviadas = {
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
    'Onza liquida': 'oz liq',
    'Pinta': 'pinta',
    'Cuarto galon': 'c-galon',
    'Galon': 'galon',
    'Persona': 'pers',
    'Porción': 'porc',
    'Ración': 'rac',
    'Plato': 'plato',
    'Unidad': 'und'
  };

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
                  tituloReceta,
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                detalles,
                style: pw.TextStyle(
                  fontSize: 16,
                  color: fontColor,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '${translations['Yield']}: $rendimiento ${unidadesAbreviadas[unidad] ?? unidad}',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: fontColor,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                translations['Ingredients']!,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          translations['Ingredient']!,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          translations['Quantity']!,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(
                          translations['Unit']!,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...ingredientes.map((i) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(i.nombre, textAlign: pw.TextAlign.left),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(i.cantidad.toString(), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text(unidadesAbreviadas[i.unidad] ?? i.unidad, textAlign: pw.TextAlign.center),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                translations['Steps']!,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: pasos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final paso = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 25,
                          height: 25,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
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
                            paso,
                            style: pw.TextStyle(color: fontColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}


