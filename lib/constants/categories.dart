import 'package:flutter/material.dart';

class RecipeCategories {
  static const String sinCategoria = 'Sin Categoría';
  static const String noCategory = 'No Category';

  static final Map<String, String> _categoryTranslations = {
    'Aderezos': 'Dressings',
    'Arroz y cereales': 'Rice and cereals',
    'Carne': 'Meat',
    'Mariscos': 'Seafood',
    'Panadería': 'Bakery',
    'Pastas': 'Pasta',
    'Pastelería': 'Pastry',
    'Salsas': 'Sauces',
    'Sopas': 'Soups',
    'Vegano': 'Vegan',
    'Vegetariano': 'Vegetarian',
    'Verduras': 'Vegetables',
    'Sin Categoría': 'No Category',
    'Desayunos': 'Breakfast',
    'Almuerzos': 'Lunch',
    'Cenas': 'Dinner',
    'Bebidas': 'Beverages',
    'Postres': 'Desserts',
    'Snacks': 'Snacks',
    'Ensaladas': 'Salads',
  };

  static List<String> categories = [
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

  static String getTranslatedCategory(String category, bool isEnglish) {
    if (isEnglish) {
      return _categoryTranslations[category] ?? category;
    }
    return category;
  }

  // Puedes agregar íconos para cada categoría
  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'Aderezos':
        return Icons.local_drink;
      case 'Arroz y cereales':
        return Icons.grain;
      case 'Carne':
        return Icons.restaurant;
      case 'Mariscos':
        return Icons.set_meal;
      case 'Panadería':
        return Icons.bakery_dining;
      case 'Pastas':
        return Icons.dinner_dining;
      case 'Pastelería':
        return Icons.cake;
      case 'Salsas':
        return Icons.soup_kitchen;
      case 'Sopas':
        return Icons.ramen_dining;
      case 'Vegano':
        return Icons.eco;
      case 'Vegetariano':
        return Icons.grass;
      case 'Verduras':
        return Icons.local_florist;
      default:
        return Icons.category;
    }
  }

  // Colores para las categorías
  static Color getColorForCategory(String category) {
    switch (category) {
      case 'Aderezos':
        return Colors.orange;
      case 'Arroz y cereales':
        return Colors.amber;
      case 'Carne':
        return Colors.red;
      case 'Mariscos':
        return Colors.blue;
      case 'Panadería':
        return Colors.brown;
      case 'Pastas':
        return Colors.yellow;
      case 'Pastelería':
        return Colors.pink;
      case 'Salsas':
        return Colors.deepOrange;
      case 'Sopas':
        return Colors.green;
      case 'Vegano':
        return Colors.lightGreen;
      case 'Vegetariano':
        return Colors.teal;
      case 'Verduras':
        return Colors.lime;
      default:
        return Colors.grey;
    }
  }
}
