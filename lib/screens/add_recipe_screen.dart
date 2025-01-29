import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/constants/categories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/ingredient.dart';
import 'package:flutter_app/widgets/add_ingredient_dialog.dart';
import 'package:flutter_app/models/recipe.dart';

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
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _stepControllers = [TextEditingController()];
  String _selectedCategory = 'Platos Principales';
  String? _imageUrl;
  bool _isPrivate = false;
  final List<Ingredient> _ingredients = [];

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
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

<<<<<<< HEAD
        // Obtener el nombre del usuario actual
=======
        // Obtener los datos del usuario desde Firestore
>>>>>>> main
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
<<<<<<< HEAD
        
        final userName = userDoc.data()?['name'] ?? 'Usuario desconocido';
=======

        // Obtener el nombre del usuario desde Firestore
        final userName = userDoc.data()?['name'] ?? currentUser.displayName ?? 'Usuario';
>>>>>>> main

        final steps = _stepControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

<<<<<<< HEAD
        final recipe = Recipe(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          userId: currentUser.uid,
          creatorName: userName,
          favoritedBy: [],
          cookingTime: Duration(minutes: int.parse(_cookingTimeController.text.trim())),
          ingredients: _ingredients,
          steps: steps,
          imageUrl: _imageUrl,
          category: _selectedCategory,
          isPrivate: _isPrivate,
        );

        final recipeData = {
          ...recipe.toMap(),
=======
        await FirebaseFirestore.instance.collection('recipes').add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'cookingTimeMinutes': int.parse(_cookingTimeController.text.trim()),
          'ingredients': _ingredients.map((ingredient) => ingredient.toMap()).toList(),
          'steps': steps,
          'imageUrl': _imageUrl,
          'category': _selectedCategory,
          'userId': currentUser.uid,
          'creatorEmail': currentUser.email ?? 'No disponible',
          'creatorName': userName,
          'isPrivate': _isPrivate,
          'favoritedBy': [],
>>>>>>> main
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('recipes').add(recipeData);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Receta guardada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar la receta: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addIngredient() async {
    final ingredients = await showDialog<List<Ingredient>>(
      context: context,
      builder: (context) => const AddIngredientDialog(),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Por favor ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cookingTimeController,
              decoration: const InputDecoration(
                labelText: 'Tiempo de preparación (minutos)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Por favor ingresa el tiempo de preparación';
                }
                final number = int.tryParse(value!);
                if (number == null || number <= 0) {
                  return 'Por favor ingresa un número válido mayor a 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text('Selecciona una categoría'),
                  items: RecipeCategories.categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            RecipeCategories.getIconForCategory(category),
                            color: RecipeCategories.getColorForCategory(category),
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
                padding: const EdgeInsets.symmetric(vertical: 15),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }
} 