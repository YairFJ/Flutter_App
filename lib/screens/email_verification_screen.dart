import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isChecking = false;
  Timer? _timer;
  int _remainingTime = 60; // 60 segundos para poder reenviar

  @override
  void initState() {
    super.initState();

    // Enviar email de verificación inmediatamente al cargar la pantalla
    _sendVerificationEmail();

    // Iniciar un temporizador para verificar periódicamente si el email ha sido verificado
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Verificar si el email ha sido verificado
  Future<void> _checkEmailVerification() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      // Forzar recarga del usuario para obtener el último estado
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Verificando estado del email para: ${user.email}');
        await user.reload();
        final reloadedUser = FirebaseAuth.instance.currentUser;

        if (reloadedUser?.emailVerified == true) {
          print('Email verificado correctamente');
          _timer?.cancel();
          // Redirigir a la pantalla principal
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Email verificado! Redirigiendo...'),
                backgroundColor: Colors.green,
              ),
            );

            // Esperar 2 segundos antes de redirigir
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            }
          }
        } else {
          print('Email aún no verificado');
        }
      } else {
        print('Error: No hay usuario autenticado para verificar');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Sesión cerrada. Vuelve a iniciar sesión.'),
              backgroundColor: Colors.red,
            ),
          );

          // Redirigir a la pantalla de login después de un error de sesión
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      }
    } catch (e) {
      print('Error al verificar email: $e');
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
        setState(() => _isChecking = false);
      }
    }
  }

  // Reenviar email de verificación
  Future<void> _resendVerificationEmail() async {
    if (_isLoading || _remainingTime > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Reenviando email de verificación a: ${user.email}');
        await user.sendEmailVerification();
        print('Email de verificación reenviado exitosamente');

        setState(() {
          _remainingTime = 60; // Reiniciar contador
        });

        // Iniciar un contador para habilitar el botón de reenvío después de 60 segundos
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingTime > 0) {
            setState(() {
              _remainingTime--;
            });
          } else {
            timer.cancel();
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Email de verificación enviado. Revisa tu bandeja de entrada.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Error: No hay usuario autenticado para reenviar el email');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No hay usuario autenticado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al reenviar email de verificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Cerrar sesión
  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método para enviar email de verificación inicial
  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Email de verificación enviado. Revisa tu bandeja de entrada.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al enviar email de verificación inicial: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar email: $e'),
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
        title: const Text('Verificación de Email'),
        backgroundColor: const Color(0xFF96B4D8),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                size: 80,
                color: Color(0xFF96B4D8),
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Verifica tu correo electrónico!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Hemos enviado un email de verificación a:\n${widget.email}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Revisa tu bandeja de entrada o spam y haz clic en el enlace de verificación.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Botón para reenviar email
              ElevatedButton.icon(
                onPressed: _remainingTime > 0 || _isLoading
                    ? null
                    : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF96B4D8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(
                  _remainingTime > 0
                      ? 'Reenviar email (${_remainingTime}s)'
                      : 'Reenviar email de verificación',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Botón para verificar manualmente
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkEmailVerification,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Ya verifiqué mi email',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 40),

              // Botón para cerrar sesión
              TextButton(
                onPressed: _isLoading ? null : _signOut,
                child: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
