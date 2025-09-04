import 'package:flutter/material.dart';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';
import 'package:flutter_app/components/square_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/language_service.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:flutter_app/providers/auth_provider.dart' as app_auth;

final _logger = Logger('LoginPage');

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

  void _toggleLanguage() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    languageService.toggleLanguage();
  }

  Future<void> _login() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isEnglish = languageService.isEnglish;

    // Validar formulario
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError(isEnglish ? 'Please complete all fields' : 'Por favor, completa todos los campos');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _logger.info('Intentando iniciar sesión con: $email');

    setState(() => _isLoading = true);

    try {
      _logger.info('Llamando a signInWithEmailAndPassword');
      await _authService.signInWithEmailAndPassword(
        email,
        password,
      );

      _logger.info('Inicio de sesión exitoso');
      _showSuccess(isEnglish ? 'Successful login' : 'Inicio de sesión correcto');
    } catch (e) {
      _logger.severe('Excepción durante inicio de sesión: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'email-not-verified') {
          _showError(isEnglish
            ? 'You must verify your email before logging in. Please check your inbox.'
            : 'Debes verificar tu correo antes de iniciar sesión. Por favor, revisa tu bandeja de entrada.');
        } else {
          _showError(_authService.getErrorMessage(e));
        }
      } else {
        _showError(isEnglish ? 'LOGIN ERROR' : 'ERROR DE INICIO DE SESIÓN');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isEnglish = languageService.isEnglish;

    if (_emailController.text.isEmpty) {
      _showError(isEnglish ? 'Please enter your email' : 'Por favor, ingresa tu correo electrónico');
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
        _showSuccess(isEnglish ? 'A recovery link has been sent to your email' : 'Se ha enviado un enlace de recuperación a tu correo');
      }
    } catch (e) {
      _showError(isEnglish ? 'Unexpected error: $e' : 'Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isEnglish = languageService.isEnglish;

    if (_isLoading) return;

    setState(() => _isLoading = true);
    print('Iniciando autenticación con Google desde login');

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        print('Google SignIn cancelado por el usuario');
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      _logger.info('Google SignIn exitoso: ${user.user?.email}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnglish ? 'Successful login' : 'Inicio de sesión correcto'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (e.toString().contains('webAuthenticationOptions argument must be provided on Android')) {
        ScaffoldMessenger.of(context).clearSnackBars();
        _showError('El inicio de sesión no es compatible con Android en este modo.');
      } else if (e is FirebaseAuthException) {
        String mensaje = isEnglish ? 'Login error' : 'Error de inicio de sesión';

        switch (e.code) {
          case 'invalid-credential':
            mensaje = isEnglish 
              ? 'Invalid credentials. Please check your app configuration.'
              : 'Credenciales inválidas. Verifica la configuración de tu app.';
            break;
          case 'user-not-found':
            mensaje = isEnglish 
              ? 'No user found with these credentials.'
              : 'No se encontró usuario con estas credenciales.';
            break;
          case 'unknown-error':
            mensaje = isEnglish 
              ? 'Unknown error. Please try again later.'
              : 'Error desconocido. Por favor, intenta más tarde.';
            break;
          default:
            mensaje = e.message ?? (isEnglish ? 'Error signing in with Google' : 'Error al iniciar sesión con Google');
        }

        _showError(isEnglish ? 'LOGIN ERROR: $mensaje' : 'INICIO DE SESIÓN INCORRECTO: $mensaje');
      } else {
        _showError(isEnglish ? 'LOGIN ERROR: $e' : 'INICIO DE SESIÓN INCORRECTO: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isEnglish = languageService.isEnglish;

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithApple();

      if (userCredential != null && userCredential.user != null) {
        _showSuccess(isEnglish ? 'Successful login' : 'Inicio de sesión correcto');

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        _showError(isEnglish 
          ? 'LOGIN ERROR: Apple sign in is not available'
          : 'INICIO DE SESIÓN INCORRECTO: El inicio de sesión con Apple no está disponible');
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.toLowerCase().contains('webauthenticationoptions')) {
        _showError(isEnglish 
          ? 'Apple sign in is not supported on Android devices.'
          : 'El inicio de sesión con Apple no es compatible con dispositivos Android.');
      } else {
        _showError(isEnglish 
          ? 'LOGIN ERROR: Apple sign in is not available'
          : 'INICIO DE SESIÓN INCORRECTO: El inicio de sesión con Apple no está disponible');
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

  void _enterGuestMode() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isEnglish = languageService.isEnglish;
    
    // Mostrar mensaje informativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnglish 
            ? 'Guest mode is temporarily disabled'
            : 'El modo invitado está temporalmente deshabilitado'
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );

    // Navegar a la aplicación principal
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final isEnglish = languageService.isEnglish;

    return Scaffold(
      backgroundColor: const Color(0xFF96B4D8),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Botón de idioma
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0, top: 20.0),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: _toggleLanguage,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: Text(
                                  isEnglish ? 'EN' : 'ES',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                // logo
                const Icon(
                  Icons.person_sharp,
                  size: 100,
                  color: Colors.white,
                ),

               

                    const SizedBox(height: 40),

                    // welcome back, you've been missed!
                    Text(
                      isEnglish ? 'Welcome!' : '¡Bienvenido!',
                      style: const TextStyle(
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
                        hintText: isEnglish ? 'Email' : 'Correo electrónico',
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        isEmailField: true,
                        textCapitalization: TextCapitalization.none,
                        autoCapitalize: false,
                        validator: (val) =>
                            val!.isEmpty ? (isEnglish ? 'Enter your email' : 'Ingresa tu correo') : null,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // password textfield
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: MyTextField(
                        controller: _passwordController,
                        hintText: isEnglish ? 'Password' : 'Contraseña',
                        obscureText: !_isPasswordVisible,
                        textCapitalization: TextCapitalization.none,
                        autoCapitalize: false,
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
                            val!.isEmpty ? (isEnglish ? 'Enter your password' : 'Ingresa tu contraseña') : null,
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
                            child: Text(
                              isEnglish ? 'Forgot password?' : '¿Olvidaste tu contraseña?',
                              style: const TextStyle(
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
                              text: isEnglish ? 'Sign In' : 'Iniciar sesión',
                            ),
                          ),

                    const SizedBox(height: 15),

                    // guest mode button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _enterGuestMode,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEnglish ? 'Enter as Guest' : 'Entrar como Invitado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              isEnglish ? 'Or continue with' : 'O continuar con',
                              style: const TextStyle(color: Colors.white),
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
                        Text(
                          isEnglish ? 'Don\'t have an account?' : '¿No tienes una cuenta?',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: Text(
                            isEnglish ? 'SIGN UP' : 'REGISTRARTE',
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
            // Botón flotante en la esquina inferior derecha
            
          ],
        ),
      ),
    );
  }
}
