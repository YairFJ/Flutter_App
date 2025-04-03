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
  final Recipe? recipe;
  final bool isEnglish;

  const GroupRecipeFormScreen({
    super.key, 
    required this.group, 
    this.recipe, 
    this.isEnglish = false
  });

  @override
  State<GroupRecipeFormScreen> createState() => _GroupRecipeFormScreenState();
}

/// Pantalla que muestra el formulario de creación/edición de receta usando el mismo
/// layout que en la página principal, con la integración de la tabla de ingredientes.
class _GroupRecipeFormScreenState extends State<GroupRecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _servingSizeController;
  final List<TextEditingController> _stepControllers = [];
  String _selectedCategory = '';
  String? _imageUrl;
  bool _isPrivate = false;
  List<Ingredient> _ingredients = [];
  String _servingUnit = 'gr';
  bool get isEnglish => widget.isEnglish;

  // Unidades disponibles para el rendimiento
  final List<String> _todasLasUnidades = [
    'gr', // Gramos
    'kg', // Kilos
    'oz', // Onzas
    'lb', // Libras
    'l', // Litros
    'ml', // Mililitros
    'porciones'
  ];

  // Expresión regular para validar números positivos
  final RegExp _numberRegExp = RegExp(r'^\d*\.?\d+$');

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.recipe?.description ?? '');
    _cookingTimeController = TextEditingController(
        text: widget.recipe?.cookingTime.inMinutes.toString() ?? '');

    // Extraer el número y la unidad del servingSize
    if (widget.recipe?.servingSize != null &&
        widget.recipe!.servingSize.isNotEmpty) {
      final parts = widget.recipe!.servingSize.split(' ');
      _servingSizeController = TextEditingController(text: parts[0]);
      _servingUnit = parts.length > 1 ? parts[1] : 'gr';
    } else {
      _servingSizeController = TextEditingController();
      _servingUnit = 'gr';
    }

    _selectedCategory = widget.recipe?.category ?? '';
    _isPrivate = widget.recipe?.isPrivate ?? false;
    _ingredients = List.from(widget.recipe?.ingredients ?? []);
    _imageUrl = widget.recipe?.imageUrl;

    // Inicializar los controladores de pasos
    if (widget.recipe?.steps != null && widget.recipe!.steps.isNotEmpty) {
      for (var step in widget.recipe!.steps) {
        _stepControllers.add(TextEditingController(text: step));
      }
    }
    if (_stepControllers.isEmpty) {
      _stepControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingSizeController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter a title' : 'Por favor ingresa un título';
    }
    if (value.trim().length < 3) {
      return isEnglish ? 'Title must have at least 3 characters' : 'El título debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return isEnglish ? 'Title cannot exceed 100 characters' : 'El título no puede exceder los 100 caracteres';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter a description' : 'Por favor ingresa una descripción';
    }
    if (value.trim().length > 500) {
      return isEnglish ? 'Description cannot exceed 500 characters' : 'La descripción no puede exceder los 500 caracteres';
    }
    return null;
  }

  String? _validateCookingTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter the cooking time' : 'Por favor ingresa el tiempo de cocción';
    }
    if (!_numberRegExp.hasMatch(value)) {
      return isEnglish ? 'Enter a valid number' : 'Ingresa un número válido';
    }
    final minutes = int.parse(value);
    if (minutes <= 0) {
      return isEnglish ? 'Time must be greater than 0' : 'El tiempo debe ser mayor a 0';
    }
    if (minutes > 1440) {
      return isEnglish ? 'Time cannot exceed 24 hours (1440 minutes)' : 'El tiempo no puede exceder las 24 horas (1440 minutos)';
    }
    return null;
  }

  String? _validateServingSize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return isEnglish ? 'Please enter the serving size' : 'Por favor ingresa el rendimiento';
    }
    if (!_numberRegExp.hasMatch(value)) {
      return isEnglish ? 'Enter a valid number' : 'Ingresa un número válido';
    }
    double? servings = double.tryParse(value);
    if (servings == null || servings <= 0) {
      return isEnglish ? 'Serving size must be greater than 0' : 'El rendimiento debe ser mayor a 0';
    }
    if (servings > 10000) {
      return isEnglish ? 'Serving size is too large' : 'El rendimiento es demasiado grande';
    }
    return null;
  }

  bool _validateSteps() {
    bool isValid = true;
    for (var controller in _stepControllers) {
      if (controller.text.trim().isEmpty) {
        isValid = false;
        break;
      }
    }
    return isValid;
  }

  Future<void> _addIngredient() async {
    final ingredients = await showDialog<List<Ingredient>>(
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

    if (ingredients != null) {
      setState(() {
        _ingredients.addAll(ingredients);
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'You must add at least one ingredient' : 'Debes agregar al menos un ingrediente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_validateSteps()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'All steps must be completed' : 'Todos los pasos deben estar completos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('Usuario no autenticado');
        }

        final steps = _stepControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        final recipe = Recipe(
          id: widget.recipe?.id ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: currentUser.uid,
          creatorEmail: currentUser.email ?? 'No disponible',
          creatorName: currentUser.displayName ?? 'Usuario',
          ingredients: _ingredients,
          steps: steps,
          cookingTime:
              Duration(minutes: int.parse(_cookingTimeController.text.trim())),
          category: _selectedCategory,
          isPrivate: false,
          favoritedBy: [],
          imageUrl: _imageUrl,
          servingSize: '${_servingSizeController.text.trim()} $_servingUnit',
        );

        if (widget.recipe == null) {
          // Crear nueva receta
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.id)
              .collection('recipes')
              .add(recipe.toMap());
        } else {
          // Actualizar receta existente
          await FirebaseFirestore.instance
              .collection('groups')
              .doc(widget.group.id)
              .collection('recipes')
              .doc(widget.recipe!.id)
              .update(recipe.toMap());
        }

        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga
          Navigator.pop(context); // Vuelve a la pantalla anterior

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish ? 'Recipe saved successfully' : 'Receta guardada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish ? 'Error saving recipe: ${e.toString()}' : 'Error al guardar la receta: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null
            ? isEnglish 
              ? 'New Recipe in ${widget.group.name}' 
              : 'Nueva Receta en ${widget.group.name}'
            : isEnglish 
              ? 'Edit Recipe' 
              : 'Editar Receta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Title' : 'Título',
                    border: OutlineInputBorder(),
                    helperText: isEnglish ? 'Between 3 and 100 characters' : 'Entre 3 y 100 caracteres',
                  ),
                  validator: _validateTitle,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Description' : 'Descripción',
                    border: OutlineInputBorder(),
                    helperText: isEnglish ? 'Maximum 500 characters' : 'Máximo 500 caracteres',
                  ),
                  maxLines: 3,
                  validator: _validateDescription,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cookingTimeController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: isEnglish ? 'Preparation time (minutes)' : 'Tiempo de preparación (minutos)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateCookingTime,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _servingSizeController,
                        decoration: InputDecoration(
                          labelText: isEnglish ? 'Serving size' : 'Rendimiento',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: _validateServingSize,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _servingUnit,
                        decoration: InputDecoration(
                          labelText: isEnglish ? 'Unit' : 'Unidad',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory.isNotEmpty
                          ? _selectedCategory
                          : null,
                      isExpanded: true,
                      dropdownColor:
                          isDarkMode ? Colors.grey[800] : Colors.white,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      hint: Text(
                        isEnglish ? 'Select a category' : 'Selecciona una categoría',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      items: RecipeCategories.categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                RecipeCategories.getIconForCategory(category),
                                color: RecipeCategories.getColorForCategory(
                                    category),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                category,
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildIngredientsList(),
                const SizedBox(height: 24),
                _buildStepsList(),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: Text(
                    isEnglish ? 'Private Recipe' : 'Receta Privada',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _isPrivate
                        ? isEnglish ? 'Only you can see this recipe' : 'Solo tú podrás ver esta receta'
                        : isEnglish ? 'Everyone can see this recipe' : 'Todos podrán ver esta receta',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  value: _isPrivate,
                  onChanged: (bool value) {
                    setState(() {
                      _isPrivate = value;
                    });
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                const Divider(),
                ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    isEnglish ? 'Save Recipe' : 'Guardar Receta',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Ingredients' : 'Ingredientes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = _ingredients[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(ingredient.name),
                subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeIngredient(index),
                  color: Colors.red,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addIngredient,
          child: Text(isEnglish ? 'Add Ingredient' : 'Agregar Ingrediente'),
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Steps' : 'Pasos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stepControllers.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stepControllers[index],
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'Step ${index + 1}' : 'Paso ${index + 1}',
                    ),
                    maxLines: 2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _stepControllers.add(TextEditingController());
                    });
                  },
                ),
                if (_stepControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        _stepControllers[index].dispose();
                        _stepControllers.removeAt(index);
                      });
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
