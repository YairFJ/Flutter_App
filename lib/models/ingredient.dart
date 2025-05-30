class Ingredient {
  final String name;
  final String? nameEn;
  final double quantity;
  final String unit;
  final String? unitEn;

  Ingredient({
    required this.name,
    this.nameEn,
    required this.quantity,
    required this.unit,
    this.unitEn,
  });

  bool isValid() {
    return name.trim().isNotEmpty && quantity > 0 && unit.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameEn': nameEn,
      'quantity': quantity,
      'unit': unit,
      'unitEn': unitEn,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      nameEn: map['nameEn'],
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      unitEn: map['unitEn'],
    );
  }

  @override
  String toString() {
    return '$quantity $unit $name';
  }
}
