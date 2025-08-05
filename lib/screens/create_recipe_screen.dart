import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/ingredient.dart';
import '../models/ingrediente_tabla.dart';
import '../widgets/add_ingredient_dialog.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Group group;
  final bool isEnglish;

  const CreateRecipeScreen({
    super.key,
    required this.group,
    required this.isEnglish,
  });

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _servingsController = TextEditingController();
  final _preparationTimeController = TextEditingController();
  final List<Map<String, String>> _ingredients = [];
  int _servings = 4;
  bool _isLoading = false;
  late bool isEnglish;

  // Lista de unidades disponibles
  final List<String> _todasLasUnidades = [
    'gr',
    'kg', 
    'mg',
    'oz',
    'lb',
    'ml',
    'l',
    'cl',
    'cda',
    'cdta',
    'tz',
    'oz liq',
    'pinta',
    'c-galon',
    'galon',
    'u',
  ];

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  Future<void> _addIngredient() async {
    final ingredients = await showDialog<List<Ingredient>>(
      context: context,
      builder: (context) => AddIngredientDialog(
        ingredientes: _ingredients
            .map((ing) => IngredienteTabla(
                  nombre: ing['name'] ?? '',
                  cantidad: double.tryParse(ing['amount'] ?? '0') ?? 0.0,
                  unidad: ing['unit'] ?? '',
                  cantidadController: TextEditingController(text: ing['amount'] ?? '0'),
                  cantidadOriginal: double.tryParse(ing['amount'] ?? '0') ?? 0.0,
                  unidadOriginal: ing['unit'] ?? '',
                ))
            .toList(),
        unidades: _todasLasUnidades,
        isEnglish: isEnglish,
      ),
    );

    if (ingredients != null) {
      setState(() {
        _ingredients.clear();
        _ingredients.addAll(ingredients.map((ing) => {
          'name': ing.name,
          'quantity': ing.quantity.toString(),
          'unit': ing.unit,
        }));
      });
    }
  }

  void _showServingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEnglish ? 'Number of People' : 'Cantidad de Personas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEnglish 
                ? 'Select how many people this recipe serves:'
                : 'Selecciona para cuántas personas rinde esta receta:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_servings > 1) {
                        setState(() {
                          _servings--;
                        });
                        Navigator.pop(context);
                        _showServingsDialog();
                      }
                    },
                  ),
                  Text(
                    '$_servings',
                    style: const TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        _servings++;
                      });
                      Navigator.pop(context);
                      _showServingsDialog();
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(isEnglish ? 'Accept' : 'Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createRecipe() async {
    // Validar que todos los ingredientes tengan una cantidad mayor que 0
    bool hasValidIngredients = _ingredients.every((ingredient) {
      String quantityText = ingredient['amount'] ?? '0';
      double quantity = double.tryParse(quantityText.replaceAll(',', '.')) ?? 0;
      return quantity > 0; // Asegúrate de que la cantidad sea mayor que 0
    });

    if (_formKey.currentState!.validate() && _servings > 0 && hasValidIngredients) {
      setState(() {
        _isLoading = true;
      });

      final String currentUser = FirebaseAuth.instance.currentUser!.uid;
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.group.id)
            .collection('recipes')
            .add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'instructions': _instructionsController.text.trim(),
          'preparationTime': _preparationTimeController.text.trim(),
          'servings': _servings,
          'ingredients': _ingredients,
          'author': currentUser,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receta creada exitosamente')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Mensaje de error si los ingredientes no son válidos
      if (!hasValidIngredients) {
        // SnackBar comentado temporalmente
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text(isEnglish 
        //       ? 'All ingredients must have a quantity greater than 0'
        //       : 'Todos los ingredientes deben tener una cantidad mayor que 0'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish 
              ? 'Please indicate how many servings the recipe yields'
              : 'Por favor, indica para cuántas personas rinde la receta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeTablet = screenSize.width > 900;
    final maxWidth = isLargeTablet ? 800.0 : (isTablet ? 600.0 : screenSize.width);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish 
          ? 'Create Recipe in ${widget.group.name}'
          : 'Crear Receta en ${widget.group.name}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.all(isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0)),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Recipe Title' : 'Título de la receta',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isEnglish ? 'Title is required' : 'El título es obligatorio';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Capitalizar la primera letra
                    final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                    if (capitalizedValue != value) {
                      _titleController.text = capitalizedValue;
                      _titleController.selection = TextSelection.fromPosition(
                        TextPosition(offset: capitalizedValue.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16.0),

              // Campo de tiempo de preparación
              TextFormField(
                controller: _preparationTimeController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Preparation Time' : 'Tiempo de preparación',
                  hintText: isEnglish ? 'Ex: 30 minutes' : 'Ej: 30 minutos',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isEnglish ? 'Time is required' : 'Tiempo requerido';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Capitalizar la primera letra
                    final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                    if (capitalizedValue != value) {
                      _preparationTimeController.text = capitalizedValue;
                      _preparationTimeController.selection = TextSelection.fromPosition(
                        TextPosition(offset: capitalizedValue.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16.0),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(isEnglish ? 'People' : 'Personas'),
                  subtitle: Text(
                      isEnglish 
                        ? 'This recipe yields $_servings ${_servings <= 1 ? 'person' : 'people'}'
                        : 'Esta receta rinde para $_servings ${_servings <= 1 ? 'persona' : 'personas'}'),
                  trailing: ElevatedButton(
                    onPressed: _showServingsDialog,
                    child: Text(isEnglish ? 'Change' : 'Cambiar'),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Lista de ingredientes
              ..._ingredients.asMap().entries.map((entry) {
                int idx = entry.key;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: _ingredients[idx]['name'] ?? ''),
                            decoration: InputDecoration(
                              labelText: isEnglish ? 'Ingredient' : 'Ingrediente',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Capitalizar la primera letra
                                final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                                if (capitalizedValue != value) {
                                  _ingredients[idx]['name'] = capitalizedValue;
                                }
                              }
                              _ingredients[idx]['name'] = value;
                            },
                            onEditingComplete: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: _ingredients[idx]['amount'] ?? '0,0'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: isEnglish ? 'Quantity' : 'Cantidad',
                              border: OutlineInputBorder(),
                            ),
                            onTap: () {
                              final controller = TextEditingController(
                                  text: _ingredients[idx]['amount'] ?? '0,0');
                              if (controller.text == '0,0') {
                                controller.clear();
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                controller.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return isEnglish 
                                  ? 'Please enter a quantity'
                                  : 'Por favor ingrese una cantidad';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: _ingredients[idx]['unit'] ?? ''),
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                              hintText: 'gr, ml, unidad',
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Capitalizar la primera letra
                                final capitalizedValue = value[0].toUpperCase() + value.substring(1);
                                if (capitalizedValue != value) {
                                  _ingredients[idx]['unit'] = capitalizedValue;
                                }
                              }
                              _ingredients[idx]['unit'] = value;
                            },
                            onEditingComplete: null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _ingredients.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addIngredient,
                child: Text(isEnglish ? 'Manage Ingredients' : 'Gestionar Ingredientes'),
              ),

              const SizedBox(height: 16.0),
              TextFormField(
                controller: _instructionsController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Preparation Instructions' : 'Instrucciones de preparación',
                ),
                maxLines: null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return isEnglish 
                      ? 'Instructions are required'
                      : 'Las instrucciones son obligatorias';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    // Capitalizar la primera letra de cada oración
                    final sentences = value.split('. ');
                    final capitalizedSentences = sentences.map((sentence) {
                      if (sentence.isNotEmpty) {
                        return sentence[0].toUpperCase() + sentence.substring(1);
                      }
                      return sentence;
                    }).join('. ');
                    
                    if (capitalizedSentences != value) {
                      _instructionsController.text = capitalizedSentences;
                      _instructionsController.selection = TextSelection.fromPosition(
                        TextPosition(offset: capitalizedSentences.length),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createRecipe,
                      child: Text(isEnglish ? 'Create Recipe' : 'Crear Receta'),
                    ),
            ],
          ),
        ),
      ),
    )
    )
    );
  }
}
