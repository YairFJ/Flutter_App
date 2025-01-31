import 'ingredient.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:firebase_auth/firebase_auth.dart';
=======
>>>>>>> main

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
  bool isFavorite;
  String? _userEmail;
  String? _userName;
  final String creatorName;
  final String creatorEmail;
  

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
<<<<<<< HEAD
    this.isFavorite = false,
    required this.creatorName,
    required this.creatorEmail,
  }) {
    _initializeUserInfo();
  }

  Future<void> _initializeUserInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userName = userData['displayName'];
        _userEmail = userData['email'];
      }
    } catch (e) {
      print('Error al obtener información del usuario: $e');
    }
  }

  // Método para obtener la información del usuario
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      return userDoc.exists ? userDoc.data() : null;
    } catch (e) {
      print('Error al obtener información del usuario: $e');
      return null;
    }
  }

  // Método para obtener el nombre del usuario según su userId
  Future<String> getUserName() async {
    try {
      final userRecord = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userRecord.exists) {
        final userData = userRecord.data() as Map<String, dynamic>;
        return userData['name'] ?? 
               userData['email']?.toString().split('@')[0] ?? 
               'Usuario';
      }
      return creatorName;
    } catch (e) {
      print('Error al obtener nombre del usuario: $e');
      return creatorName;
    }
  }

  // Actualiza el getter para usar el email como identificador principal
  Future<String> get userIdentifier async {
    final userName = await getUserName();
    return userName;
  }

  // Método para guardar la receta con la información del usuario
  Future<void> saveRecipe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Guarda la información del usuario si no existe
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'displayName': user.displayName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Guarda la receta con el userId
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(id)
          .set(toMap());
    }
  }
=======
    this.createdAt,
  }) : favoritedBy = favoritedBy ?? [];
>>>>>>> main

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
<<<<<<< HEAD
      isFavorite: map['isFavorite'] ?? false,
      creatorName: map['creatorName'] ?? '',
      creatorEmail: map['creatorEmail'] ?? '',
=======
      createdAt: map['createdAt'] as Timestamp?,
>>>>>>> main
    );
  }

  @override
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
<<<<<<< HEAD
      'userId': userId, // Este es el ID del creador original
      'isPrivate': isPrivate,
      'isFavorite': isFavorite,
      'createdAt': FieldValue.serverTimestamp(),
      'creatorName': creatorName,
      'creatorEmail': creatorEmail,
=======
      'userId': userId,
      'creatorEmail': creatorEmail,
      'favoritedBy': favoritedBy,
      'creatorName': creatorName,
      'isPrivate': isPrivate,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
>>>>>>> main
    };
  }
} 