import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'dart:async'; // Añadir import para TimeoutException
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final smtpServer = gmail('your.email@gmail.com', 'your-app-password');

  // Generar código de verificación
  String _generateVerificationCode() {
    Random random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // Enviar email de verificación
  Future<void> sendEmailVerification(String email, String verificationCode) async {
    final message = Message()
      ..from = Address('edinamita25@gmail.com', 'Gauge your Recipe')
      ..recipients.add(email)
      ..subject = 'Verifica tu cuenta'
      ..text = 'Tu código de verificación es: $verificationCode'
      ..html = '''
        <h1>Verifica tu cuenta</h1>
        <p>Tu código de verificación es: <strong>$verificationCode</strong></p>
        <p>Ingresa este código en la aplicación para completar tu registro.</p>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Error al enviar el email: $e');
    }
  }

  // Registrar usuario
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      print('Iniciando registro de usuario: $email');
      
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Usuario creado exitosamente, enviando email de verificación...');

      // Verificar si estamos en un emulador
      bool isEmulator = false;
      try {
        isEmulator = _auth.app.options.projectId.contains('emulator');
      } catch (e) {
        print('No se pudo verificar si es emulador: $e');
      }

      if (!isEmulator) {
        // Enviar email de verificación solo si no estamos en emulador
        await userCredential.user?.sendEmailVerification();
        print('Email de verificación enviado');
      } else {
        print('Ejecutando en emulador - omitiendo envío de email');
      }

      // Guardar datos del usuario en Firestore con la estructura correcta
      final userData = {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': isEmulator ? true : false,
        'userId': userCredential.user?.uid, // Añadimos el userId
        'lastLogin': FieldValue.serverTimestamp(),
      };

      print('Guardando datos en Firestore: $userData');
      await _firestore.collection('users').doc(userCredential.user?.uid).set(userData);
      print('Datos guardados en Firestore exitosamente');

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth en registro: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Error en registerWithEmailAndPassword: $e');
      if (e.toString().contains('PigeonUserDetails')) {
        print('Error de PigeonUserDetails detectado, intentando recuperar usuario...');
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Usuario recuperado: ${currentUser.email}');
          throw FirebaseAuthException(
            code: 'emulator-user-details',
            message: 'Usuario autenticado en emulador',
          );
        }
      }
      throw e;
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
      bool isEmulator = false;
      try {
        isEmulator = _auth.app.options.projectId.contains('emulator');
      } catch (e) {
        print('No se pudo verificar si es emulador: $e');
      }

      if (isEmulator) {
        print('Ejecutando en emulador - marcando email como verificado');
        // En emulador, actualizamos el estado en Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
        });
        return;
      }

      if (user.emailVerified) {
        print('El email ya está verificado');
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

  // Verificar código
  Future<UserCredential> verifyCode(String email, String code) async {
    try {
      // Obtener datos de verificación
      DocumentSnapshot doc = await _firestore
          .collection('pending_verifications')
          .doc(email)
          .get();

      if (!doc.exists) {
        throw Exception('No se encontró la solicitud de verificación');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['verificationCode'] != code) {
        throw Exception('Código de verificación inválido');
      }

      // Crear usuario en Firestore
      await _firestore.collection('users').doc(email).set({
        'name': data['name'],
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Eliminar datos temporales
      await _firestore.collection('pending_verifications').doc(email).delete();

      // Obtener credenciales del usuario
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: '', // La contraseña ya no es necesaria
      );

      return userCredential;
    } catch (e) {
      throw e;
    }
  }

  // Iniciar sesión
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e;
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
      print('Auth Service: Error durante la autenticación con Google: $e');
      if (e.toString().contains('PigeonUserDetails')) {
        print('Auth Service: Error con PigeonUserDetails detectado');
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Auth Service: Recuperando sesión existente en lugar de mostrar error');
          return currentUser;
        }
        throw FirebaseAuthException(
          code: 'emulator-google-sign-in',
          message: 'Error al iniciar sesión con Google en el emulador. Intenta con un dispositivo físico.',
        );
      }
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
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return null;
      }
      return 'No hay usuario autenticado o el email ya está verificado';
    } catch (e) {
      return 'Error al enviar email de verificación: $e';
    }
  }

  // Enviar email de recuperación de contraseña
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  // Obtener mensaje de error
  String _getErrorMessage(FirebaseAuthException e) {
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
