import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/ingrediente_tabla.dart';
import '../constants/categories.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_table_widget.dart';
import '../models/group.dart';

class EditGroupRecipeScreen extends StatefulWidget {
  final Recipe recipe;
  final Group group;
  final bool isEnglish;

  const EditGroupRecipeScreen({
    super.key,
    required this.recipe,
    required this.group,
    this.isEnglish = false,
  });

  @override
  State<EditGroupRecipeScreen> createState() => _EditGroupRecipeScreenState();
}

class _EditGroupRecipeScreenState extends State<EditGroupRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _cookingTimeController;
  late TextEditingController _servingSizeController;
  late String _selectedCategory;
  late bool _isPrivate;
  bool isEnglish = false;
  List<Ingredient> _ingredients = [];
  late List<String> _steps;
  late List<TextEditingController> _stepControllers;
  String _category = '';
  String _servingUnit = 'gr';

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
      _servingUnit = 'gr';
    }

    _selectedCategory = widget.recipe.category;
    _isPrivate = widget.recipe.isPrivate;
    _ingredients = List.from(widget.recipe.ingredients);
    _category = _selectedCategory;
    isEnglish = widget.isEnglish;

    _steps = List.from(widget.recipe.steps);
    
    // Inicializar controladores para pasos
    _stepControllers = _steps.map((step) => TextEditingController(text: step)).toList();
    
    if (_steps.isEmpty) {
      _steps.add('');
      _stepControllers.add(TextEditingController());
    }
    return null;
  }

  @override
  void didUpdateWidget(EditGroupRecipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
  }

  void _editIngredients() async {
    final ingredientesConvertidos = _ingredients
        .map((ing) => IngredienteTabla(
              nombre: ing.name,
              cantidad: ing.quantity,
              unidad: _convertirUnidadAntigua(ing.unit),
            ))
        .toList();

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
                      // Primero actualizamos los ingredientes
                      final updatedIngredients = ingredients
                          .map((ing) => Ingredient(
                                name: ing.nombre,
                                quantity: ing.cantidad ?? 0,
                                unit: ing.unidad,
                              ))
                          .where((ing) => ing.quantity > 0)
                          .toList();

                      // Comparamos si la lista ha cambiado y si hay algún ingrediente inválido
                      if (ingredients.length != updatedIngredients.length) {
                        // Solo mostramos la alerta si se filtró algún ingrediente
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Todos los ingredientes deben tener una cantidad mayor a 0'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }

                      setState(() {
                        _ingredients = updatedIngredients;
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
                        // Validar que todos los ingredientes tengan cantidad mayor a 0
                        bool hasInvalidIngredient = _ingredients.any((ing) => ing.quantity <= 0);
                        
                        if (hasInvalidIngredient) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Todos los ingredientes deben tener una cantidad mayor a 0'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          // Solo si todos los ingredientes son válidos, cerramos el diálogo
                          Navigator.of(context).pop(_ingredients);
                        }
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
        _ingredients.addAll(result.where((newIngredient) {
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

        // Actualizar en la subcolección de recetas del grupo
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.id)
            .collection('recipes')
            .doc(widget.recipe.id)
            .update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'cookingTimeMinutes': int.parse(_cookingTimeController.text.trim()),
          'ingredients': _ingredients.map((i) => i.toMap()).toList(),
          'steps': steps,
          'category': _selectedCategory,
          'isPrivate': _isPrivate,
          'servingSize': '${_servingSizeController.text.trim()} $_servingUnit',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga

          final updatedRecipe = Recipe(
            id: widget.recipe.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            ingredients: _ingredients,
            steps: steps,
            cookingTime: Duration(
                minutes: int.parse(_cookingTimeController.text.trim())),
            category: _selectedCategory,
            userId: widget.recipe.userId,
            creatorName: widget.recipe.creatorName,
            creatorEmail: widget.recipe.creatorEmail,
            favoritedBy: widget.recipe.favoritedBy,
            isPrivate: _isPrivate,
            servingSize: '${_servingSizeController.text.trim()} $_servingUnit',
            
          );

          Navigator.pop(context, updatedRecipe);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish 
                ? 'Recipe updated successfully'
                : 'Receta actualizada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEnglish 
                ? 'Error updating recipe: ${e.toString()}'
                : 'Error al actualizar la receta: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _validateSteps() {
    // Verificar que todos los pasos tengan contenido
    return _steps.every((step) => step.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Receta de Comunidad'),
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
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _servingSizeController,
              decoration: const InputDecoration(
                labelText: 'Rendimiento',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el rendimiento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

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
                  label: const Text('Editar ingredientes'),
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

            const SizedBox(height: 16),
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
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _category.isNotEmpty ? _category : null,
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

            SwitchListTile(
              title: const Text('Receta Privada'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),
            const SizedBox(height: 16),

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
                    onPressed: () => setState(() => _steps.add('')),
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
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _steps.removeAt(index)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingSizeController.dispose();
    // Liberar los controladores de pasos
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
