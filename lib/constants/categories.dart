import 'package:flutter/material.dart';

class RecipeCategories {
  static const String sinCategoria = 'Sin Categoría';
  
  static const List<String> categories = [
    // Comidas principales
    'Desayunos',
    'Almuerzos',
    'Cenas',
    
    // Tipos de platos
    'Entradas',
    'Sopas',
    'Ensaladas',
    'Platos Principales',
    'Guarniciones',
    'Salsas',
    
    // Por tipo de proteína
    'Carnes Rojas',
    'Pollo y Aves',
    'Pescados y Mariscos',
    'Vegetariano',
    'Vegano',
    
    // Cocinas del mundo
    'Italiana',
    'Mexicana',
    'China',
    'Japonesa',
    'Mediterránea',
    'Peruana',
    'India',
    
    // Horneados y postres
    'Panadería',
    'Postres',
    'Pasteles',
    'Galletas',
    
    // Bebidas
    'Bebidas',
    'Smoothies',
    'Cócteles',
    'Café y Té',
    
    // Categorías especiales
    'Saludable',
    'Bajo en Calorías',
    'Sin Gluten',
    'Snacks',
    'Comida Rápida',
    
    // Ocasiones
    'Para Niños',
    'Festivas',
    'Para Eventos',
    'Económicas',
    
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
      case 'desayunos':
        return Colors.orange[200]!;
      case 'sopas':
        return Colors.red[200]!;
      case 'ensaladas':
        return Colors.green[200]!;
      case 'postres':
        return Colors.pink[200]!;
      case 'bebidas':
        return Colors.blue[200]!;
      case 'saludable':
        return Colors.teal[200]!;
      case 'sin categoría':
        return Colors.grey[300]!;
      default:
        return Colors.grey[200]!;
    }
  }
} 