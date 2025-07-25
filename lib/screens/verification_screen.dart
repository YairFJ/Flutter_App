import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter_app/components/my_button.dart';
import 'package:flutter_app/components/my_textfield.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  int _remainingTime = 600; // 10 minutos en segundos
  bool _canResend = true; // Cambiado a true por defecto
  String? _lastSentCode; // Para mostrar el último código enviado en debug si lo deseas

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _startTimer();
          }
        });
      }
    });
  }

  String _formatTime() {
    final minutes = (_remainingTime / 60).floor();
    final seconds = _remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyCode() async {
    if (_isLoading) return;

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Por favor, ingresa el código de verificación');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'Este correo electrónico ya está registrado');
        return;
      }

      final isVerified = await _authService.verifyCode(user.uid, code);
      if (isVerified) {
        if (mounted) {
          print('Código verificado, redirigiendo a HomeScreen');
          await _authService.forceEmailVerification();
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF96B4D8),
              title: const Text('¡Usuario verificado!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: const Text('Tu cuenta ha sido verificada exitosamente.', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Future.delayed(Duration.zero, () {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    });
                  },
                  child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'Código incorrecto');
      }
    } catch (e) {
      String errorMessage = 'Error al verificar el código';
      if (e.toString().contains('El código de verificación ha expirado')) {
        errorMessage = 'El código ha expirado. Solicita uno nuevo.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Este correo electrónico ya está registrado';
      } else if (e.toString().contains('No hay usuario autenticado')) {
        errorMessage = 'Este correo electrónico ya está registrado';
      }
      setState(() => _errorMessage = errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'Este correo electrónico ya está registrado');
        return;
      }

      await _authService.resendVerificationCode(user.email!, user.uid);
      setState(() {
        _remainingTime = 600;
      });
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuevo código enviado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error al reenviar el código';
      if (e.toString().contains('El código de verificación ha expirado')) {
        errorMessage = 'El código ha expirado. Solicita uno nuevo.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'Este correo electrónico ya está registrado';
      } else if (e.toString().contains('No hay usuario autenticado')) {
        errorMessage = 'Este correo electrónico ya está registrado';
      }
      if (mounted) {
        setState(() => _errorMessage = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF96B4D8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 25.0,
            right: 25.0,
            top: 25.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 25.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              const Text(
                'Verificación de Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hemos enviado un código de verificación a tu correo electrónico. Por favor, ingrésalo a continuación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              MyTextField(
                controller: _codeController,
                hintText: 'Código de verificación',
                obscureText: false,
                prefixIcon: const Icon(Icons.lock_outline),
                keyboardType: TextInputType.number,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Tiempo restante: ${_formatTime()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              MyButton(
                onTap: _verifyCode,
                text: 'Verificar',
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : _resendCode, // Solo deshabilitamos si está cargando
                style: TextButton.styleFrom(
                  disabledForegroundColor: Colors.white.withOpacity(0.5),
                ),
                child: Text(
                  'Enviar código',
                  style: TextStyle(
                    color: _isLoading ? Colors.white.withOpacity(0.5) : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Salir de la verificación'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
} 