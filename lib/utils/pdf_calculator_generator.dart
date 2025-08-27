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
  final primaryColor = PdfColor.fromInt(0xFF2B4C8C); // Azul más fuerte
  final accentColor = PdfColor.fromInt(0xFF4C75FA); // Color del ícono de compartir

  // Función para crear el encabezado de la página
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

  // Función para crear la tabla de ingredientes
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

  // Función para crear un paso individual
  pw.Widget createStep(int index, String step, String? stepEn) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8), // Espaciado entre pasos
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
                height: 1.2, // Interlineado entre líneas del mismo paso
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Crear la primera página con encabezado e ingredientes
  final List<pw.Widget> firstPageContent = [
    createHeader(),
    pw.SizedBox(height: 15),
    createIngredientsTable(),
    pw.Spacer(),
  ];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          color: backgroundColor,
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: firstPageContent,
          ),
        );
      },
    ),
  );

  // Crear páginas adicionales para los pasos si es necesario
  if (receta.steps.isNotEmpty) {
    // Crear una sola página que contenga todos los pasos
    // El PDF se ajustará automáticamente al tamaño A4 y creará tantas páginas como sea necesario
    final List<pw.Widget> allStepsContent = [
      // Título de la página de pasos
      pw.Text(
        'Pasos / Steps',
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 4),
      // TODOS los pasos sin restricción
      ...List.generate(receta.steps.length, (index) {
        final stepEn = receta.stepsEn?[index] ?? '';
        return createStep(index, receta.steps[index], stepEn);
      }),
    ];

    // Agregar la página con todos los pasos
    // El PDF se ajustará automáticamente al tamaño A4 y creará tantas páginas como sea necesario
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: backgroundColor,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: allStepsContent,
            ),
          );
        },
      ),
    );
  }

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

  // Función para crear el encabezado de la página
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
             style: pw.TextStyle(
               fontSize: 16,
               color: fontColor,
             ),
           ),
           pw.SizedBox(height: 15),
          pw.Text(
            '${translations['Yield']}: $rendimiento ${unidadesAbreviadas[unidad] ?? unidad}',
            style: pw.TextStyle(
              fontSize: 14,
              color: fontColor,
            ),
          ),
        ],
      ),
    );
  }

  // Función para crear la tabla de ingredientes
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
      ],
    );
  }

  // Función para crear un paso individual
  pw.Widget createStep(int index, String paso) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8), // Espaciado entre pasos
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
              style: pw.TextStyle(
                color: fontColor,
                height: 1.2, // Interlineado entre líneas del mismo paso
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función para crear el pie de página
  pw.Widget createFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, width: 50, height: 50),
              pw.Text(
                '${translations['Generated by']}: $userName',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Crear la primera página con encabezado e ingredientes
  final List<pw.Widget> firstPageContent = [
    createHeader(),
    pw.SizedBox(height: 15),
    createIngredientsTable(),
    pw.Spacer(),
    createFooter(),
  ];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          color: backgroundColor,
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: firstPageContent,
          ),
        );
      },
    ),
  );

  // Crear páginas adicionales para los pasos si es necesario
  if (pasos.isNotEmpty) {
    // Crear una sola página que contenga todos los pasos
    // El PDF se ajustará automáticamente al tamaño A4 y creará tantas páginas como sea necesario
    final List<pw.Widget> allStepsContent = [
      // Título de la página de pasos
      pw.Text(
        translations['Steps']!,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
      pw.SizedBox(height: 4),
      // TODOS los pasos sin restricción
      ...List.generate(pasos.length, (index) {
        return createStep(index, pasos[index]);
      }),
    ];

    // Agregar la página con todos los pasos
    // El PDF se ajustará automáticamente al tamaño A4 y creará tantas páginas como sea necesario
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: backgroundColor,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: allStepsContent,
            ),
          );
        },
      ),
    );
  }

  return pdf.save();
}
