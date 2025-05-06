import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/screens/code_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _validatePassword(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Future<void> _register() async {
    // Verificar y mostrar el estado de la validación del formulario
    final isValid = _formKey.currentState?.validate() ?? false;
    print('Formulario válido: $isValid');

    if (!isValid) {
      _showError('Por favor, completa todos los campos correctamente');
      return;
    }

    // Validar que las contraseñas coincidan
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    // Validar fortaleza de la contraseña
    if (!_validatePassword(_passwordController.text)) {
      _showError(
          'La contraseña debe tener al menos 6 caracteres, una mayúscula y un número');
      return;
    }

    // Recopilar datos de formulario
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('Datos de registro: Nombre: $name, Email: $email');

    setState(() => _isLoading = true);

    try {
      print('Iniciando registro con email y contraseña');

      // Cerrar sesión si hay alguna activa
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          print('Hay un usuario logueado, cerrando sesión antes de registrar: ${currentUser.email}');
          await FirebaseAuth.instance.signOut();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (logoutError) {
        print('Error al cerrar sesión existente: $logoutError');
      }

      final userCredential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      print('Registro exitoso, verificando estado de verificación...');
      
      // Verificar si estamos en un emulador
      bool isEmulator = false;
      try {
        isEmulator = FirebaseAuth.instance.app.options.projectId.contains('emulator');
      } catch (e) {
        print('No se pudo verificar si es emulador: $e');
      }

      if (mounted) {
        if (isEmulator) {
          // En emulador, mostrar mensaje de éxito y redirigir
          _showSuccess('Registro exitoso en emulador');
          await Future.delayed(const Duration(seconds: 1));
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        } else {
          // En dispositivo real, mostrar mensaje y redirigir a verificación de email
          _showSuccess('Registro exitoso. Por favor, verifica tu correo electrónico.');
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushNamed(
            context,
            '/verify-email',
            arguments: email,
          );
        }
      }
    } catch (e) {
      print('Excepción capturada durante el registro: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'needs-verification') {
          // Si el usuario necesita verificación, mostrar mensaje y redirigir a verificación
          _showSuccess('Por favor, verifica tu correo electrónico.');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CodeVerificationScreen(email: _emailController.text.trim()),
              ),
            );
          }
        } else if (e.code == 'email-already-in-use') {
          _showError('Este correo ya está registrado. Por favor, inicia sesión.');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        } else {
          _showError(e.message ?? 'Error de autenticación');
        }
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          // No mostrar error si el usuario canceló voluntariamente
        }
        return;
      }

      print('Autenticación con Google exitosa: ${user.email}');

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INICIO DE SESIÓN EXITOSA'),
            backgroundColor: Colors.green,
          ),
        );

        // Esperar un momento para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        // Redireccionar a la pantalla principal y ELIMINAR todas las rutas anteriores
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('Error detallado en _handleGoogleSignIn: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is FirebaseAuthException) {
          String mensaje = 'Error al iniciar sesión con Google';

          // Personalizar mensaje según el código de error
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

        // Esperar un momento para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        // Navegar a la pantalla principal
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // logo
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 100,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 30),

                  // create a new account text
                  const Text(
                    'Crear una cuenta nueva',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Campos de texto
                  MyTextField(
                    controller: _nameController,
                    hintText: 'NOMBRE DE USUARIO',
                    obscureText: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu nombre';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  MyTextField(
                    controller: _emailController,
                    hintText: 'EMAIL',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  MyTextField(
                    controller: _passwordController,
                    hintText: 'CONTRASEÑA',
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa una contraseña';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  MyTextField(
                    controller: _confirmPasswordController,
                    hintText: 'CONFIRMAR CONTRASEÑA',
                    obscureText: !_isConfirmPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirma tu contraseña';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  // register button
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : MyButton(
                          onTap: _register,
                          text: 'REGISTRARTE',
                        ),

                  const SizedBox(height: 30),

                  // or continue with
                  /*Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            'O continuar con',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
                  ),*/

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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
