import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Crear un proveedor de Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // En Android, usa el flujo predeterminado
      if (Platform.isAndroid) {
        return await _auth.signInWithProvider(googleProvider);
      } 
      // En iOS, usa el flujo web
      else {
        return await _auth.signInWithPopup(googleProvider);
      }
    } catch (e) {
      print('Error en el inicio de sesión con Google: $e');
      return null;
    }
  }
} 