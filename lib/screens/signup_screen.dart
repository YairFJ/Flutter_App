import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/components/square_tile.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        await userCredential.user?.updateDisplayName(usernameController.text.trim());
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al registrar usuario')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
                          controller: usernameController,
                          hintText: 'Username',
                          obscureText: false,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: emailController,
                          hintText: 'Email',
                          obscureText: false,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          obscureText: true,
                        ),

                        SizedBox(height: verticalSpacing),

                        MyTextField(
                          controller: confirmPasswordController,
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
                            const SquareTile(imagePath: 'lib/images/google.png'),
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
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
} 