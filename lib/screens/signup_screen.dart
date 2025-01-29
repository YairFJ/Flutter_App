import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/components/square_tile.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear usuario con email y contraseña
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Actualizar el perfil del usuario con su nombre en Firebase Auth
        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        // Esperar un momento para asegurar que el displayName se actualice
        await Future.delayed(const Duration(seconds: 1));

        // Crear un documento en Firestore para el usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Recargar el usuario para asegurar que tenemos la información más reciente
        await userCredential.user?.reload();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Registro exitoso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al registrar: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        setState(() => _isLoading = false); // Detener la carga antes de navegar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF96B4D8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculamos proporciones basadas en el espacio disponible
            final maxHeight = constraints.maxHeight;
            final maxWidth = constraints.maxWidth;
            
            // Ajustamos los espaciados de manera proporcional
            final verticalSpacing = maxHeight * 0.02;
            final horizontalPadding = maxWidth * 0.08;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: verticalSpacing * 2),

                        // logo
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: maxWidth * 0.15, // Ajustado para ser proporcional al ancho
                        ),

                        SizedBox(height: verticalSpacing * 2),

                        // create a new account text
                        Text(
                          'Create a new account!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: maxWidth * 0.05,
                          ),
                        ),

                        SizedBox(height: verticalSpacing),

                        // Campos de texto
                        MyTextField(
                          controller: _nameController,
                          hintText: 'Username',
                          obscureText: false,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          obscureText: false,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: true,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          obscureText: true,
                        ),

                        SizedBox(height: verticalSpacing * 1.5),

                        // register button
                        _isLoading
                            ? const CircularProgressIndicator()
                            : MyButton(onTap: _signUp),

                        SizedBox(height: verticalSpacing * 1.5),

                        // or continue with
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 0.5,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 0.25),
                                child: const Text(
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

                        SizedBox(height: verticalSpacing * 1.5),

                        // google + apple sign in buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isLoading 
                              ? const CircularProgressIndicator()
                              : GestureDetector(
                                  onTap: _handleGoogleSignIn,
                                  child: const SquareTile(imagePath: 'lib/images/google.png'),
                                ),
                            SizedBox(width: maxWidth * 0.05),
                            const SquareTile(imagePath: 'lib/images/apple.png'),
                          ],
                        ),

                        SizedBox(height: verticalSpacing),

                        // already have an account? login now
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(color: Colors.black),
                            ),
                            SizedBox(width: maxWidth * 0.01),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                'Login now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: verticalSpacing),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 