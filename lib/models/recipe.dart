import 'ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String userId;
  final String creatorEmail;
  List<Ingredient> ingredients;
  final List<String> steps;
  final String? imageUrl;
  final Duration cookingTime;
  final String category;
  final bool isPrivate;
  final List<String> favoritedBy;
  final String creatorName;
  final DateTime? createdAt;

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
    required this.creatorEmail,
    required this.creatorName,
    List<String>? favoritedBy,
    this.isPrivate = false,
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
      creatorEmail: map['creatorEmail'] ?? 'No disponible',
      favoritedBy: List<String>.from(map['favoritedBy'] ?? []),
      creatorName: map['creatorName'] ?? 'Usuario',
      isPrivate: map['isPrivate'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'steps': steps,
      'imageUrl': imageUrl,
      'cookingTimeMinutes': cookingTime.inMinutes,
      'category': category,
      'userId': userId,
      'creatorEmail': creatorEmail,
      'favoritedBy': favoritedBy,
      'creatorName': creatorName,
      'isPrivate': isPrivate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
} 