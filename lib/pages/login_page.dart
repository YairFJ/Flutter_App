import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/components/square_tile.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // Text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Sign user in method
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    // Obtener las dimensiones de la pantalla
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF96B4D8),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.05),

                      // Logo
                      const Icon(
                        Icons.person_sharp,
                        size: 100,
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // Welcome back message
                      Text(
                        'Welcome back you\'ve been missed!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.045, // Ajusta según el ancho de la pantalla
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Username textfield
                      MyTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        obscureText: false,
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Password textfield
                      MyTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        obscureText: true,
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Sign in button
                      MyButton(
                        onTap: signUserIn,
                      ),

                      SizedBox(height: screenHeight * 0.05),

                      // Or continue with
                      Row(
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

                      SizedBox(height: screenHeight * 0.05),

                      // Google + Apple sign in buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          // Google button
                          SquareTile(imagePath: 'lib/images/google.png'),

                          SizedBox(width: 25),

                          // Apple button
                          SquareTile(imagePath: 'lib/images/apple.png'),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Not a member? Register now
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Not a member?',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Register now',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
