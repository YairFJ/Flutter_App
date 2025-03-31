import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/ingrediente_tabla.dart';
import '../models/group.dart';
import '../constants/categories.dart';
import '../widgets/add_ingredient_dialog.dart';

class GroupRecipeFormScreen extends StatefulWidget {
  final Group group;
  final Recipe?
      recipe; // Si se pasa una receta, el formulario funcionará en modo edición

  const GroupRecipeFormScreen({super.key, required this.group, this.recipe});

  @override
  State<GroupRecipeFormScreen> createState() => _GroupRecipeFormScreenState();
}

/// Pantalla que muestra el formulario de creación/edición de receta usando el mismo
/// layout que en la página principal, con la integración de la tabla de ingredientes.
class _GroupRecipeFormScreenState extends State<GroupRecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late List<Ingredient> _ingredients;
  late List<String> _steps;
  late String _cookingTime;
  late String _category;
  late String _servingSize;
  late String _servingUnit;

  // Unidades por categoría como en conversion_table_page.dart
  final Map<String, List<String>> _unidadesPorCategoria = {
    'Peso': ['g', 'kg', 'oz', 'lb'],
    'Volumen': ['ml', 'l', 'tz', 'cda', 'cdta'],
  };

  // Lista de todas las unidades disponibles
  late final List<String> _todasLasUnidades;

  // Expresión regular para validar números positivos (enteros o decimales)
  final RegExp _numberRegExp = RegExp(r'^\d*\.?\d+$');

  @override
  void initState() {
    super.initState();
    // Inicializar la lista de todas las unidades
    _todasLasUnidades = [
      ..._unidadesPorCategoria['Peso']!,
      ..._unidadesPorCategoria['Volumen']!,
    ];

    _title = widget.recipe?.title ?? '';
    _description = widget.recipe?.description ?? '';
    _ingredients = List<Ingredient>.from(widget.recipe?.ingredients ?? []);
    _steps = List<String>.from(widget.recipe?.steps ?? []);
    _cookingTime = widget.recipe?.cookingTime.inMinutes.toString() ?? '0';
    _category = widget.recipe?.category ?? '';

    // Separar el número y la unidad del servingSize
    if (widget.recipe?.servingSize != null &&
        widget.recipe!.servingSize.isNotEmpty) {
      final parts = widget.recipe!.servingSize.split(' ');
      _servingSize = parts[0];
      _servingUnit = parts.length > 1 ? parts[1] : 'g';
    } else {
      _servingSize = '0';
      _servingUnit = 'g';
    }

    // Si no hay pasos ingresados, se agrega uno en blanco
    if (_steps.isEmpty) {
      _steps.add('');
    }
  }

  /// Llama a un diálogo que contiene la tabla de edición de ingredientes.
  Future<void> _editIngredients() async {
    final result = await showDialog<List<Ingredient>>(
      context: context,
      builder: (context) => AddIngredientDialog(
        ingredientes: _ingredients
            .map((ing) => IngredienteTabla(
                  nombre: ing.name,
                  cantidad: ing.quantity,
                  unidad: ing.unit,
                ))
            .toList(),
        unidades: _todasLasUnidades,
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients = result; // Update the ingredients list with the result
      });
    }
  }

  String _convertirUnidadAntigua(String unidadAntigua) {
    final Map<String, String> conversion = {
      'gramos': 'g',
      'gr': 'g',
      'kilogramos': 'kg',
      'kg': 'kg',
      'mililitros': 'ml',
      'ml': 'ml',
      'litros': 'l',
      'l': 'l',
      'taza': 'tz',
      'cucharada': 'cda',
      'cucharadita': 'cdta',
      'unidad': 'u',
      'onzas': 'oz',
      'oz': 'oz',
      'libras': 'lb',
      'lb': 'lb',
    };
    return conversion[unidadAntigua.toLowerCase()] ?? 'g';
  }

  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  // Validar que el título tenga un formato válido
  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un título';
    }
    if (value.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    if (value.length > 100) {
      return 'El título no puede tener más de 100 caracteres';
    }
    return null;
  }

  // Validar que la descripción tenga un formato válido
  String? _validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'La descripción no puede tener más de 500 caracteres';
    }
    return null;
  }

  // Validar que el rendimiento sea un número válido
  String? _validateServingSize(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el rendimiento';
    }
    if (!_numberRegExp.hasMatch(value)) {
      return 'Ingresa un número válido';
    }
    double? servings = double.tryParse(value);
    if (servings == null || servings <= 0) {
      return 'El rendimiento debe ser mayor a 0';
    }
    if (servings > 10000) {
      return 'El rendimiento es demasiado grande';
    }
    return null;
  }

  // Validar que el tiempo de cocción sea un número válido
  String? _validateCookingTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa el tiempo de cocción';
    }
    if (!_numberRegExp.hasMatch(value)) {
      return 'El tiempo debe ser un número entero positivo';
    }
    int? time = int.tryParse(value);
    if (time == null || time <= 0) {
      return 'El tiempo debe ser mayor a 0';
    }
    if (time > 1440) {
      // 24 horas en minutos
      return 'El tiempo no puede ser mayor a 24 horas';
    }
    return null;
  }

  // Validar que haya al menos un ingrediente
  bool _validateIngredients() {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos un ingrediente'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Validar que los pasos no estén vacíos
  bool _validateSteps() {
    bool hasEmptySteps = _steps.any((step) => step.trim().isEmpty);
    if (hasEmptySteps) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los pasos deben tener contenido'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  /// Valida el formulario y guarda la receta en la subcolección "recipes"
  /// de la comunidad seleccionada.
  Future<void> _saveRecipe() async {
    // Validar ingredientes y pasos antes del formulario
    if (!_validateIngredients() || !_validateSteps()) {
      return;
    }

    // Validar que todos los ingredientes tengan una cantidad mayor que 0
    bool hasValidIngredients = _ingredients.every((ingredient) {
      double quantity = ingredient.quantity;
      return quantity > 0;
    });

    if (!hasValidIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Todos los ingredientes deben tener una cantidad mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        _formKey.currentState!.save();
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No hay usuario autenticado'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final recipeData = Recipe(
          id: widget.recipe?.id ?? '',
          title: _title.trim(),
          description: _description.trim(),
          userId: currentUser.uid,
          creatorEmail: currentUser.email ?? 'No disponible',
          creatorName: currentUser.displayName ?? 'Usuario',
          ingredients: _ingredients,
          steps: _steps.map((step) => step.trim()).toList(),
          cookingTime: Duration(minutes: int.parse(_cookingTime)),
          category: _category,
          isPrivate: false,
          favoritedBy: [],
          imageUrl: null,
          servingSize: '$_servingSize $_servingUnit',
        );

        if (widget.recipe == null) {
          // Crear nueva receta
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.id)
              .collection('recipes')
              .add(recipeData.toMap());
        } else {
          // Actualizar receta existente
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.id)
              .collection('recipes')
              .doc(widget.recipe!.id)
              .update(recipeData.toMap());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta guardada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la receta: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null
            ? 'Nueva Receta en ${widget.group.name}'
            : 'Editar Receta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Título
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
                helperText: 'Entre 3 y 100 caracteres',
              ),
              validator: _validateTitle,
              onSaved: (value) => _title = value ?? '',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            // Descripción
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                helperText: 'Máximo 500 caracteres',
              ),
              maxLines: 3,
              validator: _validateDescription,
              onSaved: (value) => _description = value ?? '',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            // Rendimiento
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: _servingSize,
                    decoration: const InputDecoration(
                      labelText: 'Rendimiento',
                      border: OutlineInputBorder(),                  
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: _validateServingSize,
                    onSaved: (value) => _servingSize = value ?? '0',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _servingUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      border: OutlineInputBorder(),
                    ),
                    items: _todasLasUnidades.map((String unidad) {
                      return DropdownMenuItem<String>(
                        value: unidad,
                        child: Text(unidad),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _servingUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sección de ingredientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ingredientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _editIngredients,
                  icon: const Icon(Icons.edit),
                  label: Text(_ingredients.isEmpty
                      ? 'Agregar ingredientes'
                      : 'Editar ingredientes'),
                ),
              ],
            ),
            if (_ingredients.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return Card(
                    child: ListTile(
                      title: Text(ingredient.name),
                      subtitle:
                          Text('${ingredient.quantity} ${ingredient.unit}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _ingredients.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            // Tiempo de cocción
            TextFormField(
              initialValue: _cookingTime,
              decoration: const InputDecoration(
                labelText: 'Tiempo de cocción (minutos)',
                border: OutlineInputBorder(),
                helperText: 'Número entero positivo (máximo 1440)',
              ),
              keyboardType: TextInputType.number,
              validator: _validateCookingTime,
              onSaved: (value) => _cookingTime = value ?? '0',
            ),
            const SizedBox(height: 16),
            // Categoría
            DropdownButtonFormField<String>(
              value: _category.isNotEmpty ? _category : null,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                helperText: 'Selecciona una categoría',
              ),
              items: RecipeCategories.categories
                  .toSet()
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona una categoría';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Pasos
            const Text(
              'Pasos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length + 1,
              itemBuilder: (context, index) {
                if (index == _steps.length) {
                  return TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar paso'),
                  );
                }
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: TextFormField(
                    initialValue: _steps[index],
                    onChanged: (value) => _steps[index] = value,
                    decoration: InputDecoration(
                      hintText: 'Paso ${index + 1}',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeStep(index),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveRecipe,
              child: const Text('Guardar Receta'),
            ),
          ],
        ),
      ),
    );
  }
}
