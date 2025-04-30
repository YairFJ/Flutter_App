import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Verificar el estado de login de forma segura
    Future.delayed(Duration.zero, () {
      verificarEstadoLogin();
    });
  }

  void verificarEstadoLogin() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          print('Usuario NO está logueado');
        } else {
          print('Usuario está logueado');
          print('Email: ${user.email}');
          print('UID: ${user.uid}');
          print('Email verificado: ${user.emailVerified}');
          print(
              'Proveedores: ${user.providerData.map((e) => e.providerId).join(', ')}');
        }
      });
    } catch (e) {
      print('Error al verificar estado de login: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validar formulario
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor, completa todos los campos');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    print('Intentando iniciar sesión con: $email');

    setState(() => _isLoading = true);

    try {
      print('Llamando a signInWithEmailAndPassword');
      await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      print('Inicio de sesión exitoso');
      _showSuccess('INICIO DE SESIÓN CORRECTO');
    } catch (e) {
      print('Excepción durante inicio de sesión: $e');
      _showError('INICIO DE SESIÓN INCORRECTO: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showError('Por favor, ingresa tu correo electrónico');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _authService.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (error != null) {
        _showError(error);
      } else {
        _showSuccess('Se ha enviado un enlace de recuperación a tu correo');
      }
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    print('Iniciando autenticación con Google desde login');

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        print('Google SignIn cancelado por el usuario');
        if (mounted) {
          setState(() => _isLoading = false);
          // No mostrar error si el usuario canceló voluntariamente
        }
        return;
      }

      print('Google SignIn exitoso: ${user.email}');

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('INICIO DE SESIÓN CORRECTO'),
            backgroundColor: Colors.green,
          ),
        );

        // Esperar un momento para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        // Navegar a la pantalla principal y eliminar todas las rutas anteriores
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      print('Error en Google SignIn: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (e is FirebaseAuthException) {
          String mensaje = 'Error de inicio de sesión';

          // Personalizar mensaje según el código de error
          switch (e.code) {
            case 'invalid-credential':
              mensaje =
                  'Credenciales inválidas. Verifica la configuración de tu app.';
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

          _showError('INICIO DE SESIÓN INCORRECTO: $mensaje');
        } else {
          _showError('INICIO DE SESIÓN INCORRECTO: $e');
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
        _showSuccess('INICIO DE SESIÓN CORRECTO');

        // Esperar un momento para mostrar el mensaje
        await Future.delayed(const Duration(seconds: 1));

        // Navegar a la pantalla principal
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        _showError(
            'INICIO DE SESIÓN INCORRECTO: El inicio de sesión con Apple no está disponible');
      }
    } catch (e) {
      _showError('INICIO DE SESIÓN INCORRECTO: $e');
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                // logo
                const Icon(
                  Icons.person_sharp,
                  size: 100,
                  color: Colors.white,
                ),

                const SizedBox(height: 40),

                // welcome back, you've been missed!
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // email textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: MyTextField(
                    controller: _emailController,
                    hintText: 'Correo electrónico',
                    obscureText: false,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) =>
                        val!.isEmpty ? 'Ingresa tu correo' : null,
                  ),
                ),

                const SizedBox(height: 15),

                // password textfield
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: MyTextField(
                    controller: _passwordController,
                    hintText: 'Contraseña',
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
                    validator: (val) =>
                        val!.isEmpty ? 'Ingresa tu contraseña' : null,
                  ),
                ),

                const SizedBox(height: 10),

                // forgot password?
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // sign in button
                _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: MyButton(
                          onTap: _login,
                          text: 'Iniciar sesión',
                        ),
                      ),

                const SizedBox(height: 30),

                // or continue with
                Padding(
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
                ),

                const SizedBox(height: 30),

                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes una cuenta?',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        'REGISTRARTE',
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
