import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/screens/verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

final _logger = Logger('SignUpScreen');

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
  bool _isEnglish = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnglish = prefs.getBool('isEnglish') ?? false;
    });
  }

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

      _logger.info('Autenticación con Google exitosa: ${user.user?.email}');

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
      _logger.info('Iniciando registro de usuario...');
      
      // Redirigir inmediatamente a la pantalla de verificación
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const VerificationScreen()),
          (route) => false,
        );
      }

      // Continuar con el registro en segundo plano
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      _logger.info('Registro exitoso');
    } catch (e) {
      _logger.severe('Error en registro: $e');
      if (e is FirebaseAuthException) {
        _showError(_authService.getErrorMessage(e));
      } else {
        _showError('Error al registrar usuario');
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

                Text(
                  _isEnglish ? 'Create Account' : 'Crear Cuenta',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 50),

                // Campos de registro
                MyTextField(
                  controller: _nameController,
                  hintText: _isEnglish ? 'Full Name' : 'Nombre completo',
                  obscureText: false,
                  prefixIcon: const Icon(Icons.person),
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _emailController,
                  hintText: _isEnglish ? 'Email' : 'Correo electrónico',
                  obscureText: false,
                  prefixIcon: const Icon(Icons.email),
                  isEmailField: true,
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _passwordController,
                  hintText: _isEnglish ? 'Password' : 'Contraseña',
                  obscureText: !_isPasswordVisible,
                  prefixIcon: const Icon(Icons.lock),
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 10),

                MyTextField(
                  controller: _confirmPasswordController,
                  hintText: _isEnglish ? 'Confirm Password' : 'Confirmar contraseña',
                  obscureText: !_isConfirmPasswordVisible,
                  prefixIcon: const Icon(Icons.lock),
                  suffix: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // Botón de registro
                MyButton(
                  onTap: _handleManualSignUp,
                  text: _isEnglish ? 'Sign Up' : 'Registrarse',
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 30),

                

                const SizedBox(height: 30),

                // already have an account? login now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isEnglish ? 'Already have an account?' : '¿Ya tienes una cuenta?',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        _isEnglish ? 'Login' : 'Iniciar sesión',
                        style: const TextStyle(
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
