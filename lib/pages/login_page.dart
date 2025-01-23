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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    verificarEstadoLogin();
  }

  void verificarEstadoLogin() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('Usuario NO está logueado');
      } else {
        print('Usuario está logueado');
        print('Email: ${user.email}');
        print('UID: ${user.uid}');
      }
    });
  }

  // Text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Sign user in method
  Future<void> signUserIn(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final email = usernameController.text.trim();
      final password = passwordController.text.trim();

      // Reiniciar la instancia de Firebase Auth
      await FirebaseAuth.instance.signOut();
      
      // Esperar un momento antes de intentar el login
      await Future.delayed(const Duration(milliseconds: 500));

      // Intentar iniciar sesión
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (context.mounted) {
        Navigator.pop(context); // Cerrar el indicador de carga
        
        if (userCredential.user != null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }

    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      
      String errorMessage = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con este correo',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-email' => 'El formato del correo no es válido',
        'network-request-failed' => 'Error de conexión. Verifica tu internet',
        _ => 'Error de autenticación: ${e.message}',
      };

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return; // Evitar múltiples clicks

    try {
      setState(() => _isLoading = true);
      
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        print('Usuario logueado: ${userCredential.user?.email}');
        setState(() => _isLoading = false); // Asegurarnos de detener la carga antes de navegar
        // Navegar a la pantalla principal después del login exitoso
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        // Si no hay userCredential, también detenemos la carga
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo iniciar sesión')),
          );
        }
      }
    } catch (e) {
      print('Error al iniciar sesión con Google: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión con Google')),
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please, enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: usernameController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context); // Cerrar el indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha enviado un enlace de recuperación a tu correo'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        String errorMessage = switch (e.code) {
          'invalid-email' => 'El correo electrónico no es válido',
          'user-not-found' => 'No existe una cuenta con este correo',
          _ => 'Error al enviar el correo de recuperación',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                ),

                const SizedBox(height: 50),

                // welcome back, you've been missed!
                Text(
                  'Welcome back you\'ve been missed!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                  ),
                ),

                const SizedBox(height: 25),

                // username textfield
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username',
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                // password textfield
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
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
                          '¿Forgot your password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // sign in button
                MyButton(
                  onTap: () => signUserIn(context),
                ),

                const SizedBox(height: 50),

                // or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // google + apple sign in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // google button
                    _isLoading 
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: _handleGoogleSignIn,
                          child: const SquareTile(imagePath: 'lib/images/google.png'),
                        ),
                    const SizedBox(width: 25),
                    // apple button
                    const SquareTile(imagePath: 'lib/images/apple.png')
                  ],
                ),

                const SizedBox(height: 20),

                // not a member? register now
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member?',
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register'); // Navegar a la página de registro
                      },
                      child: const Text(
                        'Register now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Añado un pequeño espacio al final
              ],
            ),
          ),
        ),
      ),
    );
  }
}
