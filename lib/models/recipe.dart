class Recipe {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  //final String? imageUrl;
  final Duration cookingTime;
  final String category;

  Recipe({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    //this.imageUrl,
    required this.cookingTime,
    required this.category,
  });

  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      //imageUrl: map['imageUrl'],
      cookingTime: Duration(minutes: map['cookingTimeMinutes'] ?? 0),
      category: map['category'] ?? 'Otras',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      //'imageUrl': imageUrl,
      'cookingTimeMinutes': cookingTime.inMinutes,
      'category': category,
    };
  }
} 