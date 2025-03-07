import 'package:flutter/material.dart';

class RecipeCategories {
  static const String sinCategoria = 'Sin Categoría';

  static const List<String> categories = [
    // Comidas principales
    /*'Desayunos',
    'Almuerzos',
    'Cenas',*/
    'Aderezos',
    'Arroz y cereales',
    'Carne',
    'Mariscos',
    'Panadería',
    'Pastas',
    'Pastelería',
    'Salsas',
    'Sopas',
    'Vegano',
    'Vegetariano',
    'Verduras',

    // Categoría para recetas sin clasificar
    sinCategoria,
  ];

  // Puedes agregar íconos para cada categoría
  static IconData getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'desayunos':
        return Icons.breakfast_dining;
      case 'almuerzos':
        return Icons.lunch_dining;
      case 'cenas':
        return Icons.dinner_dining;
      case 'entradas':
        return Icons.tapas;
      case 'sopas':
        return Icons.soup_kitchen;
      case 'ensaladas':
        return Icons.eco;
      case 'platos principales':
        return Icons.restaurant_menu;
      case 'postres':
        return Icons.cake;
      case 'bebidas':
        return Icons.local_drink;
      case 'saludable':
        return Icons.favorite;
      case 'snacks':
        return Icons.cookie;
      case 'sin categoría':
        return Icons.category_outlined;
      default:
        return Icons.restaurant;
    }
  }

  // Colores para las categorías
  static Color getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'Aderezos':
        return Colors.orange[200]!;
      case 'Arroz y cereales':
        return Colors.red[200]!;
      case 'Carne':
        return Colors.green[200]!;
      case 'Mariscos':
        return Colors.pink[200]!;
      case 'Panadería':
        return Colors.blue[200]!;
      case 'Pastas':
        return Colors.teal[200]!;
      case 'Pastelería':
        return Colors.yellow[200]!;
      case 'Salsas':
        return Colors.purple[200]!;
      case 'Sopas':
        return Colors.lightBlue[200]!;
      case 'Vegano':
        return Colors.blueGrey[200]!;
      case 'Vegetariano':
        return Colors.lightGreenAccent[200]!;
      case 'Verduras':
        return const Color.fromARGB(255, 234, 74, 197)!;

      case 'sin categoría':
        return Colors.grey[300]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
