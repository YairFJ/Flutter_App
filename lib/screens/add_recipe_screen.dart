import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/constants/categories.dart';
import 'package:flutter_app/models/ingredient.dart';
import 'package:flutter_app/widgets/add_ingredient_dialog.dart';
import 'package:flutter_app/models/recipe.dart';
import '../models/ingrediente_tabla.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRecipeScreen extends StatefulWidget {
  final bool isEnglish;
  
  const AddRecipeScreen({
    super.key,
    required this.isEnglish,
  });

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
  late bool isEnglish;

  // Unidades disponibles para el rendimiento
  final List<String> _todasLasUnidades = [
    'gr', // Gramos
    'kg', // Kilos
    'oz', // Onzas
    'lb', // Libras
    'l', // Litros
    'ml', // Mililitros
    'porc'
  ];

  // Expresión regular para validar números positivos (enteros o decimales)
  final RegExp _numberRegExp = RegExp(r'^\d*\.?\d+$');

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
  }

  @override
  void didUpdateWidget(AddRecipeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnglish != widget.isEnglish) {
      setState(() {
        isEnglish = widget.isEnglish;
      });
    }
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

        // Obtener datos del usuario actual
        final currentUser = FirebaseAuth.instance.currentUser;
        final userId = currentUser?.uid ?? "guest_user";
        final userEmail = currentUser?.email ?? "invitado@example.com";
        final userName = currentUser?.displayName ?? "Usuario";

        final steps = _stepControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        final recipe = Recipe(
          id: "",
          title: _titleController.text,
          description: _descriptionController.text,
          userId: userId,
          creatorEmail: userEmail,
          creatorName: userName,
          favoritedBy: [],
          cookingTime:
              Duration(minutes: int.parse(_cookingTimeController.text)),
          servingSize: "${_servingSizeController.text} $_servingUnit",
          ingredients: _ingredients,
          steps: steps,
          imageUrl: _imageUrl,
          category: _selectedCategory,
          isPrivate: _isPrivate,
        );

        final recipeRef = await FirebaseFirestore.instance
            .collection('recipes')
            .add(recipe.toMap());

        // Cerrar el diálogo de carga
        Navigator.pop(context);
        // Volver a la pantalla anterior
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'Recipe saved successfully!' : '¡Receta guardada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        // Asegurarse de cerrar el diálogo de carga si está abierto
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'Error saving recipe: ' : 'Error al guardar la receta: $e'),
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
                  cantidadController: TextEditingController(text: ing.quantity.toString()),
                  cantidadOriginal: ing.quantity,
                  unidadOriginal: ing.unit,
                ))
            .toList(),
        unidades: _todasLasUnidades,
        isEnglish: isEnglish,
      ),
    );

    if (ingredients != null) {
      setState(() {
        _ingredients.clear();
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'New Recipe' : 'Nueva Receta'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : (isTablet ? 32.0 : (isLargeTablet ? 48.0 : 64.0)),
          vertical: 32.0,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: _buildFormFields(isDarkMode, screenSize),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(bool isDarkMode, Size screenSize) {
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    return [
      TextFormField(
        controller: _titleController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
        ),
        decoration: InputDecoration(
          labelText: isEnglish ? 'Title' : 'Título',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
          ),
          helperText: isEnglish ? 'Between 3 and 100 characters' : 'Entre 3 y 100 caracteres',
          contentPadding: EdgeInsets.symmetric(
            horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          ),
        ),
        validator: _validateTitle,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (value) {
          if (value.isNotEmpty) {
            final capitalizedValue = value[0].toUpperCase() + value.substring(1);
            if (capitalizedValue != value) {
              _titleController.text = capitalizedValue;
              _titleController.selection = TextSelection.fromPosition(
                TextPosition(offset: capitalizedValue.length),
              );
            }
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
        ],
      ),
      SizedBox(height: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))),
      TextFormField(
        controller: _descriptionController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
        ),
        decoration: InputDecoration(
          labelText: isEnglish ? 'Description' : 'Descripción',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
          ),
          helperText: isEnglish ? 'Maximum 500 characters' : 'Máximo 500 caracteres',
          contentPadding: EdgeInsets.symmetric(
            horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          ),
        ),
        maxLines: isUltraWide ? 4 : (isLargeTablet ? 3 : 3),
        validator: _validateDescription,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (value) {
          if (value.isNotEmpty) {
            final sentences = value.split('. ');
            final capitalizedSentences = sentences.map((sentence) {
              if (sentence.isNotEmpty) {
                return sentence[0].toUpperCase() + sentence.substring(1);
              }
              return sentence;
            }).join('. ');
            
            if (capitalizedSentences != value) {
              _descriptionController.text = capitalizedSentences;
              _descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: capitalizedSentences.length),
              );
            }
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
        ],
      ),
      SizedBox(height: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))),
      TextFormField(
        controller: _cookingTimeController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
        ),
        decoration: InputDecoration(
          labelText: isEnglish ? 'Preparation Time (minutes)' : 'Tiempo de preparación (minutos)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
          ),
          helperText: isEnglish ? 'Positive integer (maximum 1440)' : 'Número entero positivo (máximo 1440)',
          contentPadding: EdgeInsets.symmetric(
            horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
            vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          ),
        ),
        keyboardType: TextInputType.number,
        validator: _validateCookingTime,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
      ),
      SizedBox(height: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))),
      // Rendimiento
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _servingSizeController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
              ),
              decoration: InputDecoration(
                labelText: isEnglish ? 'Yield' : 'Rendimiento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                  vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              validator: _validateServingSize,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
          ),
          SizedBox(width: isUltraWide ? 16 : (isLargeTablet ? 12 : (isTablet ? 10 : 8))),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _servingUnit,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
              ),
              decoration: InputDecoration(
                labelText: isEnglish ? 'Unit' : 'Unidad',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                  vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                ),
              ),
              items: _todasLasUnidades.map((String unidad) {
                return DropdownMenuItem<String>(
                  value: unidad,
                  child: Text(
                    unidad,
                    style: TextStyle(
                      fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                    ),
                  ),
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
      SizedBox(height: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10)),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
            width: isUltraWide ? 2 : (isLargeTablet ? 1.5 : 1),
          ),
          borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategory.isNotEmpty
                ? _selectedCategory
                : null,
            isExpanded: true,
            dropdownColor:
                isDarkMode ? Colors.grey[800] : Colors.white,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
            ),
            hint: Text(
              isEnglish ? 'Select a category' : 'Selecciona una categoría',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
                fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
              ),
            ),
            items: RecipeCategories.categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Row(
                  children: [
                    Icon(
                      RecipeCategories.getIconForCategory(category),
                      color: RecipeCategories.getColorForCategory(
                          category),
                      size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                    ),
                    SizedBox(width: isUltraWide ? 16 : (isLargeTablet ? 12 : (isTablet ? 10 : 8))),
                    Text(
                      RecipeCategories.getTranslatedCategory(category, isEnglish),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
                      ),
                    ),
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
      SizedBox(height: isUltraWide ? 32 : (isLargeTablet ? 28 : (isTablet ? 24 : 20))),
      _buildIngredientsList(screenSize),
      SizedBox(height: isUltraWide ? 32 : (isLargeTablet ? 28 : (isTablet ? 24 : 20))),
      _buildStepsList(screenSize),
      SizedBox(height: isUltraWide ? 32 : (isLargeTablet ? 28 : (isTablet ? 24 : 20))),
      SwitchListTile(
        title: Text(
          isEnglish ? 'Private Recipe' : 'Receta Privada',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _isPrivate
              ? isEnglish ? 'Only you can see this recipe' : 'Solo tú podrás ver esta receta'
              : isEnglish ? 'Everyone can see this recipe' : 'Todos podrán ver esta receta',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
          ),
        ),
        value: _isPrivate,
        onChanged: (bool value) {
          setState(() {
            _isPrivate = value;
          });
        },
        activeColor: Theme.of(context).primaryColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
          vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10)),
        ),
      ),
      SizedBox(height: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 18 : 16))),
      ElevatedButton(
        onPressed: _saveRecipe,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 15)),
            horizontal: isUltraWide ? 40 : (isLargeTablet ? 36 : (isTablet ? 32 : 30)),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
          ),
        ),
        child: Text(
          isEnglish ? 'Save Recipe' : 'Guardar Receta',
          style: TextStyle(
            fontSize: isUltraWide ? 20 : (isLargeTablet ? 18 : (isTablet ? 16 : 14)),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ];
  }

  Widget _buildIngredientsList(Size screenSize) {
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Ingredients' : 'Ingredientes',
          style: TextStyle(
            fontSize: isUltraWide ? 24 : (isLargeTablet ? 22 : (isTablet ? 20 : 18)),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        SizedBox(height: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 8 : 6))),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = _ingredients[index];
            return Card(
              margin: EdgeInsets.only(bottom: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 8 : 6))),
              elevation: isUltraWide ? 4 : (isLargeTablet ? 3 : 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
              ),
              child: ListTile(
                title: Text(
                  ingredient.name,
                  style: TextStyle(
                    fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${ingredient.quantity} ${ingredient.unit}',
                  style: TextStyle(
                    fontSize: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 13 : 12)),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                  ),
                  onPressed: () => _removeIngredient(index),
                  color: Colors.red,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                  vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10)),
                ),
              ),
            );
          },
        ),
        SizedBox(height: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 8 : 6))),
        ElevatedButton(
          onPressed: _addIngredient,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isUltraWide ? 24 : (isLargeTablet ? 20 : (isTablet ? 16 : 12)),
              vertical: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
            ),
          ),
          child: Text(
            isEnglish ? 'Manage Ingredients' : 'Gestionar Ingredientes',
            style: TextStyle(
              fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsList(Size screenSize) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Detección responsive mejorada
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeTablet = screenSize.width >= 1200 && screenSize.width < 2000;
    final isUltraWide = screenSize.width >= 2000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Steps' : 'Pasos',
          style: TextStyle(
            fontSize: isUltraWide ? 24 : (isLargeTablet ? 22 : (isTablet ? 20 : 18)),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        SizedBox(height: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 8 : 6))),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _stepControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: isUltraWide ? 16 : (isLargeTablet ? 14 : (isTablet ? 12 : 10))),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stepControllers[index],
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: isUltraWide ? 18 : (isLargeTablet ? 16 : (isTablet ? 15 : 14)),
                      ),
                      decoration: InputDecoration(
                        labelText: isEnglish ? 'Step ${index + 1}' : 'Paso ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(isUltraWide ? 12 : (isLargeTablet ? 10 : 8)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                          vertical: isUltraWide ? 20 : (isLargeTablet ? 16 : (isTablet ? 14 : 12)),
                        ),
                      ),
                      maxLines: isUltraWide ? 3 : (isLargeTablet ? 2 : 2),
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
                            _stepControllers[index].text = capitalizedSentences;
                            _stepControllers[index].selection = TextSelection.fromPosition(
                              TextPosition(offset: capitalizedSentences.length),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  SizedBox(width: isUltraWide ? 12 : (isLargeTablet ? 10 : (isTablet ? 8 : 6))),
                  IconButton(
                    icon: Icon(
                      Icons.add,
                      size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                    ),
                    onPressed: () {
                      setState(() {
                        _stepControllers.add(TextEditingController());
                      });
                    },
                  ),
                  if (_stepControllers.length > 1)
                    IconButton(
                      icon: Icon(
                        Icons.remove,
                        size: isUltraWide ? 28 : (isLargeTablet ? 24 : (isTablet ? 22 : 20)),
                      ),
                      onPressed: () {
                        setState(() {
                          _stepControllers.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
