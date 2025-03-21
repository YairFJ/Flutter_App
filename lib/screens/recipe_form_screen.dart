import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/ingrediente_tabla.dart';
//import '../widgets/ingredient_table_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/add_ingredient_dialog.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe; // null si es nueva receta

  const RecipeFormScreen({super.key, this.recipe});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late List<Ingredient> _ingredients;
  late List<String> _steps;
  late String _cookingTime;
  late String _category;
  late String _servingSize;
  bool _isPrivate = false;

  // Mapa de unidades completas a abreviadas
  final Map<String, String> _unidadesAbreviadas = {
    'Gramo': 'gr',
    'Kilogramo': 'kg',
    'Miligramos': 'mg',
    'Onza': 'oz',
    'Libra': 'lb',
    'Mililitros': 'ml',
    'Litro': 'l',
    'Centilitros': 'cl',
    'Cucharada': 'cda',
    'Cucharadita': 'cdta',
    'Taza': 'tz',
    'Onza liquida': 'oz liquida',
    'Pinta': 'pinta',
    'Cuarto galon': 'cuarto galon',
    'Galon': 'galon',
  };

  // Lista de todas las unidades disponibles
  late final List<String> _todasLasUnidades;

  @override
  void initState() {
    super.initState();
    _servingSize = '4 porciones';
    _title = widget.recipe?.title ?? '';
    _description = widget.recipe?.description ?? '';
    _ingredients = List<Ingredient>.from(widget.recipe?.ingredients ?? []);
    _steps = List<String>.from(widget.recipe?.steps ?? []);
    _cookingTime = widget.recipe?.cookingTime.inMinutes.toString() ?? '0';
    _category = widget.recipe?.category ?? '';
    _isPrivate = widget.recipe?.isPrivate ?? false;

    // Inicializar la lista de todas las unidades
    _todasLasUnidades = _unidadesAbreviadas.values.toList();
  }

  void _editIngredients() async {
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
        unidades: _todasLasUnidades, // Usar la lista de unidades de medida
      ),
    );

    if (result != null) {
      setState(() {
        _ingredients =
            result; // Actualizar la lista de ingredientes con el resultado
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'Nueva Receta' : 'Editar Receta'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: _title,
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
              onSaved: (value) => _title = value ?? '',
            ),
            const SizedBox(height: 16),
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
                  label: Text(widget.recipe == null
                      ? 'Agregar ingredientes'
                      : 'Editar ingredientes'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de ingredientes existentes
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
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: ['Desayuno', 'Almuerzo', 'Cena', 'Postre', 'Snack']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona una categoría';
                }
                return null;
              },
              onChanged: (value) => setState(() => _category = value!),
              onSaved: (value) => _category = value!,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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

            ElevatedButton(
              onPressed: _saveRecipe,
              child: const Text('Guardar Receta'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Crear la receta
      final newRecipe = Recipe(
        id: '',
        title: _title,
        description: _description,
        userId: currentUser?.uid ?? '',
        creatorEmail: currentUser?.email ?? 'No disponible',
        creatorName: currentUser?.displayName ?? 'Usuario',
        ingredients: _ingredients,
        steps: _steps,
        cookingTime: Duration(minutes: int.parse(_cookingTime)),
        category: _category,
        isPrivate: _isPrivate,
        favoritedBy: [],
        servingSize: _servingSize,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('recipes')
          .add(newRecipe.toMap());
      Navigator.pop(context); // Regresar a la pantalla anterior
    }
  }
}
