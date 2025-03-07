import 'package:flutter/material.dart';

class ConversionPage extends StatelessWidget {
  const ConversionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion Page'),
      ),
      body: const Center(
        child: Text('This is the Conversion Page'),
      ),
    );
  }
} 