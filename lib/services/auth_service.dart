import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'dart:async'; // Añadir import para TimeoutException
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_app/config/sendgrid_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = FlutterSecureStorage();

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
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Iniciando registro con email y contraseña...');
      
      // Verificar si el email ya está en uso
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'El correo electrónico ya está en uso',
        );
      }

      // Crear el usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        print('Usuario creado exitosamente: ${user.uid}');
        
        try {
          // Primero crear el documento en Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'isEmailVerified': false,
            'lastVerificationAttempt': FieldValue.serverTimestamp(),
          });
          print('Documento de usuario creado en Firestore');

          // Luego actualizar el nombre del usuario
          await user.updateDisplayName(name);
          print('Nombre de usuario actualizado: $name');

          // Finalmente enviar el email de verificación
          await user.sendEmailVerification();
          print('Email de verificación enviado a: $email');

          return userCredential;
        } catch (e) {
          print('Error durante el proceso de registro: $e');
          // Si algo falla, intentar limpiar
          try {
            await user.delete();
            await _firestore.collection('users').doc(user.uid).delete();
          } catch (cleanupError) {
            print('Error durante la limpieza: $cleanupError');
          }
          rethrow;
        }
      }
      
      return null;
    } catch (e) {
      print('Error en registerWithEmailAndPassword: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }
      throw Exception('Error al registrar usuario: $e');
    }
  }

  // Método para enviar email de verificación
  Future<void> _sendVerificationEmail(String email, String code) async {
    try {
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: 'tu_correo@gmail.com', // Reemplazar con tu correo
        password: 'tu_contraseña_de_aplicación', // Reemplazar con tu contraseña de aplicación
        ssl: false,
        allowInsecure: true,
      );

      final message = Message()
        ..from = Address('tu_correo@gmail.com', 'Gauge your Recipe')
        ..recipients.add(email)
        ..subject = 'Verifica tu correo electrónico'
        ..html = '''
          <h1>Bienvenido a Gauge your Recipe</h1>
          <p>Tu código de verificación es: <strong>$code</strong></p>
          <p>Este código expirará en 24 horas.</p>
          <p>Si no solicitaste este registro, por favor ignora este correo.</p>
        ''';

      final sendReport = await send(message, smtpServer);
      if (!sendReport.toString().contains('OK')) {
        throw Exception('Error al enviar el correo de verificación');
      }
    } catch (e) {
      throw Exception('Error al enviar el correo de verificación: $e');
    }
  }

  // Método para verificar el código
  Future<bool> verifyCode(String userId, String code) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final storedCode = userData['verificationCode'] as String;
      final timestamp = userData['verificationCodeTimestamp'] as Timestamp;
      
      // Verificar si el código ha expirado (24 horas)
      final now = DateTime.now();
      final codeTime = timestamp.toDate();
      if (now.difference(codeTime).inHours > 24) {
        throw Exception('El código de verificación ha expirado');
      }

      if (code == storedCode) {
        await _firestore.collection('users').doc(userId).update({
          'isVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Error al verificar el código: $e');
    }
  }

  // Método para reenviar correo de verificación
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No hay usuario autenticado');
      
      // Verificar si el documento existe
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('Documento de usuario no encontrado, creándolo...');
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'Usuario',
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': false,
          'lastVerificationAttempt': FieldValue.serverTimestamp(),
        });
      }
      
      try {
        await user.sendEmailVerification();
        print('Email de verificación reenviado exitosamente');
        
        // Actualizar último intento en Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'lastVerificationAttempt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error al reenviar email: $e');
        rethrow;
      }
    } catch (e) {
      print('Error al reenviar correo de verificación: $e');
      rethrow;
    }
  }

  // Verificar si el email está verificado
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No hay usuario autenticado');
        return false;
      }
      
      print('Verificando email para usuario: ${user.email}');
      
      try {
        // Forzar recarga del usuario para obtener el estado más reciente
        await user.reload();
        final isVerifiedInAuth = user.emailVerified;
        print('Estado de verificación desde Firebase Auth: $isVerifiedInAuth');
        
        // Si está verificado en Firebase Auth, actualizar Firestore
        if (isVerifiedInAuth) {
          await _firestore.collection('users').doc(user.uid).update({
            'isEmailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          print('Estado de verificación actualizado en Firestore');
          return true;
        }
        
        // Si no está verificado en Auth, verificar en Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final isVerifiedInFirestore = userData['isEmailVerified'] ?? false;
          print('Estado de verificación desde Firestore: $isVerifiedInFirestore');
          return isVerifiedInFirestore;
        }
        
        return false;
      } catch (e) {
        print('Error al verificar estado: $e');
        return false;
      }
    } catch (e) {
      print('Error en isEmailVerified: $e');
      return false;
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

  // Método para forzar la verificación
  Future<void> forceEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Actualizar Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'isEmailVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      print('Verificación forzada en Firestore');

      // Forzar recarga del usuario
      await user.reload();
      print('Usuario recargado');
    } catch (e) {
      print('Error al forzar verificación: $e');
    }
  }
}
