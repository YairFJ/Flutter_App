import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Group group;

  const CreateRecipeScreen({super.key, required this.group});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _preparationTimeController =
      TextEditingController();
  final List<Map<String, String>> _ingredients = [];
  bool _isLoading = false;
  int _servings = 1;
  bool isEnglish = false;
  late List<FocusNode> _nombreFocusNodes;
  late List<FocusNode> _cantidadFocusNodes;
  late List<FocusNode> _unidadFocusNodes;

  @override
  void initState() {
    super.initState();
    _nombreFocusNodes = List.generate(_ingredients.length, (_) => FocusNode());
    _cantidadFocusNodes = List.generate(_ingredients.length, (_) => FocusNode());
    _unidadFocusNodes = List.generate(_ingredients.length, (_) => FocusNode());
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': '', 'amount': '0', 'unit': ''});
    });
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
    for (final node in _nombreFocusNodes) {
      node.dispose();
    }
    for (final node in _cantidadFocusNodes) {
      node.dispose();
    }
    for (final node in _unidadFocusNodes) {
      node.dispose();
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _servingsController.dispose();
    _preparationTimeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (int i = 0; i < _nombreFocusNodes.length; i++) {
      _nombreFocusNodes[i].addListener(() {
        if (!_nombreFocusNodes[i].hasFocus) {
          final controller = TextEditingController(text: _ingredients[i]['name'] ?? '');
          _ingredients[i]['name'] = controller.text.trim();
          setState(() {});
        }
      });
      _cantidadFocusNodes[i].addListener(() {
        if (!_cantidadFocusNodes[i].hasFocus) {
          final controller = TextEditingController(text: _ingredients[i]['amount'] ?? '0,0');
          String value = controller.text;
          double cantidad = 0.0;
          try {
            cantidad = double.parse(value.replaceAll(',', '.'));
            if (cantidad <= 0 || cantidad.isNaN || cantidad.isInfinite) {
              cantidad = 1.0;
            }
          } catch (e) {
            cantidad = 1.0;
          }
          _ingredients[i]['amount'] = cantidad.toString();
          setState(() {});
        }
      });
      _unidadFocusNodes[i].addListener(() {
        if (!_unidadFocusNodes[i].hasFocus) {
          final controller = TextEditingController(text: _ingredients[i]['unit'] ?? '');
          _ingredients[i]['unit'] = controller.text.trim();
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish 
          ? 'Create Recipe in ${widget.group.name}'
          : 'Crear Receta en ${widget.group.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                            focusNode: _nombreFocusNodes[idx],
                            decoration: InputDecoration(
                              labelText: isEnglish ? 'Ingredient' : 'Ingrediente',
                            ),
                            onChanged: null,
                            onEditingComplete: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(text: _ingredients[idx]['amount'] ?? '0,0'),
                            focusNode: _cantidadFocusNodes[idx],
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: isEnglish ? 'Amount' : 'Cantidad',
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
                                  ? 'Please enter an amount'
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
                            focusNode: _unidadFocusNodes[idx],
                            decoration: const InputDecoration(
                              labelText: 'Unidad',
                              hintText: 'gr, ml, unidad',
                            ),
                            onChanged: null,
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
                child: Text(isEnglish ? 'Add Ingredient' : 'Agregar Ingrediente'),
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
    );
  }
}
