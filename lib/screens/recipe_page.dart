import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Page'),
      ),
      body: const Center(
        child: Text('This is the Recipe Page'),
      ),
    );
  }
} 