import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../constants/categories.dart';
import './recipe_detail_screen.dart';
import '../main.dart';
import '../models/ingredient.dart';
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
  late List<TextEditingController> _stepControllers;
  late String _selectedCategory;
  String? _imageUrl;
  late bool _isPrivate;
  List<Ingredient> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _cookingTimeController = TextEditingController(
      text: widget.recipe.cookingTime.inMinutes.toString()
    );
    _stepControllers = widget.recipe.steps
        .map((step) => TextEditingController(text: step))
        .toList();
    _selectedCategory = widget.recipe.category;
    _isPrivate = widget.recipe.isPrivate;
    _imageUrl = widget.recipe.imageUrl;
    _ingredients = List.from(widget.recipe.ingredients);

    // Asegurar que haya al menos un ingrediente y un paso
    if (_stepControllers.isEmpty) {
      _stepControllers.add(TextEditingController());
    }
  }

  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _addIngredient() async {
    final ingredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => const AddIngredientDialog(),
    );

    if (ingredient != null) {
      setState(() {
        _ingredients.add(ingredient);
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _editIngredient(int index) async {
    final currentIngredient = _ingredients[index];
    final editedIngredient = await showDialog<Ingredient>(
      context: context,
      builder: (context) => AddIngredientDialog(
        initialIngredient: currentIngredient,
      ),
    );

    if (editedIngredient != null) {
      setState(() {
        _ingredients[index] = editedIngredient;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Volver a la pantalla de detalle con la receta original
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: widget.recipe),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Receta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(recipe: widget.recipe),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateRecipe,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Imagen
              GestureDetector(
                onTap: () {
                  // Implementar selección de imagen
                },
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageUrl == null
                      ? const Icon(Icons.add_photo_alternate, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tiempo de cocción
              TextFormField(
                controller: _cookingTimeController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de cocción (minutos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el tiempo de cocción';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: RecipeCategories.categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Switch de privacidad
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
                activeColor: primaryColor,
              ),
              const Divider(),

              // Pasos
              const Text(
                'Pasos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stepControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stepControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Paso ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeStep(index),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Paso'),
              ),

              // Sección de ingredientes
              const Text(
                'Ingredientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editIngredient(index),
                            color: Colors.blue,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeIngredient(index),
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Agregar Ingrediente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
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
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga
          
          // Crear receta actualizada
          final updatedRecipe = Recipe(
            id: widget.recipe.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            ingredients: _ingredients,
            steps: steps,
            imageUrl: _imageUrl,
            cookingTime: Duration(
              minutes: int.parse(_cookingTimeController.text.trim())
            ),
            category: _selectedCategory,
            userId: widget.recipe.userId,
            isPrivate: _isPrivate,
          );

          Navigator.pop(context, updatedRecipe);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta actualizada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }
} 