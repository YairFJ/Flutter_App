import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'dart:async'; // Añadir import para TimeoutException
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_app/config/sendgrid_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generar código de verificación
  String _generateVerificationCode() {
    Random random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // Verificar si estamos en un emulador
  bool _isEmulator() {
    try {
      return _auth.app.options.projectId.contains('emulator') ||
             _auth.app.options.projectId.contains('demo') ||
             _auth.app.options.projectId.contains('test');
    } catch (e) {
      print('Error al verificar emulador: $e');
      return false;
    }
  }

  // Registrar usuario
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      print('=== INICIO DEL PROCESO DE REGISTRO ===');
      print('Email: $email');
      print('Nombre: $name');
      
      // Verificar si el email ya está registrado
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Este correo electrónico ya está registrado',
        );
      }
      
      // Crear usuario en Firebase Auth
      print('Creando usuario en Firebase Auth...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'No se pudo crear el usuario',
        );
      }

      print('Usuario creado exitosamente con UID: ${userCredential.user?.uid}');
      
      // Generar código de verificación
      final verificationCode = _generateVerificationCode();
      
      // Guardar datos del usuario y código de verificación en Firestore
      final userData = {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'userId': userCredential.user?.uid,
        'lastLogin': FieldValue.serverTimestamp(),
        'needsVerification': true,
        'disabled': false,
        'verificationCode': verificationCode,
        'verificationCodeCreatedAt': FieldValue.serverTimestamp(),
      };

      print('Guardando datos en Firestore...');
      await _firestore.collection('users').doc(userCredential.user?.uid).set(userData);
      print('Datos guardados en Firestore exitosamente');

      // Enviar código de verificación por email
      try {
        await _sendVerificationEmail(email, verificationCode);
        print('Email de verificación enviado exitosamente');
      } catch (e) {
        print('Error al enviar email de verificación: $e');
        // No lanzar el error, continuar con el proceso
      }

      print('=== FIN DEL PROCESO DE REGISTRO ===');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth en registro: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado en registro: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Error inesperado durante el registro',
      );
    }
  }

  // Método para enviar email de verificación
  Future<void> _sendVerificationEmail(String email, String code) async {
    try {
      print('=== INICIANDO ENVÍO DE EMAIL ===');
      print('Email destino: $email');
      print('Código de verificación: $code');
      
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: SendGridConfig.fromEmail,
        password: SendGridConfig.apiKey,
        ssl: false,
        allowInsecure: true,
      );

      print('Configuración SMTP creada');
      print('Usuario SMTP: ${SendGridConfig.fromEmail}');

      final message = Message()
        ..from = Address(SendGridConfig.fromEmail, SendGridConfig.fromName)
        ..recipients.add(email)
        ..subject = 'Código de verificación - Tu App'
        ..html = '''
          <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
              <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <h2 style="color: #96B4D8;">Verificación de Email</h2>
                <p>Gracias por registrarte en nuestra aplicación. Para verificar tu cuenta, por favor utiliza el siguiente código:</p>
                <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; margin: 20px 0;">
                  <h1 style="color: #96B4D8; margin: 0; font-size: 32px;">$code</h1>
                </div>
                <p>Este código expirará en 24 horas.</p>
                <p>Si no solicitaste este código, por favor ignora este correo.</p>
                <hr style="border: 1px solid #eee; margin: 20px 0;">
                <p style="color: #666; font-size: 12px;">Este es un correo automático, por favor no respondas a este mensaje.</p>
              </div>
            </body>
          </html>
        ''';

      print('Mensaje configurado, intentando enviar...');

      try {
        final sendReport = await send(message, smtpServer);
        print('Email enviado exitosamente');
        print('Reporte de envío: $sendReport');
      } catch (e) {
        print('Error al enviar email: $e');
        print('Detalles del error: ${e.toString()}');
        // Si falla el envío, mostrar el código en la consola para desarrollo
        print('Código de verificación para $email: $code');
        throw Exception('Error al enviar email: $e');
      }
    } catch (e) {
      print('Error en _sendVerificationEmail: $e');
      print('Stack trace: ${StackTrace.current}');
      // En caso de error, mostrar el código en la consola para desarrollo
      print('Código de verificación para $email: $code');
      throw Exception('Error al enviar email: $e');
    }
  }

  // Método para verificar el código
  Future<bool> verifyCode(String code) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      final storedCode = userData['verificationCode'] as String?;
      final codeCreatedAt = userData['verificationCodeCreatedAt'] as Timestamp?;

      if (storedCode == null || codeCreatedAt == null) return false;

      // Verificar si el código ha expirado (24 horas)
      final now = DateTime.now();
      final codeAge = now.difference(codeCreatedAt.toDate());
      if (codeAge.inHours > 24) {
        throw Exception('El código de verificación ha expirado');
      }

      if (storedCode == code) {
        // Marcar usuario como verificado
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
          'needsVerification': false,
          'verificationCode': FieldValue.delete(),
          'verificationCodeCreatedAt': FieldValue.delete(),
        });
        return true;
      }

      return false;
    } catch (e) {
      print('Error al verificar código: $e');
      return false;
    }
  }

  // Método para reenviar código de verificación
  Future<void> resendVerificationCode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');

      final newCode = _generateVerificationCode();
      
      await _firestore.collection('users').doc(user.uid).update({
        'verificationCode': newCode,
        'verificationCodeCreatedAt': FieldValue.serverTimestamp(),
      });

      await _sendVerificationEmail(user.email!, newCode);
    } catch (e) {
      print('Error al reenviar código: $e');
      rethrow;
    }
  }

  // Verificar email
  Future<void> verifyEmail() async {
    try {
      final user = _auth.currentUser;
      print('=== Iniciando verificación de email ===');
      print('Usuario actual: ${user?.email}');
      print('Email verificado: ${user?.emailVerified}');
      print('Proveedor: ${user?.providerData.map((e) => e.providerId).join(', ')}');
      
      if (user == null) {
        print('Error: No hay usuario autenticado');
        throw Exception('No hay usuario autenticado');
      }

      // Verificar si estamos en un emulador
      bool isEmulator = _isEmulator();
      print('¿Es emulador?: $isEmulator');

      if (isEmulator) {
        print('Ejecutando en emulador - marcando email como verificado');
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
          'needsVerification': false,
        });
        return;
      }

      if (user.emailVerified) {
        print('El email ya está verificado');
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
          'needsVerification': false,
        });
        return;
      }

      print('Intentando enviar email de verificación...');
      try {
        await user.sendEmailVerification();
        print('Email de verificación enviado exitosamente');
      } on FirebaseAuthException catch (e) {
        print('Error de Firebase Auth al enviar email:');
        print('Código: ${e.code}');
        print('Mensaje: ${e.message}');
        print('Detalles: ${e.toString()}');
        throw e;
      } catch (e) {
        print('Error inesperado al enviar email: $e');
        throw e;
      }
    } catch (e) {
      print('Error en verifyEmail: $e');
      rethrow;
    }
  }

  // Verificar estado de verificación
  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      final updatedUser = _auth.currentUser;
      
      if (updatedUser?.emailVerified == true) {
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
          'needsVerification': false,
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error al verificar email: $e');
      return false;
    }
  }

  // Iniciar sesión
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('=== INICIO DEL PROCESO DE LOGIN ===');
      print('Email: $email');
      
      // Validar email
      if (!email.contains('@') || !email.contains('.')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'El formato del correo electrónico no es válido',
        );
      }

      // Validar contraseña
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'La contraseña debe tener al menos 6 caracteres',
        );
      }

      // Verificar si el usuario existe
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No existe una cuenta con este correo electrónico',
        );
      }
      
      // Intentar iniciar sesión
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Verificar si el usuario existe
      if (userCredential.user != null) {
        // Verificar si el usuario está verificado
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (userData['needsVerification'] == true) {
            throw FirebaseAuthException(
              code: 'email-not-verified',
              message: 'Por favor, verifica tu correo electrónico antes de iniciar sesión',
            );
          }
        }

        // Actualizar último login en Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        print('Login exitoso para: ${userCredential.user?.email}');
        return userCredential;
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se pudo iniciar sesión',
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');
      String mensaje = 'Error al iniciar sesión';
      
      switch (e.code) {
        case 'invalid-credential':
          mensaje = 'Correo electrónico o contraseña incorrectos';
          break;
        case 'user-not-found':
          mensaje = 'No existe una cuenta con este correo electrónico';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          mensaje = 'El formato del correo electrónico no es válido';
          break;
        case 'user-disabled':
          mensaje = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'too-many-requests':
          mensaje = 'Demasiados intentos fallidos. Por favor, intenta más tarde';
          break;
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: mensaje,
      );
    } catch (e) {
      print('Error inesperado en login: $e');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Error inesperado al iniciar sesión',
      );
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      throw e;
    }
  }

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Método simplificado para iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      print('Auth Service: Iniciando método simplificado de inicio de sesión con Google');

      // Verificar si ya hay un usuario autenticado con Google
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (currentUser.providerData
            .any((provider) => provider.providerId == 'google.com')) {
          print('Auth Service: Usuario ya autenticado con Google, devolviendo usuario actual');
          return currentUser;
        }
      }

      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await _auth.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Auth Service: Usuario canceló el inicio de sesión');
        return null;
      }

      print('Auth Service: Cuenta seleccionada: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user != null) {
          print('Auth Service: Inicio de sesión exitoso: ${user.email}');
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'name': user.displayName ?? 'Usuario de Google',
              'email': user.email ?? '',
              'lastLogin': FieldValue.serverTimestamp(),
              'provider': 'google',
              'verified': true,
            }, SetOptions(merge: true));
          } catch (e) {
            print('Auth Service: Error al actualizar Firestore: $e');
          }
        }
        return user;
      } catch (e) {
        print('Auth Service: Error durante signInWithCredential: $e');
        if (e.toString().contains('PigeonUserDetails')) {
          print('Auth Service: Error de PigeonUserDetails detectado, intentando recuperar sesión');
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Auth Service: Sesión recuperada exitosamente');
            return currentUser;
          }
        }
        rethrow;
      }
    } catch (e) {
      print('Auth Service: Error durante la autenticación con Google: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
      rethrow;
    }
  }

  // Inicio de sesión con Apple (simulado para Android)
  Future<UserCredential?> signInWithApple() async {
    try {
      // Esta implementación es un marcador de posición
      // Para una implementación real, necesitarías el apple_sign_in package

      // En Android, podemos mostrar un mensaje que no está disponible
      if (Platform.isAndroid) {
        throw Exception('Inicio de sesión con Apple no disponible en Android');
      }

      // Para iOS, implementarías la autenticación real con Apple
      // Esta es una simulación
      return null;
    } catch (e) {
      print('Error al iniciar sesión con Apple: $e');
      return null;
    }
  }

  // Enviar email de verificación
  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 'No hay usuario autenticado';
      }

      // Configurar el idioma del email
      await _auth.setLanguageCode('es');
      
      try {
        // Forzar recarga del usuario
        await user.reload();
        
        print('Enviando email de verificación a: ${user.email}');
        print('Estado de verificación actual: ${user.emailVerified}');
        
        // Para evitar el error de PigeonUserInfo/PigeonUserDetails, intentamos un método más simple
        try {
          // Configurar URL de acción personalizada si es necesario
          ActionCodeSettings actionCodeSettings = ActionCodeSettings(
            url: 'https://restaurante-app-6e13d.firebaseapp.com/__/auth/action',
            handleCodeInApp: true,
            androidPackageName: 'com.yourcompany.restaurante_app',
            androidInstallApp: true,
            androidMinimumVersion: '12',
            iOSBundleId: 'com.yourcompany.restauranteApp',
          );
          
          // Enviar email con las configuraciones personalizadas
          await user.sendEmailVerification(actionCodeSettings);
          print('Email de verificación enviado exitosamente con configuración personalizada');
        } catch (e) {
          print('Error con configuración personalizada: $e');
          // Si falla con la configuración personalizada, intentar el método básico
          await user.sendEmailVerification();
          print('Email de verificación enviado exitosamente con método básico');
        }
        
        return null;
      } catch (e) {
        if (e.toString().contains('PigeonUserInfo') || 
            e.toString().contains('PigeonUserDetails')) {
          print('Error conocido de Pigeon detectado, intentando solución alternativa');
          // Si es error de Pigeon, marcar como verificado en Firestore para desarrollo
          if (_isEmulator()) {
            await _firestore.collection('users').doc(user.uid).update({
              'verified': true,
              'needsVerification': false,
            });
            return 'Verificación simulada en entorno de desarrollo';
          }
          return 'Error de Firebase: Por favor, intenta de nuevo más tarde';
        }
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth al enviar email:');
      print('Código: ${e.code}');
      print('Mensaje: ${e.message}');
      return getErrorMessage(e);
    } catch (e) {
      print('Error inesperado al enviar email: $e');
      return 'Error inesperado: $e';
    }
  }

  // Enviar email de recuperación de contraseña
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return getErrorMessage(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Obtener mensaje de error
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'El formato del correo no es válido';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo, pero con otro método de inicio de sesión';
      default:
        return e.message ?? 'Error desconocido';
    }
  }
}
