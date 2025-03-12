import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/constants/categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/ingredient.dart';
import 'package:flutter_app/widgets/add_ingredient_dialog.dart';
import 'package:flutter_app/models/recipe.dart';
import '../models/ingrediente_tabla.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [
    TextEditingController()
  ];
  final List<TextEditingController> _stepControllers = [
    TextEditingController()
  ];
  String _selectedCategory = '';
  String? _imageUrl;
  bool _isPrivate = false;
  final List<Ingredient> _ingredients = [];
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

  // Expresión regular para validar números positivos (enteros o decimales)
  final RegExp _numberRegExp = RegExp(r'^\d*\.?\d+$');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingSizeController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
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
      return 'Ingresa solo números enteros positivos';
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

  Future<void> _saveRecipe() async {
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
        // Mostrar indicador de carga
        if (!mounted) return;
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

        // Obtener el nombre del usuario actual
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception('No se encontraron datos del usuario');
        }

        final userName = userDoc.data()?['name'] ?? 'Usuario desconocido';

        final steps = _stepControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        final recipe = Recipe(
          id: "",
          title: _titleController.text,
          description: _descriptionController.text,
          userId: currentUser.uid,
          creatorEmail: currentUser.email ?? 'No disponible',
          creatorName: userName,
          favoritedBy: [],
          cookingTime:
              Duration(minutes: int.parse(_cookingTimeController.text.trim())),
          servingSize: '${_servingSizeController.text.trim()} $_servingUnit',
          ingredients: _ingredients,
          steps: steps,
          imageUrl: _imageUrl,
          category: _selectedCategory,
          isPrivate: _isPrivate,
        );

        final recipeData = {
          ...recipe.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('recipes').add(recipeData);

        if (!mounted) return;

        // Cerrar el diálogo de carga
        Navigator.pop(context);
        // Volver a la pantalla anterior
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Receta guardada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        // Asegurarse de cerrar el diálogo de carga si está abierto
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la receta: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
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
                  decoration: const InputDecoration(
                    labelText: 'Tiempo de preparación (minutos)',
                    border: OutlineInputBorder(),
                    helperText: 'Número entero positivo (máximo 1440)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateCookingTime,
                ),
                const SizedBox(height: 16),
                // Rendimiento
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
                          //helperText: 'Cantidad',
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
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory.isNotEmpty
                          ? _selectedCategory
                          : null,
                      isExpanded: true,
                      hint: const Text('Selecciona una categoría'),
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
                              Text(category),
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
                  title: const Text('Receta Privada'),
                  subtitle: Text(
                    _isPrivate
                        ? 'Solo tú podrás ver esta receta'
                        : 'Todos podrán ver esta receta',
                    style: TextStyle(
                      color: Colors.grey[600],
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
                  child: const Text(
                    'Guardar Receta',
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
        const Text(
          'Ingredientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        const Text(
          'Pasos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
