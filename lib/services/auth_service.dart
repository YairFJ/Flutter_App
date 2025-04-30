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
    UserCredential? userCredential;
    try {
      print('=== INICIO DEL PROCESO DE REGISTRO ===');
      print('Email: $email');
      print('Nombre: $name');
      
      // Crear usuario en Firebase Auth
      print('Creando usuario en Firebase Auth...');
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Usuario creado exitosamente con UID: ${userCredential.user?.uid}');
      
      // Asegurarse de que el usuario esté autenticado
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'No se pudo crear el usuario correctamente',
        );
      }

      // Guardar datos del usuario en Firestore primero
      final userData = {
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'userId': userCredential.user?.uid,
        'lastLogin': FieldValue.serverTimestamp(),
        'needsVerification': true,
      };

      print('Guardando datos en Firestore...');
      await _firestore.collection('users').doc(userCredential.user?.uid).set(userData);
      print('Datos guardados en Firestore exitosamente');

      // Enviar email de verificación después de guardar en Firestore
      print('Enviando email de verificación...');
      try {
        // Forzar recarga del usuario
        await userCredential.user?.reload();
        final currentUser = _auth.currentUser;
        
        if (currentUser == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No se encontró el usuario después de la creación',
          );
        }

        print('Usuario actual antes de enviar email: ${currentUser.email}');
        print('Estado de verificación antes de enviar: ${currentUser.emailVerified}');
        
        // Configurar el idioma del email
        await _auth.setLanguageCode('es');
        
        // Enviar el email de verificación
        await currentUser.sendEmailVerification();
        print('Email de verificación enviado exitosamente');
        
        // Verificar el estado después de enviar
        await Future.delayed(const Duration(seconds: 1));
        await currentUser.reload();
        print('Estado de verificación después de enviar: ${currentUser.emailVerified}');
      } catch (e) {
        print('Error al enviar email de verificación: $e');
        if (e is FirebaseAuthException) {
          print('Código de error: ${e.code}');
          print('Mensaje de error: ${e.message}');
          print('Detalles completos: ${e.toString()}');
        }
      }

      print('=== FIN DEL PROCESO DE REGISTRO ===');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth en registro:');
      print('Código: ${e.code}');
      print('Mensaje: ${e.message}');
      throw e;
    } catch (e) {
      print('Error inesperado en registerWithEmailAndPassword: $e');
      // Si es el error de PigeonUserDetails y tenemos un userCredential válido
      if (e.toString().contains('PigeonUserDetails') && userCredential != null) {
        print('Error de PigeonUserDetails detectado, continuando con el proceso...');
        // Intentar enviar el email de verificación de nuevo
        try {
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Intentando enviar email de verificación nuevamente...');
            await currentUser.sendEmailVerification();
            print('Email de verificación enviado en segundo intento');
          }
        } catch (emailError) {
          print('Error al enviar email en segundo intento: $emailError');
        }
        return userCredential;
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
      if (user == null) {
        return 'No hay usuario autenticado';
      }

      // Configurar el idioma del email
      await _auth.setLanguageCode('es');
      
      // Forzar recarga del usuario
      await user.reload();
      
      print('Enviando email de verificación a: ${user.email}');
      print('Estado de verificación actual: ${user.emailVerified}');
      
      await user.sendEmailVerification();
      
      // Verificar el estado después de enviar
      await Future.delayed(const Duration(seconds: 1));
      await user.reload();
      print('Estado de verificación después de enviar: ${user.emailVerified}');
      
      return null;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth al enviar email:');
      print('Código: ${e.code}');
      print('Mensaje: ${e.message}');
      return _getErrorMessage(e);
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
