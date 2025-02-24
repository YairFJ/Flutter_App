import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/ingrediente_tabla.dart';
import '../constants/categories.dart';
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
  late TextEditingController _servingSizeController;
  late String _selectedCategory;
  String? _imageUrl;
  late bool _isPrivate;
  List<Ingredient> _ingredients = [];
  late List<String> _steps;
  String _category = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController =
        TextEditingController(text: widget.recipe.description);
    _cookingTimeController = TextEditingController(
        text: widget.recipe.cookingTime.inMinutes.toString());
    _servingSizeController =
        TextEditingController(text: widget.recipe.servingSize);
    _steps = List.from(widget.recipe.steps);
    _selectedCategory = widget.recipe.category;
    _isPrivate = widget.recipe.isPrivate;
    _imageUrl = widget.recipe.imageUrl;
    _ingredients = List.from(widget.recipe.ingredients);
    _category = _selectedCategory;

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
    final ingredientesConvertidos = widget.recipe.ingredients
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
                      setState(() {
                        _ingredients = ingredients
                            .map((ing) => Ingredient(
                                  name: ing.nombre,
                                  quantity: ing.cantidad ?? 0,
                                  unit: ing.unidad,
                                ))
                            .toList();
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

  // Agregar esta función para verificar si hubo cambios
  bool _hasChanges() {
    return _titleController.text != widget.recipe.title ||
        _descriptionController.text != widget.recipe.description ||
        _cookingTimeController.text !=
            widget.recipe.cookingTime.inMinutes.toString() ||
        _servingSizeController.text != widget.recipe.servingSize ||
        _selectedCategory != widget.recipe.category ||
        _isPrivate != widget.recipe.isPrivate ||
        _ingredients.length != widget.recipe.ingredients.length ||
        _steps.length != widget.recipe.steps.length ||
        !_compareIngredients() ||
        !_compareSteps();
  }

  // Función auxiliar para comparar ingredientes
  bool _compareIngredients() {
    if (_ingredients.length != widget.recipe.ingredients.length) return false;
    for (int i = 0; i < _ingredients.length; i++) {
      if (_ingredients[i].name != widget.recipe.ingredients[i].name ||
          _ingredients[i].quantity != widget.recipe.ingredients[i].quantity ||
          _ingredients[i].unit != widget.recipe.ingredients[i].unit) {
        return false;
      }
    }
    return true;
  }

  // Función auxiliar para comparar pasos
  bool _compareSteps() {
    if (_steps.length != widget.recipe.steps.length) return false;
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i] != widget.recipe.steps[i]) return false;
    }
    return true;
  }

  // Función para manejar la navegación hacia atrás
  void _handleBack() {
    if (!_hasChanges()) {
      // Si no hay cambios, simplemente volver con pop
      Navigator.pop(context);
    } else {
      // Si hay cambios, mostrar diálogo de confirmación
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Guardar cambios?'),
          content: const Text('¿Deseas guardar los cambios realizados?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a la pantalla anterior
              },
              child: const Text('Descartar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo
                _updateRecipe();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Receta'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
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

              // Rendimiento
              TextFormField(
                controller: _servingSizeController,
                decoration: const InputDecoration(
                  labelText: 'Rendimiento',
                  hintText: 'Ej: 4',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el rendimiento';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Ingresa un número válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _category.isNotEmpty ? _category : null,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
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
          'category': _category,
          'isPrivate': _isPrivate,
          'servingSize': _servingSizeController.text.trim(),
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
                minutes: int.parse(_cookingTimeController.text.trim())),
            category: _category,
            userId: widget.recipe.userId,
            creatorName: widget.recipe.creatorName,
            creatorEmail: widget.recipe.creatorEmail,
            favoritedBy: widget.recipe.favoritedBy,
            isPrivate: _isPrivate,
            servingSize: _servingSizeController.text.trim(),
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
    _servingSizeController.dispose();
    super.dispose();
  }
}
