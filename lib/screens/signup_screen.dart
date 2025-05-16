import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SquareTile extends StatelessWidget {
  final String imagePath;
  const SquareTile({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: Image.asset(
        imagePath,
        height: 40,
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    print('Iniciando autenticación con Google');

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        print('Autenticación con Google cancelada por el usuario');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      print('Autenticación con Google exitosa: ${user.email}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INICIO DE SESIÓN EXITOSA'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('Error detallado en _handleGoogleSignIn: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is FirebaseAuthException) {
          String mensaje = 'Error al iniciar sesión con Google';
          switch (e.code) {
            case 'invalid-credential':
              mensaje = 'Credenciales inválidas. Por favor, intenta de nuevo.';
              break;
            case 'user-not-found':
              mensaje = 'No se encontró usuario con estas credenciales.';
              break;
            case 'unknown-error':
              mensaje = 'Error desconocido. Por favor, intenta más tarde.';
              break;
            default:
              mensaje = e.message ?? 'Error al iniciar sesión con Google';
          }
          _showError(mensaje);
        } else {
          _showError('Error al iniciar sesión con Google: $e');
        }
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential != null && userCredential.user != null) {
        _showSuccess('INICIO DE SESIÓN EXITOSA');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        _showError('El inicio de sesión con Apple no está disponible');
      }
    } catch (e) {
      _showError('Error al iniciar sesión con Apple: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleManualSignUp() async {
    if (_isLoading) return;

    // Validaciones básicas
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Por favor, completa todos los campos');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        _showSuccess('REGISTRO EXITOSO');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/verification');
        }
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        _showError(_authService.getErrorMessage(e));
      } else {
        _showError('Error al registrar usuario: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF96B4D8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 100,
                  color: Colors.white,
                ),

                const SizedBox(height: 30),

                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 50),

                // Campos de registro
                MyTextField(
                  controller: _nameController,
                  hintText: 'Nombre completo',
                  obscureText: false,
                  prefixIcon: Icon(Icons.person),
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _emailController,
                  hintText: 'Correo electrónico',
                  obscureText: false,
                  prefixIcon: Icon(Icons.email),
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _passwordController,
                  hintText: 'Contraseña',
                  obscureText: true,
                  prefixIcon: Icon(Icons.lock),
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirmar contraseña',
                  obscureText: true,
                  prefixIcon: Icon(Icons.lock),
                ),

                const SizedBox(height: 25),

                // Botón de registro
                MyButton(
                  onTap: _handleManualSignUp,
                  text: 'Registrarse',
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 30),

                // google + apple sign in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    GestureDetector(
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                      child: const SquareTile(
                        imagePath: 'lib/images/google.png',
                      ),
                    ),
                    const SizedBox(width: 25),
                    // apple button
                    GestureDetector(
                      onTap: _isLoading ? null : _handleAppleSignIn,
                      child: const SquareTile(
                        imagePath: 'lib/images/apple.png',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // already have an account? login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
