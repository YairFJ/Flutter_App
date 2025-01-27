import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../constants/categories.dart';
import './recipe_detail_screen.dart';
import '../main.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_table_widget.dart';

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
  late String _selectedCategory;
  String? _imageUrl;
  late bool _isPrivate;
  List<Ingredient> _ingredients = [];
  late List<String> _steps;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description);
    _cookingTimeController = TextEditingController(
      text: widget.recipe.cookingTime.inMinutes.toString()
    );
    _steps = List.from(widget.recipe.steps);
    _selectedCategory = widget.recipe.category;
    _isPrivate = widget.recipe.isPrivate;
    _imageUrl = widget.recipe.imageUrl;
    _ingredients = List.from(widget.recipe.ingredients);

    // Asegurar que haya al menos un ingrediente y un paso
    if (_steps.isEmpty) {
      _steps.add('');
    }
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

  void _editIngredients() async {
    final ingredientesConvertidos = _ingredients.map((ing) => Ingredient(
      name: ing.name,
      quantity: ing.quantity,
      unit: _convertirUnidadAntigua(ing.unit),
    )).toList();

    final result = await showDialog<List<Ingredient>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Editar Ingredientes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(_ingredients),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: IngredientTableWidget(
                    ingredientes: ingredientesConvertidos,
                    onIngredientsChanged: (ingredients) {
                      setState(() {
                        _ingredients = ingredients;
                      });
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_ingredients),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_ingredients);
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients = result;
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
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _steps[index],
                            decoration: InputDecoration(
                              labelText: 'Paso ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onChanged: (value) {
                              setState(() {
                                _steps[index] = value;
                              });
                            },
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ingredientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _editIngredients,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar ingredientes'),
                  ),
                ],
              ),
              if (_ingredients.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = _ingredients[index];
                    return Card(
                      child: ListTile(
                        title: Text(ingredient.name),
                        subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
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
              ],
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

        final steps = _steps
            .map((step) => step.trim())
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
    super.dispose();
  }
} 