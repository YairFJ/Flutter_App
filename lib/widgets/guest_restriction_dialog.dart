import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/language_service.dart';

class GuestRestrictionDialog extends StatelessWidget {
  final String action;
  
  const GuestRestrictionDialog({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isEnglish = languageService.isEnglish;

    return AlertDialog(
      title: Text(
        isEnglish ? 'Guest Mode Restriction' : 'Restricción de Modo Invitado',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish 
              ? 'To $action, you need to create an account or sign in.'
              : 'Para $action, necesitas crear una cuenta o iniciar sesión.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isEnglish ? 'Cancel' : 'Cancelar',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Salir del modo invitado y redirigir al login
            final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
            authProvider.exitGuestMode();
            Navigator.of(context).pushNamed('/login');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF96B4D8),
            foregroundColor: Colors.white,
          ),
          child: Text(
            isEnglish ? 'Sign In' : 'Iniciar Sesión',
          ),
        ),
      ],
    );
  }
} 