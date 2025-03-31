import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/ingrediente_tabla.dart';
import '../constants/categories.dart';
import '../main.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_table_widget.dart';
import '../widgets/add_ingredient_dialog.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = HomeScreen.primaryColor;
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
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController =
        TextEditingController(text: widget.recipe.description);
    _cookingTimeController = TextEditingController(
        text: widget.recipe.cookingTime.inMinutes.toString());

    // Extraer el número y la unidad del servingSize
    final servingSizeParts = widget.recipe.servingSize.split(' ');
    if (servingSizeParts.length > 1) {
      _servingSizeController = TextEditingController(text: servingSizeParts[0]);
      _servingUnit = servingSizeParts[1];
    } else {
      _servingSizeController =
          TextEditingController(text: widget.recipe.servingSize);
    }

    _selectedCategory = widget.recipe.category;
    _isPrivate = widget.recipe.isPrivate;
    _ingredients = List.from(widget.recipe.ingredients);
    _imageUrl = widget.recipe.imageUrl;

    // Inicializar los controladores de pasos
    for (var step in widget.recipe.steps) {
      _stepControllers.add(TextEditingController(text: step));
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
      return 'Por favor ingresa un título';
    }
    if (value.trim().length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El título no puede exceder los 100 caracteres';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa una descripción';
    }
    if (value.trim().length > 500) {
      return 'La descripción no puede exceder los 500 caracteres';
    }
    return null;
  }

  String? _validateCookingTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el tiempo de cocción';
    }
    if (!_numberRegExp.hasMatch(value)) {
      return 'Ingresa un número válido';
    }
    final minutes = int.parse(value);
    if (minutes <= 0) {
      return 'El tiempo debe ser mayor a 0';
    }
    if (minutes > 1440) {
      return 'El tiempo no puede exceder las 24 horas (1440 minutos)';
    }
    return null;
  }

  String? _validateServingSize(String? value) {
    if (value == null || value.trim().isEmpty) {
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
        _ingredients.addAll(ingredients.where((newIngredient) {
          return !_ingredients.any((existing) =>
              existing.name == newIngredient.name &&
              existing.quantity == newIngredient.quantity &&
              existing.unit == newIngredient.unit);
        }));
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receta'),
        backgroundColor: const Color(0xFF96B4D8),
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
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    helperText: 'Entre 3 y 100 caracteres',
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
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    helperText: 'Máximo 500 caracteres',
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
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de preparación (minutos)',
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
                        decoration: const InputDecoration(
                          labelText: 'Rendimiento',
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
                        'Selecciona una categoría',
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
                    'Receta Privada',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _isPrivate
                        ? 'Solo tú podrás ver esta receta'
                        : 'Todos podrán ver esta receta',
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
                  onPressed: _updateRecipe,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text(
                    'Guardar Cambios',
                    style: TextStyle(
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
          'Ingredientes',
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
          child: const Text('Agregar Ingrediente'),
        ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pasos',
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
                      labelText: 'Paso ${index + 1}',
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

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
      if (_ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes agregar al menos un ingrediente'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!_validateSteps()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos los pasos deben estar completos'),
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

        final steps = _stepControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        // Actualizamos la receta en Firestore
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.recipe.id)
            .update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'cookingTimeMinutes': int.parse(_cookingTimeController.text.trim()),
          'ingredients': _ingredients.map((i) => i.toMap()).toList(),
          'steps': steps,
          'imageUrl': _imageUrl,
          'category': _selectedCategory,
          'isPrivate': _isPrivate,
          'servingSize': '${_servingSizeController.text.trim()} $_servingUnit',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // Obtenemos la receta actualizada
          final updatedRecipeDoc = await FirebaseFirestore.instance
              .collection('recipes')
              .doc(widget.recipe.id)
              .get();

          if (updatedRecipeDoc.exists) {
            final data = updatedRecipeDoc.data()!;
            final updatedRecipe = Recipe.fromMap(
              data,
              updatedRecipeDoc.id,
            );

            Navigator.pop(context); // Cierra el diálogo de carga
            Navigator.pop(context,
                updatedRecipe); // Vuelve a la pantalla anterior con la receta actualizada

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receta actualizada con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar la receta: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
