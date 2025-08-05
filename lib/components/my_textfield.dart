import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final Widget? prefixIcon;
  final bool isEmailField;
  final TextCapitalization textCapitalization;
  final bool autoCapitalize;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.prefixIcon,
    this.isEmailField = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.autoCapitalize = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: textCapitalization,
        onChanged: (value) {
          // Solo aplicar capitalización automática si autoCapitalize es true
          if (autoCapitalize && value.isNotEmpty && textCapitalization != TextCapitalization.none) {
            // Capitalizar la primera letra de cada oración
            final sentences = value.split('. ');
            final capitalizedSentences = sentences.map((sentence) {
              if (sentence.isNotEmpty) {
                return sentence[0].toUpperCase() + sentence.substring(1);
              }
              return sentence;
            }).join('. ');
            
            // Solo actualizar si el valor cambió para evitar loops infinitos
            if (capitalizedSentences != value) {
              controller.text = capitalizedSentences;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: capitalizedSentences.length),
              );
            }
          }
        },
        inputFormatters: [
          if (isEmailField)
            // Para campos de email, solo permitir letras, números, @, ., -, _
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._-]'))
          else if (keyboardType == TextInputType.number)
            // Para campos numéricos, solo permitir números
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
          else if (obscureText)
            // Para campos de contraseña, permitir todos los caracteres excepto espacios
            FilteringTextInputFormatter.allow(RegExp(r'[^\s]'))
          else
            // Para otros campos, solo permitir letras, números y espacios
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
        ],
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
          fillColor: Colors.white.withOpacity(0.3),
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white70),
          suffixIcon: suffix,
          prefixIcon: prefixIcon,
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
