import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'dart:async'; 
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_app/config/sendgrid_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AuthService');

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

  // Eliminar variable en memoria

  // Registrar usuario
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _logger.info('Iniciando registro con email y contraseña...');
      
      // Verificar si el email ya está en uso
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        _logger.warning('El email $email ya está en uso');
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Este correo electrónico ya está registrado',
        );
      }

      // Crear el usuario
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        _logger.info('Usuario creado exitosamente:  [32m${user.uid} [0m');
        
        try {
          // Generar código de verificación
          final verificationCode = _generateVerificationCode();
          final timestamp = DateTime.now();
          // Guardar el código y timestamp en Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'isEmailVerified': false,
            'verificationCode': verificationCode,
            'verificationCodeTimestamp': timestamp,
            'lastVerificationAttempt': FieldValue.serverTimestamp(),
            'needsVerification': true,
            'verified': false,
          }, SetOptions(merge: true));
          _logger.info('Documento de usuario creado en Firestore');

          // Actualizar el nombre del usuario
          await user.updateDisplayName(name);
          _logger.info('Nombre de usuario actualizado: $name');

          // Enviar el código de verificación usando Firebase
          await sendVerificationCodeEmail(email, user.uid, name: name);
          _logger.info('Código de verificación enviado a: $email');

          return userCredential;
        } catch (e) {
          _logger.severe('Error durante el proceso de registro: $e');
          // Si algo falla, intentar limpiar
          try {
            await user.delete();
            await _firestore.collection('users').doc(user.uid).delete();
          } catch (cleanupError) {
            _logger.warning('Error durante la limpieza: $cleanupError');
          }
          rethrow;
        }
      }
      
      return null;
    } catch (e) {
      _logger.severe('Error en registerWithEmailAndPassword: $e');
      if (e is FirebaseAuthException) {
        // Asegurarnos de que el mensaje sea amigable para el usuario
        if (e.code == 'email-already-in-use') {
          throw FirebaseAuthException(
            code: e.code,
            message: 'Este correo electrónico ya está registrado',
          );
        }
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
      print('=== Iniciando verificación de código ===');
      print('UserId: $userId');
      print('Código ingresado: $code');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('Error: Usuario no encontrado en Firestore');
        throw Exception('Usuario no encontrado');
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      final storedCode = userData['verificationCode'] as String;
      final timestamp = userData['verificationCodeTimestamp'] as Timestamp;
      final email = userData['email'] as String;
      print('Código almacenado: $storedCode');
      print('Timestamp del código: ${timestamp.toDate()}');
      // Verificar si el código ha expirado (10 minutos)
      final now = DateTime.now();
      final codeTime = timestamp.toDate();
      if (now.difference(codeTime).inMinutes > 10) {
        print('Error: Código expirado');
        throw Exception('El código de verificación ha expirado');
      }
      if (code == storedCode) {
        print('Código verificado correctamente');
        // Actualizar Firestore
        await _firestore.collection('users').doc(userId).update({
          'isEmailVerified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
          'needsVerification': false,
          'verified': true,
        });
        print('Estado de verificación actualizado en Firestore');
        return true;
      }
      print('Error: Código incorrecto');
      return false;
    } catch (e) {
      print('Error al verificar el código: $e');
      rethrow;
    }
  }

  // Método para reenviar el código de verificación
  Future<void> resendVerificationCode(String email, String userId) async {
    try {
      print('=== Iniciando reenvío de código de verificación ===');
      print('Email: $email');
      print('UserId: $userId');
      // Verificar si el documento existe
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('Error: Documento de usuario no encontrado');
        // Crear el documento si no existe
        final verificationCode = _generateVerificationCode();
        final timestamp = DateTime.now();
        await _firestore.collection('users').doc(userId).set({
          'email': email,
          'isEmailVerified': false,
          'verificationCode': verificationCode,
          'verificationCodeTimestamp': timestamp,
          'lastVerificationAttempt': FieldValue.serverTimestamp(),
          'needsVerification': true,
          'verified': false,
        });
        print('Documento de usuario creado');
      }
      // Generar nuevo código
      final verificationCode = _generateVerificationCode();
      final timestamp = DateTime.now();
      // Actualizar el código en Firestore
      await _firestore.collection('users').doc(userId).update({
        'verificationCode': verificationCode,
        'verificationCodeTimestamp': timestamp,
        'lastVerificationAttempt': FieldValue.serverTimestamp(),
      });
      print('Código actualizado en Firestore');
      // Enviar el nuevo código
      await sendVerificationCodeEmail(email, userId);
      print('Nuevo código de verificación enviado a: $email');
      print('=== Proceso de reenvío completado ===');
    } catch (e) {
      print('Error al reenviar código de verificación: $e');
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
      
      // Forzar recarga del usuario de manera más agresiva
      try {
        await _auth.signOut();
        await Future.delayed(const Duration(seconds: 1));
        await _auth.signInWithEmailAndPassword(
          email: user.email!,
          password: '', // La contraseña se mantiene en la sesión
        );
        await Future.delayed(const Duration(seconds: 1));
        await user.reload();
      } catch (e) {
        print('Error durante la recarga forzada: $e');
      }
      
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) return false;
      
      final isVerifiedInAuth = updatedUser.emailVerified;
      print('Estado de verificación desde Firebase Auth: $isVerifiedInAuth');
      
      // Si está verificado en Firebase Auth, actualizar Firestore
      if (isVerifiedInAuth) {
        try {
          await _firestore.collection('users').doc(updatedUser.uid).update({
            'isEmailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          print('Estado de verificación actualizado en Firestore');
          return true;
        } catch (e) {
          print('Error al actualizar Firestore: $e');
          return true; // Si está verificado en Auth, retornamos true aunque falle Firestore
        }
      }
      
      return false;
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

      // Intentar iniciar sesión primero
      print('Intentando iniciar sesión con Firebase Auth...');
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } catch (e) {
        // Manejar específicamente el error de PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails')) {
          print('Error de PigeonUserDetails detectado, intentando recuperar sesión...');
          // Intentar recuperar la sesión actual
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            print('Sesión recuperada exitosamente');
            // Intentar iniciar sesión nuevamente
            userCredential = await _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
          }
        }
        if (userCredential == null) {
          rethrow;
        }
      }
      
      if (userCredential?.user != null) {
        print('Usuario autenticado exitosamente: ${userCredential?.user?.uid}');
        
        // Verificar el estado de verificación en Firestore
        try {
          print('Verificando estado en Firestore...');
          final userDoc = await _firestore
              .collection('users')
              .doc(userCredential!.user!.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            print('Datos del usuario en Firestore: $userData');
            
            // Verificar si el usuario necesita verificación
            if (userData['needsVerification'] == true || userData['verified'] != true) {
              print('Usuario no verificado, cerrando sesión');
              await _auth.signOut(); // Cerrar sesión si no está verificado
              throw FirebaseAuthException(
                code: 'email-not-verified',
                message: 'Por favor, verifica tu correo electrónico antes de iniciar sesión',
              );
            }

            // Actualizar último login en Firestore
            print('Actualizando último login...');
            await _firestore.collection('users').doc(userCredential.user!.uid).update({
              'lastLogin': FieldValue.serverTimestamp(),
            });
            print('Último login actualizado en Firestore');
          } else {
            print('Documento de usuario no encontrado en Firestore, creando...');
            // Crear el documento si no existe
            await _firestore.collection('users').doc(userCredential.user!.uid).set({
              'email': email,
              'name': userCredential.user?.displayName ?? 'Usuario',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'isEmailVerified': true,
              'verified': true,
              'needsVerification': false,
            });
            print('Documento de usuario creado en Firestore');
          }
        } catch (e) {
          print('Error al verificar estado en Firestore: $e');
          if (e is FirebaseException) {
            print('Código de error de Firebase: ${e.code}');
            print('Mensaje de error de Firebase: ${e.message}');
          }
          // Si hay error en Firestore pero la autenticación fue exitosa, permitir el login
        }
        
        print('Login exitoso para: ${userCredential?.user?.email}');
        return userCredential!;
      } else {
        print('Error: No se pudo obtener el usuario después de la autenticación');
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se pudo iniciar sesión',
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');
      print('Stack trace: ${e.stackTrace}');
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
        case 'email-not-verified':
          mensaje = 'Por favor, verifica tu correo electrónico antes de iniciar sesión';
          break;
      }
      
      throw FirebaseAuthException(
        code: e.code,
        message: mensaje,
      );
    } catch (e) {
      print('Error inesperado en login: $e');
      print('Tipo de error: ${e.runtimeType}');
      if (e is Error) {
        print('Stack trace: ${e.stackTrace}');
      }
      
      // Si es el error de PigeonUserDetails, no mostrar el error al usuario
      if (e.toString().contains('PigeonUserDetails')) {
        throw FirebaseAuthException(
          code: 'unknown-error',
          message: 'Error al iniciar sesión. Por favor, intenta nuevamente.',
        );
      }
      
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Error inesperado al iniciar sesión: ${e.toString()}',
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

  // Método para vincular cuentas
  Future<UserCredential?> _linkAccounts(UserCredential googleCredential, String email) async {
    try {
      // Obtener los métodos de inicio de sesión para el email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        // Si existe una cuenta con email/password, intentar vincular
        final user = googleCredential.user;
        if (user != null) {
          // Ya no se puede obtener la contraseña desde Firestore, así que no se puede vincular automáticamente
          // El usuario debe vincular manualmente desde la app
        }
      }
      return googleCredential;
    } catch (e) {
      print('Error al vincular cuentas: $e');
      return googleCredential;
    }
  }

  // Modificar el método de inicio de sesión con Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        // Intentar iniciar sesión con Google
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          final email = userCredential.user!.email;
          if (email != null) {
            // Verificar si existe una cuenta con email/password
            final methods = await _auth.fetchSignInMethodsForEmail(email);
            
            if (methods.contains('password')) {
              // Ya no se puede obtener la contraseña desde Firestore, así que no se puede vincular automáticamente
              // El usuario debe vincular manualmente desde la app
            }
          }
        }

        return userCredential;
      } catch (e) {
        // Ignorar específicamente el error de PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails')) {
          // Si hay un usuario actual, intentar recuperar la sesión
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            // Intentar iniciar sesión nuevamente con las credenciales de Google
            return await _auth.signInWithCredential(credential);
          }
        }
        rethrow;
      }
    } catch (e) {
      _logger.severe('Error en signInWithGoogle: $e');
      rethrow;
    }
  }

  // Inicio de sesión con Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Obtener las credenciales de Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Crear credencial de OAuth para Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Iniciar sesión en Firebase con las credenciales de Apple
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      // Si el usuario existe, actualizar su información en Firestore
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        
        // Actualizar el nombre del usuario si está disponible
        if (displayName.isNotEmpty && user.displayName != displayName) {
          await user.updateDisplayName(displayName);
        }

        // Guardar información adicional en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': displayName.isNotEmpty ? displayName : user.displayName,
          'isEmailVerified': true,
          'lastLogin': FieldValue.serverTimestamp(),
          'provider': 'apple.com',
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      print('Error en signInWithApple: $e');
      rethrow;
    }
  }

  // Enviar email de verificación
  Future<String?> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      
      // Si no hay usuario autenticado, verificar si el email está en uso
      if (user == null) {
        // Obtener el email del último intento de registro
        final lastEmail = await _getLastRegistrationEmail();
        if (lastEmail != null) {
          final methods = await _auth.fetchSignInMethodsForEmail(lastEmail);
          if (methods.isNotEmpty) {
            return 'Este correo electrónico ya está registrado';
          }
        }
        return 'No hay usuario autenticado';
      }

      // Configurar el idioma del email
      await _auth.setLanguageCode('es');
      
      try {
        // Forzar recarga del usuario
        await user.reload();
        
        _logger.info('Enviando email de verificación a: ${user.email}');
        _logger.info('Estado de verificación actual: ${user.emailVerified}');
        
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
          _logger.info('Email de verificación enviado exitosamente con configuración personalizada');
        } catch (e) {
          _logger.warning('Error con configuración personalizada: $e');
          // Si falla con la configuración personalizada, intentar el método básico
          await user.sendEmailVerification();
          _logger.info('Email de verificación enviado exitosamente con método básico');
        }
        
        return null;
      } catch (e) {
        if (e.toString().contains('PigeonUserInfo') || 
            e.toString().contains('PigeonUserDetails')) {
          _logger.warning('Error conocido de Pigeon detectado, intentando solución alternativa');
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
      _logger.severe('Error de Firebase Auth al enviar email: ${e.code} - ${e.message}');
      return getErrorMessage(e);
    } catch (e) {
      _logger.severe('Error inesperado al enviar email: $e');
      return 'Error inesperado: $e';
    }
  }

  // Método para obtener el último email usado en el registro
  Future<String?> _getLastRegistrationEmail() async {
    try {
      // Buscar en la colección de usuarios el último registro
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      _logger.warning('Error al obtener último email de registro: $e');
      return null;
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
        return 'El formato del correo electrónico no es válido';
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
        return 'Contraseña incorrecta';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo, pero con otro método de inicio de sesión';
      default:
        return 'Error al iniciar sesión. Por favor, intenta nuevamente';
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
        'needsVerification': false,
        'verified': true,
      });
      print('Verificación forzada en Firestore');
    } catch (e) {
      print('Error al forzar verificación: $e');
      // No relanzamos el error para permitir que el proceso continúe
    }
  }

  // Método para manejar el enlace de verificación
  Future<bool> handleVerificationLink(String link) async {
    try {
      print('Manejando enlace de verificación: $link');
      
      // Verificar si el enlace es válido
      if (await _auth.isSignInWithEmailLink(link)) {
        print('Enlace de verificación válido');
        
        // Obtener el email del enlace
        String? email = _auth.currentUser?.email;
        if (email == null) {
          print('No se pudo obtener el email del usuario actual');
          return false;
        }
        
        // Completar la verificación
        await _auth.signInWithEmailLink(email: email, emailLink: link);
        print('Verificación completada con éxito');
        
        // Actualizar el estado en Firestore
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'isEmailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          print('Estado de verificación actualizado en Firestore');
        }
        
        return true;
      } else {
        print('Enlace de verificación inválido');
        return false;
      }
    } catch (e) {
      print('Error al manejar enlace de verificación: $e');
      return false;
    }
  }

  // Método para enviar el código de verificación por email
  Future<void> sendVerificationCodeEmail(String email, String userId, {String? name}) async {
    try {
      print('=== Iniciando envío de código de verificación ===');
      print('Email: $email');
      print('UserId: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('Error: Usuario no encontrado en Firestore');
        throw Exception('Usuario no encontrado');
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      final verificationCode = userData['verificationCode'] as String;
      print('Código de verificación: $verificationCode');
      // Configurar el email usando Gmail
      final message = Message()
        ..from = Address('farinayair1@gmail.com', 'Gauge your Recipe')
        ..recipients.add(email)
        ..subject = 'Tu código de verificación'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1 style="color: #96B4D8; text-align: center;">Gauge your Recipe</h1>
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 10px;">
              <h2 style="color: #333;">Tu código de verificación</h2>
              <p style="font-size: 16px; color: #666;">Hola${name != null ? ' $name' : ''},</p>
              <p style="font-size: 16px; color: #666;">Tu código de verificación es:</p>
              <div style="background-color: #96B4D8; color: white; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; border-radius: 5px; margin: 20px 0;">
                $verificationCode
              </div>
              <p style="font-size: 14px; color: #666;">Este código expirará en 10 minutos.</p>
              <p style="font-size: 14px; color: #666;">Si no solicitaste este código, por favor ignora este correo.</p>
            </div>
          </div>
        ''';
      // Enviar el email usando Gmail
      final smtpServer = SmtpServer(
        'smtp.gmail.com',
        port: 587,
        username: 'farinayair1@gmail.com',
        password: 'qugq fchb amdl qfzm', // Contraseña de aplicación de Gmail
        ssl: false,
        allowInsecure: true,
      );
      final sendReport = await send(message, smtpServer);
      print('Email enviado: ${sendReport.toString()}');
      print('=== Proceso de envío de código completado ===');
    } catch (e) {
      print('Error al enviar código de verificación: $e');
      rethrow;
    }
  }
}
