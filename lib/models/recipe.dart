import 'ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String? description;
  final String userId;
  final String creatorEmail;
  final String creatorName;
  final List<String> favoritedBy;
  final Duration cookingTime;
  final String servingSize;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final String? imageUrl;
  final String category;
  final bool isPrivate;
  final Timestamp? createdAt;
  final String? groupId;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.userId,
    required this.creatorEmail,
    required this.creatorName,
    required this.favoritedBy,
    required this.cookingTime,
    required this.servingSize,
    required this.ingredients,
    required this.steps,
    this.imageUrl,
    required this.category,
    required this.isPrivate,
    this.createdAt,
    this.groupId,
  });

  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      ingredients: (map['ingredients'] as List<dynamic>?)?.map((ingredient) {
            if (ingredient is Map<String, dynamic>) {
              return Ingredient.fromMap(ingredient);
            } else if (ingredient is String) {
              // Manejar ingredientes antiguos que son strings
              return Ingredient(name: ingredient, quantity: 1, unit: 'unidad');
            }
            throw Exception('Formato de ingrediente no válido');
          }).toList() ??
          [],
      steps: List<String>.from(map['steps'] ?? []),
      imageUrl: map['imageUrl'],
      cookingTime: Duration(minutes: map['cookingTimeMinutes'] ?? 0),
      category: map['category'] ?? '',
      userId: map['userId'] ?? '',
      creatorEmail: map['creatorEmail'] ?? 'No disponible',
      favoritedBy: List<String>.from(map['favoritedBy'] ?? []),
      creatorName: map['creatorName'] ?? 'Usuario',
      isPrivate: map['isPrivate'] ?? false,
      servingSize: map['servingSize'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      groupId: map['groupId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients':
          ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'steps': steps,
      'imageUrl': imageUrl,
      'cookingTimeMinutes': cookingTime.inMinutes,
      'servingSize': servingSize,
      'category': category,
      'userId': userId,
      'creatorEmail': creatorEmail,
      'favoritedBy': favoritedBy,
      'creatorName': creatorName,
      'isPrivate': isPrivate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'groupId': groupId,
    };
  }

  factory Recipe.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      ingredients: (data['ingredients'] as List<dynamic>?)?.map((ingredient) {
            return Ingredient.fromMap(ingredient);
          }).toList() ??
          [],
      steps: List<String>.from(data['steps'] ?? []),
      imageUrl: data['imageUrl'],
      cookingTime: Duration(minutes: data['cookingTimeMinutes'] ?? 0),
      category: data['category'] ?? '',
      userId: data['userId'] ?? '',
      creatorEmail: data['creatorEmail'] ?? 'No disponible',
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      creatorName: data['creatorName'] ?? 'Usuario',
      isPrivate: data['isPrivate'] ?? false,
      servingSize: data['servingSize'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      groupId: data['groupId'],
    );
  }
}
