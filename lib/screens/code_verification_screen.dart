import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CodeVerificationScreen extends StatefulWidget {
  final String email;

  const CodeVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<CodeVerificationScreen> createState() => _CodeVerificationScreenState();
}

class _CodeVerificationScreenState extends State<CodeVerificationScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;
  bool _isVerified = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    // Enviar email de verificación inmediatamente al abrir la pantalla
    _resendVerificationEmail();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Verificar el estado de verificación cada 3 segundos
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('Verificando estado de email para usuario: ${user.email}');
          // Recargar el usuario para obtener el estado actualizado
          await user.reload();
          final updatedUser = FirebaseAuth.instance.currentUser;
          
          print('Estado de verificación: ${updatedUser?.emailVerified}');
          
          if (updatedUser?.emailVerified == true && !_isVerified) {
            setState(() => _isVerified = true);
            timer.cancel();
            
            // Actualizar el estado en Firestore
            await _firestore.collection('users').doc(user.uid).update({
              'verified': true,
              'needsVerification': false,
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Email verificado exitosamente!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Esperar un momento antes de navegar
              await Future.delayed(const Duration(seconds: 1));
              
              // Navegar a la pantalla principal
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          }
        } else {
          print('No hay usuario autenticado');
          // Si no hay usuario, cancelar el timer
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sesión expirada. Por favor, inicia sesión nuevamente.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      } catch (e) {
        print('Error al verificar el estado: $e');
        // Si hay un error, cancelar el timer
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al verificar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _resendCountdown = 60;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      print('Reenviando email de verificación a: ${user.email}');
      await user.sendEmailVerification();
      print('Email de verificación reenviado exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificación reenviado. Revisa tu bandeja de entrada o spam.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Iniciar el contador de reenvío
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCountdown > 0) {
          setState(() => _resendCountdown--);
        } else {
          setState(() => _isResending = false);
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error al reenviar email de verificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reenviar el email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Email'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              'Se ha enviado un email de verificación a:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.email,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Por favor, revisa tu bandeja de entrada y sigue las instrucciones para verificar tu cuenta.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Si no encuentras el email, revisa tu carpeta de spam o correo no deseado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 30),
            if (_isResending)
              Text(
                'Podrás reenviar el email en $_resendCountdown segundos',
                style: const TextStyle(color: Colors.grey),
              )
            else
              TextButton(
                onPressed: _resendVerificationEmail,
                child: const Text('Reenviar email de verificación'),
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await user.reload();
                      if (user.emailVerified) {
                        await _firestore.collection('users').doc(user.uid).update({
                          'verified': true,
                          'needsVerification': false,
                        });
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El email aún no ha sido verificado. Por favor, revisa tu correo y haz clic en el enlace de verificación.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al verificar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: const Text('Ya verifiqué mi email'),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text('Volver al inicio de sesión'),
            ),
          ],
        ),
      ),
    );
  }
} 