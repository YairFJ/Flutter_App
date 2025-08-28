import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/recipe.dart';
import 'package:flutter/material.dart';
import '../models/ingrediente_tabla.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List> generateRecipePdf(Recipe receta) async {
  final pdf = pw.Document();
  
  final fontColor = PdfColors.black;
  final backgroundColor = PdfColors.white;
  final primaryColor = PdfColor.fromInt(0xFF2B4C8C); 
  final accentColor = PdfColor.fromInt(0xFF4C75FA); 

  pw.Widget createHeader() {
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
          pw.SizedBox(height: 15),
          pw.Text(
            '${receta.description ?? ''}\n${receta.descriptionEn ?? ''}',
            style: pw.TextStyle(
              fontSize: 16,
              color: fontColor,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Rendimiento / Yield: ${receta.servingSize}',
            style: pw.TextStyle(
              fontSize: 14,
              color: fontColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget createIngredientsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ingredientes / Ingredients',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
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
      ],
    );
  }

  pw.Widget createStep(int index, String step, String? stepEn) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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
              style: pw.TextStyle(
                color: fontColor,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) => [
        createHeader(),
        pw.SizedBox(height: 15),
        createIngredientsTable(),
        pw.SizedBox(height: 15),
        if (receta.steps.isNotEmpty) ...[
          pw.Text(
            'Pasos / Steps',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          for (int i = 0; i < receta.steps.length; i++)
            createStep(i, receta.steps[i], receta.stepsEn?[i] ?? ''),
        ]
      ],
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
  required String userName,
  bool isEnglish = false,
}) async {
  final pdf = pw.Document();
  final logoBytes = await rootBundle.load('assets/icon/icon.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final fontColor = PdfColors.black;
  final backgroundColor = PdfColors.white;
  final primaryColor = PdfColor.fromInt(0xFF2B4C8C);
  final accentColor = PdfColor.fromInt(0xFF4C75FA);

  final Map<String, String> translations = {
    'Yield': isEnglish ? 'Yield' : 'Rendimiento',
    'Ingredients': isEnglish ? 'Ingredients' : 'Ingredientes',
    'Ingredient': isEnglish ? 'Ingredient' : 'Ingrediente',
    'Quantity': isEnglish ? 'Quantity' : 'Cantidad',
    'Unit': isEnglish ? 'Unit' : 'Unidad',
    'Steps': isEnglish ? 'Steps' : 'Pasos',
    'Generated by': isEnglish ? 'Generated by' : 'Generado por',
  };

  final Map<String, String> unidadesAbreviadas = {
    'Gramo': 'gr', 'Kilogramo': 'kg', 'Miligramos': 'mg', 'Onza': 'oz', 'Libra': 'lb',
    'Mililitros': 'ml', 'Litro': 'l', 'Centilitros': 'cl', 'Cucharada': 'tbsp',
    'Cucharadita': 'tsp', 'Taza': 'cup', 'Onza liquida': 'fl oz', 'Pinta': 'pint',
    'Cuarto galon': 'c-gal', 'Galon': 'gal', 'Persona': 'pers', 'Porción': 'porc',
    'Ración': 'rac', 'Plato': 'plato', 'Unidad': 'und'
  };

  pw.Widget createHeader() {
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
          pw.SizedBox(height: 15),
          pw.Text(
            detalles,
            style: pw.TextStyle(fontSize: 16, color: fontColor),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            '${translations['Yield']}: $rendimiento ${unidadesAbreviadas[unidad] ?? unidad}',
            style: pw.TextStyle(fontSize: 14, color: fontColor),
          ),
        ],
      ),
    );
  }

  pw.Widget createIngredientsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          translations['Ingredients']!,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: primaryColor,
          ),
        ),
        pw.SizedBox(height: 8),
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
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(
                    translations['Quantity']!,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(
                    translations['Unit']!,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor),
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
      ],
    );
  }

  pw.Widget createStep(int index, String paso) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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
              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              paso,
              style: pw.TextStyle(color: fontColor, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget createFooter() {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Text(
            '${translations['Generated by']}: $userName',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      header: (pw.Context context) => pw.Container(),
      footer: (pw.Context context) => createFooter(),
      build: (pw.Context context) => [
        createHeader(),
        pw.SizedBox(height: 15),
        createIngredientsTable(),
        pw.SizedBox(height: 15),
        if (pasos.isNotEmpty) ...[
          pw.Text(
            translations['Steps']!,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          for (int i = 0; i < pasos.length; i++) createStep(i, pasos[i]),
        ],
      ],
    ),
  );

  return pdf.save();
}
