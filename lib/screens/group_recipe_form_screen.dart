import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/ingrediente_tabla.dart';
import '../models/group.dart';
import '../widgets/ingredient_table_widget.dart';
import '../constants/categories.dart';

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
  bool _isPrivate = false;
  late String _servingSize;

  @override
  void initState() {
    super.initState();
    _title = widget.recipe?.title ?? '';
    _description = widget.recipe?.description ?? '';
    _ingredients = List<Ingredient>.from(widget.recipe?.ingredients ?? []);
    _steps = List<String>.from(widget.recipe?.steps ?? []);
    _cookingTime = widget.recipe?.cookingTime.inMinutes.toString() ?? '0';
    _category = widget.recipe?.category ?? '';
    _isPrivate = widget.recipe?.isPrivate ?? false;
    _servingSize = widget.recipe?.servingSize ?? '4';

    // Si no hay pasos ingresados, se agrega uno en blanco para que siempre haya al menos un campo.
    if (_steps.isEmpty) {
      _steps.add('');
    }
  }

  /// Llama a un diálogo que contiene la tabla de edición de ingredientes.
  void _editIngredients() async {
    final ingredientesConvertidos = _ingredients
        .map((ing) => Ingredient(
              name: ing.name,
              quantity: ing.quantity,
              unit: _convertirUnidadAntigua(ing.unit),
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
                    Text(
                      widget.recipe == null
                          ? 'Agregar Ingredientes'
                          : 'Editar Ingredientes',
                      style: const TextStyle(
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
                    ingredientes: ingredientesConvertidos
                        .map((ing) => IngredienteTabla(
                              nombre: ing.name,
                              cantidad: ing.quantity,
                              unidad: ing.unit,
                            ))
                        .toList(),
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
                        ScaffoldMessenger.of(context).clearSnackBars(); // Limpiamos SnackBars previos
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Todos los ingredientes deben tener una cantidad mayor a 0'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2), // Reducimos la duración
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

  /// Valida el formulario y guarda la receta en la subcolección "recipes"
  /// de la comunidad seleccionada.
  Future<void> _saveRecipe() async {
    // Validar que todos los ingredientes tengan una cantidad mayor que 0
    bool hasValidIngredients = _ingredients.every((ingredient) {
      double quantity = ingredient.quantity;
      return quantity > 0;
    });

    if (!hasValidIngredients) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los ingredientes deben tener una cantidad mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Salimos de la función si hay ingredientes inválidos
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final recipeData = Recipe(
        id: widget.recipe?.id ?? '',
        title: _title,
        description: _description,
        userId: currentUser.uid,
        creatorEmail: currentUser.email ?? 'No disponible',
        creatorName: currentUser.displayName ?? 'Usuario',
        ingredients: _ingredients,
        steps: _steps,
        cookingTime: Duration(minutes: int.parse(_cookingTime)),
        category: _category,
        isPrivate: _isPrivate,
        favoritedBy: [],
        imageUrl: null,
        servingSize: _servingSize,
      );

      try {
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receta guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la receta: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Por favor ingresa un título'
                  : null,
              onSaved: (value) => _title = value ?? '',
            ),
            const SizedBox(height: 16),
            // Descripción
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (value) => _description = value ?? '',
            ),
            const SizedBox(height: 16),
            // Rendimiento
            TextFormField(
              initialValue: _servingSize,
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
              onSaved: (value) => _servingSize = value ?? '4',
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
                  label: Text(widget.recipe == null
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
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el tiempo de cocción';
                }
                return null;
              },
              onSaved: (value) => _cookingTime = value ?? '0',
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
            const SizedBox(height: 16),
            // Privacidad
            SwitchListTile(
              title: const Text('Receta Privada'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
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
