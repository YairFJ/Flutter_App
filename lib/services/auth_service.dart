import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'dart:async'; // Añadir import para TimeoutException

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Registro con email y contraseña
  Future<String?> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      print('Intentando registrar usuario: $email');

      // Verificar si hay un usuario actualmente logueado y cerrar sesión si es así
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print(
            'Hay un usuario logueado, cerrando sesión antes de registrar: ${currentUser.email}');
        await _auth.signOut();

        // Esperar un momento para asegurar que la sesión se cerró
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Crear usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print(
            'Error: userCredential.user es null después de createUserWithEmailAndPassword');
        return 'Error al crear el usuario';
      }

      print(
          'Usuario creado correctamente en Firebase Auth: ${userCredential.user!.uid}');

      // Actualizar nombre del usuario
      await userCredential.user!.updateDisplayName(name);
      print('Nombre de usuario actualizado: $name');

      // Crear documento en Firestore
      try {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'verified': false,
          'provider': 'password',
        });
        print(
            'Documento creado en Firestore para el usuario: ${userCredential.user!.uid}');
      } catch (firestoreError) {
        print('Error al crear documento en Firestore: $firestoreError');
        // Continuar incluso si hay un error en Firestore
      }

      // Enviar email de verificación
      try {
        await userCredential.user!.sendEmailVerification();
        print('Email de verificación enviado a: $email');
      } catch (verificationError) {
        print('Error al enviar email de verificación: $verificationError');
        // Continuar incluso si hay un error en el envío del email
      }

      // Cerrar sesión para forzar la verificación del email
      await _auth.signOut();
      print('Sesión cerrada después del registro para forzar verificación');

      return null; // No hay error
    } on FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException durante el registro: ${e.code} - ${e.message}');
      return _getErrorMessage(e);
    } catch (e) {
      print('Error inesperado durante el registro: $e');
      // Asegurarnos de cerrar sesión en caso de error
      try {
        await _auth.signOut();
      } catch (logoutError) {
        print('Error al cerrar sesión después de error: $logoutError');
      }
      return 'Error inesperado: $e';
    }
  }

  // Login con email y contraseña
  Future<String?> loginWithEmailAndPassword(
      String email, String password) async {
    print('Auth Service: Intentando iniciar sesión con email: $email');
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        print(
            'Auth Service: Error - Usuario es nulo después de signInWithEmailAndPassword');
        return 'Error al iniciar sesión';
      }

      print('Auth Service: Usuario encontrado: ${userCredential.user!.uid}');

      // Verificar si el email está verificado
      if (!userCredential.user!.emailVerified) {
        print(
            'Auth Service: Email no verificado, enviando nuevo email y cerrando sesión');

        // Enviar otro email de verificación
        await userCredential.user!.sendEmailVerification();

        // Asegurarnos de cerrar la sesión
        await _auth.signOut();

        return 'Por favor, verifica tu email. Se ha enviado un nuevo correo de verificación.';
      }

      print(
          'Auth Service: Email verificado, actualizando último inicio de sesión');

      // Actualizar último inicio de sesión
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
        'verified': true,
        'provider': 'password',
      });

      print('Auth Service: Inicio de sesión exitoso');
      return null; // No hay error
    } on FirebaseAuthException catch (e) {
      print(
          'Auth Service: FirebaseAuthException en loginWithEmailAndPassword: ${e.code} - ${e.message}');

      // Asegurarnos de cerrar cualquier sesión parcial
      try {
        await _auth.signOut();
      } catch (logoutError) {
        print('Auth Service: Error al cerrar sesión: $logoutError');
      }

      return _getErrorMessage(e);
    } catch (e) {
      print('Auth Service: Error inesperado en loginWithEmailAndPassword: $e');

      // Asegurarnos de cerrar cualquier sesión parcial
      try {
        await _auth.signOut();
      } catch (logoutError) {
        print(
            'Auth Service: Error al cerrar sesión después de error: $logoutError');
      }

      return 'Error inesperado: $e';
    }
  }

  // Inicio de sesión con Google - Enfoque simplificado
  Future<User?> signInWithGoogle() async {
    try {
      print('Auth Service: Comenzando proceso de inicio de sesión con Google');

      // Cerrar sesión actual si existe
      await _auth.signOut();

      // Crear una nueva instancia de GoogleSignIn
      final GoogleSignIn googleSignIn = GoogleSignIn(
        signInOption: SignInOption.standard,
      );

      // Asegurarse de que no hay sesión previa
      await googleSignIn.signOut();

      print('Auth Service: Solicitando cuenta de Google');

      // Solicitar cuenta de Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Auth Service: Usuario canceló la selección de cuenta');
        return null;
      }

      print('Auth Service: Cuenta seleccionada: ${googleUser.email}');

      try {
        // Solicitar autenticación
        print('Auth Service: Solicitando tokens de autenticación');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Verificar tokens
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('Auth Service: Tokens nulos recibidos');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'No se pudieron obtener credenciales válidas de Google',
          );
        }

        print('Auth Service: Tokens recibidos correctamente');

        // Crear credenciales para Firebase Auth
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken!,
          idToken: googleAuth.idToken!,
        );

        // Iniciar sesión en Firebase
        print('Auth Service: Iniciando sesión en Firebase');
        final userCredential = await _auth.signInWithCredential(credential);

        // Verificar usuario
        final User? user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No se pudo obtener información del usuario',
          );
        }

        print('Auth Service: Inicio de sesión exitoso: ${user.email}');

        // Actualizar información en Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'Usuario de Google',
          'email': user.email ?? '',
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'google',
        }, SetOptions(merge: true));

        return user;
      } catch (e) {
        print('Auth Service: Error en proceso de autenticación: $e');

        // Intentar cerrar sesión en Google para limpiar estado
        await googleSignIn
            .signOut()
            .catchError((e) => print('Error al cerrar sesión de Google: $e'));

        // Relanzar error para ser manejado arriba
        rethrow;
      }
    } catch (e) {
      print('Auth Service: Error global en signInWithGoogle: $e');

      // Asegurarse de cerrar cualquier sesión parcial
      await _auth
          .signOut()
          .catchError((e) => print('Error al cerrar sesión de Firebase: $e'));

      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw FirebaseAuthException(
          code: 'unknown-error',
          message: 'Error inesperado al iniciar sesión con Google: $e',
        );
      }
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

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener usuario actual
  User? getCurrentUser() {
    return _auth.currentUser;
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
