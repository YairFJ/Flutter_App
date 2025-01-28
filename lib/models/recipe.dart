import 'ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  List<Ingredient> ingredients;
  final List<String> steps;
  final String? imageUrl;
  final Duration cookingTime;
  final String category;
  final String userId;
  final bool isPrivate;
  final String creatorName;
  final List<String> favoritedBy;
  final Timestamp? createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    this.imageUrl,
    required this.cookingTime,
    required this.category,
    required this.userId,
    this.isPrivate = false,
    required this.creatorName,
    List<String>? favoritedBy,
    this.createdAt,
  }) : favoritedBy = favoritedBy ?? [];

  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((ingredient) {
        if (ingredient is Map<String, dynamic>) {
          return Ingredient.fromMap(ingredient);
        } else if (ingredient is String) {
          // Manejar ingredientes antiguos que son strings
          return Ingredient(
            name: ingredient,
            quantity: 1,
            unit: 'unidad'
          );
        }
        throw Exception('Formato de ingrediente no válido');
      }).toList() ?? [],
      steps: List<String>.from(map['steps'] ?? []),
      imageUrl: map['imageUrl'],
      cookingTime: Duration(minutes: map['cookingTimeMinutes'] ?? 0),
      category: map['category'] ?? '',
      userId: map['userId'] ?? '',
      isPrivate: map['isPrivate'] ?? false,
      creatorName: map['creatorName'] ?? 'Usuario desconocido',
      favoritedBy: List<String>.from(map['favoritedBy'] ?? []),
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'steps': steps,
      'imageUrl': imageUrl,
      'cookingTimeMinutes': cookingTime.inMinutes,
      'category': category,
      'userId': userId,
      'isPrivate': isPrivate,
      'creatorName': creatorName,
      'favoritedBy': favoritedBy,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
} 